# The app end to end, driven the way a user drives it, against ImapKit (core/e2e). Every feature is used once and
# its effect checked, on the server through ImapKit's REST API where there is one: adding an account (and a wrong
# password), reading plain and HTML mail, marking read and unread, inline and remote pictures, saving an attachment,
# replying, replying to all, forwarding, writing a new message (and a mistyped address), Send/Recv, Sent Items,
# About and the help. A screenshot of each step goes to -Out (scripts/feature-map.mjs builds a page from them).
#
#   powershell -ExecutionPolicy Bypass -File scripts\ui-e2e.ps1 [-Exe build\InboxClassic.exe] [-Out build\ui-e2e]
#
# Needs a desktop (a logged in session, or a CI runner), Node.js and `npm ci` in core\e2e. The app runs with a
# store of its own and --memory-passwords, so nothing of the user's is touched. The control and command ids are those
# of app/src/app.h, accounts.cpp and compose.cpp.
param(
    [string]$Exe = (Join-Path $PSScriptRoot '..\build\InboxClassic.exe'),
    [string]$Out = (Join-Path $PSScriptRoot '..\build\ui-e2e')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -Namespace Native -Name Win -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindow(string cls, string title);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string cls, string title);
[DllImport("user32.dll")] public static extern IntPtr GetDlgItem(IntPtr hwnd, int id);
[DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, string lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hwnd, uint message, IntPtr wParam, System.Text.StringBuilder lParam);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out RECT rect);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int cx, int cy, uint flags);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
[DllImport("user32.dll")] public static extern IntPtr GetDesktopWindow();
[DllImport("user32.dll")] public static extern bool IsWindowEnabled(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hwnd);
[DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hwnd);
[DllImport("user32.dll")] public static extern IntPtr GetWindow(IntPtr hwnd, uint cmd);
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
[DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(uint access, bool inherit, uint pid);
[DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr process, IntPtr address, IntPtr size, uint type, uint protect);
[DllImport("kernel32.dll")] public static extern bool VirtualFreeEx(IntPtr process, IntPtr address, IntPtr size, uint type);
[DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr process, IntPtr address, byte[] buffer, IntPtr size, out IntPtr read);
[DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
public delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumProc proc, IntPtr lParam);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc proc, IntPtr lParam);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hwnd, System.Text.StringBuilder name, int size);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int InternalGetWindowText(IntPtr hwnd, System.Text.StringBuilder text, int size);
[DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr menu);
[DllImport("user32.dll")] public static extern IntPtr GetSubMenu(IntPtr menu, int position);
[DllImport("user32.dll")] public static extern bool GetMenuItemRect(IntPtr hwnd, IntPtr menu, uint item, out RECT rect);
[DllImport("user32.dll")] public static extern uint GetMenuState(IntPtr menu, uint id, uint flags);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetMenuString(IntPtr menu, uint item, System.Text.StringBuilder text, int size, uint flags);
// the labels of a menu's items, by position (separators empty)
public static string[] MenuLabels(IntPtr menu) {
    int count = GetMenuItemCount(menu);
    var labels = new string[count < 0 ? 0 : count];
    for (int i = 0; i < labels.Length; i++) {
        var text = new System.Text.StringBuilder(128);
        GetMenuString(menu, (uint)i, text, 128, 0x400);
        labels[i] = text.ToString().Replace("&", "");
    }
    return labels;
}
public struct RECT { public int Left, Top, Right, Bottom; }
[StructLayout(LayoutKind.Sequential)] public struct GUITHREADINFO { public int cbSize, flags; public IntPtr active, focus, capture, menuOwner, moveSize, caret; public RECT caretRect; }
[DllImport("user32.dll")] public static extern bool GetGUIThreadInfo(uint thread, ref GUITHREADINFO info);
// the window with the keyboard focus in the thread of `window`
public static IntPtr FocusOf(IntPtr window) {
    uint pid;
    var info = new GUITHREADINFO { cbSize = Marshal.SizeOf(typeof(GUITHREADINFO)) };
    return GetGUIThreadInfo(GetWindowThreadProcessId(window, out pid), ref info) ? info.focus : IntPtr.Zero;
}
[StructLayout(LayoutKind.Sequential)] struct MouseInput { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
[StructLayout(LayoutKind.Explicit)] struct Input { [FieldOffset(0)] public uint type; [FieldOffset(8)] public MouseInput mouse; }
[DllImport("user32.dll")] static extern uint SendInput(uint count, Input[] inputs, int size);
[DllImport("user32.dll")] static extern int GetSystemMetrics(int index);
// the mouse as a user's: moved to (x, y), screen pixels, with the left button pressed (0x0002), let go (0x0004) or
// neither (0)
public static void Mouse(int x, int y, uint button) {
    var input = new Input { type = 0 };
    input.mouse.dx = x * 65535 / (GetSystemMetrics(0) - 1);
    input.mouse.dy = y * 65535 / (GetSystemMetrics(1) - 1);
    input.mouse.flags = button | 0x0001 | 0x8000;
    SendInput(1, new[] { input }, Marshal.SizeOf(typeof(Input)));
    System.Threading.Thread.Sleep(50);
}
// a click of the left mouse button at (x, y)
public static void MouseClick(int x, int y) {
    foreach (uint button in new uint[] { 0, 0x0002, 0x0004 }) { Mouse(x, y, button); }
}
// a click of the right mouse button at (x, y)
public static void MouseRightClick(int x, int y) {
    foreach (uint button in new uint[] { 0, 0x0008, 0x0010 }) { Mouse(x, y, button); }
}
// from (x, y) with the button pressed, a few steps at a time, to (toX, toY), where it stays pressed
public static void MouseDragTo(int x, int y, int toX, int toY) {
    Mouse(x, y, 0);
    Mouse(x, y, 0x0002);
    for (int i = 1; i <= 20; i++) { Mouse(x + (toX - x) * i / 20, y + (toY - y) * i / 20, 0); }
    System.Threading.Thread.Sleep(300);
}
[DllImport("user32.dll")] public static extern void keybd_event(byte key, byte scan, uint flags, IntPtr extra);
[DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hwnd, ref POINT point);
public struct POINT { public int X, Y; }
[DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr process, IntPtr address, byte[] buffer, IntPtr size, out IntPtr written);
// a rectangle a control of another process fills in (LVM_GETITEMRECT, TVM_GETITEMRECT) from `seed` at its start, in
// screen pixels
public static RECT RemoteRect(IntPtr window, uint message, IntPtr wParam, long seed) {
    uint pid;
    GetWindowThreadProcessId(window, out pid);
    var rect = new RECT();
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return rect; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)16, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        IntPtr done;
        byte[] start = new byte[16];
        BitConverter.GetBytes(seed).CopyTo(start, 0);
        WriteProcessMemory(process, remote, start, (IntPtr)16, out done);
        if (SendMessage(window, message, wParam, remote) != IntPtr.Zero) {
            byte[] bytes = new byte[16];
            ReadProcessMemory(process, remote, bytes, (IntPtr)16, out done);
            var corner = new POINT { X = BitConverter.ToInt32(bytes, 0), Y = BitConverter.ToInt32(bytes, 4) };
            var end = new POINT { X = BitConverter.ToInt32(bytes, 8), Y = BitConverter.ToInt32(bytes, 12) };
            ClientToScreen(window, ref corner);
            ClientToScreen(window, ref end);
            rect = new RECT { Left = corner.X, Top = corner.Y, Right = end.X, Bottom = end.Y };
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return rect;
}
// where the tooltip of tool `id` of `owner` (a header's column) is, in screen pixels: found among the tooltip windows
// of owner's process (TTM_ENUMTOOLSW into its memory); empty when there is none
public static RECT RemoteToolRect(IntPtr owner, long id) {
    uint pid;
    GetWindowThreadProcessId(owner, out pid);
    var found = new RECT();
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return found; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)128, 0x3000, 0x04);
    var tips = new System.Collections.Generic.List<IntPtr>();
    EnumWindows((hwnd, l) => {
        uint owned;
        GetWindowThreadProcessId(hwnd, out owned);
        var name = new System.Text.StringBuilder(64);
        GetClassName(hwnd, name, 64);
        if (owned == pid && name.ToString() == "tooltips_class32") { tips.Add(hwnd); }
        return true;
    }, IntPtr.Zero);
    foreach (IntPtr tip in tips) {
        int count = (int)SendMessage(tip, 0x040D, IntPtr.Zero, IntPtr.Zero);
        for (int i = 0; i < count && remote != IntPtr.Zero; i++) {
            IntPtr done;
            // a TOOLINFOW of 64-bit Windows in its first version's size, as the classic tooltips take it: cbSize,
            // uFlags, hwnd, uId, rect, then pointers left empty (no text copied)
            byte[] info = new byte[72];
            BitConverter.GetBytes(64).CopyTo(info, 0);
            WriteProcessMemory(process, remote, info, (IntPtr)72, out done);
            if (SendMessage(tip, 0x043A, (IntPtr)i, remote) == IntPtr.Zero) { continue; }
            ReadProcessMemory(process, remote, info, (IntPtr)72, out done);
            if (BitConverter.ToInt64(info, 8) != owner.ToInt64() || BitConverter.ToInt64(info, 16) != id) { continue; }
            var corner = new POINT { X = BitConverter.ToInt32(info, 24), Y = BitConverter.ToInt32(info, 28) };
            var end = new POINT { X = BitConverter.ToInt32(info, 32), Y = BitConverter.ToInt32(info, 36) };
            ClientToScreen(owner, ref corner);
            ClientToScreen(owner, ref end);
            found = new RECT { Left = corner.X, Top = corner.Y, Right = end.X, Bottom = end.Y };
        }
    }
    if (remote != IntPtr.Zero) { VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000); }
    CloseHandle(process);
    return found;
}
// the text of tree item `item` of a tree view of another process (TVM_GETITEMW into its memory)
public static string RemoteTreeText(IntPtr tree, IntPtr item) {
    uint pid;
    GetWindowThreadProcessId(tree, out pid);
    string text = "";
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return text; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)1024, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        IntPtr done;
        // TVITEMW on x64: mask, hItem at 8, pszText at 24, cchTextMax at 32; the text after it at 64
        byte[] tvitem = new byte[64];
        BitConverter.GetBytes((uint)0x0011).CopyTo(tvitem, 0);
        BitConverter.GetBytes(item.ToInt64()).CopyTo(tvitem, 8);
        BitConverter.GetBytes(remote.ToInt64() + 64).CopyTo(tvitem, 24);
        BitConverter.GetBytes(256).CopyTo(tvitem, 32);
        WriteProcessMemory(process, remote, tvitem, (IntPtr)64, out done);
        if (SendMessage(tree, 0x113E, IntPtr.Zero, remote) != IntPtr.Zero) {
            byte[] bytes = new byte[512];
            ReadProcessMemory(process, (IntPtr)(remote.ToInt64() + 64), bytes, (IntPtr)512, out done);
            text = System.Text.Encoding.Unicode.GetString(bytes);
            int end = text.IndexOf('\0');
            if (end >= 0) { text = text.Substring(0, end); }
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return text;
}
// a string handed to another window with WM_COPYDATA (the app's test hooks, with --test-hooks); what it returns
[StructLayout(LayoutKind.Sequential)] public struct COPYDATASTRUCT { public IntPtr dwData; public int cbData; public IntPtr lpData; }
[DllImport("user32.dll", EntryPoint = "SendMessageW")] static extern IntPtr SendCopyData(IntPtr hwnd, uint message, IntPtr wParam, ref COPYDATASTRUCT data);
public static long SendText(IntPtr hwnd, long kind, string text) {
    byte[] bytes = System.Text.Encoding.Unicode.GetBytes(text);
    IntPtr memory = Marshal.AllocHGlobal(Math.Max(bytes.Length, 1));
    Marshal.Copy(bytes, 0, memory, bytes.Length);
    COPYDATASTRUCT data = new COPYDATASTRUCT { dwData = (IntPtr)kind, cbData = bytes.Length, lpData = memory };
    long result = SendCopyData(hwnd, 0x004A, IntPtr.Zero, ref data).ToInt64();
    Marshal.FreeHGlobal(memory);
    return result;
}
// the text of a cell of a list view of another process (LVM_GETITEMTEXTW into its memory)
public static string RemoteListText(IntPtr list, int row, int column) {
    uint pid;
    GetWindowThreadProcessId(list, out pid);
    string text = "";
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return text; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)1024, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        IntPtr done;
        // LVITEMW on x64: iSubItem at 8, pszText at 24, cchTextMax at 32; the text after it at 128
        byte[] item = new byte[128];
        BitConverter.GetBytes(column).CopyTo(item, 8);
        BitConverter.GetBytes(remote.ToInt64() + 128).CopyTo(item, 24);
        BitConverter.GetBytes(256).CopyTo(item, 32);
        WriteProcessMemory(process, remote, item, (IntPtr)128, out done);
        int length = (int)SendMessage(list, 0x1073, (IntPtr)row, remote);
        if (length > 0) {
            byte[] bytes = new byte[length * 2];
            ReadProcessMemory(process, (IntPtr)(remote.ToInt64() + 128), bytes, (IntPtr)bytes.Length, out done);
            text = System.Text.Encoding.Unicode.GetString(bytes);
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return text;
}
// a text a window of another process writes into memory it is given with a message Windows does not copy between
// processes (TB_GETBUTTONTEXTW), its length the result of `message`
public static string RemoteText(IntPtr window, uint message, IntPtr wParam) {
    uint pid;
    GetWindowThreadProcessId(window, out pid);
    string text = "";
    IntPtr process = OpenProcess(0x0038, false, pid);
    if (process == IntPtr.Zero) { return text; }
    IntPtr remote = VirtualAllocEx(process, IntPtr.Zero, (IntPtr)4096, 0x3000, 0x04);
    if (remote != IntPtr.Zero) {
        int length = (int)SendMessage(window, message, wParam, remote);
        if (length > 0 && length < 2048) {
            IntPtr done;
            byte[] bytes = new byte[length * 2];
            ReadProcessMemory(process, remote, bytes, (IntPtr)bytes.Length, out done);
            text = System.Text.Encoding.Unicode.GetString(bytes);
        }
        VirtualFreeEx(process, remote, IntPtr.Zero, 0x8000);
    }
    CloseHandle(process);
    return text;
}
[DllImport("user32.dll")] public static extern IntPtr GetMenu(IntPtr hwnd);
[DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hwnd, int index);
[DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hwnd, out RECT rect);
[DllImport("user32.dll")] static extern IntPtr GetDC(IntPtr hwnd);
[DllImport("user32.dll")] static extern int ReleaseDC(IntPtr hwnd, IntPtr dc);
[DllImport("gdi32.dll")] static extern IntPtr SelectObject(IntPtr dc, IntPtr obj);
[DllImport("gdi32.dll")] static extern IntPtr GetStockObject(int index);
[DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int DrawText(IntPtr dc, string text, int count, ref RECT rect, uint format);
// whether the words of a control fit it in the dialog font the app gives its controls (DEFAULT_GUI_FONT): a static's
// wrapped to its width within its height, a button's on one line with room for its frame, and for its box when `box`
public static bool Fits(IntPtr hwnd, string text, bool button, bool box, bool wraps = false, bool edit = false) {
    RECT client;
    GetClientRect(hwnd, out client);
    IntPtr dc = GetDC(hwnd);
    IntPtr old = SelectObject(dc, GetStockObject(17));
    int width = client.Right - client.Left - (button ? (box ? 18 : 8) : 0);
    RECT need = new RECT { Left = 0, Top = 0, Right = width, Bottom = 0 };
    // DT_CALCRECT, and DT_SINGLELINE or DT_WORDBREAK (a multi-line button's words wrap as a static text's do)
    bool single = button && !wraps;
    // DT_EDITCONTROL for a static text that wraps as an edit control does (SS_EDITCONTROL), breaking a long word
    DrawText(dc, text, -1, ref need, 0x400u | (single ? 0x20u : 0x10u) | (edit ? 0x2000u : 0u));
    SelectObject(dc, old);
    ReleaseDC(hwnd, dc);
    return need.Right <= width && (single || need.Bottom <= client.Bottom - client.Top);
}
// a static text's words fit it, measured in the font it has (a heading's larger one) and wrapped as it wraps them,
// or on one line for one that cuts its words (SS_ENDELLIPSIS)
public static bool FitsOwnFont(IntPtr hwnd, string text) {
    RECT client;
    GetClientRect(hwnd, out client);
    IntPtr dc = GetDC(hwnd);
    IntPtr font = SendMessage(hwnd, 0x0031, IntPtr.Zero, IntPtr.Zero);
    IntPtr old = SelectObject(dc, font != IntPtr.Zero ? font : GetStockObject(17));
    int width = client.Right - client.Left;
    int style = GetWindowLong(hwnd, -16);
    bool single = (style & 0xC000) == 0x4000;
    // SS_EDITCONTROL: a word longer than a line is broken, as DT_EDITCONTROL breaks it
    bool edit = (style & 0x2000) != 0;
    RECT need = new RECT { Left = 0, Top = 0, Right = width, Bottom = 0 };
    DrawText(dc, text, -1, ref need, 0x400u | 0x800u | (single ? 0x20u : 0x10u) | (edit ? 0x2000u : 0u));
    SelectObject(dc, old);
    ReleaseDC(hwnd, dc);
    return need.Right <= width && need.Bottom <= client.Bottom - client.Top;
}
// the visible top-level windows of class `cls` of the processes `pids`, in z-order (the front one first)
public static System.Collections.Generic.List<IntPtr> TopWindowsOf(uint[] pids, string cls) {
    var found = new System.Collections.Generic.List<IntPtr>();
    EnumWindows((hwnd, _) => {
        uint pid;
        GetWindowThreadProcessId(hwnd, out pid);
        if (Array.IndexOf(pids, pid) < 0 || !IsWindowVisible(hwnd)) { return true; }
        var name = new System.Text.StringBuilder(64);
        GetClassName(hwnd, name, 64);
        if (name.ToString() == cls) { found.Add(hwnd); }
        return true;
    }, IntPtr.Zero);
    return found;
}
// the window that owns the menu of the thread of `menu` (GUITHREADINFO.hwndMenuOwner)
public static IntPtr MenuOwnerOf(IntPtr menu) {
    uint pid;
    var info = new GUITHREADINFO { cbSize = Marshal.SizeOf(typeof(GUITHREADINFO)) };
    return GetGUIThreadInfo(GetWindowThreadProcessId(menu, out pid), ref info) ? info.menuOwner : IntPtr.Zero;
}
// the windows of class `cls` anywhere under `parent`
public static System.Collections.Generic.List<IntPtr> FindDescendants(IntPtr parent, string cls) {
    var found = new System.Collections.Generic.List<IntPtr>();
    EnumChildWindows(parent, (hwnd, _) => {
        var name = new System.Text.StringBuilder(64);
        GetClassName(hwnd, name, 64);
        if (name.ToString() == cls) { found.Add(hwnd); }
        return true;
    }, IntPtr.Zero);
    return found;
}
'@
# what a screen reader is told of a control's item (its accessible description, MSAA)
Add-Type -ReferencedAssemblies Accessibility -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class AccLook {
    [DllImport("oleacc.dll")] static extern int AccessibleObjectFromWindow(IntPtr hwnd, uint id, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out Accessibility.IAccessible acc);
    // item `child` (from 1) of the client of `hwnd` (OBJID_CLIENT), or null
    public static string Description(IntPtr hwnd, int child) {
        Guid iid = new Guid("618736E0-3C3D-11CF-810C-00AA00389B71");
        Accessibility.IAccessible acc;
        if (AccessibleObjectFromWindow(hwnd, 0xFFFFFFFC, ref iid, out acc) != 0 || acc == null) { return null; }
        try { return acc.get_accDescription(child); } catch { return null; }
    }
}
'@
[void][Native.Win]::SetProcessDPIAware()

$WM_SETTEXT = 0x000C; $WM_GETTEXT = 0x000D; $WM_CLOSE = 0x0010; $WM_COMMAND = 0x0111; $WM_KEYDOWN = 0x0100
$WM_KEYUP = 0x0101; $CB_SETCURSEL = 0x014E; $CB_GETCOUNT = 0x0146; $CB_GETLBTEXT = 0x0148; $EM_SETSEL = 0x00B1; $EM_REPLACESEL = 0x00C2
$TVM_GETCOUNT = 0x1105; $TVM_GETNEXTITEM = 0x110A; $TVM_SELECTITEM = 0x110B; $LVM_GETITEMCOUNT = 0x1004; $LVM_GETNEXTITEM = 0x100C
$VK_RETURN = 0x0D; $VK_ESCAPE = 0x1B; $VK_SPACE = 0x20; $VK_HOME = 0x24; $VK_UP = 0x26; $VK_DOWN = 0x28; $VK_DELETE = 0x2E
# app/src/app.h
$IDM_NEW_ACCOUNT = 100; $IDM_EXIT = 101; $IDM_SYNC = 102; $IDM_MARK_READ = 103; $IDM_MARK_UNREAD = 104; $IDM_PICTURES = 105
$IDM_VIEW_SOURCE = 132; $IDM_AI_AGENTS = 133
$IDM_ABOUT = 106; $IDM_NEW_MAIL = 107; $IDM_REPLY = 108; $IDM_REPLY_ALL = 109; $IDM_FORWARD = 110; $IDM_HELP = 111
$IDM_DELETE = 112; $IDM_MOVE = 113; $IDM_FLAG = 114; $IDM_NEW_FOLDER = 115; $IDM_RENAME_FOLDER = 116; $IDM_DELETE_FOLDER = 117; $IDM_ACCOUNTS = 118; $IDM_SAVE_AS = 121; $IDM_PRINT = 122; $IDM_PRINT_CONVERSATION = 179; $IDM_IMPORT = 123; $IDM_OUTBOX = 124; $IDM_PROPERTIES = 125; $IDC_SAVE = 309;
$LB_GETTEXT = 0x0189; $LB_GETCOUNT = 0x018B; $LB_SETCURSEL = 0x0186; $CB_SELECTSTRING = 0x014D
$IDC_TREE = 200; $IDC_LIST = 201; $IDC_ATTACHMENTS = 202; $IDC_PICTURES = 203
$IDC_SEND = 300; $IDC_ATTACH = 301; $IDC_FILES = 307; $IDC_FROM = 310; $IDC_SHOW_CC = 311; $IDC_SHOW_BCC = 312; $IDC_BCC = 304; $IDC_TO = 302; $IDC_CC = 303; $IDC_SUBJECT = 305; $IDC_BODY = 306; $IDF_BOLD = 330; $IDF_UNDERLINE = 332; $IDF_LINK = 341

New-Item -ItemType Directory -Force -Path $Out | Out-Null
# the app's preferences, where Options keeps the language: the one of whoever runs the test is put back at the end
$preferencesKey = 'HKCU:\Software\Postal Systems\InboxClassic'
$savedLanguage = (Get-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue).Language
# and Group messages by conversation, left out for the run so it is on, as it is out of the box
$savedGrouping = (Get-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue).GroupByConversation
# and the folder tree's closed rows, left out so every row starts open
$savedClosedRows = (Get-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -ErrorAction SilentlyContinue).ClosedFolderRows
# and the sign-in codes in notifications, left out so they are off, as out of the box
$savedCodes = (Get-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue).CodesInNotifications
# and View > Hide Read Messages, left out so every message is listed, as out of the box
$savedHideRead = (Get-ItemProperty -Path $preferencesKey -Name HideReadMessages -ErrorAction SilentlyContinue).HideReadMessages
# and View > Folder List, left out so the folder list is shown, as out of the box
$savedFolderList = (Get-ItemProperty -Path $preferencesKey -Name FolderList -ErrorAction SilentlyContinue).FolderList
# and View > Layout, Classic during the test so every screenshot but the layout's own is as before; the list's width
# in Columns and whether the columns note was shown, left out as out of the box
$savedLayout = @{}
# and the senders' pictures of the list, left out so they are shown, as out of the box
foreach ($name in 'Layout', 'ListWidth', 'ColumnsNoteShown', 'ListPictures') {
    $savedLayout[$name] = (Get-ItemProperty -Path $preferencesKey -Name $name -ErrorAction SilentlyContinue).$name
}
# a scheduled task shows no output: everything also goes to log.txt, and result.txt is written last
Remove-Item -Force -ErrorAction SilentlyContinue (Join-Path $Out 'result.txt')
Start-Transcript -Path (Join-Path $Out 'log.txt') -Force | Out-Null
$failures = @()
# the apps started again (StartAgain), ended at the end should one hang
$started = @()
function Step([string]$text) {
    # whatever a step before left open over the app is closed first, so it can not fail the steps after it too
    CloseStrays "before '$text'" -Writing
    Write-Host "== $text"
}
# a line of GitHub's annotations (::error:: and the like), under GitHub Actions only: the job's summary then names it
function Annotate([string]$kind, [string]$what) {
    if ($env:GITHUB_ACTIONS -ne 'true') { return }
    $text = $what.Replace('%', '%25').Replace("`r", '%0D').Replace("`n", '%0A')
    Write-Host "::$kind::$text"
}
# a check of what a user sees
function Check([bool]$ok, [string]$what) {
    if ($ok) { Write-Host "   ok: $what" } else { Write-Host "   FAILED: $what"; Annotate 'error' $what; $script:failures += $what }
}
# a condition of the test itself that stops it from checking (a button that stays disabled, an error of the script):
# a failure too, but said as one of the harness, not of the app
function Harness([string]$what) {
    Write-Host "   FAILED (harness): $what"
    Annotate 'error' "harness: $what"
    $script:failures += "harness: $what"
}

# where the time goes: the fixed pauses and the waits that ran out, in seconds by the lines that asked for them (the
# caller's line after the helper's), said at the end
$pauses = @{}; $waitedOut = @{}
function Start-Sleep {
    param([int]$Seconds = 0, [int]$Milliseconds = 0)
    $calls = Get-PSCallStack
    $where = if ($calls.Count -gt 2) { "$($calls[1].ScriptLineNumber)<$($calls[2].ScriptLineNumber)" } else { "$($calls[1].ScriptLineNumber)" }
    $script:pauses[$where] += $Seconds + $Milliseconds / 1000
    Microsoft.PowerShell.Utility\Start-Sleep -Milliseconds ($Seconds * 1000 + $Milliseconds)
}
function PollPause([int]$Milliseconds) { Microsoft.PowerShell.Utility\Start-Sleep -Milliseconds $Milliseconds }
function TimingReport {
    foreach ($kind in @(@{ Name = 'fixed pauses'; Table = $pauses }, @{ Name = 'waits that ran out'; Table = $waitedOut })) {
        $total = ($kind.Table.Values | Measure-Object -Sum).Sum
        Write-Host ("timing: {0:N0} s in {1}; the most at lines (line<caller):" -f $total, $kind.Name)
        $kind.Table.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 25 | ForEach-Object { Write-Host ("   {0,7:N1} s  {1}" -f $_.Value, $_.Key) }
        # and by the line of the pause or wait itself, whoever called it (a helper's pause adds up over its callers)
        $byLine = @{}
        foreach ($entry in $kind.Table.GetEnumerator()) { $byLine[($entry.Key -split '<')[0]] += $entry.Value }
        Write-Host '   by the line of the pause or wait itself:'
        $byLine.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 10 | ForEach-Object { Write-Host ("   {0,7:N1} s  {1}" -f $_.Value, $_.Key) }
    }
}

# waits up to $Seconds for $Condition to give something truthy, returns it (or $null)
function WaitFor([scriptblock]$Condition, [int]$Seconds = 20) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        $value = & $Condition
        if ($value) { return $value }
        PollPause 250
    }
    $calls = Get-PSCallStack
    $where = if ($calls.Count -gt 2) { "$($calls[1].ScriptLineNumber)<$($calls[2].ScriptLineNumber)" } else { "$($calls[1].ScriptLineNumber)" }
    $script:waitedOut[$where] += $Seconds
    return $null
}

# the screen at ($left, $top) into $bitmap; the desktop of a remote session may refuse a copy for a moment (its
# display redrawn, the client resized)
function CopyScreen($bitmap, [int]$left, [int]$top) {
    for ($try = 1; ; $try++) {
        try {
            [System.Drawing.Graphics]::FromImage($bitmap).CopyFromScreen($left, $top, 0, 0, $bitmap.Size)
            return
        } catch {
            if ($try -ge 10) { throw }
            Start-Sleep -Seconds 2
        }
    }
}
# a picture of a window; with $Also (a popup menu, say) of the area that holds both
function Shot([IntPtr]$hwnd, [string]$name, [IntPtr]$Also = [IntPtr]::Zero) {
    # in front and painted: a window that just opened may not have drawn itself yet
    if ($Also -eq [IntPtr]::Zero) {
        [void][Native.Win]::SetWindowPos($hwnd, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($hwnd)
    }
    Start-Sleep -Milliseconds 700
    $rect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($hwnd, [ref]$rect)
    if ($Also -ne [IntPtr]::Zero) {
        $other = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($Also, [ref]$other)
        $rect.Left = [Math]::Min($rect.Left, $other.Left); $rect.Top = [Math]::Min($rect.Top, $other.Top)
        $rect.Right = [Math]::Max($rect.Right, $other.Right); $rect.Bottom = [Math]::Max($rect.Bottom, $other.Bottom)
    }
    # a window that closed in the meantime has no picture
    if ($rect.Right -le $rect.Left -or $rect.Bottom -le $rect.Top) { return }
    $bitmap = New-Object System.Drawing.Bitmap ($rect.Right - $rect.Left), ($rect.Bottom - $rect.Top)
    CopyScreen $bitmap $rect.Left $rect.Top
    if ($Also -eq [IntPtr]::Zero) { [void][Native.Win]::SetWindowPos($hwnd, [IntPtr](-2), 0, 0, 0, 0, 0x13) }
    $bitmap.Save((Join-Path $Out "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
}

function SetText([IntPtr]$window, [int]$id, [string]$text) {
    [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($window, $id), $WM_SETTEXT, [IntPtr]::Zero, $text)
}
function WindowText([IntPtr]$window) {
    $buffer = New-Object System.Text.StringBuilder 4096
    [void][Native.Win]::SendMessage($window, $WM_GETTEXT, [IntPtr]4096, $buffer)
    return $buffer.ToString()
}
function GetText([IntPtr]$window, [int]$id) { WindowText ([Native.Win]::GetDlgItem($window, $id)) }
# the rows of a list view, and the rows and the text of a row of a list box (LB_GETTEXT, which Windows copies between
# processes)
function ListCount([IntPtr]$list) { [int][Native.Win]::SendMessage($list, $LVM_GETITEMCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) }
function ListBoxCount([IntPtr]$box) { [int][Native.Win]::SendMessage($box, $LB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) }
function ListBoxText([IntPtr]$box, [int]$row) {
    $text = New-Object System.Text.StringBuilder 1024
    [void][Native.Win]::SendMessage($box, $LB_GETTEXT, [IntPtr]$row, $text)
    $text.ToString()
}
# the words of a window's static texts (a message box, a form's intro)
function Statics([IntPtr]$window) { ([Native.Win]::FindDescendants($window, 'Static') | ForEach-Object { WindowText $_ }) -join ' ' }
# the text of a part of a status bar: SB_GETTEXT writes it to memory of the app's own process, read back from there
function StatusPart([IntPtr]$bar, [int]$index) {
    $appPid = [uint32]0
    [void][Native.Win]::GetWindowThreadProcessId($bar, [ref]$appPid)
    # PROCESS_VM_OPERATION | PROCESS_VM_READ | PROCESS_VM_WRITE
    $process = [Native.Win]::OpenProcess(0x0038, $false, $appPid)
    if ($process -eq [IntPtr]::Zero) { return '' }
    $size = 4096
    # MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE
    $remote = [Native.Win]::VirtualAllocEx($process, [IntPtr]::Zero, [IntPtr]$size, 0x3000, 0x04)
    $text = ''
    if ($remote -ne [IntPtr]::Zero) {
        # SB_GETTEXTLENGTHW first, so the text fits
        $length = [int]([Native.Win]::SendMessage($bar, 0x040C, [IntPtr]$index, [IntPtr]::Zero).ToInt64() -band 0xFFFF)
        if ($length -gt 0 -and ($length + 1) * 2 -le $size) {
            [void][Native.Win]::SendMessage($bar, 0x040D, [IntPtr]$index, $remote)
            $bytes = New-Object byte[] ($length * 2)
            $read = [IntPtr]::Zero
            if ([Native.Win]::ReadProcessMemory($process, $remote, $bytes, [IntPtr]$bytes.Length, [ref]$read)) {
                $text = [System.Text.Encoding]::Unicode.GetString($bytes)
            }
        }
        # MEM_RELEASE
        [void][Native.Win]::VirtualFreeEx($process, $remote, [IntPtr]::Zero, 0x8000)
    }
    [void][Native.Win]::CloseHandle($process)
    return $text
}
# whether window $a is in front of window $b
function InFront([IntPtr]$a, [IntPtr]$b) {
    for ($w = [Native.Win]::GetWindow($a, 2); $w -ne [IntPtr]::Zero; $w = [Native.Win]::GetWindow($w, 2)) {
        if ($w -eq $b) { return $true }
    }
    return $false
}
# whether control `id` of `window` is a push button that Tab reaches (not a link drawn on a button, not a static)
function PushButton([IntPtr]$window, [int]$id) {
    $control = [Native.Win]::GetDlgItem($window, $id)
    if ($control -eq [IntPtr]::Zero) { return $false }
    $class = New-Object System.Text.StringBuilder 64
    [void][Native.Win]::GetClassName($control, $class, 64)
    $style = [Native.Win]::GetWindowLong($control, -16)
    $class.ToString() -eq 'Button' -and ($style -band 0xF) -le 1 -and ($style -band 0x00010000) -ne 0
}
# presses a button as its click ends up: BN_CLICKED to its window, which works whether or not that window is active
# (BM_CLICK can be lost when it is not, as on the CI runner). A disabled button can not be pressed, as with the mouse:
# one is waited for a few seconds (a window turns its buttons on as it fills in), then the harness says it stayed off
function Click([IntPtr]$window, [int]$id) {
    $button = [Native.Win]::GetDlgItem($window, $id)
    if ($button -ne [IntPtr]::Zero -and -not [Native.Win]::IsWindowEnabled($button)) {
        if (-not (WaitFor { -not [Native.Win]::IsWindow($button) -or [Native.Win]::IsWindowEnabled($button) } 5)) {
            Harness "button $id of $(Describe $window) stayed disabled, so it could not be pressed"
            return
        }
    }
    [void][Native.Win]::PostMessage($window, $WM_COMMAND, [IntPtr]($id -band 0xFFFF), $button)
}
# the text of control $id of $window once it is there and has any (a window may make or fill a static after it shows);
# $null when it does not come
function WaitText([IntPtr]$window, [int]$id, [int]$Seconds = 10) {
    WaitFor { $t = GetText $window $id; if ($t) { $t } } $Seconds
}
# the visible top-level windows of the app's processes, the front one first: their handles
function AppWindows {
    $ids = AppIds
    $found = New-Object System.Collections.Generic.List[IntPtr]
    [void][Native.Win]::EnumWindows({
        param($w, $l)
        $owner = [uint32]0
        [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner)
        if ($ids -contains $owner -and [Native.Win]::IsWindowVisible($w)) { $found.Add($w) }
        $true
    }, [IntPtr]::Zero)
    $found.ToArray()
}
# what is open when a window does not come: the app's visible windows, and a picture of $shown
function ShowAppWindows([IntPtr]$shown, [string]$shot) {
    foreach ($w in AppWindows) { Write-Host "   window of the app: $(Describe $w)" }
    Shot $shown $shot
}
# a menu or toolbar command, posted as the menu would
function Command([IntPtr]$window, [int]$id) {
    [void][Native.Win]::PostMessage($window, $WM_COMMAND, [IntPtr]$id, [IntPtr]::Zero)
}
function Key([IntPtr]$window, [int]$vk) {
    [void][Native.Win]::PostMessage($window, $WM_KEYDOWN, [IntPtr]$vk, [IntPtr]::Zero)
    [void][Native.Win]::PostMessage($window, $WM_KEYUP, [IntPtr]$vk, [IntPtr]::Zero)
}
# an account's Properties form, titled "<account> Properties", or 0
function PropertiesForm() {
    $w = [IntPtr]::Zero
    while (($w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'InboxClassicForm', [NullString]::Value)) -ne [IntPtr]::Zero) {
        if ((WindowText $w) -match 'Properties$') { return $w }
    }
    return [IntPtr]::Zero
}
# a top-level window of a class (and title), once it is there
function WaitWindow([string]$class, [string]$title = $null, [int]$Seconds = 20) {
    $t = if ($title) { $title } else { [NullString]::Value }
    WaitFor { $w = [Native.Win]::FindWindow($class, $t); if ($w -ne [IntPtr]::Zero) { $w } } $Seconds
}
# a window of the app's own once it shows: its controls are made and filled before it does, so they can be read
function WaitShown([string]$class, [int]$Seconds = 20) {
    WaitFor { $w = [Native.Win]::FindWindow($class, [NullString]::Value); if ($w -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($w)) { $w } } $Seconds
}
# a form of the app with this title once it shows. FindWindow finds it as soon as it is made, before its fields are: a
# field set then is lost, and OK takes what the form filled in itself (Find's the words of the last find)
function WaitForm([string]$title, [int]$Seconds = 20) {
    WaitFor { $w = [Native.Win]::FindWindow('InboxClassicForm', $title); if ($w -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($w)) { $w } } $Seconds
}
# Options' page $page (0 General, 1 Reading, 2 Downloading, as core/settings.toml orders them) chosen by a click on its
# tab, posted to the tab strip (app.h: IDC_OPTIONS_TABS, 680) at the middle of the tab (TCM_GETITEMRECT)
function OptionsPage([IntPtr]$options, [int]$page) {
    $tabs = [Native.Win]::GetDlgItem($options, 680)
    $item = [Native.Win]::RemoteRect($tabs, 0x130A, [IntPtr]$page, 0)
    $strip = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($tabs, [ref]$strip)
    $x = [int][Math]::Floor(($item.Left + $item.Right) / 2) - $strip.Left
    $y = [int][Math]::Floor(($item.Top + $item.Bottom) / 2) - $strip.Top
    $point = [IntPtr](($y -shl 16) -bor $x)
    [void][Native.Win]::PostMessage($tabs, 0x0201, [IntPtr]1, $point)
    [void][Native.Win]::PostMessage($tabs, 0x0202, [IntPtr]::Zero, $point)
    [void](WaitFor { [int][Native.Win]::SendMessage($tabs, 0x130B, [IntPtr]::Zero, [IntPtr]::Zero) -eq $page } 5)
    Start-Sleep -Milliseconds 200
}
# the window of the WebView2 of a compose window's editor that takes input, clicked into as a user would when the
# cursor is in another field
function ClickEditor([IntPtr]$compose) {
    $input = WaitFor { [Native.Win]::FindDescendants($compose, 'Chrome_RenderWidgetHostHWND') | Select-Object -First 1 }
    if (-not $input) { return $null }
    Start-Sleep -Milliseconds 500
    $point = [IntPtr]((12 -shl 16) -bor 12)
    [void][Native.Win]::PostMessage($input, 0x0201, [IntPtr]1, $point)
    [void][Native.Win]::PostMessage($input, 0x0202, [IntPtr]::Zero, $point)
    Start-Sleep -Milliseconds 300
    return $input
}
# types into the HTML editor of a compose window
function TypeInEditor([IntPtr]$compose, [string]$text) {
    $input = ClickEditor $compose
    if (-not $input) { return $false }
    foreach ($c in $text.ToCharArray()) {
        [void][Native.Win]::PostMessage($input, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero)
    }
    Start-Sleep -Milliseconds 500
    return $true
}
# the process ids of the app: the run going on, and those started before it (a second start, a restart)
# (an array, even of one)
function AppIds { , [uint32[]]@(@($script:app) + @($script:started) | Where-Object { $_ -and -not $_.HasExited } | ForEach-Object { $_.Id }) }
# a window's class and title, for the log
function Describe([IntPtr]$w) {
    $cls = New-Object System.Text.StringBuilder 64
    [void][Native.Win]::GetClassName($w, $cls, 64)
    "$cls '$(WindowText $w)'"
}
# a dialog of the app closed as a user would: Cancel, else No (a question with Yes and No only), else its close box.
# Whether it closed
function CloseDialog([IntPtr]$dialog) {
    # Cancel again every 3 seconds for up to 30: the system's file dialog on a cold runner can take several seconds
    # before it acts on Cancel
    for ($tries = 0; $tries -lt 10; $tries++) {
        if (-not [Native.Win]::IsWindow($dialog)) { return $true }
        [void][Native.Win]::PostMessage($dialog, $WM_COMMAND, [IntPtr]2, [Native.Win]::GetDlgItem($dialog, 2))
        if (WaitFor { -not [Native.Win]::IsWindow($dialog) } 3) { return $true }
    }
    if ([Native.Win]::GetDlgItem($dialog, 7) -ne [IntPtr]::Zero) {
        [void][Native.Win]::PostMessage($dialog, $WM_COMMAND, [IntPtr]7, [Native.Win]::GetDlgItem($dialog, 7))
        if (WaitFor { -not [Native.Win]::IsWindow($dialog) } 3) { return $true }
    }
    [void][Native.Win]::PostMessage($dialog, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    [bool](WaitFor { -not [Native.Win]::IsWindow($dialog) } 5)
}
# what a step left open over the app closed: the popup menus and the dialogs (#32770: message boxes, file and folder
# pickers) of the app's own processes, never a window of anything else, each one said in the log; with -Writing the
# compose windows too, not saved (a step that left one open has failed: the next would take it for its own, and Exit
# would stop at its question). The app's other windows (forms, the keys) are left as they are
function CloseStrays([string]$where, [switch]$Writing) {
    $ids = AppIds
    if ($ids.Length -eq 0) { return }
    foreach ($menu in [Native.Win]::TopWindowsOf($ids, '#32768')) {
        Write-Host "   (closing a menu left open, $where)"
        # Esc as the menu takes it, then the way EndMenu ends one: WM_CANCELMODE to the window it is for
        Key $menu $VK_ESCAPE
        if (-not (WaitFor { -not [Native.Win]::IsWindowVisible($menu) } 2)) {
            $owner = [Native.Win]::MenuOwnerOf($menu)
            if ($owner -ne [IntPtr]::Zero) { [void][Native.Win]::PostMessage($owner, 0x001F, [IntPtr]::Zero, [IntPtr]::Zero) }
            [void](WaitFor { -not [Native.Win]::IsWindowVisible($menu) } 3)
        }
    }
    # the front one first: a dialog over another is the one that takes input (the one under it is disabled)
    for ($pass = 0; $pass -lt 5; $pass++) {
        $open = @([Native.Win]::TopWindowsOf($ids, '#32770'))
        if ($open.Count -eq 0) { break }
        $dialog = $open[0]
        $what = Describe $dialog
        $words = Statics $dialog
        if ($words.Length -gt 160) { $words = $words.Substring(0, 160) + '...' }
        $closed = CloseDialog $dialog
        Write-Host "   (closing a dialog left open, $where`: $what $(if ($words) { "saying '$words'" }), $(if ($closed) { 'closed' } else { 'did not close' }))"
    }
    if ($Writing) {
        foreach ($c in (ComposeWindows)) {
            $what = Describe $c
            Write-Host "   (closing a compose window left open, $where`: $what, $(if (CloseCompose $c) { 'closed' } else { 'did not close' }))"
        }
    }
}
# the compose windows of the app open now, shown or not
function ComposeWindows {
    $found = @()
    $w = [IntPtr]::Zero
    while (($w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'InboxClassicCompose', [NullString]::Value)) -ne [IntPtr]::Zero) { $found += $w }
    $found
}
# the compose window `composeAction` opens, once its fields are there (the window exists a moment before them): one
# that was not open before it ran (or before `composeBefore`, the compose windows open earlier), never one left open
# by a step before
function WaitCompose([scriptblock]$composeAction = $null, $composeBefore = $null, [int]$Seconds = 20) {
    $known = if ($null -ne $composeBefore) { @($composeBefore) } else { @(ComposeWindows) }
    if ($composeAction) { . $composeAction }
    WaitFor {
        foreach ($c in (ComposeWindows)) {
            if ($known -notcontains $c -and [Native.Win]::GetDlgItem($c, $IDC_BODY) -ne [IntPtr]::Zero) { return $c }
        }
    } $Seconds
}
# the message box `owner` shows over itself (a dialog of the app's it owns, GW_OWNER): the box this window asked, never
# another window's with the same title; $null when there is none
function OwnBox([IntPtr]$owner) {
    [Native.Win]::TopWindowsOf((AppIds), '#32770') | Where-Object { [Native.Win]::GetWindow($_, 4) -eq $owner } | Select-Object -First 1
}
# OwnBox once it is there
function BoxOf([IntPtr]$owner, [int]$Seconds = 10) { WaitFor { OwnBox $owner } $Seconds }
# a compose window closed as a user closes it: its close box, then `answer` (No: not saved) when it asks whether to save
# (its own box, BoxOf); whether it is gone. When it stays, what holds it open is said in the log, with a picture of
# the screen (debug-compose-close-<n>)
function CloseCompose([IntPtr]$compose, [int]$answer = 7) {
    if (-not [Native.Win]::IsWindow($compose)) { return $true }
    $name = Describe $compose
    [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    $asked = WaitFor {
        if (-not [Native.Win]::IsWindow($compose)) { return 'gone' }
        OwnBox $compose
    } 10
    if ($asked -is [string]) { return $true }
    if ($asked) {
        $box = [IntPtr]$asked
        $said = "$(Describe $box) saying '$(Statics $box)'"
        Click $box $answer
        if (WaitFor { -not [Native.Win]::IsWindow($compose) } 10) { return $true }
        Write-Host "   (closing $name, it asked $said; answered $answer, the window stayed$(if ([Native.Win]::IsWindow($box)) { ' and so did the box' }))"
    } else {
        # what else holds it: the window over it that takes its input (GW_ENABLEDPOPUP), when there is one
        $over = [Native.Win]::GetWindow($compose, 6)
        $what = if ($over -ne [IntPtr]::Zero -and $over -ne $compose) { "$(Describe $over) is over it" } else { 'nothing is over it' }
        Write-Host "   (closing $name, it neither closed nor asked: enabled $([Native.Win]::IsWindowEnabled($compose)), $what)"
    }
    foreach ($w in AppWindows) { Write-Host "   (window of the app: $(Describe $w), enabled $([Native.Win]::IsWindowEnabled($w)))" }
    $script:composeShots++
    Shot ([Native.Win]::GetDesktopWindow()) "debug-compose-close-$($script:composeShots)"
    -not [Native.Win]::IsWindow($compose)
}
$composeShots = 0
# a picture of the whole screen when a file dialog goes wrong (debug-file-dialog-<title>-<what>), to tell what held it up
function DialogDebugShot([string]$kind, [string]$title, [string]$what) {
    Shot ([Native.Win]::GetDesktopWindow()) "debug-$kind-dialog-$(($title -replace '[^\w]+', '-').Trim('-').ToLowerInvariant())-$what"
}
# the name box of a file dialog once it is ready to take a name: shown, enabled, the dialog shown and enabled, and the
# box holding the keyboard focus, which the dialog gives it last when it is set up (it fills in the box before that,
# over anything put there earlier). `find` gives the box; $null when there is none
function ReadyNameBox([IntPtr]$dialog, [scriptblock]$find) {
    $name = WaitFor {
        $n = & $find
        if ($n -and [Native.Win]::IsWindowVisible($dialog) -and [Native.Win]::IsWindowEnabled($dialog) -and
            [Native.Win]::IsWindowVisible($n) -and [Native.Win]::IsWindowEnabled($n)) { $n }
    } 20
    if (-not $name) { return $null }
    if (-not (WaitFor { [Native.Win]::FocusOf($dialog) -eq $name } 10)) {
        Write-Host "   (the file dialog's name box did not get the focus: going on)"
    }
    # and what it holds no longer changing
    [void](WaitFor { $a = WindowText $name; Start-Sleep -Milliseconds 300; if ((WindowText $name) -eq $a) { $true } } 5)
    $name
}
# `text` put in a name box: all of it but the last character set at once (WM_SETTEXT), then that one typed at the end,
# so the dialog sees an edit of the user's (it keeps its own copy of the name). Whether the box has it, and keeps it a
# moment later. Where that does not take, every character typed
function PutName([IntPtr]$name, [string]$text) {
    $held = { $t = WindowText $name; if ($t -eq $text) { Start-Sleep -Milliseconds 400; (WindowText $name) -eq $text } }
    $head = $text.Substring(0, $text.Length - 1)
    [void][Native.Win]::SendMessage($name, $WM_SETTEXT, [IntPtr]::Zero, $head)
    [void][Native.Win]::SendMessage($name, $EM_SETSEL, [IntPtr]$head.Length, [IntPtr]$head.Length)
    [void][Native.Win]::PostMessage($name, 0x0102, [IntPtr][int]$text[-1], [IntPtr]::Zero)
    if (WaitFor $held 5) { return $true }
    Write-Host "   (the name box holds '$(WindowText $name)': typing all of it)"
    [void][Native.Win]::SendMessage($name, $WM_SETTEXT, [IntPtr]::Zero, '')
    foreach ($c in $text.ToCharArray()) { [void][Native.Win]::PostMessage($name, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero) }
    [bool](WaitFor $held 10)
}
# a dialog left over by a file dialog that went wrong closed (what it asked, said), then the file dialog itself and
# whatever else is left over the app, so the steps after it start clean
function GiveUpFileDialog([string]$kind, [IntPtr]$dialog, [string]$title, [string]$what) {
    Write-Host "   (the $kind dialog '$title' $what)"
    DialogDebugShot $kind $title $what
    if ([Native.Win]::IsWindow($dialog)) {
        $edits = @([Native.Win]::FindDescendants($dialog, 'Edit') | ForEach-Object { "$([Native.Win]::IsWindowVisible($_)):'$(WindowText $_)'" }) -join ', '
        Write-Host "   (its edit fields: $edits)"
        Write-Host "   (Cancel: $(if (CloseDialog $dialog) { 'closed' } else { 'did not close' }))"
    }
    CloseStrays "after the $kind dialog '$title'"
}
# a box (a #32770 of the app) shown over a dialog, by the dialog: "the file is not there", "replace it?"; or $null
function BoxOver([IntPtr]$dialog) {
    [Native.Win]::TopWindowsOf((AppIds), '#32770') | Where-Object { $_ -ne $dialog -and [Native.Win]::GetWindow($_, 4) -eq $dialog } | Select-Object -First 1
}
# Open or Save of a file dialog pressed (posted, as Click does: whether or not the dialog is in front) once the name box
# holds `path`, up to three times; whether it closed. A box it shows says why it would not, and ends the tries
function PressUntilClosed([string]$kind, [IntPtr]$dialog, [IntPtr]$name, [string]$path, [string]$title, [scriptblock]$between = $null) {
    for ($try = 1; $try -le 3; $try++) {
        if (-not [Native.Win]::IsWindow($dialog)) { return $true }
        if (-not (PutName $name $path)) {
            Write-Host "   (the $kind dialog '$title' did not take the name, try $try)"
            continue
        }
        Click $dialog 1
        if ($between) { & $between }
        if (WaitFor { -not [Native.Win]::IsWindow($dialog) } 10) { return $true }
        $box = BoxOver $dialog
        if ($box) {
            Write-Host "   (the $kind dialog '$title' answered: $(Statics $box))"
            return $false
        }
        Write-Host "   (the $kind dialog '$title' is still open after $(if ($kind -eq 'folder') { 'Select Folder' } else { 'Open or Save' }), try $try)"
    }
    -not [Native.Win]::IsWindow($dialog)
}
# a file dialog answered with `path`, whose name box has the suggested name `suggested` in a Save dialog: once it is
# ready (ReadyNameBox), the name put in (PutName) and Open or Save pressed until it closes (PressUntilClosed); a picture
# `shot` of it first. On a failure the dialog and what it left are closed (GiveUpFileDialog), so one check fails, not
# the steps after it
function AnswerFileDialog([string]$title, [string]$path, [string]$shot, [string]$suggested = $null) {
    # the first file dialog of a session can take long to open while the shell starts (CI runners)
    $dialog = WaitWindow '#32770' $title 40
    if (-not $dialog) {
        GiveUpFileDialog 'file' ([IntPtr]::Zero) $title 'missing'
        return $false
    }
    # the name box: the one with the suggested name in a Save dialog, the one in the name combo box (1148) otherwise
    $name = ReadyNameBox $dialog {
        if ($suggested) {
            [Native.Win]::FindDescendants($dialog, 'Edit') | Where-Object { (WindowText $_) -like $suggested } | Select-Object -First 1
        } else {
            $combo = [Native.Win]::GetDlgItem($dialog, 1148)
            if ($combo -ne [IntPtr]::Zero) { [Native.Win]::FindDescendants($combo, 'Edit') | Select-Object -First 1 }
        }
    }
    if (-not $name) {
        GiveUpFileDialog 'file' $dialog $title 'name'
        return $false
    }
    if ($shot) { Shot $dialog $shot }
    if (PressUntilClosed 'file' $dialog $name $path $title) { return $true }
    GiveUpFileDialog 'file' $dialog $title 'open'
    $false
}
# the Windows folder picker (Save Messages In) answered with `path`: put into its Folder box, then Select Folder, as
# AnswerFileDialog does
function AnswerFolderDialog([string]$title, [string]$path) {
    $dialog = WaitWindow '#32770' $title 40
    if (-not $dialog) {
        GiveUpFileDialog 'folder' ([IntPtr]::Zero) $title 'missing'
        return $false
    }
    # the Folder box: the one edit field it shows (the address bar's is hidden until clicked)
    $name = ReadyNameBox $dialog { [Native.Win]::FindDescendants($dialog, 'Edit') | Where-Object { [Native.Win]::IsWindowVisible($_) } | Select-Object -First 1 }
    if (-not $name) {
        GiveUpFileDialog 'folder' $dialog $title 'name'
        return $false
    }
    # a typed folder is opened first, its name then in the box: Select Folder once more chooses it
    $leaf = Split-Path -Leaf $path
    $again = {
        if (-not (WaitFor { -not [Native.Win]::IsWindow($dialog) } 3) -and (WaitFor { (WindowText $name) -eq $leaf } 5)) { Click $dialog 1 }
    }
    if (PressUntilClosed 'folder' $dialog $name $path $title $again) { return $true }
    GiveUpFileDialog 'folder' $dialog $title 'open'
    $false
}
# whether a button of the format bar is pressed
function Pressed([IntPtr]$compose, [int]$id) {
    $bar = [Native.Win]::GetDlgItem($compose, 322)
    [int][Native.Win]::SendMessage($bar, 0x040A, [IntPtr]$id, [IntPtr]::Zero) -ne 0
}
# a right-click on a row of the folder tree, as the user gives it: its menu's window (null when none opened) and its
# labels. The window topmost for the click, as SetForegroundWindow alone is refused to a background process.
function TreeRowMenu([IntPtr]$window, [IntPtr]$tree, [IntPtr]$row) {
    [void][Native.Win]::SetWindowPos($window, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($window)
    Start-Sleep -Milliseconds 300
    $box = [Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $row.ToInt64())
    [Native.Win]::MouseRightClick([int](($box.Left + $box.Right) / 2), [int](($box.Top + $box.Bottom) / 2))
    $menu = WaitWindow '#32768' $null 10
    [void][Native.Win]::SetWindowPos($window, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    $labels = if ($menu) { @([Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero))) } else { @() }
    @{ menu = $menu; labels = $labels }
}
# the language of a catalog, as the app shows it: id to words (core/locales/<language>/*.ftl), the access keys' & left
# out; a message of one line by its id, each variant of a select by "id[key]" (the default also as "id[*]")
function Catalog([string]$language) {
    $words = @{}
    foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot "..\core\locales\$language") -Filter '*.ftl') {
        $select = $null
        foreach ($line in Get-Content -Encoding UTF8 $file.FullName) {
            if ($line -match '^([a-z][a-z0-9-]*) =\s*(.*)$') {
                $id = $Matches[1]; $value = $Matches[2]
                $select = if ($value -eq '' -or $value -match '^\{ \$\w+ ->$') { $id } else { $null }
                if (-not $select) { $words[$id] = $value.Replace('&', '') }
            } elseif ($select -and $line -match '^\s+(\*?)\[(\w+)\] (.+)$') {
                $words["$select[$($Matches[2])]"] = $Matches[3].Replace('&', '')
                if ($Matches[1]) { $words["$select[*]"] = $Matches[3].Replace('&', '') }
            } elseif ($line -match '^\S') {
                $select = $null
            }
        }
    }
    $words
}
# a regular expression for a message of a catalog as the app shows it, from its start: its placeables { $name } the
# words in `values`, any words where `values` has none
function Pattern([string]$message, [hashtable]$values = @{}) {
    if (-not $message) { return '^(?!)' }
    $pattern = '^'
    foreach ($piece in [regex]::Split($message, '(\{ \$\w+ \})')) {
        if ($piece -match '^\{ \$(\w+) \}$') {
            $pattern += if ($values.ContainsKey($Matches[1])) { [regex]::Escape([string]$values[$Matches[1]]) } else { '.+?' }
        } else {
            $pattern += [regex]::Escape($piece)
        }
    }
    $pattern
}
# the English words of the app, which the checks of the run in English look for
$en = Catalog 'en'
function Visible([IntPtr]$window, [int]$id) { [Native.Win]::IsWindowVisible([Native.Win]::GetDlgItem($window, $id)) }

# ---- ImapKit, with mail to read ----

Step 'starting ImapKit'
$e2e = Join-Path $PSScriptRoot '..\core\e2e'
$start = New-Object System.Diagnostics.ProcessStartInfo 'node', 'harness.mjs'
$start.WorkingDirectory = (Resolve-Path $e2e)
$start.UseShellExecute = $false
$start.RedirectStandardInput = $true
$start.RedirectStandardOutput = $true
$harness = [System.Diagnostics.Process]::Start($start)
# with its OAuth 2.0 / OpenID Connect provider, and a user with an address for name to sign in as there
# and a second server with a mailbox of its own for the second account (ImapKit's users share one mailbox)
$harness.StandardInput.WriteLine('{"oauth":{},"users":{"testuser":{"password":"testpass"},"alice@example.com":{"password":"pw","displayName":"Alice Example"}},"second":{"users":{"testuser2":{"password":"testpass2"}}}}')
$ports = $harness.StandardOutput.ReadLine() | ConvertFrom-Json
$rest = "http://127.0.0.1:$($ports.rest)/v1/mailboxes"
$rest2 = "http://127.0.0.1:$($ports.second.rest)/v1/mailboxes"
function Messages([string]$mailbox, [string]$server = $rest) {
    # through the pipeline, which unrolls the array: Windows PowerShell hands an empty one on as one object
    @(Invoke-RestMethod "$server/$([uri]::EscapeDataString($mailbox))/messages?raw=true" | ForEach-Object { $_ })
}
# the REST API gives the source base64 encoded
function RawText($message) {
    try { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($message.raw)) }
    catch { "UNDECODED(" + ([string]$message.raw).Substring(0, [Math]::Min(80, ([string]$message.raw).Length)) + ")" }
}
function Find([string]$mailbox, [string]$pattern) { (Messages $mailbox) | Where-Object { (RawText $_) -match $pattern } | Select-Object -First 1 }
function Seen([string]$pattern) { (Find 'INBOX' $pattern).flags -contains '\Seen' }
# $arrived: when the server says it got the message (its INTERNALDATE), else now or its Date when that is ahead
function AddMessage([string]$raw, [string[]]$flags = @(), [string]$mailbox = 'INBOX', [string]$server = $rest, [Nullable[DateTime]]$arrived = $null) {
    $body = @{ raw = $raw; flags = $flags }
    if ($arrived) {
        $body.internaldate = ([DateTime]$arrived).ToString("dd-MMM-yyyy HH:mm:ss '+0000'", [Globalization.CultureInfo]::InvariantCulture)
    }
    # a message dated ahead, so it lists above what came before it, arrives at its date: the list shows no date
    # later than the arrival
    if ($raw -match '(?m)^Date: ([^\r\n]+)') {
        $dated = [DateTime]::MinValue
        if ([DateTime]::TryParse($Matches[1], [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal, [ref]$dated) -and $dated -gt [DateTime]::UtcNow) {
            $body.internaldate = $dated.ToString("dd-MMM-yyyy HH:mm:ss '+0000'", [Globalization.CultureInfo]::InvariantCulture)
        }
    }
    $body = $body | ConvertTo-Json
    [void](Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $body "$server/$mailbox/messages")
}

# a picture sent inside the message: the newsletter's banner
$picture = New-Object System.Drawing.Bitmap 560, 110
$graphics = [System.Drawing.Graphics]::FromImage($picture)
$graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$graphics.Clear([System.Drawing.Color]::FromArgb(31, 77, 58))
$graphics.DrawString('Trail Notes', (New-Object System.Drawing.Font 'Georgia', 30, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)), [System.Drawing.Brushes]::White, 24, 22)
$graphics.DrawString('Walks, maps and weekend ideas  |  October', (New-Object System.Drawing.Font 'Georgia', 15, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)), (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(214, 232, 220))), 26, 66)
$stream = New-Object System.IO.MemoryStream
$picture.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
$png = [Convert]::ToBase64String($stream.ToArray(), 'InsertLineBreaks')
$pdf = "%PDF-1.4`n% a small attachment from scripts/ui-e2e.ps1`n"
$pdf64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pdf))

# in the list newest first: the newsletter, Ann's message, the minutes
$minutes = 'Minutes of the planning meeting'
AddMessage ("From: Bob Harris <bob@example.com>`r`nTo: testuser@inboxclassic.test, Dave <dave@example.com>`r`n" +
    "Cc: Carol <carol@example.com>`r`nSubject: $minutes`r`nMessage-ID: <minutes@example.com>`r`n" +
    "Date: Wed, 1 Oct 2025 09:00:00 +0000`r`n`r`nWe agreed on the dates.`r`n") @('\Seen')
# a reply with the message it answers quoted below, as Gmail sends it: the oldest, the last row
AddMessage ("From: Carol <carol@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: Lunch on Friday`r`n" +
    "Message-ID: <lunch2@example.com>`r`nIn-Reply-To: <lunch1@example.com>`r`nDate: Mon, 29 Sep 2025 12:00:00 +0000`r`n" +
    "Content-Type: text/html; charset=utf-8`r`n`r`n" +
    '<div dir="ltr">Friday is fine, see you at noon.</div><br><div class="gmail_quote"><div dir="ltr" class="gmail_attr">' +
    'On Mon, Sep 29, 2025 at 9:00 AM Alex Morgan &lt;testuser@inboxclassic.test&gt; wrote:<br></div>' +
    '<blockquote class="gmail_quote" style="margin:0px 0px 0px 0.8ex;border-left:1px solid rgb(204,204,204);padding-left:1ex">' +
    'Lunch on Friday? The usual place.</blockquote></div>' + "`r`n") @('\Seen')
$subject = 'Photos from Saturday'
AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $subject`r`n" +
    "Message-ID: <ui-e2e@example.com>`r`nDate: Mon, 6 Oct 2025 10:00:00 +0000`r`n`r`nHi Alex,`r`n" +
    "the photos from Saturday are in the shared album. The one from the lake came out best.`r`n`r`nAnn`r`n")
$newsletter = 'October newsletter'
$html = '<div style="font-family:Georgia,serif;max-width:560px;color:#222">' +
    '<p><a href="https://example.com/trail-notes"><img src="cid:banner@example.com" width="560" height="110" alt="Trail Notes"></a></p>' +
    '<h2 style="color:#1f4d3a;margin:18px 0 6px">Five autumn walks worth the drive</h2>' +
    '<p>The larches are turning gold and the summer crowds have gone home. This month we picked five routes for short ' +
    'October days, each under four hours, with a warm cafe at the end.</p>' +
    '<p><a href="https://example.com/news">Read the full guide</a> <script>alert("never runs")</script></p>' +
    '<p style="color:#666;font-size:14px">Photo of the month, sent in by a reader:</p>' +
    '<p><img src="https://nodemailer.com/img/nm_logo_200x136.png" width="200" height="136" alt="Photo of the month"></p></div>'
AddMessage ("From: Trail Notes <news@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $newsletter`r`n" +
    "Message-ID: <news@example.com>`r`nDate: Wed, 8 Oct 2025 08:00:00 +0000`r`nMIME-Version: 1.0`r`n" +
    "Content-Type: multipart/mixed; boundary=`"mixed`"`r`n`r`n--mixed`r`n" +
    "Content-Type: multipart/related; boundary=`"related`"`r`n`r`n--related`r`n" +
    "Content-Type: text/html; charset=utf-8`r`n`r`n$html`r`n--related`r`n" +
    "Content-Type: image/png`r`nContent-ID: <banner@example.com>`r`nContent-Transfer-Encoding: base64`r`n`r`n$png`r`n" +
    "--related--`r`n--mixed`r`nContent-Type: application/pdf; name=`"report.pdf`"`r`n" +
    "Content-Disposition: attachment; filename=`"report.pdf`"`r`nContent-Transfer-Encoding: base64`r`n`r`n$pdf64`r`n" +
    "--mixed--`r`n") @('\Flagged')

$app = $null
try {
    # ---- adding the account ----

    Step 'starting Inbox Classic with a store of its own'
    $store = Join-Path $Out 'store.db'
    Remove-Item -Force -ErrorAction SilentlyContinue "$store*", (Join-Path $Out '*.png'), (Join-Path $Out 'report*.pdf')
    # ImapKit's certificate is self-signed: the app trusts it, and only it, for this run. A browser sign-in writes its
    # page to a file, where the test opens it as the browser would
    $signInPage = Join-Path $Out 'sign-in-page.txt'
    Remove-Item -Force -ErrorAction SilentlyContinue $signInPage
    # an attachment opened is written to a file in place of being opened, so nothing is started; a link the browser
    # would open too
    $openedLog = Join-Path $Out 'opened-files.txt'
    Remove-Item -Force -ErrorAction SilentlyContinue $openedLog
    # the files and links the app opened (--opened-files-log), a path or an address a line
    # read sharing the file with the app, which may be writing a line
    function OpenedFiles {
        if (-not (Test-Path $openedLog)) { return @() }
        $stream = [IO.File]::Open($openedLog, 'Open', 'Read', 'ReadWrite')
        try { $text = (New-Object IO.StreamReader($stream)).ReadToEnd() } finally { $stream.Dispose() }
        @($text -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    $arguments = @('--store', "`"$store`"", '--memory-passwords', '--pin-certificate', "`"$($ports.cert)`"",
        '--sign-in-page-file', "`"$signInPage`"", '--opened-files-log', "`"$openedLog`"", '--test-hooks',
        '--key-server', "http://127.0.0.1:$($ports.pgp)")
    Remove-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name HideReadMessages -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name FolderList -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name ListWidth -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name ColumnsNoteShown -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $preferencesKey -Name ListPictures -ErrorAction SilentlyContinue
    # the classic layout for every step but the column layout's (a fresh machine has no key yet)
    if (-not (Test-Path $preferencesKey)) { New-Item -Path $preferencesKey -Force | Out-Null }
    Set-ItemProperty -Path $preferencesKey -Name Layout -Value 1 -Type DWord
    $app = Start-Process -FilePath $Exe -ArgumentList $arguments -PassThru

    # the first page of Add Mail Account, with the address fields when $fields, else the page that offers a
    # provider's sign-in for an address found there
    function StartPage([bool]$fields, [int]$seconds = 10) {
        WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicAccountStart', 'Add Mail Account')
            if ($f -ne [IntPtr]::Zero -and (([Native.Win]::GetDlgItem($f, 101) -ne [IntPtr]::Zero) -eq $fields)) { $f }
        } $seconds
    }

    # both steps of the form: the name and address, then the servers with the password; on the second server. The
    # second step's fields are 100 + their place (Field in accounts.cpp): Account name, Your name, E-mail address,
    # User name, Password, the incoming server, port and security, the outgoing server, port and security
    function AddAccount([string]$name, [string]$user, [string]$password, [bool]$shots, [bool]$onSecond = $false) {
        $on = if ($onSecond) { $ports.second } else { $ports }
        $first = StartPage $true
        Check ($null -ne $first) "the account form opens ($name)"
        if ($shots) {
            $google = [Native.Win]::GetDlgItem($first, 120); $microsoft = [Native.Win]::GetDlgItem($first, 121)
            Check ((WindowText $google) -eq 'Sign in with Google' -and (WindowText $microsoft) -eq 'Sign in with Microsoft') 'it starts with the Google and Microsoft sign-in buttons'
            Check ([Native.Win]::GetDlgItem($first, 102) -eq [IntPtr]::Zero) 'and asks no password before the servers are known'
        }
        SetText $first 100 $name
        SetText $first 101 "$user@inboxclassic.test"
        if ($shots) { Shot $first 'account-1-form' }
        Click $first 1
        if ($shots) {
            $wait = WaitWindow 'InboxClassicWait' $null 5
            if ($wait) { Shot $wait 'account-2-lookup' }
        }
        # the lookup finds nothing for this domain: the second form comes with the usual names to correct
        $second = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', 'Add Mail Account')
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        } 40
        Check ($null -ne $second) 'the server settings form follows the lookup'
        if (-not $second) { Shot $first "account-failed-$user"; throw 'no server settings form' }
        Check ((GetText $second 105) -eq 'imap.inboxclassic.test') 'the lookup guessed the IMAP server'
        Check ((GetText $second 101) -eq $name) 'the server form keeps the name typed first'
        Check ((GetText $second 100) -eq 'inboxclassic.test') "the Account name starts as the address's domain ($(GetText $second 100))"
        # the first account keeps the name offered; the second is named as the test calls it ("Work"), so the folder
        # tree and the Account column say that
        if ($onSecond) { SetText $second 100 $name }
        SetText $second 103 $user
        SetText $second 104 $password
        SetText $second 105 '127.0.0.1'
        SetText $second 106 "$($on.imap)"
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 107), $CB_SETCURSEL, [IntPtr]2, [IntPtr]::Zero)
        SetText $second 108 '127.0.0.1'
        SetText $second 109 "$($on.smtp)"
        # ImapKit's SMTP server takes a password only after STARTTLS
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($second, 110), $CB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
        if ($shots) { Shot $second 'account-3-servers' }
        Click $second 1
        $warning = WaitWindow '#32770' 'Add Mail Account'
        Check ($null -ne $warning) 'a connection without encryption is warned about'
        if ($shots -and $warning) { Shot $warning 'account-4-warning' }
        Click $warning 6
    }
    # before the first account, Add Mail Account asks whether there is another computer (accounts.cpp, app.h
    # SetupControlId, SyncControlId): Join Its Sync opens Set Up Sync, Import from a File the import, which asks for a
    # file first; cancelled, the page is there again
    $IDC_SETUP_FIRST_RUN = 956; $IDC_SYNC_FIRST_RUN = 1224
    $start = StartPage $true 20
    $importLink = if ($start) { [Native.Win]::GetDlgItem($start, $IDC_SETUP_FIRST_RUN) } else { [IntPtr]::Zero }
    $joinLink = if ($start) { [Native.Win]::GetDlgItem($start, $IDC_SYNC_FIRST_RUN) } else { [IntPtr]::Zero }
    Check ($importLink -ne [IntPtr]::Zero -and (WindowText $importLink) -eq $en['ui-first-run-import'] -and $joinLink -ne [IntPtr]::Zero -and (WindowText $joinLink) -eq $en['ui-first-run-sync'] -and (Statics $start) -match [regex]::Escape($en['ui-first-run-other'])) "before the first account, Add Mail Account asks about another computer and offers Join Its Sync and Import from a File ($(if ($joinLink -ne [IntPtr]::Zero) { WindowText $joinLink }), $(if ($importLink -ne [IntPtr]::Zero) { WindowText $importLink }))"
    if ($joinLink -ne [IntPtr]::Zero) {
        Shot $start 'setup-5-first-run'
        Check ((PushButton $start $IDC_SYNC_FIRST_RUN) -and (PushButton $start $IDC_SETUP_FIRST_RUN)) 'both are push buttons, which Tab reaches'
        Click $start $IDC_SYNC_FIRST_RUN
        $setUp = WaitShown 'InboxClassicSyncSetUp' 20
        Check ($null -ne $setUp) 'Join Its Sync opens Set Up Sync'
        if ($setUp) {
            Click $setUp 2
            [void](WaitFor { -not [Native.Win]::IsWindow($setUp) } 10)
        }
        $start = StartPage $true 20
        Check ($null -ne $start) 'cancelled, Add Mail Account is there again'
    }
    if ($start -and $importLink -ne [IntPtr]::Zero) {
        Click $start $IDC_SETUP_FIRST_RUN
        $open = WaitWindow '#32770' 'Import Settings and Accounts' 40
        Check ($null -ne $open) 'Import from a File opens the import, which asks for a file'
        if ($open) { Check (CloseDialog $open) 'Cancel closes it' }
        Check ($null -ne (StartPage $true 20)) 'cancelled, Add Mail Account is there again'
    }
    AddAccount 'Alex Morgan' 'testuser' 'testpass' $true

    # ---- reading ----

    Step 'syncing'
    $main = [Native.Win]::FindWindow('InboxClassicMain', [NullString]::Value)
    $tree = [Native.Win]::GetDlgItem($main, $IDC_TREE)
    $list = [Native.Win]::GetDlgItem($main, $IDC_LIST)
    # the message list's columns (Column in mailbox.cpp)
    $COL_FLAG = 1; $COL_SECURE = 2; $COL_FROM = 3; $COL_SUBJECT = 4; $COL_RECEIVED = 5; $COL_FOLDER = 6
    # the columns of a folder's list: attachment, flag, the lock, From, Subject, Received; a search adds Folder
    $FOLDER_COLUMNS = 6
    $folders = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -ge 7) { $n } }
    Check ($null -ne $folders) "the folders of the account are in the tree ($folders)"
    # a tree row's text without its unread count
    function Bare([IntPtr]$item) { ([Native.Win]::RemoteTreeText($tree, $item)) -replace ' \(\d+\)$', '' }
    # the rows under `parent` (the top rows for Zero), top to bottom
    function ChildRows([IntPtr]$parent) {
        $rows = @()
        $item = if ($parent -eq [IntPtr]::Zero) { [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero) } else { [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $parent) }
        while ($item -ne [IntPtr]::Zero) {
            $rows += $item
            $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        $rows
    }
    # the first row named `name` under `parent` (the top rows for Zero); Zero when there is none
    function NamedRow([IntPtr]$parent, [string]$name) {
        foreach ($row in @(ChildRows $parent)) { if ((Bare $row) -eq $name) { return $row } }
        [IntPtr]::Zero
    }
    # a folder of the first account, by its name: with one account the folders are the top rows (the Inbox first);
    # with two the Inbox, Sent Items and Drafts are the first rows under All Inboxes, All Sent and All Drafts, and the
    # others are under the first account's heading, the first top row after those and Flagged
    function FolderItem([string]$folder) {
        $all = NamedRow ([IntPtr]::Zero) 'All Inboxes'
        if ($all -eq [IntPtr]::Zero) { return (NamedRow ([IntPtr]::Zero) $folder) }
        $gathered = @{ 'Inbox' = $all; 'Sent Items' = (NamedRow ([IntPtr]::Zero) 'All Sent'); 'Drafts' = (NamedRow ([IntPtr]::Zero) 'All Drafts') }
        if ($gathered.ContainsKey($folder)) { return [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $gathered[$folder]) }
        $heading = @(ChildRows ([IntPtr]::Zero) | Where-Object { (Bare $_) -notin @('All Inboxes', 'All Sent', 'All Drafts', 'Flagged') }) | Select-Object -First 1
        if ($null -eq $heading) { return [IntPtr]::Zero }
        NamedRow $heading $folder
    }
    # the folders of the account by their place on the server: Inbox, Sent Items, Drafts, Archive, Junk E-mail,
    # Deleted Items
    $FOLDER_NAMES = @('Inbox', 'Sent Items', 'Drafts', 'Archive', 'Junk E-mail', 'Deleted Items')
    # the list read off the window thread: waits until the load of the list shown is drawn (the app's hook: 9 while a
    # load of it is not here yet)
    $kTestListOrder = 0x4C4F5244
    function Settled { [void](WaitFor { [Native.Win]::SendText($main, $kTestListOrder, '') -ne 9 } 10) }
    function SelectFolder([int]$index) {
        $item = FolderItem $FOLDER_NAMES[$index]
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $item)
        Settled
    }
    function Rows { ListCount $list }
    # the rows of the list with this subject
    function SubjectRows([string]$s) { @(0..([Math]::Max(0, (Rows) - 1)) | Where-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) -eq $s }) }
    # a tree's row by its account and folder, their unread counts and "(current)" left out; Zero when it is not there.
    # A tree without a row for the account (one account) has the folders at the top
    function TreeRow([IntPtr]$t, [string]$account, [string]$folder) {
        $name = { param($item) ([Native.Win]::RemoteTreeText($t, $item)) -replace ' \((\d+|current)\)$', '' }
        $tops = @()
        $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        while ($item -ne [IntPtr]::Zero) {
            $tops += $item
            if ((& $name $item) -eq $account) {
                $child = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]4, $item)
                while ($child -ne [IntPtr]::Zero) {
                    if ((& $name $child) -eq $folder) { return $child }
                    $child = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]1, $child)
                }
                return [IntPtr]::Zero
            }
            $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        foreach ($top in $tops) { if ((& $name $top) -eq $folder) { return $top } }
        [IntPtr]::Zero
    }
    # the texts of the rows a tree shows, top to bottom
    function TreeTexts([IntPtr]$t) {
        $texts = @()
        $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        while ($item -ne [IntPtr]::Zero) {
            $texts += [Native.Win]::RemoteTreeText($t, $item)
            $item = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]6, $item)
        }
        $texts
    }
    # the Move and Copy window, once it is open
    function WaitPicker([string]$title) {
        WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicFolderPicker', $title)
            # once its tree has the folders
            if ($f -ne [IntPtr]::Zero) {
                $t = [Native.Win]::GetDlgItem($f, 102)
                if ($t -ne [IntPtr]::Zero -and [int][Native.Win]::SendMessage($t, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -gt 0) { $f }
            }
        }
    }
    # a folder of the Move and Copy window chosen, as a click on it would
    function PickIn([IntPtr]$picker, [string]$account, [string]$folder) {
        $pickerTree = [Native.Win]::GetDlgItem($picker, 102)
        $row = TreeRow $pickerTree $account $folder
        if ($row -ne [IntPtr]::Zero) { [void][Native.Win]::SendMessage($pickerTree, $TVM_SELECTITEM, [IntPtr]9, $row) }
        $row -ne [IntPtr]::Zero
    }
    # the row selected in the list, -1 for none
    function SelectedRow { [int][Native.Win]::SendMessage($list, $LVM_GETNEXTITEM, [IntPtr](-1), [IntPtr]2) }
    # whether the reading pane shows the message with this subject (the selected row's when empty), loaded (the app's
    # hook, main.cpp kTestShown)
    $kTestShown = 0x53484F57
    function Shown([string]$subject = '') { [Native.Win]::SendText($main, $kTestShown, $subject) -eq 1 }
    # a row of the list, reached with the keys as a user would: once it is selected and the reading pane shows its
    # message (a row that shows none, of a message not downloaded or of several, is waited for a few seconds)
    function SelectRow([int]$row) {
        # a list still loading (a search, a folder) takes the selection away when it comes
        Settled
        # a click into the first row gives the list the keyboard, as it does for a user
        $point = [IntPtr]((28 -shl 16) -bor 60)
        [void][Native.Win]::PostMessage($list, 0x0201, [IntPtr]1, $point)
        [void][Native.Win]::PostMessage($list, 0x0202, [IntPtr]::Zero, $point)
        [void](WaitFor { [Native.Win]::FocusOf($list) -eq $list } 3)
        # the click taken first: it selects the top row shown (LVM_GETTOPINDEX), whose message the pane then shows, so
        # the row asked for is opened again even when it was the one selected (its message shown anew: a key verified
        # since, say), and a row selected before is not taken for it. The keys posted after the click come after it
        $first = [int][Native.Win]::SendMessage($list, 0x1027, [IntPtr]::Zero, [IntPtr]::Zero)
        if ($row -ne $first) { [void](WaitFor { (SelectedRow) -eq $first -and (Shown) } 3) }
        Key $list $VK_HOME
        for ($i = 0; $i -lt $row; $i++) { Key $list $VK_DOWN }
        if (WaitFor { (SelectedRow) -eq $row } 5) {
            [void](WaitFor { Shown } 5)
        } else {
            Write-Host "   (row $row was not selected: $(SelectedRow) is)"
        }
    }
    # the first row with this subject selected, once the list has it, and the reading pane showing that message;
    # whether it does
    function SelectSubject([string]$subject) {
        $row = WaitFor { $r = @(SubjectRows $subject); if ($r.Count) { "$($r[0])" } } 20
        if ($null -eq $row) { return $false }
        SelectRow ([int]$row)
        [bool](WaitFor { Shown $subject } 15)
    }
    # a picture of a part of the list's row $row as the screen shows it, the main window in front: the part $rect gives
    # for the row (asked while the window is in front); $null when it is empty
    function CellPicture($row, [scriptblock]$rect) {
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 300
        $cell = & $rect $row
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        if ($cell.Right -le $cell.Left -or $cell.Bottom -le $cell.Top) { return $null }
        $picture = New-Object System.Drawing.Bitmap ($cell.Right - $cell.Left), ($cell.Bottom - $cell.Top)
        CopyScreen $picture $cell.Left $cell.Top
        $picture
    }
    # every pixel of the part $rect gives of the row $row (CellPicture) handed to $visit; false when the part is empty.
    # $visit keeps what it finds in a hashtable of its caller's
    function ScanCell($row, [scriptblock]$rect, [scriptblock]$visit) {
        $picture = CellPicture $row $rect
        if (-not $picture) { return $false }
        for ($x = 0; $x -lt $picture.Width; $x++) {
            for ($y = 0; $y -lt $picture.Height; $y++) { $null = & $visit $picture.GetPixel($x, $y) }
        }
        $true
    }
    SelectFolder 0
    $rows = WaitFor { if ((Rows) -ge 4) { Rows } }
    Check ($rows -eq 4) 'the messages are in the list'
    Shot $main 'main-1-inbox'

    Step 'reading an HTML message'
    SelectRow 0
    Check ([bool](WaitFor { Seen $newsletter })) 'showing the message marked it read on the server'
    Check (Visible $main $IDC_ATTACHMENTS) 'the paper clip of the attachments is there'
    Check (Visible $main $IDC_PICTURES) 'the information bar says pictures are blocked'
    $title = WindowText $main
    Check ($title -eq 'Inbox - Inbox Classic') "the title names the folder, as the folder bar does ($title)"
    Shot $main 'read-1-html'
    # the banner sent inside the message is drawn by the core and served from /pv/, as the previews are: no picture of
    # the document has a data: or cid: address (Preview::TestPreviews "inline", each look answering the one before)
    $kTestPreviews = 0x50565753
    $inline = WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, 'inline'); if ($v -eq 10560) { $v } } 20
    Check ($null -ne $inline) "the banner is drawn by Inbox Classic, served from /pv/ and loaded, 560 pixels wide, and no picture has a data: or cid: address ($([Native.Win]::SendText($main, $kTestPreviews, 'inline')))"
    # a right click on the banner, a link to the web: Copy Link stays, as Copy Image does, while Save Image As goes
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    [void](WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, 'banner'); if ($v -ge 0) { "$v" } } 5)
    Start-Sleep -Milliseconds 300
    $p = WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, 'banner'); if ($v -gt 0) { "$v" } } 5
    Check ($null -ne $p) 'the banner is on the screen'
    if ($p) {
        $p = [int64]$p
        [Native.Win]::MouseRightClick([int][Math]::Floor($p / 100000), [int]($p % 100000))
        $menuItems = WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, 'menu'); if ($v -ge 1000) { $v } } 5
        Start-Sleep -Milliseconds 500
        Shot $main 'read-1b-picture-menu'
        [Native.Win]::keybd_event($VK_ESCAPE, 0, 0, [IntPtr]::Zero); [Native.Win]::keybd_event($VK_ESCAPE, 0, 2, [IntPtr]::Zero)
        Check ($menuItems -eq 1110) "right-clicking the linked banner offers Copy Link and Copy Image, and nothing that saves the picture ($menuItems)"
    }
    # the newsletter printed: its banner, drawn by the core, in the page as a data: picture (TestPrint: the pictures
    # loaded times 10, plus 1 for the text); the photo on the internet stays blocked
    $kTestPrint = 0x50524E54
    Command $main $IDM_PRINT
    $print = WaitWindow 'InboxClassicPrint' $null 20
    Check ($null -ne $print) 'Print of the newsletter opens the print preview'
    if ($print) {
        $looked = WaitFor { $v = [Native.Win]::SendText($main, $kTestPrint, 'Five autumn walks worth the drive'); if ($v -eq 11) { $v } } 20
        Check ($null -ne $looked) "the printout has the banner as a picture of its own, loaded ($([Native.Win]::SendText($main, $kTestPrint, 'Five autumn walks worth the drive')))"
        Start-Sleep -Seconds 2
        Shot $print 'read-1c-print-newsletter'
        [void][Native.Win]::PostMessage($print, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($print) } 10)
    }

    Step 'message properties'
    Command $main $IDM_PROPERTIES
    $properties = WaitWindow 'InboxClassicText' $null 10
    Check ($null -ne $properties) 'File > Properties opens the headers of the message'
    if ($properties) {
        $box = [Native.Win]::FindDescendants($properties, 'Edit') | Select-Object -First 1
        $headers = if ($box) { WindowText $box } else { '' }
        Check ($headers -match 'Subject: October newsletter' -and $headers -notmatch 'larches are turning') 'the headers, without the body'
        Shot $properties 'read-7-properties'
        Click $properties 1
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)) 'OK closes it'
    }

    Step 'the message list menu and the message source'
    # the menu key in the list, as Shift+F10 opens it: the menu at the selected message
    $WM_CONTEXTMENU = 0x007B
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    Check ($null -ne $menu) 'the message list has a right-click menu'
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = [Native.Win]::MenuLabels($hmenu)
        Check (($labels -contains 'Reply to Sender') -and ($labels -contains 'Mark as Unread') -and ($labels -contains 'Move to Folder...') -and
            ($labels -contains 'View Source') -and ($labels -contains 'Properties...')) "with the message's actions ($($labels -join ', '))"
        Check ($labels -notcontains 'Mark as Read') 'a read message offers Mark as Unread, not Mark as Read'
        Shot $main 'read-14-menu' $menu
        $sourceAt = [array]::IndexOf($labels, 'View Source')
        for ($i = 0; $i -le $sourceAt; $i++) { if ($labels[$i]) { Key $menu $VK_DOWN } }
        Key $menu $VK_RETURN
    }
    $source = WaitShown 'InboxClassicSource' 5
    if (-not $source) {
        # where the menu does not take posted keys: the command, as the menu would send it
        $menu = [Native.Win]::FindWindow('#32768', [NullString]::Value)
        if ($menu -ne [IntPtr]::Zero) { Key $menu $VK_ESCAPE }
        Command $main $IDM_VIEW_SOURCE
        $source = WaitShown 'InboxClassicSource' 10
    }
    Check ($null -ne $source) 'View Source opens the whole message'
    if ($source) {
        $box = [Native.Win]::FindDescendants($source, 'Edit') | Select-Object -First 1
        $raw = if ($box) { WindowText $box } else { '' }
        Check ($raw -match 'Subject: October newsletter' -and $raw -match 'Content-Type: multipart' -and $raw -match 'larches are turning') 'with its header and every part, as the server has it'
        $sourceTitle = WindowText $source
        Check ($sourceTitle -eq 'Message Source: October newsletter') "the window names the message ($sourceTitle)"
        Shot $source 'read-15-source'
        $sourceEml = Join-Path (Resolve-Path $Out) 'source-saved.eml'
        Remove-Item -Force -ErrorAction SilentlyContinue $sourceEml
        Click $source $IDM_SAVE_AS
        Check (AnswerFileDialog 'Save Message As' $sourceEml $null '*October newsletter*') 'Save As in it asks where, with the subject as the name'
        Check ([bool](WaitFor { (Test-Path $sourceEml) -and (Get-Content -Raw $sourceEml) -match 'larches are turning' } 10)) 'and saves the message as it came'
        Check ([Native.Win]::IsWindow($source)) 'and the source stays open'
        Click $source 1
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($source) } 10)) 'Close closes it'
    }

    Step 'pictures from the internet'
    # Download Pictures on the information bar: a push button, which Tab reaches
    Check (PushButton $main $IDC_PICTURES) 'the bar offers Download Pictures, a push button'
    Click $main $IDC_PICTURES
    Check ([bool](WaitFor { -not (Visible $main $IDC_PICTURES) } 10)) 'Download Pictures shows the pictures, and the bar goes away'
    Start-Sleep -Seconds 3
    Shot $main 'read-2-pictures'

    Step 'saving the attachment'
    # the paper clip's menu, as its drop-down opens it
    Command $main $IDC_ATTACHMENTS
    $menu = WaitWindow '#32768' $null 10
    Check ($null -ne $menu) 'the paper clip offers the files to save'
    if ($menu) {
        Shot $main 'read-3-attachments' $menu
        # the keys once the menu takes them: on a slow machine it appears before it does
        $save = $null
        for ($try = 0; $try -lt 3 -and -not $save; $try++) {
            Start-Sleep -Milliseconds 500
            $menu = [Native.Win]::FindWindow('#32768', [NullString]::Value)
            if ($menu -ne [IntPtr]::Zero) {
                if ($try -eq 0) {
                    Key $menu $VK_DOWN
                    Key $menu $VK_RETURN
                } else {
                    # where the menu does not take posted keys (a CI runner): real keystrokes, the app in front
                    [void][Native.Win]::SetForegroundWindow($main)
                    [System.Windows.Forms.SendKeys]::SendWait('{DOWN}{ENTER}')
                }
            }
            $save = WaitWindow '#32770' 'Save Attachment As' 5
        }
        Check ($null -ne $save) 'choosing one asks where to save it'
        if ($save) {
            # the file name box holds the suggested name (Explorer may hide the extension)
            $target = Join-Path (Resolve-Path $Out) 'report-saved.pdf'
            Check (AnswerFileDialog 'Save Attachment As' $target 'read-4-save' 'report*') "the suggested name is the file's"
            $saved = WaitFor { if (Test-Path $target) { Get-Content -Raw $target } } 10
            if (-not $saved) { Shot $main 'read-4-save-failed' }
            Check ($saved -eq $pdf) 'the attachment is saved as it was sent'
            # marked as from the internet, so SmartScreen and Protected View look at it when it is opened
            $zone = Get-Content -Path $target -Stream Zone.Identifier -ErrorAction SilentlyContinue
            Check (($zone -join "`n") -match 'ZoneId=3') 'and marked as from the internet'
        }
    }

    Step 'marking unread and read'
    Command $main $IDM_MARK_UNREAD
    Check ([bool](WaitFor { -not (Seen $newsletter) })) 'Mark Unread clears \Seen on the server'
    Shot $main 'read-5-unread'
    Command $main $IDM_MARK_READ
    Check ([bool](WaitFor { Seen $newsletter })) 'Mark Read sets it again'

    Step 'a reply with the earlier message folded'
    SelectRow 3
    Shot $main 'read-6-folded'

    # ---- writing ----

    Step 'forwarding'
    SelectRow 0
    $compose = WaitCompose { Command $main $IDM_FORWARD }
    Check ($null -ne $compose) 'Forward opens a compose window'
    Check ((GetText $compose $IDC_SUBJECT) -eq "Fw: $newsletter") 'the subject is marked Fw:'
    Check ((GetText $compose $IDC_TO) -eq '') 'the recipients are left to the user'
    Shot $compose 'write-1-forward'
    [void](CloseCompose $compose)

    Step 'replying to all'
    SelectRow 2
    $compose = WaitCompose { Command $main $IDM_REPLY_ALL }
    Check ($null -ne $compose) 'Reply All opens a compose window'
    $to = GetText $compose $IDC_TO
    Check ($to -like '*bob@example.com*' -and $to -like '*dave@example.com*') "it goes to the sender and the others ($to)"
    Check ($to -notlike '*testuser@*') 'but not to the account itself'
    Check ((GetText $compose $IDC_CC) -like '*carol@example.com*') 'with the Cc kept'
    Check (Visible $compose $IDC_CC) 'the Cc row is open, as it has someone in it'
    Shot $compose 'write-2-reply-all'
    [void](CloseCompose $compose)

    Step 'replying'
    SelectRow 1
    $compose = WaitCompose { Command $main $IDM_REPLY }
    Check ($null -ne $compose) 'Reply opens a compose window'
    Check ((GetText $compose $IDC_TO) -like '*ann@example.com*') 'the reply goes to the sender'
    # the quote is folded behind "...", the cursor is at the top: Bold, then the answer
    [void](ClickEditor $compose)
    Command $compose $IDF_BOLD
    Check ([bool](WaitFor { Pressed $compose $IDF_BOLD } 10)) 'B shows bold is on'
    Check (TypeInEditor $compose 'Thanks, Ann. The lake one is my favourite too.') 'the editor takes typing'
    Shot $compose 'write-3-reply'
    # Select All unfolds the quote and selects it along with the text
    [void][Native.Win]::SetForegroundWindow($compose)
    [void](ClickEditor $compose)
    [System.Windows.Forms.SendKeys]::SendWait('^a')
    Start-Sleep -Milliseconds 800
    Shot $compose 'write-3b-select-all'
    # the cursor back to the end, so nothing selected is typed over
    [System.Windows.Forms.SendKeys]::SendWait('^{END}')
    Command $compose $IDC_SEND
    # ImapKit's SMTP server delivers to its INBOX
    $answer = WaitFor { Find 'INBOX' "Subject: Re: $subject" } 30
    Check ($null -ne $answer) 'the reply arrived over SMTP'
    if ($answer) {
        $text = RawText $answer
        Check ($text -match 'In-Reply-To: <ui-e2e@example.com>') 'the reply refers to the message it answers'
        Check ($text -match 'my favourite too') 'the reply has what was typed'
        Check ($text -match 'Content-Type: text/html' -and $text -match 'Content-Type: text/plain') 'it is HTML with a text part'
        Check ($text -match '<b>Thanks, Ann') 'what was typed in bold is bold'
        Check ($text -match 'Original Message' -and $text -match 'shared album') 'the folded quote is sent along'
        # once in the HTML part and once in the text part: unfolded into the text, it is not added a second time
        Check ((([regex]::Matches($text, 'shared album')).Count) -eq 2) 'the quote is sent once'
    }
    Check ($null -ne (WaitFor { Find 'Sent' "Subject: Re: $subject" })) 'a copy of the reply is in Sent'

    Step 'a new message'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    Check ($null -ne $compose) 'Create Mail opens an empty compose window'
    # only the rows that are needed: Cc, Bcc and Attach wait until there is something to put in them
    Check (-not (Visible $compose $IDC_CC) -and -not (Visible $compose $IDC_BCC) -and -not (Visible $compose $IDC_FILES)) 'a new message shows no empty Cc, Bcc or Attach row'
    Check ((Visible $compose $IDC_SHOW_CC) -and (Visible $compose $IDC_SHOW_BCC)) 'the Cc and Bcc buttons are at the end of the To row'
    Shot $compose 'write-0-new-empty'
    Command $compose $IDC_SHOW_CC
    Check ([bool](WaitFor { (Visible $compose $IDC_CC) -and -not (Visible $compose $IDC_SHOW_CC) } 10)) 'Cc opens its row, and its button goes'
    $from = GetText $compose $IDC_FROM
    Check ($from -eq 'Alex Morgan <testuser@inboxclassic.test>') "From names the account it goes from ($from)"
    SetText $compose $IDC_TO 'dave at example.com'
    SetText $compose $IDC_SUBJECT 'Trail map for Sunday'
    Check ((WindowText $compose) -eq 'Trail map for Sunday') "a new message's window is named by the subject typed ($(WindowText $compose))"
    Check (TypeInEditor $compose 'Hi Dave, here is the trail map for Sunday. See you at nine!') 'the editor of a new message takes typing'
    Command $compose $IDC_SEND
    $problem = BoxOf $compose 10
    Check ($null -ne $problem) 'a mistyped address is pointed out before sending'
    if ($problem) {
        Shot $problem 'write-4-bad-address'
        [void][Native.Win]::PostMessage($problem, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    }
    Check ([bool](WaitFor { [Native.Win]::IsWindow($compose) -and [Native.Win]::FindWindow('#32770', 'Inbox Classic') -eq [IntPtr]::Zero })) 'and the message stays open to fix it'
    SetText $compose $IDC_TO 'Dave <dave@example.com>'
    # two files attached, one taken off again with Delete
    $files = Join-Path $env:TEMP 'pe-ui-attach'
    New-Item -ItemType Directory -Force $files | Out-Null
    Set-Content (Join-Path $files 'trail-map.txt') 'the attachment that goes'
    Set-Content (Join-Path $files 'packing-list.txt') 'attached by mistake'
    $attached = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
    $count = { ListBoxCount $attached }
    foreach ($file in 'trail-map.txt', 'packing-list.txt') {
        $before = & $count
        # once more if the dialog did not take the file (AnswerFileDialog closes what is left of it)
        for ($try = 0; $try -lt 2 -and (& $count) -le $before; $try++) {
            Command $compose $IDC_ATTACH
            if (-not (AnswerFileDialog 'Insert Attachment' (Join-Path $files $file) $null)) { Write-Host "   the file dialog did not take $file (try $($try + 1))" }
            [void](WaitFor { (& $count) -gt $before } 10)
        }
    }
    Check ([bool](WaitFor { (& $count) -eq 2 } 10)) 'Attach adds the files to the Attach row'
    Shot $compose 'write-5-new'
    [void][Native.Win]::SendMessage($attached, $LB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
    Key $attached $VK_DELETE
    Check ([bool](WaitFor { (& $count) -eq 1 } 10)) 'Delete in the Attach row takes one off'
    Command $compose $IDC_SEND
    $new = WaitFor { Find 'INBOX' 'Subject: Trail map for Sunday' } 30
    Check ($null -ne $new) 'the new message was sent'
    Check ($new -and (RawText $new) -match 'here is the trail map for Sunday') 'with what was typed'
    Check ($new -and (RawText $new) -match 'trail-map\.txt' -and (RawText $new) -notmatch 'packing-list') 'with only the file left attached'
    Check ($new -and (RawText $new) -match 'Content-Type: text/plain' -and (RawText $new) -notmatch 'Content-Type: text/html') 'nothing formatted: it went as plain text'

    Step 'pictures dropped into the text'
    # a real drag and drop, as from Explorer: a small window of this test starts an OLE drag of the files while the
    # mouse, moved by SendInput, carries them onto the editor and lets go there
    Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Collections.Specialized;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
public static class Dragger {
    [StructLayout(LayoutKind.Sequential)] struct MouseInput { public int dx, dy; public uint data, flags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] struct Input { [FieldOffset(0)] public uint type; [FieldOffset(8)] public MouseInput mouse; }
    [DllImport("user32.dll")] static extern uint SendInput(uint count, Input[] inputs, int size);
    const uint MOVE = 0x0001, DOWN = 0x0002, UP = 0x0004, ABSOLUTE = 0x8000;
    static void Mouse(int x, int y, uint flags) {
        Rectangle screen = Screen.PrimaryScreen.Bounds;
        var input = new Input { type = 0 };
        input.mouse.dx = x * 65535 / (screen.Width - 1);
        input.mouse.dy = y * 65535 / (screen.Height - 1);
        input.mouse.flags = flags | MOVE | ABSOLUTE;
        SendInput(1, new[] { input }, Marshal.SizeOf(typeof(Input)));
    }
    // drags `files` from (fromX, fromY) to (toX, toY), screen pixels; false when the drag ended without a drop
    public static bool Drag(string[] files, int fromX, int fromY, int toX, int toY) {
        var list = new StringCollection();
        list.AddRange(files);
        var data = new DataObject();
        data.SetFileDropList(list);
        var effect = DragDropEffects.None;
        var form = new Form {
            FormBorderStyle = FormBorderStyle.None, StartPosition = FormStartPosition.Manual, ShowInTaskbar = false,
            TopMost = true, BackColor = Color.Orange, Location = new Point(fromX - 20, fromY - 20), Size = new Size(40, 40)
        };
        form.MouseDown += (s, e) => { effect = form.DoDragDrop(data, DragDropEffects.Copy); form.Close(); };
        form.Shown += (s, e) => new Thread(() => {
            Thread.Sleep(400);
            Mouse(fromX, fromY, 0);
            Thread.Sleep(100);
            Mouse(fromX, fromY, DOWN);
            Thread.Sleep(300);
            for (int i = 1; i <= 25; i++) {
                Mouse(fromX + (toX - fromX) * i / 25, fromY + (toY - fromY) * i / 25, 0);
                Thread.Sleep(60);
            }
            // a few small moves over the target and a pause: WebView2 takes the drop only once it has seen the drag
            // over it, which a busy machine is slow to tell it
            for (int i = 0; i < 4; i++) {
                Mouse(toX + (i % 2 == 0 ? 2 : -2), toY, 0);
                Thread.Sleep(150);
            }
            Thread.Sleep(600);
            Mouse(toX, toY, UP);
        }) { IsBackground = true }.Start();
        Application.Run(form);
        return effect != DragDropEffects.None;
    }
}
'@
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    SetText $compose $IDC_TO 'Dave <dave@example.com>'
    SetText $compose $IDC_SUBJECT 'Pictures dropped in the UI test'
    Check (TypeInEditor $compose 'A picture: ') 'the editor takes typing'
    $pictureFile = Join-Path $files 'dropped.png'
    $picture.Save($pictureFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $noteFile = Join-Path $files 'dropped-note.txt'
    Set-Content $noteFile 'not a picture, attached'
    [void][Native.Win]::SetForegroundWindow($compose)
    $editorRect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($compose, $IDC_BODY), [ref]$editorRect)
    $toX = [int](($editorRect.Left + $editorRect.Right) / 2); $toY = [int](($editorRect.Top + $editorRect.Bottom) / 2)
    $attached = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
    # a drag the system ended without a drop (the editor not told of it in time on a busy machine) is tried again;
    # one that dropped is never repeated
    $dropped = $false
    for ($try = 0; $try -lt 3 -and -not $dropped; $try++) {
        [void][Native.Win]::SetForegroundWindow($compose)
        $dropped = [Dragger]::Drag(@($pictureFile, $noteFile), 40, 40, $toX, $toY)
        # a drop that landed though the drag said not: its file arrives in a moment, and then it is not tried again
        if (-not $dropped -and [bool](WaitFor { (ListBoxCount $attached) -gt 0 } 2)) { break }
    }
    Check $dropped 'the text takes files dropped on it'
    Check ([bool](WaitFor { (ListBoxCount $attached) -eq 1 } 10)) 'a file that is no picture is attached'
    Start-Sleep -Seconds 1
    Shot $compose 'write-13-dropped-picture'
    Command $compose $IDC_SEND
    $sentPicture = WaitFor { Find 'INBOX' 'Subject: Pictures dropped in the UI test' } 30
    Check ($null -ne $sentPicture) 'the message with the dropped picture was sent'
    $raw = if ($sentPicture) { RawText $sentPicture } else { '' }
    Check ($raw -match '(?s)multipart/related.*Content-Type: image/png.*Content-ID: <picture1\.' -and $raw -match 'src=(3D)?"cid:picture1\.') 'the picture went inline, as a cid: part, like Insert Picture puts one'
    Check ($raw -notmatch 'data:image') 'with no data: URI left in the HTML'
    Check ($raw -match 'dropped-note\.txt' -and $raw -notmatch 'filename="?dropped\.png') 'the other file went as an attachment, the picture not'

    Step 'links in a message being written'
    # the mouse away from where the last step left it, so no link is under it
    [Native.Win]::Mouse(5, 5, 0)
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    SetText $compose $IDC_TO 'Dave <dave@example.com>'
    SetText $compose $IDC_SUBJECT 'Links in the UI test'
    $input = ClickEditor $compose
    $composeStatus = [Native.Win]::FindWindowEx($compose, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    # a link with nothing selected: the address itself is the link's text
    Command $compose $IDF_LINK
    $dialog = WaitWindow 'InboxClassicForm' 'Hyperlink' 10
    # found as soon as it is made: its field is read once it is filled in
    Check ($dialog -and (WaitFor { (GetText $dialog 100) -eq 'https://' } 5)) 'the Link button asks for an address'
    if ($dialog) {
        SetText $dialog 100 'https://example.com/first'
        Click $dialog 1
        [void](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
    }
    # the cursor into the link: the status bar says where it goes
    Start-Sleep -Milliseconds 500
    Key $input 0x25
    Key $input 0x25
    Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'https://example.com/first*Ctrl+click to open*') { $t } } 10)) 'with the cursor in a link, the status bar shows its address'
    # a link is underlined by its own style, not by Underline: the button stays up
    Check (-not (Pressed $compose $IDF_UNDERLINE)) 'with the cursor in a link, Underline is not pressed'
    Shot $compose 'write-14-link-status'
    # the Link button on a link: its address to change
    Command $compose $IDF_LINK
    $dialog = WaitWindow 'InboxClassicForm' 'Edit Hyperlink' 10
    Check ($dialog -and (WaitFor { (GetText $dialog 100) -eq 'https://example.com/first' } 5)) 'the Link button on a link shows its address to change'
    if ($dialog) {
        Shot $dialog 'write-15-edit-link'
        SetText $dialog 100 'https://example.com/second'
        Click $dialog 1
        [void](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
    }
    Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'https://example.com/second*') { $t } } 10)) 'and changes it'
    # its menu, the app's own: Open Link, Edit Link and Remove Link first, then the editing commands
    $point = [IntPtr]((12 -shl 16) -bor 20)
    [void][Native.Win]::PostMessage($input, 0x0204, [IntPtr]2, $point)
    [void][Native.Win]::PostMessage($input, 0x0205, [IntPtr]::Zero, $point)
    $linkMenu = WaitWindow '#32768' $null 10
    Check ($null -ne $linkMenu) 'a link in the editor has a right-click menu of the app'
    if ($linkMenu) {
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($linkMenu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)))
        Check (($labels[0] -eq 'Open Link') -and ($labels -contains 'Edit Link...') -and ($labels -contains 'Remove Link') -and
            ($labels -contains 'Copy') -and ($labels -contains 'Paste') -and ($labels -contains 'Select All') -and
            ($labels -notcontains 'Emoji')) "with Open Link, Edit Link and Remove Link, then Cut, Copy, Paste ($($labels -join ', '))"
        Shot $compose 'write-16-link-menu' $linkMenu
        Key $linkMenu $VK_ESCAPE
        [void](WaitFor { -not [Native.Win]::IsWindow($linkMenu) } 5)
    }
    Start-Sleep -Milliseconds 500
    # emptied, the address takes the link off and leaves its text; the mouse off the text, so the status bar says
    # nothing of a link under it
    $composeRect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($compose, [ref]$composeRect)
    [Native.Win]::Mouse($composeRect.Left + 40, $composeRect.Bottom - 8, 0)
    Command $compose $IDF_LINK
    $dialog = WaitWindow 'InboxClassicForm' 'Edit Hyperlink' 10
    Check ($dialog -and (WaitFor { (GetText $dialog 100) -eq 'https://example.com/second' } 5)) 'the dialog shows the changed address'
    if ($dialog) {
        SetText $dialog 100 ''
        Click $dialog 1
        [void](WaitFor { -not [Native.Win]::IsWindow($dialog) } 10)
    }
    Check ([bool](WaitFor { (WindowText $composeStatus) -notlike '*example.com*' } 10)) "an empty address removes the link ($(WindowText $composeStatus))"
    Shot $compose 'write-16b-unlinked'
    Command $compose $IDC_SEND
    $linked = WaitFor { Find 'INBOX' 'Subject: Links in the UI test' } 30
    $raw = if ($linked) { RawText $linked } else { '' }
    Check ($raw -match 'https://example\.com/first' -and $raw -notmatch 'href' -and $raw -notmatch 'example\.com/second') 'the link text went, without the link'

    # a server out of reach, as when offline: its port (106 the incoming, 109 the outgoing) changed in Accounts >
    # Properties, and back
    function SetPort([int]$field, [string]$port) {
        Command $main $IDM_ACCOUNTS
        $list = WaitWindow 'InboxClassicAccounts' 'Accounts'
        if (-not $list) {
            ShowAppWindows $main 'accounts-missing'
            throw 'Tools > Accounts did not open'
        }
        Click $list 402
        $form = WaitFor {
            $f = PropertiesForm
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        }
        if (-not $form) {
            ShowAppWindows $list 'properties-missing'
            throw 'Properties did not open'
        }
        SetText $form $field $port
        Click $form 1
        # a question about a connection without encryption: Yes
        [void](WaitFor {
            $box = [Native.Win]::FindWindow('#32770', 'Properties')
            if ($box -ne [IntPtr]::Zero) { Click $box 6 }
            -not [Native.Win]::IsWindow($form)
        } 10)
        Click $list 404
        [void](WaitFor { -not [Native.Win]::IsWindow($list) })
    }
    function SetSmtpPort([string]$port) { SetPort 109 $port }

    Step 'a message that is not downloaded yet'
    $IDC_RETRY = 214
    $waiting = 'Subject: Waiting on the server'
    # in Archive, so the rows of the Inbox the later steps count stay as they are; dated a moment ahead, so it is the
    # first row there
    AddMessage ("From: Hal Example <hal@example.com>`r`nTo: testuser@inboxclassic.test`r`n$waiting`r`n" +
        "Message-ID: <waiting@example.com>`r`nDate: $([DateTime]::UtcNow.AddMinutes(5).ToString('r'))`r`n`r`nHere at last.`r`n") @() 'Archive'
    Command $main $IDM_SYNC
    [void](WaitFor { Find 'Archive' $waiting })
    # a server that takes the connection and says nothing: the download waits. Set before Archive is chosen, as a
    # folder opens with its newest message
    $silent = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, 0)
    $silent.Start()
    SetPort 106 "$($silent.LocalEndpoint.Port)"
    SelectFolder 3
    Start-Sleep -Seconds 2
    SelectRow 0
    $header = Statics $main
    Check ($header -like '*Waiting on the server*' -and $header -like '*Hal Example*') 'the header shows the message''s sender and subject at once'
    Check (-not (Visible $main $IDC_RETRY)) 'while it is being downloaded there is no Try Again'
    Shot $main 'read-13-downloading'
    # the server gone: why, and Try Again
    $silent.Stop()
    Check ([bool](WaitFor { Visible $main $IDC_RETRY } 30) -and (PushButton $main $IDC_RETRY)) 'a message that can not be downloaded says why, with Try Again, a push button'
    Shot $main 'read-12-not-downloaded'
    # the server back: the account syncs, and the message is tried again by itself
    SetPort 106 "$($ports.imap)"
    Check ([bool](WaitFor { -not (Visible $main $IDC_RETRY) -and (Find 'Archive' $waiting).flags -contains '\Seen' } 40)) "once the account is back the message shows by itself (Try Again $(Visible $main $IDC_RETRY), flags $((Find 'Archive' $waiting).flags -join ' '))"
    SelectFolder 0

    Step 'a large message shows its text first'
    # SCENARIO 17a: the whole message comes slowly, in pieces of 256 KB 300 ms apart
    [void](Invoke-RestMethod -Method Post -ContentType 'application/json' "http://127.0.0.1:$($ports.rest)/v1/script/rules" -Body (@{
        on = 'response'; command = 'UID FETCH'; untagged = $true; match = 'BODY\[\] '; chunk = 262144; chunkDelay = 300 } | ConvertTo-Json))
    $large = 'Subject: The quarterly report'
    $pdf = (@('A' * 76) * [int](3 * 1024 * 1024 / 57)) -join "`r`n"
    # in Archive, dated ahead of the one before, so it is the first row there
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`n$large`r`n" +
        "Message-ID: <quarterly@example.com>`r`nDate: $([DateTime]::UtcNow.AddMinutes(10).ToString('r'))`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: multipart/mixed; boundary=`"q`"`r`n`r`n--q`r`nContent-Type: text/plain; charset=utf-8`r`n`r`n" +
        "The figures are attached.`r`n--q`r`nContent-Type: application/pdf; name=`"report.pdf`"`r`n" +
        "Content-Disposition: attachment; filename=`"report.pdf`"`r`nContent-Transfer-Encoding: base64`r`n`r`n" +
        "$pdf`r`n--q--`r`n") @() 'Archive'
    Command $main $IDM_SYNC
    [void](WaitFor { Find 'Archive' $large } 30)
    SelectFolder 3
    # the row listed, then opened at once: no pause in which the download could end before the status bar is read
    [void](WaitFor { (SubjectRows 'The quarterly report').Count -gt 0 } 10)
    SelectRow 0
    $status = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    # every text the status bar shows meanwhile, and whether the message came from the store, to say why if it fails
    $seen = [System.Collections.Generic.List[string]]::new()
    $progress = WaitFor { $t = WindowText $status; if (-not $seen.Contains($t)) { $seen.Add($t) }; if ($t -like 'Downloading*') { $t } } 15
    $fromStore = [Native.Win]::SendText($main, 0x53544F52, '')
    Check ($null -ne $progress) "the status bar says how far the rest of a large message is (seen: $($seen -join ' | '); from the store: $($fromStore -eq 11))"
    # its PDF file a tile that says it is on its way, until the whole message is here and the view is made again
    $textLook = { param($words) $v = WaitFor { $a = [Native.Win]::SendText($main, 0x50565753, "text:$words"); if ($a -gt 0) { "$a" } } 5; if ($v) { [int]$v } else { -1 } }
    Check ($null -ne (WaitFor { if ((& $textLook 'Downloading') -eq 2) { 1 } } 10)) 'its PDF file is a tile that says it is on its way'
    Shot $main 'large-1-text-first'
    Check ($null -ne (WaitFor { $t = WindowText $status; if ($t -like 'Downloaded*') { $t } } 30)) "then that it is all here ($(WindowText $status))"
    Check ($null -ne (WaitFor { if ((& $textLook 'Downloading') -eq 1 -and (& $textLook 'The figures are attached') -eq 2) { 1 } } 15)) 'and the message is made again: the tile no longer says it is on its way'
    SelectFolder 0

    Step 'the Outbox: a send that can not go'
    SetSmtpPort '1'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    Check ([Native.Win]::GetDlgItem($compose, 308) -eq [IntPtr]::Zero) 'there is no Send Later: Send sends'
    SetText $compose $IDC_TO 'Erin <erin@example.com>'
    SetText $compose $IDC_SUBJECT 'Waited in the Outbox in the UI test'
    [void](TypeInEditor $compose 'This waited in the Outbox.')
    Command $compose $IDC_SEND
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'Send closes the message'
    $status = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ($null -ne (WaitFor { $t = WindowText $status; if ($t -match 'Outbox') { $t } } 40)) 'a send that can not go says it waits in the Outbox'
    Check ($null -eq (Find 'INBOX' 'Subject: Waited in the Outbox in the UI test')) 'and it was not sent'
    Command $main $IDM_OUTBOX
    $outbox = WaitWindow 'InboxClassicOutbox' 'Outbox'
    Check ($null -ne $outbox) 'Tools > Outbox lists what waits'
    if ($outbox) {
        $waiting = (ListCount ([Native.Win]::GetDlgItem($outbox, 450)))
        Check ($waiting -eq 1) 'the message is in it'
        Shot $outbox 'write-7-outbox'
        [void][Native.Win]::PostMessage($outbox, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($outbox) })
    }
    # the server back: the settings change syncs the account, and a sync sends the Outbox first
    SetSmtpPort "$($ports.smtp)"
    Check ($null -ne (WaitFor { Find 'INBOX' 'Subject: Waited in the Outbox in the UI test' } 30)) 'once the server is back it goes by itself'

    Step 'Drafts'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    # a window of its own, not owned by the main window: the main window can come in front of it
    Check ([Native.Win]::GetWindow($compose, 4) -eq [IntPtr]::Zero) 'the message window is a window of its own'
    # neither pinned on top (the screenshots pin the window they take)
    foreach ($w in $main, $compose) { [void][Native.Win]::SetWindowPos($w, [IntPtr](-2), 0, 0, 0, 0, 0x13) }
    [void][Native.Win]::SetForegroundWindow($main)
    Check ([bool](WaitFor { InFront $main $compose } 5)) 'the main window comes in front of a message being written'
    Shot $main 'write-0-main-in-front' $compose
    [void][Native.Win]::SetForegroundWindow($compose)
    SetText $compose $IDC_TO 'Fay <fay@example.com>'
    SetText $compose $IDC_SUBJECT 'Draft from the UI test'
    [void](TypeInEditor $compose 'Half written.')
    # closing what was written asks whether to keep it; Yes saves it in Drafts
    [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    $ask = BoxOf $compose 10
    Check ($null -ne $ask) 'closing a written message asks to save it'
    if ($ask) {
        Shot $ask 'write-8-save-draft'
        Click $ask 6
    }
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'Yes saves it and closes the window'
    $draft = WaitFor { Find 'Drafts' 'Subject: Draft from the UI test' } 30
    Check ($null -ne $draft) 'the draft is in Drafts on the server'
    Check ($draft -and $draft.flags -contains '\Draft') 'marked as a draft'
    # Drafts is the third folder; Enter on the draft opens it to go on writing
    SelectFolder 2
    Check ($null -ne (WaitFor { if ((Rows) -ge 1) { Rows } })) 'Drafts lists it'
    SelectRow 0
    $compose = WaitCompose { Key $list $VK_RETURN }
    Check ($null -ne $compose) 'opening the draft opens a compose window'
    if ($compose) {
        Check ((GetText $compose $IDC_SUBJECT) -eq 'Draft from the UI test') 'with its subject'
        Check ((GetText $compose $IDC_TO) -like '*fay@example.com*') 'and its recipient'
        Check (-not (Visible $compose 354)) 'the user''s own draft says nothing of an agent'
        [void][Native.Win]::SetForegroundWindow($compose)
        [System.Windows.Forms.SendKeys]::SendWait('^{END}')
        [void](TypeInEditor $compose 'Now finished. ')
        Shot $compose 'write-9-draft-reopened'
        # saved again: one draft, the new one
        Command $compose $IDC_SAVE
        Check ($null -ne (WaitFor { $d = @(Messages 'Drafts'); if ($d.Count -eq 1 -and (RawText $d[0]) -match 'Now finished') { $d } } 30)) 'Save replaces the draft'
        $composeStatus = [Native.Win]::FindWindowEx($compose, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'Saved in Drafts at *') { $t } } 30)) 'the message window says when the draft is saved'
        Shot $compose 'write-10-draft-saved'
        Command $compose $IDC_SEND
        $finished = WaitFor { Find 'INBOX' 'Subject: Draft from the UI test' } 30
        Check ($null -ne $finished) 'the finished draft is sent'
        Check ($finished -and (RawText $finished) -match 'Half written' -and (RawText $finished) -match 'Now finished') 'with all that was written'
        Check ([bool](WaitFor { @(Messages 'Drafts').Count -eq 0 } 30)) 'and its draft is gone'
        $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        $outgoing = WaitFor { $t = StatusPart $mainStatus 1; if ($t -like "Sent *Draft from the UI test* at *") { $t } } 30
        Check ($null -ne $outgoing) "the main window says what was sent ($(StatusPart $mainStatus 1))"
        Shot $main 'write-11-sent'
    }
    SelectFolder 0

    Step 'drafts saved automatically'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    SetText $compose $IDC_TO 'Gus <gus@example.com>'
    SetText $compose $IDC_SUBJECT 'Saved by itself in the UI test'
    [void](TypeInEditor $compose 'Not saved by hand.')
    $composeStatus = [Native.Win]::FindWindowEx($compose, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'Saved in Drafts at *') { $t } } 30)) 'a message being written is saved in Drafts once typing stops'
    $saved = WaitFor { Find 'Drafts' 'Subject: Saved by itself in the UI test' } 30
    Check ($saved -and (RawText $saved) -match 'Not saved by hand') 'the draft is in Drafts on the server'
    Shot $compose 'write-20-autosave'
    # closed without saving: the copy only the automatic saving made goes
    [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    $ask = BoxOf $compose 10
    Check ($null -ne $ask) 'closing a message saved only automatically asks whether to keep it'
    if ($ask) { Click $ask 7 }
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'No closes the window'
    Check ([bool](WaitFor { -not (Find 'Drafts' 'Subject: Saved by itself in the UI test') } 30)) 'and removes the copy saved automatically from Drafts'

    Step 'a message being written opened again after a crash'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    SetText $compose $IDC_TO 'Hal <hal@example.com>'
    SetText $compose $IDC_SUBJECT 'Written when it crashed'
    [void](TypeInEditor $compose 'Kept for a crash.')
    $composeStatus = [Native.Win]::FindWindowEx($compose, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ($null -ne (WaitFor { $t = WindowText $composeStatus; if ($t -like 'Saved in Drafts at *') { $t } } 30)) 'saved by itself'
    # the window gone as a crash takes it, without closing, and what was kept opened as at the next start
    $writing = @(ComposeWindows)
    $open = [Native.Win]::SendText($main, 0x43524153, '') - 10
    Check ($open -eq 1) "it opens again ($open)"
    $restored = WaitCompose -composeBefore $writing
    if ($restored) {
        Check ((GetText $restored $IDC_SUBJECT) -eq 'Written when it crashed') 'with its subject'
        Check ((GetText $restored $IDC_TO) -like '*hal@example.com*') 'and its recipient'
        $restoredStatus = [Native.Win]::FindWindowEx($restored, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        Check ((WindowText $restoredStatus) -like 'Restored*') "and says it was restored ($(WindowText $restoredStatus))"
        Start-Sleep -Milliseconds 500
        Shot $restored 'write-21-restored'
        [void][Native.Win]::PostMessage($restored, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        $ask = BoxOf $restored 10
        Check ($null -ne $ask) 'closing it asks whether to keep it'
        if ($ask) { Click $ask 7 }
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($restored) })) 'No closes it'
        Check ($null -ne (Find 'Drafts' 'Subject: Written when it crashed')) 'and leaves its draft in Drafts, as it may be one the user kept'
        Check (([Native.Win]::SendText($main, 0x43524153, '') - 10) -eq 0) 'closed, it is not opened again at the next start'
    }

    Step 'Undo Send'
    $IDC_OPTIONS_SEND_DELAY = 678; $IDC_UNDO_SEND = 225
    Command $main 137
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 0
        $delay = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_SEND_DELAY)
        Check ($delay -ne [IntPtr]::Zero -and [int][Native.Win]::SendMessage($delay, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -eq 5) 'Options offers the wait before sending'
        [void][Native.Win]::SendMessage($delay, $CB_SETCURSEL, [IntPtr]2, [IntPtr]::Zero)
        Shot $o 'write-24-send-delay'
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
    } else {
        Check $false 'Tools > Options opens'
    }
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    SetText $compose $IDC_TO 'Ida <ida@example.com>'
    SetText $compose $IDC_SUBJECT 'Taken back in the UI test'
    [void](TypeInEditor $compose 'On second thought.')
    Command $compose $IDC_SEND
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'Send closes the message'
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    $counting = WaitFor { $t = StatusPart $mainStatus 1; if ($t -like 'Sending *Taken back in the UI test* in *') { $t } } 5
    Check ($null -ne $counting) "the status bar counts down to sending ($(StatusPart $mainStatus 1))"
    $undo = [Native.Win]::GetDlgItem($mainStatus, $IDC_UNDO_SEND)
    Check ($undo -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($undo)) 'with an Undo button'
    Shot $main 'write-22-undo-send'
    $again = WaitCompose { Click $mainStatus $IDC_UNDO_SEND }
    Check ($null -ne $again -and (GetText $again $IDC_SUBJECT) -eq 'Taken back in the UI test') 'Undo opens the message again, as it was'
    Check (-not [Native.Win]::IsWindowVisible($undo)) 'and the Undo button goes'
    Check ((StatusPart $mainStatus 0) -like '*was not sent*') "the status bar says it was not sent ($(StatusPart $mainStatus 0))"
    if ($again) { Shot $again 'write-23-undone' }
    Start-Sleep -Seconds 12
    Check (-not (Find 'INBOX' 'Subject: Taken back in the UI test')) 'taken back, it never goes'
    if ($again) {
        # sent again and left alone: it goes once its time came
        Command $again $IDC_SEND
        Check ($null -ne (WaitFor { Find 'INBOX' 'Subject: Taken back in the UI test' } 40)) 'left alone, it goes once its time came'
        Check ([bool](WaitFor { -not [Native.Win]::IsWindowVisible($undo) } 10)) 'and the Undo button goes with it'
    }
    # back to sending at once for the steps after
    Command $main 137
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 0
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $IDC_OPTIONS_SEND_DELAY), $CB_SETCURSEL, [IntPtr]0, [IntPtr]::Zero)
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
    }

    Step 'a reminder when an attachment is missing'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    SetText $compose $IDC_TO 'Jo <jo@example.com>'
    SetText $compose $IDC_SUBJECT 'Forgot the file in the UI test'
    [void](TypeInEditor $compose 'Here is the attached plan.')
    Command $compose $IDC_SEND
    $ask = BoxOf $compose 10
    Check ($null -ne $ask) 'a message that says a file is attached, with none, asks first'
    if ($ask) {
        Shot $ask 'write-25-attachment-reminder'
        Click $ask 7
    }
    Start-Sleep -Seconds 1
    Check ([Native.Win]::IsWindow($compose)) 'No keeps the message open'
    Command $compose $IDC_SEND
    $ask = BoxOf $compose 10
    if ($ask) { Click $ask 6 }
    Check ($null -ne (WaitFor { Find 'INBOX' 'Subject: Forgot the file in the UI test' } 30)) 'Yes sends it'

    Step 'Text Size'
    $IDM_TEXT_SIZE_LARGER = 166; $IDM_TEXT_SIZE_MEDIUM = 167; $kTextZoom = 0x5A4F4F4D
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 1) { Rows } } 20)
    SelectRow 0
    Check (([Native.Win]::SendText($main, $kTextZoom, '') - 10) -eq 100) 'View > Text Size is Medium at first'
    Command $main $IDM_TEXT_SIZE_LARGER
    Check ([bool](WaitFor { ([Native.Win]::SendText($main, $kTextZoom, '') - 10) -eq 120 } 5)) 'Larger shows the message larger'
    Start-Sleep -Milliseconds 800
    Shot $main 'read-30-text-size'
    Command $main $IDM_TEXT_SIZE_MEDIUM
    Check ([bool](WaitFor { ([Native.Win]::SendText($main, $kTextZoom, '') - 10) -eq 100 } 5)) 'Medium is the usual size again'

    Step 'sending from another address'
    # the other addresses of the account set in Properties (its last field), empty to have none
    # a field of the account's Properties (100 + its place, accounts.cpp Field) set to $text, shown as $shot, and OK;
    # what the field showed before
    function SetAccountField([int]$id, [string]$text, [string]$shot = $null) {
        Command $main $IDM_ACCOUNTS
        $accountsList = WaitWindow 'InboxClassicAccounts' 'Accounts'
        Click $accountsList 402
        $form = WaitFor {
            $f = PropertiesForm
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, $id) -ne [IntPtr]::Zero) { $f }
        }
        if (-not $form) { Check $false "Properties has the field $id"; return '' }
        $shown = GetText $form $id
        SetText $form $id $text
        if ($shot) { Shot $form $shot }
        Click $form 1
        [void](WaitFor { -not [Native.Win]::IsWindow($form) } 10)
        [void][Native.Win]::PostMessage($accountsList, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($accountsList) } 10)
        return $shown
    }
    function SetOtherAddresses([string]$text, [string]$shot = $null) { [void](SetAccountField 111 $text $shot) }
    SetOtherAddresses 'Sales Desk <sales@inboxclassic.test>' 'account-12-other-addresses'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    $fromBox = [Native.Win]::GetDlgItem($compose, $IDC_FROM)
    $choices = [int][Native.Win]::SendMessage($fromBox, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
    Check ($choices -eq 2) "From offers the other address ($choices choices)"
    [void][Native.Win]::SendMessage($fromBox, $CB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
    [void][Native.Win]::SendMessage($compose, $WM_COMMAND, [IntPtr](($IDC_FROM -band 0xFFFF) -bor (1 -shl 16)), $fromBox)
    SetText $compose $IDC_TO 'Kim <kim@example.com>'
    SetText $compose $IDC_SUBJECT 'From the sales desk in the UI test'
    [void](TypeInEditor $compose 'Prices on request.')
    Shot $compose 'write-26-from-alias'
    Command $compose $IDC_SEND
    $sent = WaitFor { Find 'INBOX' 'Subject: From the sales desk in the UI test' } 30
    Check ($sent -and (RawText $sent) -match 'From: Sales Desk <sales@inboxclassic\.test>') 'it goes from that address, with its name'
    AddMessage ("From: Lee <lee@example.com>`r`nTo: sales@inboxclassic.test`r`nSubject: Price list please`r`n" +
        "Message-ID: <prices@example.com>`r`nDate: Mon, 06 Oct 2025 09:00:00 +0000`r`n`r`nCould you send it?`r`n") @() 'Archive'
    Command $main $IDM_SYNC
    [void](WaitFor { Find 'Archive' 'Subject: Price list please' } 20)
    SelectFolder 3
    $row = WaitFor { $r = @(SubjectRows 'Price list please'); if ($r.Count -gt 0) { $r[0] } } 20
    if ($null -ne $row) {
        SelectRow $row
        $reply = WaitCompose { Command $main $IDM_REPLY }
        if ($reply) {
            $replyFrom = [Native.Win]::GetDlgItem($reply, $IDC_FROM)
            Check ([int][Native.Win]::SendMessage($replyFrom, 0x0147, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1) 'a reply to a message sent to it goes from it'
            Shot $reply 'write-27-reply-from-alias'
            Check (CloseCompose $reply) 'the reply closes without saving'
        }
    } else {
        Check $false 'the message sent to the other address is there'
    }
    SelectFolder 0
    SetOtherAddresses ''

    Step 'trusting sender checks'
    # Account Properties' Trust sender checks from (field 112): the account's domain until others are written; those
    # kept; emptied, the account's domain again
    $provider = SetAccountField 112 'mx.inboxclassic.test, relay.example.net' 'account-13-sender-checks'
    Check ($provider -eq 'inboxclassic.test') "Trust sender checks from shows the account's domain ($provider)"
    $written = SetAccountField 112 ''
    Check ($written -eq 'mx.inboxclassic.test, relay.example.net') "Properties keeps the servers whose sender checks are trusted ($written)"
    $back = SetAccountField 112 $provider
    Check ($back -eq 'inboxclassic.test') "emptied, the provider's names are back ($back)"

    Step 'message rules'
    # Tools > Message Rules and the rule editor (rules.cpp, RulesControlId in app.h)
    $IDM_MESSAGE_RULES = 170; $IDM_CREATE_RULE_FROM_MESSAGE = 171; $IDC_SEARCH_RULE = 239
    $IDC_RULES_LIST = 840; $IDC_RULES_NEW = 841; $IDC_RULES_DELETE = 843; $IDC_RULES_CLOSE = 846
    $IDC_RULE_NAME = 850; $IDC_RULE_QUERY = 852; $IDC_RULE_COUNT = 854; $IDC_RULE_MOVE = 856; $IDC_RULE_MOVE_TO = 857
    $IDC_RULE_MARK_READ = 858; $IDC_RULE_FLAG = 859; $IDC_RULE_ARCHIVE = 860
    $BM_SETCHECK = 0x00F1; $BM_GETCHECK = 0x00F0
    # a check box of the editor ticked as a click would: checked, then BN_CLICKED to the editor
    function Tick([IntPtr]$editor, [int]$id) {
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($editor, $id), $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $editor $id
        # the click handled before the next one: a check box ticked meanwhile would be taken for the one clicked
        Start-Sleep -Milliseconds 300
    }
    function OpenRules {
        Command $main $IDM_MESSAGE_RULES
        WaitShown 'InboxClassicRules'
    }
    function CloseRules([IntPtr]$rules) {
        Click $rules $IDC_RULES_CLOSE
        [void](WaitFor { -not [Native.Win]::IsWindow($rules) } 10)
    }
    $rulesStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    $rules = OpenRules
    Check ($null -ne $rules) 'Tools > Message Rules opens the rules'
    if ($rules) {
        $ruleList = [Native.Win]::GetDlgItem($rules, $IDC_RULES_LIST)
        Check ((ListCount $ruleList) -eq 0) 'there are none at first'
        Shot $rules 'rules-1-list'
        Click $rules $IDC_RULES_NEW
        $editor = WaitShown 'InboxClassicRule'
        Check ($null -ne $editor) 'New opens the rule editor'
        if ($editor) {
            SetText $editor $IDC_RULE_NAME 'Newsletters'
            SetText $editor $IDC_RULE_QUERY 'from:news@example.com'
            # a message goes to one place: Move it to unticks Archive it
            Tick $editor $IDC_RULE_ARCHIVE
            Tick $editor $IDC_RULE_MOVE
            $archiveTicked = { [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($editor, $IDC_RULE_ARCHIVE), $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 }
            Check ([bool](WaitFor { -not (& $archiveTicked) } 5)) 'ticking Move it to unticks Archive it'
            # the folder to move to: Archive, as the core labels it (indented as in the tree)
            $moveTo = [Native.Win]::GetDlgItem($editor, $IDC_RULE_MOVE_TO)
            $archiveIndex = -1
            $targets = [int][Native.Win]::SendMessage($moveTo, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
            for ($i = 0; $i -lt $targets; $i++) {
                $label = New-Object System.Text.StringBuilder 256
                [void][Native.Win]::SendMessage($moveTo, $CB_GETLBTEXT, [IntPtr]$i, $label)
                if ($label.ToString().Trim() -eq 'Archive') { $archiveIndex = $i }
            }
            Check ($archiveIndex -ge 0) "Move it to offers Archive (folders offered: $targets)"
            Check ([Native.Win]::IsWindowEnabled($moveTo)) 'the folder can be chosen once Move it to is ticked'
            [void][Native.Win]::SendMessage($moveTo, $CB_SETCURSEL, [IntPtr]$archiveIndex, [IntPtr]::Zero)
            Tick $editor $IDC_RULE_MARK_READ
            # the count follows the query a moment after it changed: the newsletter in the Inbox
            $count = WaitFor { $t = GetText $editor $IDC_RULE_COUNT; if ($t -match 'Inbox messages? currentl') { $t } } 5
            Check ($null -ne $count) "the editor says how many messages in the Inbox match now ($(GetText $editor $IDC_RULE_COUNT))"
            Shot $editor 'rules-2-editor'
            Click $editor 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($editor) } 10)) 'OK saves the rule'
        }
        Check ([bool](WaitFor { (ListCount $ruleList) -eq 1 } 5)) 'the rule is listed'
        Check ([Native.Win]::RemoteListText($ruleList, 0, 0) -eq 'Newsletters' -and [Native.Win]::RemoteListText($ruleList, 0, 1) -eq 'from:news@example.com') 'with its name and what it matches'
        CloseRules $rules
    }
    # new mail it matches is read and moved to Archive as it arrives
    AddMessage ("From: News <news@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Weekly news in the UI test`r`n" +
        "Message-ID: <weekly-news@example.com>`r`nDate: Tue, 07 Oct 2025 08:00:00 +0000`r`n`r`nThis week's news.`r`n")
    Command $main $IDM_SYNC
    $sorted = WaitFor { Find 'Archive' 'Subject: Weekly news in the UI test' } 30
    Check ($null -ne $sorted) 'the rule moves new mail it matches to Archive'
    Check ($sorted -and $sorted.flags -contains '\Seen') 'and marks it read'
    Check ($null -eq (Find 'INBOX' 'Subject: Weekly news in the UI test')) 'it is not left in the Inbox'
    $said = WaitFor { $t = StatusPart $rulesStatus 0; if ($t -like '*processed by your rules') { $t } } 15
    Check ($null -ne $said) "the status bar says the rules sorted it ($(StatusPart $rulesStatus 0))"
    SelectFolder 3
    [void](WaitFor { @(SubjectRows 'Weekly news in the UI test').Count -gt 0 } 10)
    Shot $main 'rules-5-applied'
    SelectFolder 0

    # a query that names a folder can not be a rule's: the editor says why and stays open
    $rules = OpenRules
    if ($rules) {
        Click $rules $IDC_RULES_NEW
        $editor = WaitShown 'InboxClassicRule'
        if ($editor) {
            SetText $editor $IDC_RULE_QUERY 'in:sent from:x'
            Tick $editor $IDC_RULE_FLAG
            Click $editor 1
            $refused = WaitWindow '#32770' 'Message Rule' 10
            # the alert's text is read once it is there, not as the window appears
            $why = if ($refused) { WaitFor { $t = (Statics $refused) -join ' '; if ($t -match 'folder or (a )?date') { $t } } 5 }
            Check ($null -ne $why) "OK refuses a query with a folder, and says why ($(if ($refused) { Statics $refused }))"
            if ($refused) {
                Shot $refused 'rules-6-bad-query'
                Click $refused 2
                [void](WaitFor { -not [Native.Win]::IsWindow($refused) } 5)
            }
            Check ([Native.Win]::IsWindow($editor)) 'the editor stays open'
            Click $editor 2
            [void](WaitFor { -not [Native.Win]::IsWindow($editor) } 5)
        }
        CloseRules $rules
    }

    # a rule from what was searched for: Create Rule on the search bar
    $ruleFind = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    $inboxRows = Rows
    [void][Native.Win]::SendMessage($ruleFind, $WM_SETTEXT, [IntPtr]::Zero, 'lunch')
    $IDC_SEARCH_CLEAR = 209
    Check ([bool](WaitFor { (Visible $main 208) -and (Visible $main $IDC_SEARCH_RULE) } 10) -and (PushButton $main $IDC_SEARCH_RULE) -and (PushButton $main $IDC_SEARCH_CLEAR)) 'the search bar has Create Rule and Clear search, push buttons'
    Click $main $IDC_SEARCH_RULE
    $editor = WaitShown 'InboxClassicRule'
    Check ($editor -and (GetText $editor $IDC_RULE_QUERY) -eq 'lunch') "Create Rule opens the editor with the words searched for ($(if ($editor) { GetText $editor $IDC_RULE_QUERY }))"
    if ($editor) {
        Shot $editor 'rules-3-from-search'
        Click $editor 2
        [void](WaitFor { -not [Native.Win]::IsWindow($editor) } 5)
    }
    Click $main 209
    [void](WaitFor { (Rows) -eq $inboxRows -and -not (Visible $main 208) } 10)

    # a rule from a message: its sender
    SelectFolder 0
    SelectRow 0
    Command $main $IDM_CREATE_RULE_FROM_MESSAGE
    $editor = WaitShown 'InboxClassicRule'
    Check ($editor -and (GetText $editor $IDC_RULE_QUERY) -like 'from:*') "Create Rule from Message starts with its sender ($(if ($editor) { GetText $editor $IDC_RULE_QUERY }))"
    if ($editor) {
        Shot $editor 'rules-4-from-message'
        Click $editor 2
        [void](WaitFor { -not [Native.Win]::IsWindow($editor) } 5)
    }

    # the rule deleted, so the steps after this one get their mail as before
    $rules = OpenRules
    if ($rules) {
        $ruleList = [Native.Win]::GetDlgItem($rules, $IDC_RULES_LIST)
        Click $rules $IDC_RULES_DELETE
        $ask = WaitWindow '#32770' 'Message Rules' 10
        Check ($ask -and (Statics $ask) -match 'Newsletters') 'Delete asks first, naming the rule'
        if ($ask) { Click $ask 6 }
        Check ([bool](WaitFor { (ListCount $ruleList) -eq 0 } 5)) 'and deletes it'
        CloseRules $rules
    }

    Step 'encryption keys'
    # Tools > Encryption Keys and its windows (keys.cpp, KeysControlId in app.h); the key files of scripts/ui-e2e/keys
    $IDM_ENCRYPTION_KEYS = 172
    $IDC_KEYS_LIST = 870; $IDC_KEYS_NEW = 871; $IDC_KEYS_IMPORT = 872; $IDC_KEYS_EXPORT = 873; $IDC_KEYS_BACKUP = 874
    $IDC_KEYS_VERIFY = 875; $IDC_KEYS_PROPERTIES = 876; $IDC_KEYS_REMOVE = 877; $IDC_KEYS_CLOSE = 878
    $IDC_KEY_ACCOUNT = 880; $IDC_KEY_NOTE = 881; $IDC_KEY_PASSPHRASE = 882; $IDC_KEY_PASSPHRASE_AGAIN = 883; $IDC_KEY_PROBLEM = 884
    $IDC_KEY_NAMES = 885; $IDC_KEY_FINGERPRINT = 886; $IDC_KEY_STATUS = 887; $IDC_KEY_CREATED = 888; $IDC_KEY_EXPIRES = 889
    $IDC_KEY_ALGORITHM = 890; $IDC_KEY_SOURCE = 891; $IDC_KEY_ADDRESSES = 892; $IDC_VERIFY_MATCH = 894; $IDC_VERIFY_DIFFER = 895
    $IDC_ACCOUNT_KEY = 897; $IDC_ACCOUNT_KEY_NEW = 898; $IDC_ACCOUNT_AUTOCRYPT = 899; $IDC_CONTACT_KEY = 785
    $keyFiles = Resolve-Path (Join-Path $PSScriptRoot 'ui-e2e\keys')
    $keysOut = Resolve-Path $Out
    function OpenKeys {
        Command $main $IDM_ENCRYPTION_KEYS
        WaitShown 'InboxClassicKeys'
    }
    function CloseKeys([IntPtr]$keys) {
        Click $keys $IDC_KEYS_CLOSE
        [void](WaitFor { -not [Native.Win]::IsWindow($keys) } 10)
    }
    function Enabled([IntPtr]$window, [int]$id) { [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($window, $id)) }
    # the row of the key list whose Name is $name selected as the arrow keys do, its index (-1 when it is not there)
    function SelectKey([IntPtr]$keys, [string]$name) {
        $l = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        $at = -1
        for ($i = 0; $i -lt (ListCount $l); $i++) { if ([Native.Win]::RemoteListText($l, $i, 0) -eq $name) { $at = $i } }
        if ($at -lt 0) { return -1 }
        Key $l $VK_HOME
        for ($i = 0; $i -lt $at; $i++) { Key $l $VK_DOWN }
        Start-Sleep -Milliseconds 300
        $at
    }
    function KeyRow([IntPtr]$keys, [int]$row) {
        $l = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        @(0..3 | ForEach-Object { [Native.Win]::RemoteListText($l, $row, $_) }) -join ' | '
    }
    # a message box of the key windows once its words are there: its words, after which OK closes it
    function Told([string]$title, [string]$pattern) {
        $box = WaitWindow '#32770' $title 10
        $said = if ($box) { WaitFor { $t = Statics $box; if ($t -match $pattern) { $t } } 5 }
        $all = if ($box) { Statics $box } else { '' }
        if ($box) {
            Click $box 2
            [void](WaitFor { -not [Native.Win]::IsWindow($box) } 5)
        }
        if ($said) { $said } else { "(not said: $all)" }
    }
    # the question of the key windows with answers of their own
    function Asked([string]$pattern) {
        WaitFor { $w = [Native.Win]::FindWindow('InboxClassicAsk', [NullString]::Value); if ($w -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($w) -and (Statics $w) -match $pattern) { $w } } 10
    }
    # the passphrase window, the one that says why when $problem
    function PassphraseWindow([bool]$problem = $false) {
        WaitFor {
            $w = [Native.Win]::FindWindow('InboxClassicPassphrase', [NullString]::Value)
            if ($w -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($w) -and (-not $problem -or [Native.Win]::GetDlgItem($w, $IDC_KEY_PROBLEM) -ne [IntPtr]::Zero)) { $w }
        } 15
    }

    $keys = OpenKeys
    Check ($null -ne $keys) 'Tools > Encryption Keys opens the keys'
    if ($keys) {
        $keyList = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        Check ((ListCount $keyList) -eq 0) 'there are none at first'
        Check ((Enabled $keys $IDC_KEYS_NEW) -and (Enabled $keys $IDC_KEYS_IMPORT)) 'New Key and Import can be used'
        $greyed = @($IDC_KEYS_EXPORT, $IDC_KEYS_BACKUP, $IDC_KEYS_VERIFY, $IDC_KEYS_PROPERTIES, $IDC_KEYS_REMOVE | Where-Object { Enabled $keys $_ })
        Check ($greyed.Count -eq 0) "Export, Back Up, Verify, Properties and Remove are greyed without a key ($($greyed -join ', '))"
        Shot $keys 'keys-1-empty'

        # New Key: for the only account, which is chosen; passwords in memory only, so the key will not outlive the run
        Click $keys $IDC_KEYS_NEW
        $newKey = WaitShown 'InboxClassicNewKey'
        Check ($null -ne $newKey) 'New Key opens'
        if ($newKey) {
            $choice = [Native.Win]::GetDlgItem($newKey, $IDC_KEY_ACCOUNT)
            $accountText = WindowText $choice
            Check ([int][Native.Win]::SendMessage($choice, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 -and $accountText -match 'testuser@inboxclassic\.test') "it names the account, chosen ($accountText)"
            Check ((GetText $newKey $IDC_KEY_NOTE) -match 'memory only') "it says passwords are kept in memory only ($(GetText $newKey $IDC_KEY_NOTE))"
            Shot $newKey 'keys-2-new-key'
            Click $newKey 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($newKey) } 30)) 'Make Key makes it'
        }
        $offer = Asked 'backup'
        Check ($null -ne $offer) 'a backup is offered at once'
        if ($offer) {
            Shot $offer 'keys-3-backup-offer'
            Click $offer 1
        }

        # Back Up: the passphrase twice; what the core says of it as it is typed, OK only once it takes it
        $backup = PassphraseWindow
        Check ($null -ne $backup -and (WindowText $backup) -eq 'Back Up Key') "Save a Backup asks for a passphrase ($(if ($backup) { WindowText $backup }))"
        if ($backup) {
            $feedback = { if ([Native.Win]::IsWindowVisible([Native.Win]::GetDlgItem($backup, $IDC_KEY_PROBLEM))) { GetText $backup $IDC_KEY_PROBLEM } else { '' } }
            Check (-not (Enabled $backup 1) -and (& $feedback) -eq '') 'OK waits for a passphrase, nothing said before one is typed'
            SetText $backup $IDC_KEY_PASSPHRASE 'correct horse battery staple'
            SetText $backup $IDC_KEY_PASSPHRASE_AGAIN 'correct horse battery stable'
            Check ([bool](WaitFor { (& $feedback) -match 'not the same' -and -not (Enabled $backup 1) } 5)) "two different passphrases are refused as they are typed ($(& $feedback))"
            Shot $backup 'keys-4-backup'
            SetText $backup $IDC_KEY_PASSPHRASE 'short'
            SetText $backup $IDC_KEY_PASSPHRASE_AGAIN 'short'
            Check ([bool](WaitFor { (& $feedback) -match 'at least 8' -and -not (Enabled $backup 1) } 5)) "a short one is refused ($(& $feedback))"
            SetText $backup $IDC_KEY_PASSPHRASE 'correct horse battery staple'
            SetText $backup $IDC_KEY_PASSPHRASE_AGAIN 'correct horse battery staple'
            Check ([bool](WaitFor { (& $feedback) -eq '' -and (Enabled $backup 1) } 5)) 'the same one twice is taken, OK on'
            Click $backup 1
            $backupFile = Join-Path $keysOut 'own-key-backup.asc'
            Remove-Item -Force -ErrorAction SilentlyContinue $backupFile
            Check (AnswerFileDialog 'Save a Backup' $backupFile $null '*private key*') 'a good one asks where to save the backup, under the name the core gave'
            $said = Told 'Back Up Key' 'saved'
            Check ($said -match 'saved') "it says the backup was saved ($said)"
            $armored = if (Test-Path $backupFile) { Get-Content -Raw $backupFile } else { '' }
            Check ($armored -match '^-----BEGIN PGP PRIVATE KEY BLOCK-----') 'the file is an armored private key'
        }
        Check ([bool](WaitFor { (ListCount $keyList) -eq 1 } 5)) 'the new key is listed'
        $own = KeyRow $keys 0
        Check ($own -eq 'Alex Morgan | testuser@inboxclassic.test | Your key | Valid') "with the account's name and address, Your key, Valid ($own)"
        Shot $keys 'keys-5-list'

        # the backup asks for its passphrase when it is imported (and is not imported here)
        if ($armored) {
            Click $keys $IDC_KEYS_IMPORT
            Check (AnswerFileDialog 'Import' $backupFile $null) 'Import asks for a key file'
            $asks = PassphraseWindow
            Check ($null -ne $asks) 'the backup asks for its passphrase'
            if ($asks) {
                Click $asks 2
                [void](WaitFor { -not [Native.Win]::IsWindow($asks) } 5)
            }
        }

        # Bob's public key: a contact's, Valid, and the core's summary said
        Click $keys $IDC_KEYS_IMPORT
        Check (AnswerFileDialog 'Import' (Join-Path $keyFiles 'bob.pub.asc') $null) 'Import of a public key'
        $said = Told 'Import Key' '.'
        Check ($said -notmatch '^\(not said') "the core's summary is shown ($said)"
        Check ([bool](WaitFor { (ListCount $keyList) -eq 2 } 5)) 'it is listed'
        $bob = -1
        for ($i = 0; $i -lt (ListCount $keyList); $i++) { if ([Native.Win]::RemoteListText($keyList, $i, 0) -eq 'Bob Example') { $bob = $i } }
        Check ($bob -ge 0 -and (KeyRow $keys $bob) -eq 'Bob Example | bob@example.net | Contact | Valid') "as Bob's, a contact's, Valid ($(if ($bob -ge 0) { KeyRow $keys $bob }))"
        CloseKeys $keys
    }

    # Carol's private key holds an address of the account: the window asks whether to use it for that address
    SetOtherAddresses 'carol@example.org'
    $keys = OpenKeys
    if ($keys) {
        $keyList = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        Click $keys $IDC_KEYS_IMPORT
        Check (AnswerFileDialog 'Import' (Join-Path $keyFiles 'carol.sec.asc') $null) 'Import of a protected private key'
        $asks = PassphraseWindow
        Check ($null -ne $asks -and (WindowText $asks) -eq 'Import Key') 'it asks for the passphrase'
        if ($asks) {
            Shot $asks 'keys-6-import-passphrase'
            SetText $asks $IDC_KEY_PASSPHRASE 'wrong horse'
            Click $asks 1
            $again = PassphraseWindow $true
            Check ($null -ne $again) "a wrong one says so and asks again ($(if ($again) { GetText $again $IDC_KEY_PROBLEM }))"
            if ($again) {
                Shot $again 'keys-6b-wrong-passphrase'
                SetText $again $IDC_KEY_PASSPHRASE 'correct horse battery'
                Click $again 1
                $said = Told 'Import Key' '.'
                Check ($said -notmatch '^\(not said') "the right one imports it ($said)"
                $useFor = Asked 'carol@example\.org'
                Check ($null -ne $useFor) 'the window asks "Use this key for carol@example.org?"'
                if ($useFor) {
                    Shot $useFor 'keys-7-use-for'
                    Click $useFor 1
                    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($useFor) } 5)) 'Use It makes it that address''s key'
                }
            }
        }
        Check ([bool](WaitFor { (ListCount $keyList) -eq 3 } 5)) "Carol's key is listed ($(ListCount $keyList))"
        Check ((KeyRow $keys 1) -eq 'Carol Example | carol@example.org | Your key | Valid') "as the user's own, after the account's ($(KeyRow $keys 1))"

        # Bob's Properties: every line filled in
        Check ((SelectKey $keys 'Bob Example') -ge 0) "Bob's key can be selected"
        Check (-not (Enabled $keys $IDC_KEYS_BACKUP) -and (Enabled $keys $IDC_KEYS_VERIFY)) 'a contact''s key can be verified, not backed up'
        Click $keys $IDC_KEYS_PROPERTIES
        $properties = WaitShown 'InboxClassicKeyProperties'
        Check ($null -ne $properties) 'Properties opens'
        if ($properties) {
            $values = @{}
            foreach ($id in $IDC_KEY_NAMES, $IDC_KEY_FINGERPRINT, $IDC_KEY_STATUS, $IDC_KEY_CREATED, $IDC_KEY_EXPIRES, $IDC_KEY_ALGORITHM, $IDC_KEY_SOURCE, $IDC_KEY_ADDRESSES) {
                $values[$id] = GetText $properties $id
            }
            Write-Host "   properties: $(($values.Values | ForEach-Object { $_ -replace "`r`n", ' / ' }) -join ' | ')"
            Check ($values[$IDC_KEY_NAMES] -eq 'Bob Example <bob@example.net>') "the names ($($values[$IDC_KEY_NAMES]))"
            Check ($values[$IDC_KEY_FINGERPRINT] -match '^([0-9A-F]{4} ){9}[0-9A-F]{4}$') "the fingerprint in groups of four ($($values[$IDC_KEY_FINGERPRINT]))"
            Check ($values[$IDC_KEY_STATUS] -eq 'Valid' -and $values[$IDC_KEY_CREATED] -match '\d' -and $values[$IDC_KEY_EXPIRES] -eq 'Never') 'Valid, created, expires Never'
            Check ($values[$IDC_KEY_ALGORITHM] -eq 'Ed25519' -and $values[$IDC_KEY_SOURCE] -match 'file') "Ed25519, imported from a file ($($values[$IDC_KEY_SOURCE]))"
            Check ($values[$IDC_KEY_ADDRESSES] -eq 'bob@example.net (not verified)') "bob@example.net, not verified ($($values[$IDC_KEY_ADDRESSES]))"
            Shot $properties 'keys-8-properties'
            Click $properties 2
            [void](WaitFor { -not [Native.Win]::IsWindow($properties) } 5)
        }

        # Verify: the fingerprint large, They Match marks it
        Click $keys $IDC_KEYS_VERIFY
        $verify = WaitShown 'InboxClassicVerify'
        Check ($null -ne $verify) 'Verify opens'
        if ($verify) {
            Check ((Statics $verify) -match 'Ask Bob Example') "the intro names Bob ($(Statics $verify))"
            Check ((Statics $verify) -match 'this address belongs to the contact: bob@example\.net') "and the addresses They Match marks ($(Statics $verify))"
            $large = GetText $verify $IDC_KEY_FINGERPRINT
            Check ($large -match '^([0-9A-F]{4} ){4}[0-9A-F]{4}\r\n([0-9A-F]{4} ){4}[0-9A-F]{4}$') "the fingerprint in two lines of five groups ($($large -replace "`r`n", ' / '))"
            Check ((GetText $verify $IDC_VERIFY_MATCH) -match 'Match' -and (GetText $verify $IDC_VERIFY_DIFFER) -match 'Differ') 'They Match and They Differ'
            Shot $verify 'keys-9-verify'
            Click $verify $IDC_VERIFY_MATCH
            [void](WaitFor { -not [Native.Win]::IsWindow($verify) } 5)
        }
        $bob = SelectKey $keys 'Bob Example'
        Check ($bob -ge 0 -and [Native.Win]::RemoteListText($keyList, $bob, 3) -eq 'Valid, verified') "They Match marks it: Valid, verified ($(if ($bob -ge 0) { [Native.Win]::RemoteListText($keyList, $bob, 3) }))"

        # Export: an armored public key, named after Bob
        $exported = Join-Path $keysOut 'bob-exported.asc'
        Remove-Item -Force -ErrorAction SilentlyContinue $exported
        Click $keys $IDC_KEYS_EXPORT
        Check (AnswerFileDialog 'Export' $exported $null 'Bob Example public key*') 'Export offers "Bob Example public key.asc"'
        Check ([bool](WaitFor { (Test-Path $exported) -and (Get-Content -Raw $exported) -match '^-----BEGIN PGP PUBLIC KEY BLOCK-----' } 5)) 'and saves an armored public key'
        CloseKeys $keys
    }

    # Account Properties > Security: the account's key chosen, None and Carol's offered, New Key, Autocrypt on
    Command $main $IDM_ACCOUNTS
    $accountsList = WaitWindow 'InboxClassicAccounts' 'Accounts'
    if ($accountsList) {
        Click $accountsList 402
        $form = WaitFor { $f = PropertiesForm; if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, $IDC_ACCOUNT_KEY) -ne [IntPtr]::Zero) { $f } }
        Check ($null -ne $form) 'Account Properties has Security'
        if ($form) {
            $keyChoice = [Native.Win]::GetDlgItem($form, $IDC_ACCOUNT_KEY)
            $offered = @()
            for ($i = 0; $i -lt [int][Native.Win]::SendMessage($keyChoice, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); $i++) {
                $label = New-Object System.Text.StringBuilder 256
                [void][Native.Win]::SendMessage($keyChoice, $CB_GETLBTEXT, [IntPtr]$i, $label)
                $offered += $label.ToString()
            }
            Check ((WindowText $keyChoice) -match '^Alex Morgan \(([0-9A-F]{4} ){3}[0-9A-F]{4}\)$') "the account's key is chosen ($(WindowText $keyChoice))"
            Check ($offered.Count -eq 3 -and $offered[0] -eq 'None' -and ($offered -match '^Carol Example \(').Count -eq 1) "None and the other own keys are offered ($($offered -join ', '))"
            Check ((Visible $form $IDC_ACCOUNT_KEY_NEW) -and [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($form, $IDC_ACCOUNT_AUTOCRYPT), 0x00F0, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1) 'New Key, and Send my public key with my messages, on'
            Shot $form 'keys-10-account-security'
            Click $form 2
            [void](WaitFor { -not [Native.Win]::IsWindow($form) } 10)
        }
        [void][Native.Win]::PostMessage($accountsList, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($accountsList) } 10)
    }

    # Bob in the Address Book: his Properties show his key, verified; the card goes again for the Address Book's steps
    $IDM_ADDRESS_BOOK = 147; $IDC_BOOK_LIST = 701; $IDC_BOOK_NEW_CONTACT = 710; $IDC_BOOK_PROPERTIES = 712; $IDC_BOOK_DELETE = 713
    $IDC_CONTACT_FIRST = 720; $IDC_CONTACT_LAST = 721; $IDC_CONTACT_ADDRESS = 725; $IDC_CONTACT_ADD = 726; $IDC_CONTACT_ADDRESSES = 727
    Command $main $IDM_ADDRESS_BOOK
    $book = WaitShown 'InboxClassicAddressBook' 10
    if ($book) {
        $bookList = [Native.Win]::GetDlgItem($book, $IDC_BOOK_LIST)
        Click $book $IDC_BOOK_NEW_CONTACT
        $contact = WaitShown 'InboxClassicContact' 10
        if ($contact) {
            SetText $contact $IDC_CONTACT_FIRST 'Bob'
            SetText $contact $IDC_CONTACT_LAST 'Example'
            SetText $contact $IDC_CONTACT_ADDRESS 'bob@example.net'
            Click $contact $IDC_CONTACT_ADD
            [void](WaitFor { (ListBoxCount ([Native.Win]::GetDlgItem($contact, $IDC_CONTACT_ADDRESSES))) -eq 1 } 5)
            Click $contact 1
            [void](WaitFor { -not [Native.Win]::IsWindow($contact) } 10)
        }
        Check ([bool](WaitFor { (ListCount $bookList) -eq 1 } 10)) 'a card for Bob is added'
        Key $bookList $VK_HOME
        Start-Sleep -Milliseconds 300
        Click $book $IDC_BOOK_PROPERTIES
        $contact = WaitShown 'InboxClassicContact' 10
        if ($contact) {
            $line = GetText $contact $IDC_CONTACT_KEY
            Check ($line -match '^bob@example\.net:\s+([0-9A-F]{4} ){9}[0-9A-F]{4} \(Valid, verified\)$') "his Properties show his key's fingerprint and Valid, verified ($line)"
            Shot $contact 'keys-11-contact'
            Click $contact 2
            [void](WaitFor { -not [Native.Win]::IsWindow($contact) } 5)
        }
        Click $book $IDC_BOOK_DELETE
        $ask = BoxOf $book 10
        if ($ask) { Click $ask 6 }
        Check ([bool](WaitFor { (ListCount $bookList) -eq 0 } 5)) 'and the card goes again'
        [void][Native.Win]::PostMessage($book, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($book) } 10)
    }

    # Remove of Bob's key asks first; Carol's key and the account's stay
    $keys = OpenKeys
    if ($keys) {
        $keyList = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        [void](SelectKey $keys 'Bob Example')
        Click $keys $IDC_KEYS_REMOVE
        $ask = WaitWindow '#32770' 'Encryption Keys' 10
        $question = if ($ask) { WaitFor { $t = Statics $ask; if ($t -match 'Bob Example') { $t } } 5 }
        Check ($null -ne $question) "Remove asks first, naming Bob ($(if ($ask) { Statics $ask }))"
        if ($ask) { Click $ask 6 }
        Check ([bool](WaitFor { (ListCount $keyList) -eq 2 } 5)) 'and removes it, the two own keys staying'
        CloseKeys $keys
    }
    SetOtherAddresses ''

    # ---- signed and encrypted mail ----

    Step 'signed and encrypted mail'
    # the security bar under the header and its Details button, a child of the bar (app.h); the test hooks of the
    # reading pane: its parts' frames, and its requests to the internet (main.cpp)
    $IDC_SECURITY_BAR = 240; $IDC_SECURITY_DETAILS = 241; $IDC_PICTURES_MENU = 234; $IDM_FIND_IN_MESSAGE = 144
    $kTestFrames = 0x46524D53; $kTestRemote = 0x4E455452
    $pgpFiles = Resolve-Path (Join-Path $PSScriptRoot 'ui-e2e\pgp')
    $secureStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    $securityBar = [Native.Win]::GetDlgItem($main, $IDC_SECURITY_BAR)
    $detailsButton = [Native.Win]::GetDlgItem($securityBar, $IDC_SECURITY_DETAILS)
    # a key file imported in Encryption Keys, with its passphrase when it has one; what the core said
    function ImportKeyFile([IntPtr]$keys, [string]$file, [string]$passphrase = $null) {
        Click $keys $IDC_KEYS_IMPORT
        if (-not (AnswerFileDialog 'Import' (Join-Path $pgpFiles $file) $null)) { return '(no file window)' }
        if ($passphrase) {
            $asks = PassphraseWindow
            if (-not $asks) { return '(no passphrase asked)' }
            SetText $asks $IDC_KEY_PASSPHRASE $passphrase
            Click $asks 1
        }
        $said = Told 'Import Key' '.'
        # an address of the account with no key of its own would be offered: not now
        $offer = WaitFor { $w = [Native.Win]::FindWindow('InboxClassicAsk', [NullString]::Value); if ($w -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($w)) { $w } } 2
        if ($offer) { Click $offer 2 }
        $said
    }
    # the bar's fill, its frame and the words on it: a pixel inside its frame, as the screen shows it
    function BarFill {
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 400
        $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($securityBar, [ref]$box)
        $picture = New-Object System.Drawing.Bitmap 1, 1
        CopyScreen $picture ($box.Left + 3) ($box.Top + 3)
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        $p = $picture.GetPixel(0, 0)
        '{0:x2}{1:x2}{2:x2}' -f $p.R, $p.G, $p.B
    }
    $fills = @{ verified = 'e8f5e9'; good = 'e6eefa'; warning = 'fff4e0'; neutral = 'f2f2f2' }
    # the rows of the message pane, top down, where a colour is first found (within 6 of each part): a part's frame
    # border, say; -1 when it is not there
    $securePane = [Native.Win]::FindDescendants($main, 'Chrome_RenderWidgetHostHWND') | Select-Object -First 1
    function PaneRow([int]$r, [int]$g, [int]$b) {
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 400
        $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($securePane, [ref]$box)
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        $w = [Math]::Min(400, $box.Right - $box.Left); $h = [Math]::Min(400, $box.Bottom - $box.Top)
        if ($w -le 0 -or $h -le 0) { return -1 }
        $picture = New-Object System.Drawing.Bitmap $w, $h
        CopyScreen $picture $box.Left $box.Top
        for ($y = 0; $y -lt $h; $y++) {
            for ($x = 0; $x -lt $w; $x += 2) {
                $p = $picture.GetPixel($x, $y)
                if ([Math]::Abs($p.R - $r) -le 6 -and [Math]::Abs($p.G - $g) -le 6 -and [Math]::Abs($p.B - $b) -le 6) { return $y }
            }
        }
        -1
    }
    # the frames of the message shown: how many, whether each is as tall as its document, their height; once the
    # reading pane answered a look (each look answers the one before)
    function Frames {
        $v = WaitFor { $a = [Native.Win]::SendText($main, $kTestFrames, ''); if ($a -ge 0) { "$a" } } 5
        if (-not $v) { return [pscustomobject]@{ Count = -1; Fit = $false; Height = 0 } }
        $v = [int64]$v
        [pscustomobject]@{ Count = [int]($v % 100); Fit = ($v % 1000) -ge 100; Height = [int][Math]::Floor($v / 1000) }
    }
    # frames once there are $count of them, each as tall as its document
    function FramesFit([int]$count) {
        WaitFor { $f = Frames; if ($f.Count -eq $count -and $f.Fit) { $f } } 15
    }
    # Find in This Message of the main window asked for `words`: how many places the reading pane found, as it answered
    # (the app's hook, main.cpp kTestFound: its count plus 10, 9 before it answered); -1 when the form did not open or
    # the pane did not answer
    $kTestFound = 0x464F554E
    function FindInShown([string]$words) {
        Command $main $IDM_FIND_IN_MESSAGE
        $form = WaitForm 'Find in This Message' 10
        if (-not $form) { return -1 }
        SetText $form 100 $words
        Click $form 1
        [void](WaitFor { -not [Native.Win]::IsWindow($form) } 10)
        $v = WaitFor { $n = [Native.Win]::SendText($main, $kTestFound, ''); if ($n -ne 9) { "$n" } } 10
        if ($null -eq $v) { return -1 }
        [int]$v - 10
    }
    # words of the message shown found by Find in This Message (which looks into the parts' frames too)
    # (asked again a few times: a part's frame may still be loading its document)
    function FoundInSecure([string]$words) {
        for ($try = 0; $try -lt 3; $try++) {
            if ((FindInShown $words) -gt 0) { return $true }
            # its parts' frames sized to their documents first, once they loaded
            $f = Frames
            if ($f.Count -gt 0) { [void](FramesFit $f.Count) }
        }
        $false
    }
    # a message of scripts/ui-e2e/pgp put in the Inbox and shown: the words of its bar once the bar is there (an
    # encrypted one's subject is "..." in the list until it is read)
    # the row of the Inbox with this subject or "..." (an encrypted message's until it is read) selected; the words of
    # the bar once it is there
    function SelectSecure([string]$subject) {
        SelectFolder 0
        $row = WaitFor { $r = @(SubjectRows $subject) + @(SubjectRows '...'); if ($r.Count -gt 0) { "$($r[0])" } } 30
        if ($null -eq $row) { return "(not listed: $subject)" }
        SelectRow ([int]$row)
        $words = WaitFor { if ([Native.Win]::IsWindowVisible($securityBar)) { $t = WindowText $securityBar; if ($t) { $t } } } 20
        if ($words) { $words } else { '(no bar)' }
    }
    # a message of scripts/ui-e2e/pgp put in the Inbox and shown
    function ShowSecure([string]$file, [string]$subject) {
        AddMessage ([IO.File]::ReadAllText((Join-Path $pgpFiles $file))) @('\Seen')
        Command $main $IDM_SYNC
        SelectSecure $subject
    }
    # the message of `file` taken away again, and out of the list
    function RemoveSecure([string]$file, [string]$subject) {
        $raw = [IO.File]::ReadAllText((Join-Path $pgpFiles $file))
        if ($raw -match '(?m)^Message-ID: (<[^>\r\n]+>)') {
            $added = Find 'INBOX' ([regex]::Escape($Matches[1]))
            if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
        }
        Command $main $IDM_SYNC
        [void](WaitFor { @(SubjectRows $subject).Count -eq 0 -and @(SubjectRows '...').Count -eq 0 } 20)
    }
    # the Details window once it opens, its text; closed after
    function DetailsText([string]$shot = $null) {
        $details = WaitShown 'InboxClassicSecurityDetails' 10
        if (-not $details) { return $null }
        $text = GetText $details $IDC_SECURITY_DETAILS
        $title = WindowText $details
        if ($shot) { Shot $details $shot }
        Click $details 2
        [void](WaitFor { -not [Native.Win]::IsWindow($details) } 5)
        [pscustomobject]@{ Title = $title; Text = $text }
    }

    # the keys: the user's own (me.asc, with its passphrase), Alice's and Mallory's
    $keys = OpenKeys
    if ($keys) {
        $passphrase = (Get-Content -Raw (Join-Path $pgpFiles 'me.passphrase')).Trim()
        $said = ImportKeyFile $keys 'me.asc' $passphrase
        Check ($said -notmatch '^\(') "the user's key of the messages is imported with its passphrase ($said)"
        foreach ($file in 'alice.asc', 'mallory.asc') {
            $said = ImportKeyFile $keys $file
            Check ($said -notmatch '^\(') "$file is imported ($said)"
        }
        CloseKeys $keys
    }

    # signed by Alice, her key not verified: blue, the ribbon; one frame labelled the same
    $words = ShowSecure 'secure-signed.eml' 'Signed by Alice'
    Check ($words -eq 'Signed by alice@example.org (key not verified)') "a signed message has the bar, its words the signer's address, not verified ($words)"
    Check ((BarFill) -eq $fills.good) "the bar is blue ($(BarFill))"
    Check ($null -ne (FramesFit 1)) "the part is one frame, as tall as its document ($(Frames))"
    Check ((PaneRow 0x1f 0x5f 0xae) -ge 0) 'the part has its label in blue'
    Shot $main 'secure-2-signed-unverified'

    # They Match on Alice's key: the same message green, "key verified"
    $keys = OpenKeys
    if ($keys) {
        Check ((SelectKey $keys 'Alice Example') -ge 0) "Alice's key is listed"
        Click $keys $IDC_KEYS_VERIFY
        $verify = WaitShown 'InboxClassicVerify'
        if ($verify) {
            Click $verify $IDC_VERIFY_MATCH
            [void](WaitFor { -not [Native.Win]::IsWindow($verify) } 5)
        }
        CloseKeys $keys
    }
    SelectRow ([int](@(SubjectRows 'Signed by Alice')[0]))
    $words = WaitFor { $t = WindowText $securityBar; if ($t -match 'key verified') { $t } } 15
    Check ($null -ne $words) "after They Match the bar says the key is verified ($(WindowText $securityBar))"
    Check ((BarFill) -eq $fills.verified) "and is green ($(BarFill))"
    Shot $main 'secure-1-verified'

    # Details by the bar's button: the words, each part with the key that signed it, Close
    Click $securityBar $IDC_SECURITY_DETAILS
    $details = DetailsText
    Check ($null -ne $details -and $details.Title -eq 'Security Details') "Details opens the Security Details window ($(if ($details) { $details.Title }))"
    Check ($null -ne $details -and $details.Text -match 'Part 1' -and $details.Text -match 'with the key') "it names the part and the key that signed it ($(if ($details) { $details.Text -replace "`r`n", ' / ' }))"
    # a click on the part's label opens it too, and nothing else
    $labelTop = PaneRow 0x2e 0x7d 0x32
    if ($labelTop -ge 0) {
        $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($securePane, [ref]$box)
        [void][Native.Win]::SetForegroundWindow($main)
        [Native.Win]::MouseClick($box.Left + 60, $box.Top + $labelTop + 8)
    }
    $details = DetailsText
    Check ($null -ne $details) "a click on the part's label opens Details (its frame at row $labelTop)"
    # the keyboard: Tab reaches Details, Alt with its letter presses it
    Check ([bool]([Native.Win]::GetWindowLong($detailsButton, -16) -band 0x00010000) -and [Native.Win]::IsWindowEnabled($detailsButton)) 'Details is a Tab stop'
    Check ((WindowText $detailsButton) -eq '&Details...') "with an access key ($(WindowText $detailsButton))"
    SelectRow ([int](@(SubjectRows 'Signed by Alice')[0]))
    [void](WaitFor { [Native.Win]::IsWindowVisible($securityBar) } 10)
    [void][Native.Win]::SetForegroundWindow($main)
    $focusClass = New-Object System.Text.StringBuilder 64
    [void][Native.Win]::GetClassName([Native.Win]::FocusOf($main), $focusClass, 64)
    [System.Windows.Forms.SendKeys]::SendWait('%d')
    $details = DetailsText
    Check ($null -ne $details) "Alt+D opens Details from the list (the focus in $focusClass)"
    # and from the message, which has the keyboard after a click into its text
    if ($labelTop -ge 0) {
        $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($securePane, [ref]$box)
        [void][Native.Win]::SetForegroundWindow($main)
        [Native.Win]::MouseClick($box.Left + 300, $box.Top + $labelTop + 40)
        Start-Sleep -Milliseconds 500
        [System.Windows.Forms.SendKeys]::SendWait('%d')
        Check ($null -ne (DetailsText)) 'Alt+D opens Details from the message too'
    }
    RemoveSecure 'secure-signed.eml' 'Signed by Alice'

    # encrypted to the user's key, signed by Alice: the lock, and the text
    $words = ShowSecure 'secure-encrypted.eml' 'Encrypted'
    Check ($words -match '^Encrypted\. Signed by alice@example\.org, key verified') "an encrypted message's bar has the lock's words and the signer ($words)"
    Check ((BarFill) -eq $fills.verified) "green, signed by a verified key ($(BarFill))"
    Check ([bool](FoundInSecure 'old mill')) 'the text is decrypted and shown'
    Shot $main 'secure-3-encrypted'
    RemoveSecure 'secure-encrypted.eml' 'Encrypted'

    # three parts each with their own label, the bar counting them
    $words = ShowSecure 'secure-mixed.eml' 'Parts signed apart'
    Check ($words -match '3 parts' -and $words -match '1 verified' -and $words -match '2 without a confirmed signature') "the bar counts the parts ($words)"
    Check ($null -ne (FramesFit 3)) "three frames, each as tall as its part ($(Frames))"
    Check ((BarFill) -eq $fills.neutral) "grey, as its least part ($(BarFill))"
    Shot $main 'secure-4-mixed-parts'
    # a link in part 1's frame ("The mill"): the click goes to the browser (the part's <base target="_top"> navigates
    # the page, which the app cancels and follows), and the page stays as it was
    $kTestPreviews = 0x50565753
    $before = (OpenedFiles).Count
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    # asked twice: scrolled into view by the first look, where it is told by the second
    [void](WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, 'partlink:1'); if ($v -ge 0) { "$v" } } 5)
    Start-Sleep -Milliseconds 300
    $p = WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, 'partlink:1'); if ($v -gt 0) { "$v" } } 5
    Check ($null -ne $p) 'the link of part 1 is on the screen'
    if ($p) {
        $p = [int64]$p
        [Native.Win]::MouseClick([int][Math]::Floor($p / 100000), [int]($p % 100000))
    }
    $link = WaitFor { $o = @(OpenedFiles); if ($o.Count -gt $before) { $o[-1] } } 10
    Check ($link -eq 'https://example.org/mill') "a link clicked in a part's frame opens in the browser ($link)"
    Start-Sleep -Milliseconds 500
    Check ($null -ne (FramesFit 3) -and (WindowText $securityBar) -eq $words) "and the message stays as it was, its three frames and its bar ($(Frames))"
    # Details names each part, the signed one with its key
    Click $securityBar $IDC_SECURITY_DETAILS
    $details = DetailsText 'secure-9-details'
    Check ($null -ne $details -and $details.Text -match 'Part 2: Signed by alice@example\.org' -and $details.Text -match 'Part 3' -and $details.Text -match 'with the key') "Details names Part 2, signed by Alice, and its key ($(if ($details) { $details.Text -replace "`r`n", ' / ' }))"
    # Print: the core's one document of every part (a printer prints no frames), with the bar's words and the labels
    Command $main $IDM_PRINT
    $print = WaitWindow 'InboxClassicPrint' $null 20
    Check ($null -ne $print) 'Print of a message of parts opens the print preview'
    if ($print) {
        Start-Sleep -Seconds 5
        Shot $print 'secure-14-print'
        [void][Native.Win]::PostMessage($print, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($print) } 10)
    }
    RemoveSecure 'secure-mixed.eml' 'Parts signed apart'

    # a changed text, a stranger's signature, a key not known
    $words = ShowSecure 'secure-bad.eml' 'A changed text'
    Check ($words -match 'does not match') "a changed text: the signature does not match ($words)"
    Check ((BarFill) -eq $fills.warning) "amber ($(BarFill))"
    Shot $main 'secure-5-bad-signature'
    RemoveSecure 'secure-bad.eml' 'A changed text'
    $words = ShowSecure 'secure-wrong-signer.eml' 'Signed by someone else'
    Check ($words -match 'mallory@example\.net' -and $words -match 'not the sender') "signed by someone else: who, and that it is not the sender ($words)"
    Check ((BarFill) -eq $fills.warning) "amber ($(BarFill))"
    Shot $main 'secure-6-wrong-signer'
    RemoveSecure 'secure-wrong-signer.eml' 'Signed by someone else'
    $words = ShowSecure 'secure-no-key.eml' 'A key you do not have'
    Check ($words -eq 'Signed, but the key is not known') "a key not known ($words)"
    Check ((BarFill) -eq $fills.neutral) "grey ($(BarFill))"
    Shot $main 'secure-7-no-key'
    RemoveSecure 'secure-no-key.eml' 'A key you do not have'

    # a label painted in the sender's own part stays in its frame, under the real label
    $words = ShowSecure 'secure-fake-frame.eml' 'A painted frame'
    Check ($words -match '2 parts') "the bar counts 2 parts ($words)"
    $fake = FramesFit 2
    Check ($null -ne $fake) "two frames, their labels the app's ($(Frames))"
    Check ($null -ne $fake -and $fake.Height -ge 96) "the painted part out of the flow still has a frame of its own, at least 48 pixels ($(if ($fake) { $fake.Height }))"
    $real = PaneRow 0x9e 0x9e 0x9e
    $painted = PaneRow 0x2e 0x7d 0x32
    Check ($real -ge 0 -and ($painted -lt 0 -or $painted -gt $real)) "the real label Not signed is at the top, the painted green one under it (rows $real and $painted)"
    Shot $main 'secure-8-fake-frame'
    RemoveSecure 'secure-fake-frame.eml' 'A painted frame'

    # an encrypted block in plain text: a part of its own between the text around it
    $words = ShowSecure 'secure-inline.eml' 'Inline encrypted'
    Check ($words -match '3 parts') "the inline block and the text around it are 3 parts ($words)"
    Check ($null -ne (FramesFit 3)) "three frames ($(Frames))"
    Check ([bool](FoundInSecure '4711')) 'the block is decrypted in its frame'
    Shot $main 'secure-10-inline'
    RemoveSecure 'secure-inline.eml' 'Inline encrypted'

    # pictures in an encrypted part: the bar without "always", nothing asked of the internet before the click
    $words = ShowSecure 'secure-pictures.eml' 'Encrypted with a picture'
    Check ($words -match '^Encrypted\.' -and $words -notmatch 'Pictures were loaded') "an encrypted message with a picture ($words)"
    Check ([bool](WaitFor { Visible $main $IDC_PICTURES } 10)) 'the pictures bar is there'
    Check (-not (Visible $main $IDC_PICTURES_MENU)) 'without its arrow: there is no "always" for encrypted mail'
    Start-Sleep -Seconds 2
    $asked = [Native.Win]::SendText($main, $kTestRemote, '') - 10
    Check ($asked -eq 0) "nothing was asked of the internet ($asked)"
    Shot $main 'secure-11b-pictures-blocked'
    Click $main $IDC_PICTURES
    $words = WaitFor { $t = WindowText $securityBar; if ($t -match 'Pictures were loaded') { $t } } 15
    Check ($null -ne $words) "after the click the bar says pictures were loaded ($(WindowText $securityBar))"
    Check (-not (Visible $main $IDC_PICTURES)) 'and the pictures bar goes'
    Check ([bool](WaitFor { ([Native.Win]::SendText($main, $kTestRemote, '') - 10) -gt 0 } 10)) 'the picture is asked for'
    Shot $main 'secure-11-pictures-in-decrypted'
    # opened again: nothing loads until the next click
    SelectFolder 1
    Start-Sleep -Seconds 1
    $words = SelectSecure 'Encrypted with a picture'
    Start-Sleep -Seconds 2
    Check ((Visible $main $IDC_PICTURES) -and ([Native.Win]::SendText($main, $kTestRemote, '') - 10) -eq 0) "opened again, the pictures wait for a click again ($words)"
    RemoveSecure 'secure-pictures.eml' 'Encrypted with a picture'

    # a long part: its frame as tall as it, again when "..." unfolds and when the pane is narrower
    $words = ShowSecure 'secure-long.eml' 'A long encrypted message'
    $long = FramesFit 1
    Check ($null -ne $long) "a long part's frame is as tall as it: no scroll bar inside it ($(Frames))"
    Check ([bool](FoundInSecure 'Line 40 of the long part')) 'its last lines are there'
    Check ([bool](FoundInSecure 'The earlier message, folded')) 'Find unfolds the "..."'
    $unfolded = WaitFor { $f = Frames; if ($f.Fit -and $long -and $f.Height -gt $long.Height) { $f } } 10
    Check ($null -ne $unfolded) "unfolded, the frame grows to what it holds ($(if ($long) { $long.Height }) to $(if ($unfolded) { $unfolded.Height }))"
    $place = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($main, [ref]$place)
    [void][Native.Win]::SetWindowPos($main, [IntPtr]::Zero, 0, 0, 520, ($place.Bottom - $place.Top), 0x16)
    $before = if ($unfolded) { $unfolded.Height } else { 0 }
    # (its lines are short: at the narrowest the window goes they do not wrap, so it keeps its height)
    Start-Sleep -Seconds 1
    $narrow = WaitFor { $f = Frames; if ($f.Fit -and $f.Height -ge $before) { $f } } 10
    Check ($null -ne $narrow) "made narrower, it still shows all of its part ($before to $(if ($narrow) { $narrow.Height }), $(Frames))"
    Shot $main 'secure-12-resized'
    [void][Native.Win]::SetWindowPos($main, [IntPtr]::Zero, 0, 0, ($place.Right - $place.Left), ($place.Bottom - $place.Top), 0x16)
    RemoveSecure 'secure-long.eml' 'A long encrypted message'

    # ---- encrypted mail in the list and the search ----

    Step 'encrypted mail in the list and the search'
    # Reading > Encryption in Options (app.h), the Find box in its field
    $IDM_OPTIONS = 137; $IDC_OPTIONS_SEARCH_ENCRYPTED = 683; $IDC_OPTIONS_APPLY = 681
    $IDM_LAYOUT_CLASSIC = 157; $IDM_LAYOUT_COLUMNS = 158
    $secureFind = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    # Search in encrypted messages set in Options with OK; whether it was found
    function SetSearchEncrypted([bool]$on) {
        Command $main $IDM_OPTIONS
        $o = WaitShown 'InboxClassicOptions' 10
        if (-not $o) { return $false }
        OptionsPage $o 1
        $box = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_SEARCH_ENCRYPTED)
        [void][Native.Win]::SendMessage($box, $BM_SETCHECK, [IntPtr]([int]$on), [IntPtr]::Zero)
        Click $o $IDC_OPTIONS_SEARCH_ENCRYPTED
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 5)
        $box -ne [IntPtr]::Zero
    }
    # the subjects the list shows for the words typed in the Find box
    function FoundSubjects([string]$words) {
        [void][Native.Win]::SendMessage($secureFind, $WM_SETTEXT, [IntPtr]::Zero, $words)
        Start-Sleep -Milliseconds 800
        Settled
        $count = Rows
        if ($count -eq 0) { return @() }
        @(0..($count - 1) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
    }
    # the security column of a row (LVM_GETSUBITEMRECT), and its dark pixels as the screen shows them: where its mark is
    $secureCell = { param($row) [Native.Win]::RemoteRect($list, 0x1038, [IntPtr]$row, ([long]$COL_SECURE -shl 32)) }
    $secureMark = {
        param($row)
        $picture = CellPicture $row $secureCell
        if (-not $picture) { return '' }
        $dark = @()
        for ($x = 0; $x -lt $picture.Width; $x++) {
            for ($y = 0; $y -lt $picture.Height; $y++) {
                $p = $picture.GetPixel($x, $y)
                if ($p.R -lt 120 -and $p.G -lt 120 -and $p.B -lt 120) { $dark += "$x,$y" }
            }
        }
        $dark -join ' '
    }

    # with Search in encrypted messages off: nothing is decrypted for the list or the search
    Check (SetSearchEncrypted $false) 'Options has Search in encrypted messages, turned off'
    $plainSubject = 'Plain words about lunch'
    AddMessage ("From: Kim Example <kim@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $plainSubject`r`n" +
        "Message-ID: <plain-beside-secure@example.com>`r`nDate: Sun, 01 Nov 2026 09:00:00 +0000`r`n`r`nNothing protected here.`r`n") @('\Seen')
    foreach ($file in 'secure-signed.eml', 'secure-encrypted.eml') {
        AddMessage ([IO.File]::ReadAllText((Join-Path $pgpFiles $file))) @('\Seen')
    }
    Command $main $IDM_SYNC
    SelectFolder 0
    $listed = WaitFor { if (@(SubjectRows $plainSubject).Count -eq 1 -and @(SubjectRows 'Signed by Alice').Count -eq 1 -and @(SubjectRows '...').Count -eq 1) { $true } } 30
    Check ([bool]$listed) 'a plain, a signed and an encrypted message are in the Inbox together, the encrypted one as "..."'
    $rowOfSubject = { param($subject) @(SubjectRows $subject)[0] }
    # the plain one selected, so the marks are drawn on the list's white
    Check (SelectSubject $plainSubject) "the reading pane shows the message selected ($($plainSubject))"
    $lockMark = & $secureMark (& $rowOfSubject '...')
    $sealMark = & $secureMark (& $rowOfSubject 'Signed by Alice')
    $plainMark = & $secureMark (& $rowOfSubject $plainSubject)
    Check ($lockMark -ne '') 'the encrypted message has a mark in the security column'
    Check ($sealMark -ne '' -and $sealMark -ne $lockMark) 'the signed one has another mark (the seal, not the lock)'
    Check ($plainMark -eq '') 'the plain one has none'
    $header = [Native.Win]::SendMessage($list, 0x101F, [IntPtr]::Zero, [IntPtr]::Zero)
    $headerWidth = { param($column) $r = [Native.Win]::RemoteRect($header, 0x1207, [IntPtr]$column, 0); $r.Right - $r.Left }
    Check ((& $headerWidth $COL_SECURE) -gt 0 -and (& $headerWidth $COL_SECURE) -eq (& $headerWidth 0)) "the column is as narrow as the paper clip's ($(& $headerWidth $COL_SECURE))"
    # the header's tooltip over the lock's header, and still there once a column before it is made wider (the
    # header's own change notice moves it, mailbox.cpp PlaceHeaderTips)
    $tipOverHeader = {
        $h = [Native.Win]::RemoteRect($header, 0x1207, [IntPtr]$COL_SECURE, 0)
        $t = [Native.Win]::RemoteToolRect($header, [long]$COL_SECURE)
        @((($t.Right -gt $t.Left) -and $t.Left -eq $h.Left -and $t.Right -eq $h.Right), "tip $($t.Left)..$($t.Right), header $($h.Left)..$($h.Right)")
    }
    $over = & $tipOverHeader
    Check $over[0] "the lock column header has its tooltip over it ($($over[1]))"
    $flagWidth = & $headerWidth $COL_FLAG
    [void][Native.Win]::SendMessage($list, 0x101E, [IntPtr]$COL_FLAG, [IntPtr]($flagWidth + 20))
    Start-Sleep -Milliseconds 300
    $over = & $tipOverHeader
    Check $over[0] "the tooltip follows the lock column header when a column before it is resized ($($over[1]))"
    [void][Native.Win]::SendMessage($list, 0x101E, [IntPtr]$COL_FLAG, [IntPtr]$flagWidth)
    Shot $main 'main-12-lock-in-list'
    # selected, the lock stays on the highlight
    SelectRow (& $rowOfSubject '...')
    Check ((& $secureMark (& $rowOfSubject '...')) -ne '') 'the lock is drawn on a selected row too'
    Shot $main 'main-12b-lock-selected'
    # the column layout: the marks among the second line's, "Encrypted message" for its first words; a screen reader
    # hears Encrypted or Signed (the first column's text in that layout)
    Command $main $IDM_LAYOUT_COLUMNS
    Start-Sleep -Seconds 1
    $spoken = { param($subject) $r = @(0..([Math]::Max(0, (Rows) - 1)) | Where-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) -eq $subject })[0]; if ($null -ne $r) { [Native.Win]::RemoteListText($list, $r, 0) } }
    $encryptedSpoken = & $spoken '...'
    $signedSpoken = & $spoken 'Signed by Alice'
    Check ($encryptedSpoken -match ', Encrypted, ' -and $encryptedSpoken -match 'Encrypted message$') "the encrypted row says Encrypted, and Encrypted message for its first words ($encryptedSpoken)"
    Check ($signedSpoken -match ', Signed, ') "the signed row says Signed ($signedSpoken)"
    Check ((& $spoken $plainSubject) -notmatch ', (Encrypted|Signed),') "the plain one says neither ($(& $spoken $plainSubject))"
    Shot $main 'main-12c-lock-in-columns'
    Command $main $IDM_LAYOUT_CLASSIC
    Start-Sleep -Seconds 1

    # the search: is:encrypted, is:signed; with the switch off a word of its text finds nothing, its sender finds it
    $found = @(FoundSubjects 'in:inbox is:encrypted')
    Check ($found.Count -eq 1 -and $found[0] -eq '...') "is:encrypted lists the encrypted message alone ($($found -join ', '))"
    $found = @(FoundSubjects 'in:inbox is:signed')
    Check ($found.Count -eq 1 -and $found[0] -eq 'Signed by Alice') "is:signed lists the signed one alone ($($found -join ', '))"
    $found = @(FoundSubjects 'in:inbox -is:encrypted')
    Check ($found -notcontains '...' -and $found -contains 'Signed by Alice' -and $found -contains $plainSubject) "-is:encrypted lists all but the encrypted one ($($found.Count))"
    $found = @(FoundSubjects 'alice')
    Check ($found -contains '...') "its sender finds it ($($found -join ', '))"
    # opened while the switch is off: shown, but its words stay out of the index
    $at = [array]::IndexOf($found, '...')
    if ($at -ge 0) { SelectRow $at }
    Check ([bool](WaitFor { (WindowText $securityBar) -match '^Encrypted\.' } 20)) "opened, it is decrypted for the reading pane ($(WindowText $securityBar))"
    $found = @(FoundSubjects 'mill')
    Check ($found.Count -eq 0) "with the switch off, a word of its text finds nothing, opened or not ($($found -join ', '))"
    [void](FoundSubjects '')
    # on again: the background pass decrypts what is downloaded, without it being opened again
    Check (SelectSubject $plainSubject) "the reading pane shows the message selected ($($plainSubject))"
    Check (SetSearchEncrypted $true) 'Search in encrypted messages turned on again'
    $found = WaitFor { $f = @(FoundSubjects 'mill'); if ($f.Count -ge 1) { , $f } } 30
    Check ($null -ne $found) "turned on, the background pass decrypts it: a word of its text finds it ($($found -join ', '))"
    Shot $main 'search-9-encrypted'
    [void](FoundSubjects '')

    # an encrypted message with a protected Subject: listed by it once decrypted, the row changing in place while it
    # is selected
    AddMessage ([IO.File]::ReadAllText((Join-Path $pgpFiles 'secure-protected-subject.eml'))) @('\Seen')
    Command $main $IDM_SYNC
    [void](WaitFor { @(SubjectRows '...').Count -ge 2 } 30)
    # it and the encrypted message without one are both "..." until it is opened: each opened in turn
    $selectedRow = { [int][Native.Win]::SendMessage($list, 0x100C, [IntPtr](-1), [IntPtr]2) }
    $renamed = $null
    foreach ($row in @(SubjectRows '...')) {
        SelectRow $row
        $renamed = WaitFor { $r = & $selectedRow; if ($r -ge 0 -and [Native.Win]::RemoteListText($list, $r, $COL_SUBJECT) -eq 'The mill on Friday') { $r } } 10
        if ($null -ne $renamed) { break }
    }
    Check ($null -ne $renamed) "the message with a protected Subject is listed as The mill on Friday, not ..., and stays selected ($(@(0..((Rows) - 1) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) }) -join ', '))"
    Shot $main 'main-12d-protected-subject'

    # taken away again
    foreach ($id in '<plain-beside-secure@example.com>', '<signed@ui-test.example>', '<encrypted@ui-test.example>', '<protected-subject@ui-test.example>') {
        $added = Find 'INBOX' ([regex]::Escape($id))
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { @(SubjectRows $plainSubject).Count -eq 0 -and @(SubjectRows 'Signed by Alice').Count -eq 0 -and @(SubjectRows 'The mill on Friday').Count -eq 0 } 20)

    # ---- signing and encrypting what is written (SCENARIO 19j) ----

    Step 'signing and encrypting what is written'
    # the commands (core/commands.toml) and the controls of app.h's ComposeKeysControlId
    $IDM_COMPOSE_SIGN = 175; $IDM_COMPOSE_ENCRYPT = 176; $IDM_ATTACH_MY_KEY = 177
    $IDC_COMPOSE_SECURITY = 350; $IDC_COMPOSE_KEYS = 353
    $IDC_RKEYS_INTRO = 360; $IDC_RKEYS_LIST = 361; $IDC_RKEYS_FIND = 362; $IDC_RKEYS_REMOVE = 363; $IDC_RKEYS_SEND_UNENCRYPTED = 368
    # what the harness checks a sent message with: me.asc, whose private part it has, made the account's key (the one
    # New Key made in the keys' step was until now), and Alice's key, to see that it was encrypted to her
    # (read as plain strings: Get-Content's carry properties that ConvertTo-Json would send along)
    $ownKey = [IO.File]::ReadAllText((Join-Path $pgpFiles 'me.asc'))
    $ownPassphrase = [IO.File]::ReadAllText((Join-Path $pgpFiles 'me.passphrase')).Trim()
    # me.asc's key id: of the two "Alex Morgan" keys, the one imported from a file (its Properties say so), the last four
    # groups of its fingerprint, as Account Properties names the keys
    $fixtureId = $null
    $keys = OpenKeys
    if ($keys) {
        $keyList = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        for ($i = 0; $i -lt (ListCount $keyList) -and -not $fixtureId; $i++) {
            if ([Native.Win]::RemoteListText($keyList, $i, 0) -ne 'Alex Morgan') { continue }
            Key $keyList $VK_HOME
            for ($j = 0; $j -lt $i; $j++) { Key $keyList $VK_DOWN }
            Start-Sleep -Milliseconds 300
            Click $keys $IDC_KEYS_PROPERTIES
            $properties = WaitShown 'InboxClassicKeyProperties'
            if ($properties) {
                if ((GetText $properties $IDC_KEY_SOURCE) -match 'file') {
                    $fixtureId = ((GetText $properties $IDC_KEY_FINGERPRINT) -split ' ' | Select-Object -Last 4) -join ' '
                }
                Click $properties 2
                [void](WaitFor { -not [Native.Win]::IsWindow($properties) } 5)
            }
        }
        CloseKeys $keys
    }
    $used = $false
    Command $main $IDM_ACCOUNTS
    $accountsList = WaitWindow 'InboxClassicAccounts' 'Accounts'
    if ($accountsList -and $fixtureId) {
        Click $accountsList 402
        $form = WaitFor { $f = PropertiesForm; if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, $IDC_ACCOUNT_KEY) -ne [IntPtr]::Zero) { $f } }
        if ($form) {
            $keyChoice = [Native.Win]::GetDlgItem($form, $IDC_ACCOUNT_KEY)
            for ($i = 0; $i -lt [int][Native.Win]::SendMessage($keyChoice, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); $i++) {
                $label = New-Object System.Text.StringBuilder 256
                [void][Native.Win]::SendMessage($keyChoice, $CB_GETLBTEXT, [IntPtr]$i, $label)
                if ($label.ToString().EndsWith("($fixtureId)")) {
                    [void][Native.Win]::SendMessage($keyChoice, $CB_SETCURSEL, [IntPtr]$i, [IntPtr]::Zero)
                    $used = $true
                }
            }
            Click $form 1
            [void](WaitFor { -not [Native.Win]::IsWindow($form) } 10)
        }
    }
    if ($accountsList) {
        [void][Native.Win]::PostMessage($accountsList, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($accountsList) } 10)
    }
    Check $used "the key of me.asc is made the account's in Account Properties ($fixtureId)"
    $aliceKey = [IO.File]::ReadAllText((Join-Path $pgpFiles 'alice.asc'))
    function PgpCheck($message) {
        $body = @{ raw = $message.raw; key = $ownKey; passphrase = $ownPassphrase; recipients = @($aliceKey) } | ConvertTo-Json
        # a message it can not read is a failed check, not the end of the run
        try { Invoke-RestMethod -Method Post -ContentType 'application/json' "http://127.0.0.1:$($ports.pgp)/pgp/check" -Body $body }
        catch { [pscustomobject]@{ kind = 'unreadable'; error = "$_ $($_.ErrorDetails.Message)" } }
    }
    # the newest message of the Inbox after `before` (its highest uid then): an encrypted one's subject is "..."
    function NewestUid { $u = @(Messages 'INBOX' | ForEach-Object { [int]$_.uid }); if ($u.Count) { ($u | Measure-Object -Maximum).Maximum } else { 0 } }
    function SentSince([int]$before) { WaitFor { Messages 'INBOX' | Where-Object { [int]$_.uid -gt $before } | Select-Object -First 1 } 30 }
    function TakeAway($message) { if ($message) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($message.uid)") } }
    # the compose window's toolbar (the one with Sign), a button pressed or enabled, and an item of its menus
    function ComposeBar([IntPtr]$c) {
        foreach ($b in [Native.Win]::FindDescendants($c, 'ToolbarWindow32')) {
            if ([int][Native.Win]::SendMessage($b, 0x0419, [IntPtr]$IDM_COMPOSE_SIGN, [IntPtr]::Zero) -ge 0) { return $b }
        }
        [IntPtr]::Zero
    }
    function BarPressed([IntPtr]$c, [int]$id) { [int][Native.Win]::SendMessage((ComposeBar $c), 0x040A, [IntPtr]$id, [IntPtr]::Zero) -ne 0 }
    function MenuChecked([IntPtr]$c, [int]$id) { $s = [Native.Win]::GetMenuState([Native.Win]::GetMenu($c), $id, 0); $s -ne [uint32]::MaxValue -and ($s -band 0x8) -ne 0 }
    function MenuGreyed([IntPtr]$c, [int]$id) { $s = [Native.Win]::GetMenuState([Native.Win]::GetMenu($c), $id, 0); $s -ne [uint32]::MaxValue -and ($s -band 0x3) -ne 0 }
    # the line under the fields and the Keys row, as their words say them ('' while hidden)
    function SecurityLine([IntPtr]$c) { if (Visible $c $IDC_COMPOSE_SECURITY) { GetText $c $IDC_COMPOSE_SECURITY } else { '' } }
    function KeysRow([IntPtr]$c) { if (Visible $c $IDC_COMPOSE_KEYS) { GetText $c $IDC_COMPOSE_KEYS } else { '' } }
    # the line's fill inside its frame, as the screen shows it
    function LineFill([IntPtr]$c) {
        [void][Native.Win]::SetWindowPos($c, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($c)
        Start-Sleep -Milliseconds 400
        $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($c, $IDC_COMPOSE_SECURITY), [ref]$box)
        $picture = New-Object System.Drawing.Bitmap 1, 1
        CopyScreen $picture ($box.Left + 3) ($box.Top + 3)
        [void][Native.Win]::SetWindowPos($c, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        $p = $picture.GetPixel(0, 0)
        '{0:x2}{1:x2}{2:x2}' -f $p.R, $p.G, $p.B
    }
    # a new message to `to` with `subject` and `text` written
    function NewMessageTo([string]$to, [string]$subject, [string]$text) {
        $c = WaitCompose { Command $main $IDM_NEW_MAIL }
        if (-not $c) { return $null }
        SetText $c $IDC_TO $to
        SetText $c $IDC_SUBJECT $subject
        [void](TypeInEditor $c $text)
        $c
    }

    # a new message: both off, no line; Sign (Ctrl+Shift+D in the text) pressed and checked, the blue line
    $compose = NewMessageTo 'Alice Example <alice@example.org>' 'Signed in the UI test' 'A signed hello.'
    if ($compose) {
        Check (-not (BarPressed $compose $IDM_COMPOSE_SIGN) -and -not (BarPressed $compose $IDM_COMPOSE_ENCRYPT) -and
            -not (MenuChecked $compose $IDM_COMPOSE_SIGN) -and -not (MenuChecked $compose $IDM_COMPOSE_ENCRYPT)) 'a new message starts with Sign and Encrypt off'
        Check ((SecurityLine $compose) -eq '' -and (KeysRow $compose) -eq '') 'with no line under the fields and no Keys row'
        [void][Native.Win]::SetForegroundWindow($compose)
        [void](ClickEditor $compose)
        [System.Windows.Forms.SendKeys]::SendWait('^+d')
        Check ([bool](WaitFor { (BarPressed $compose $IDM_COMPOSE_SIGN) -and (MenuChecked $compose $IDM_COMPOSE_SIGN) } 10)) 'Ctrl+Shift+D in the text presses Sign and checks Tools > Digitally Sign'
        $line = WaitFor { $t = SecurityLine $compose; if ($t) { $t } } 10
        Check ($line -eq 'Will be signed: recipients can check that the signed content has not changed. They must also verify who owns your key.') "the line says it is signed ($line)"
        Check ((LineFill $compose) -eq $fills.good) "in blue ($(LineFill $compose))"
        Shot $compose 'write-30-sign'
        $before = NewestUid
        Command $compose $IDC_SEND
        $sent = SentSince $before
        $said = if ($sent) { PgpCheck $sent }
        Check ($said -and $said.kind -eq 'signed' -and $said.valid -and $said.text -match 'A signed hello') "OpenPGP.js finds it signed, the signature good ($(if ($said) { "$($said.kind) $($said.valid) $($said.error)" }))"
        TakeAway $sent
    }

    # Encrypt: Sign on and greyed, Alice's green lock, the green line; sent encrypted to her
    $compose = NewMessageTo 'Alice Example <alice@example.org>' 'Encrypted in the UI test' 'The meeting moves to Thursday.'
    if ($compose) {
        Command $compose $IDM_COMPOSE_ENCRYPT
        Check ([bool](WaitFor { (BarPressed $compose $IDM_COMPOSE_ENCRYPT) -and (MenuChecked $compose $IDM_COMPOSE_ENCRYPT) } 10)) 'Encrypt is pressed and checked'
        Check ((BarPressed $compose $IDM_COMPOSE_SIGN) -and (MenuChecked $compose $IDM_COMPOSE_SIGN) -and (MenuGreyed $compose $IDM_COMPOSE_SIGN)) 'Sign shows on: pressed in the toolbar, checked and greyed in Tools'
        Command $compose $IDM_COMPOSE_SIGN
        Start-Sleep -Milliseconds 500
        Check ((BarPressed $compose $IDM_COMPOSE_SIGN)) 'a click on Sign leaves it on while Encrypt is'
        $row = WaitFor { $t = KeysRow $compose; if ($t -match 'Alice Example, Key verified') { $t } } 10
        Check ($null -ne $row) "the Keys row shows Alice with her key verified ($(KeysRow $compose))"
        $line = WaitFor { $t = SecurityLine $compose; if ($t -match '^Will be encrypted') { $t } } 10
        Check ($line -eq 'Will be encrypted and signed for you and Alice Example.') "the line says who can read it ($line)"
        Check ((LineFill $compose) -eq $fills.verified) "in green ($(LineFill $compose))"
        Shot $compose 'write-31-encrypt'
        $before = NewestUid
        Command $compose $IDC_SEND
        $sent = SentSince $before
        $said = if ($sent) { PgpCheck $sent }
        Check ($said -and $said.kind -eq 'encrypted' -and $said.signed -and $said.valid -and @($said.to) -contains $true -and $said.text -match 'Thursday') "OpenPGP.js decrypts it, signed, to Alice's key ($(if ($said) { "$($said.kind) $($said.signed) $($said.valid) $($said.to) $($said.error)" }))"
        Check ($sent -and (RawText $sent) -notmatch 'Thursday') 'the server holds none of its words'
        TakeAway $sent
    }

    # Alice and Dave, whose key is nowhere: his lock amber, Send opens Recipients' Keys; Remove from Message, then Send
    $compose = NewMessageTo 'Alice Example <alice@example.org>, Dave <dave@example.com>' 'Two recipients in the UI test' 'For both of you.'
    if ($compose) {
        Command $compose $IDM_COMPOSE_ENCRYPT
        $row = WaitFor { $t = KeysRow $compose; if ($t -match 'Dave, No key: none was found on') { $t } } 20
        Check ($null -ne $row) "Dave's lock says no key was found ($(KeysRow $compose))"
        $line = SecurityLine $compose
        Check ($line -match '^No usable key is available for (Dave|dave@example\.com)') "the line names him ($line)"
        Check ((LineFill $compose) -eq $fills.warning) "in amber ($(LineFill $compose))"
        $status = [Native.Win]::FindWindowEx($compose, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        Write-Host "   the status bar after the lookup: $(StatusPart $status 0)"
        Command $compose $IDC_SEND
        $keysWindow = WaitShown 'InboxClassicRecipientKeys' 10
        Check ($null -ne $keysWindow) "Send opens Recipients' Keys instead of sending"
        if ($keysWindow) {
            $keyList = [Native.Win]::GetDlgItem($keysWindow, $IDC_RKEYS_LIST)
            $intro = GetText $keysWindow $IDC_RKEYS_INTRO
            Check ($intro -match (Pattern $en['pgp-recipients-intro-missing[one]'])) "it says why ($intro)"
            $rows = @(0..([Math]::Max(0, (ListCount $keyList) - 1)) | ForEach-Object { "$([Native.Win]::RemoteListText($keyList, $_, 0)) | $([Native.Win]::RemoteListText($keyList, $_, 1))" })
            Check ((ListCount $keyList) -eq 2 -and $rows[0] -eq 'Alice Example <alice@example.org> | Key verified' -and $rows[1] -match '^Dave <dave@example.com> \| No key: none was found on') "Alice and Dave with their keys ($($rows -join '; '))"
            Check (-not (Enabled $keysWindow $IDC_RKEYS_FIND) -and (Enabled $keysWindow $IDC_RKEYS_REMOVE)) "Dave is selected: Find Key greyed (asked a moment ago), Remove from Message"
            Check (-not (Enabled $keysWindow 1) -and (Enabled $keysWindow $IDC_RKEYS_SEND_UNENCRYPTED)) 'Send waits for his key, Send Without Encryption can be used'
            Check (([Native.Win]::GetWindowLong([Native.Win]::GetDlgItem($keysWindow, 2), -16) -band 0xF) -eq 1) 'Cancel is the default'
            Shot $compose 'write-32-missing-key' $keysWindow
            Click $keysWindow $IDC_RKEYS_REMOVE
            Check ([bool](WaitFor { (ListCount $keyList) -eq 1 -and (Enabled $keysWindow 1) } 10)) 'Remove from Message leaves Alice, and Send can be used'
            Check ((GetText $compose $IDC_TO) -notmatch 'dave') "Dave is out of To ($(GetText $compose $IDC_TO))"
            Check (([Native.Win]::GetWindowLong([Native.Win]::GetDlgItem($keysWindow, 1), -16) -band 0xF) -eq 1) 'Send is the default now'
            $before = NewestUid
            Click $keysWindow 1
            $sent = SentSince $before
            $said = if ($sent) { PgpCheck $sent }
            Check ($said -and $said.kind -eq 'encrypted' -and @($said.to) -contains $true -and (RawText $sent) -notmatch 'dave@example\.com') "Send sends it encrypted to Alice alone ($(if ($said) { "$($said.kind) $($said.to)" }))"
            TakeAway $sent
        }
    }

    # a reply to encrypted mail starts encrypted; Encrypt off asks first, Keep It Encrypted the default
    AddMessage ([IO.File]::ReadAllText((Join-Path $pgpFiles 'secure-encrypted.eml'))) @('\Seen')
    Command $main $IDM_SYNC
    $words = SelectSecure 'Encrypted'
    $reply = WaitCompose { Command $main $IDM_REPLY }
    Check ($null -ne $reply) "Reply opens a compose window ($words)"
    if ($reply) {
        Check ([bool](WaitFor { (BarPressed $reply $IDM_COMPOSE_ENCRYPT) -and (BarPressed $reply $IDM_COMPOSE_SIGN) } 10)) 'the reply to encrypted mail starts with Encrypt and Sign on'
        Check ([bool](WaitFor { (KeysRow $reply) -match 'Alice Example, Key verified' } 10)) "Alice's lock green ($(KeysRow $reply))"
        Command $reply $IDM_COMPOSE_ENCRYPT
        $ask = WaitShown 'InboxClassicAsk' 10
        Check ($null -ne $ask) 'Encrypt off asks first'
        if ($ask) {
            Check ((Statics $ask) -match 'contains text, pictures or attachments from encrypted mail') "naming the encrypted quote ($(Statics $ask))"
            Check ((GetText $ask 1) -eq '&Turn Encryption Off' -and (GetText $ask 2) -eq '&Keep It Encrypted') "with Turn Encryption Off and Keep It Encrypted ($(GetText $ask 1) / $(GetText $ask 2))"
            Check (([Native.Win]::GetWindowLong([Native.Win]::GetDlgItem($ask, 2), -16) -band 0xF) -eq 1) 'Keep It Encrypted is the default'
            Shot $reply 'write-33-reply-encrypted' $ask
            Click $ask 2
            [void](WaitFor { -not [Native.Win]::IsWindow($ask) } 5)
        }
        Check ((BarPressed $reply $IDM_COMPOSE_ENCRYPT)) 'Keep It Encrypted leaves it on'

        # Turn Encryption Off: the amber line, Send refused while the quote is there; without it, it goes signed
        Command $reply $IDM_COMPOSE_ENCRYPT
        $ask = WaitShown 'InboxClassicAsk' 10
        if ($ask) {
            Click $ask 1
            [void](WaitFor { -not [Native.Win]::IsWindow($ask) } 5)
        }
        Check ([bool](WaitFor { -not (BarPressed $reply $IDM_COMPOSE_ENCRYPT) } 10)) 'Turn Encryption Off turns it off'
        $line = WaitFor { $t = SecurityLine $reply; if ($t -match 'only be sent encrypted') { $t } } 10
        Check ($null -ne $line) "the line says it can only be sent encrypted ($(SecurityLine $reply))"
        Check ((LineFill $reply) -eq $fills.warning) "in amber ($(LineFill $reply))"
        Shot $reply 'write-34-quote-in-clear'
        Command $reply $IDC_SEND
        $refused = BoxOf $reply 10
        Check ($refused -and (Statics $refused) -match 'only be sent encrypted') "Send is refused with the same words ($(if ($refused) { Statics $refused }))"
        if ($refused) { Click $refused 2; [void](WaitFor { -not [Native.Win]::IsWindow($refused) } 5) }
        Check ([Native.Win]::IsWindow($reply)) 'the message stays open'
        # the quote unfolded and taken away with the rest (Select All unfolds it), then a line of one's own
        [void][Native.Win]::SetForegroundWindow($reply)
        [void](ClickEditor $reply)
        [System.Windows.Forms.SendKeys]::SendWait('^a')
        Start-Sleep -Milliseconds 500
        [System.Windows.Forms.SendKeys]::SendWait('{DEL}')
        [void](TypeInEditor $reply 'Nothing secret in this answer.')
        $line = WaitFor { $t = SecurityLine $reply; if ($t -match (Pattern $en['pgp-compose-reply-clear'])) { $t } } 10
        Check ($line -eq 'Not encrypted, although the message it answers or forwards was.') "without the quote, the line says it is not encrypted ($(SecurityLine $reply))"
        $before = NewestUid
        Command $reply $IDC_SEND
        $sent = SentSince $before
        $said = if ($sent) { PgpCheck $sent }
        Check ($said -and $said.kind -eq 'signed' -and $said.valid -and $said.text -notmatch 'old mill') "it goes signed, Sign having stayed on, without the quote ($(if ($said) { "$($said.kind) $($said.valid)" }))"
        TakeAway $sent
    }
    RemoveSecure 'secure-encrypted.eml' 'Encrypted'

    # Insert > Attach My Public Key: the key in the Attach row, sent as application/pgp-keys
    $compose = NewMessageTo 'Alice Example <alice@example.org>' 'My key in the UI test' 'Here is my key.'
    if ($compose) {
        Check (-not (MenuGreyed $compose $IDM_ATTACH_MY_KEY)) 'Insert > Attach My Public Key can be used'
        Command $compose $IDM_ATTACH_MY_KEY
        $files = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
        $file = WaitFor { if ((ListBoxCount $files) -eq 1) { ListBoxText $files 0 } } 10
        Check ($file -match '^Alex Morgan public key\.asc \(') "the Attach row lists the key ($file)"
        Shot $compose 'write-35-attach-key'
        $before = NewestUid
        Command $compose $IDC_SEND
        $sent = SentSince $before
        $said = if ($sent) { PgpCheck $sent }
        $keyFile = if ($said) { @($said.attachments) | Where-Object { $_.type -eq 'application/pgp-keys' } | Select-Object -First 1 }
        Check ($keyFile -and $keyFile.name -eq 'Alex Morgan public key.asc') "it is sent as application/pgp-keys ($(if ($said) { ($said.attachments | ForEach-Object { "$($_.type) $($_.name)" }) -join ', ' }))"
        TakeAway $sent
    }

    # ---- finding, publishing and passing on keys (SCENARIO 19k) ----

    Step 'finding, publishing and passing on keys'
    # app.h: Publish and Import from Clipboard of Encryption Keys, Find Key of Contact Properties and its words
    $IDC_KEYS_PUBLISH = 879; $IDC_KEYS_PASTE = 920; $IDC_CONTACT_FIND_KEY = 745; $IDC_CONTACT_KEY_SAID = 746
    $IDC_CONTACT_KEY_VERIFY = 786; $IDC_CONTACT_KEY_PENDING = 787; $IDC_CONTACT_KEY_USE_NEW = 788; $IDC_CONTACT_KEY_KEEP = 789
    $pgpBase = "http://127.0.0.1:$($ports.pgp)"
    # a key file of scripts/ui-e2e/pgp put on the harness's key server (by its address too, and in its Web Key
    # Directory, when asked): the harness's answer, with the key's fingerprint
    function ServeKey([string]$file, [string]$address = $null, [bool]$wkd = $false) {
        $body = @{ key = [IO.File]::ReadAllText((Join-Path $pgpFiles $file)) }
        if ($address) { $body.address = $address }
        if ($wkd) { $body.wkd = $true }
        Invoke-RestMethod -Method Post -ContentType 'application/json' "$pgpBase/pgp/keys" -Body ($body | ConvertTo-Json)
    }
    # the pane's look at Find Key: the middle of it on the screen, 0 when the page has none, -1 before it answered
    function FindKeyLook { $v = WaitFor { $a = [Native.Win]::SendText($main, $kTestPreviews, 'findkey'); if ($a -ge 0) { "$a" } } 5; if ($v) { [int64]$v } else { -1 } }
    # the key lookups the harness was asked, in order, and those after the first $from
    function Lookups { $r = Invoke-RestMethod "$pgpBase/pgp/lookups"; @($r | ForEach-Object { $_ }) }
    function LookupsSince([int]$from) { @(Lookups | Select-Object -Skip $from) }
    function LookupText($l) { @($l | ForEach-Object { "$($_.kind) $($_.value) $($_.found)" }) -join '; ' }
    # a key's row of Encryption Keys by its name, as its columns say it; '' when it is not listed
    function KeyRowNamed([IntPtr]$keys, [string]$name) {
        $l = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        for ($i = 0; $i -lt (ListCount $l); $i++) { if ([Native.Win]::RemoteListText($l, $i, 0) -eq $name) { return KeyRow $keys $i } }
        ''
    }
    # the Properties of the key named $name: where it came from; closed after
    function KeySource([IntPtr]$keys, [string]$name) {
        if ((SelectKey $keys $name) -lt 0) { return '(not listed)' }
        Click $keys $IDC_KEYS_PROPERTIES
        $p = WaitShown 'InboxClassicKeyProperties'
        if (-not $p) { return '(no Properties)' }
        $source = GetText $p $IDC_KEY_SOURCE
        Click $p 2
        [void](WaitFor { -not [Native.Win]::IsWindow($p) } 5)
        $source
    }
    # Encryption Keys opened, $name's row and source read, closed again
    function KeyListed([string]$name) {
        $k = OpenKeys
        if (-not $k) { return [pscustomobject]@{ Row = '(no window)'; Source = '' } }
        $found = [pscustomobject]@{ Row = (KeyRowNamed $k $name); Source = (KeySource $k $name) }
        CloseKeys $k
        $found
    }
    # a message of scripts/ui-e2e/pgp put in the Inbox and shown in the reading pane; whether it is
    function ShowPlain([string]$file, [string]$subject) {
        AddMessage ([IO.File]::ReadAllText((Join-Path $pgpFiles $file))) @('\Seen')
        Command $main $IDM_SYNC
        SelectFolder 0
        SelectSubject $subject
    }
    # the labels of the strip's menu of item $item of the main window's strip (closed again, or $choose chosen by its
    # label), '|' between them
    $keyStrip = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 243), 242)
    function KeyStripMenu([int]$item, [string]$choose = $null) {
        [void](WaitFor { (ListCount $keyStrip) -gt $item } 10)
        Key $keyStrip 0x24
        for ($i = 0; $i -lt $item; $i++) { Key $keyStrip $VK_DOWN }
        Start-Sleep -Milliseconds 300
        [void][Native.Win]::PostMessage($keyStrip, 0x007B, $keyStrip, [IntPtr](-1))
        $menu = WaitWindow '#32768' $null 10
        if (-not $menu) { return '(no menu)' }
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)))
        $at = if ($choose) { [array]::IndexOf($labels, $choose) } else { -1 }
        if ($at -ge 0) {
            Key $menu $VK_HOME
            for ($i = 0; $i -lt @($labels[0..$at] | Where-Object { $_ }).Count - 1; $i++) { Key $menu $VK_DOWN }
            Key $menu $VK_RETURN
        } else {
            Key $menu $VK_ESCAPE
        }
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
        $labels -join '|'
    }
    # the Address Book's cards: one added with a name and an address, a card's row by its name, its Properties
    function OpenBook { Command $main $IDM_ADDRESS_BOOK; WaitShown 'InboxClassicAddressBook' 10 }
    function CloseBook([IntPtr]$b) {
        [void][Native.Win]::PostMessage($b, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($b) } 10)
    }
    function BookRow([IntPtr]$b, [string]$name) {
        $l = [Native.Win]::GetDlgItem($b, $IDC_BOOK_LIST)
        for ($i = 0; $i -lt (ListCount $l); $i++) { if ([Native.Win]::RemoteListText($l, $i, 0) -eq $name) { return $i } }
        -1
    }
    function AddCard([IntPtr]$b, [string]$first, [string]$last, [string]$address) {
        if ((BookRow $b "$first $last") -ge 0) { return }
        Click $b $IDC_BOOK_NEW_CONTACT
        $c = WaitShown 'InboxClassicContact' 10
        if (-not $c) { return }
        SetText $c $IDC_CONTACT_FIRST $first
        SetText $c $IDC_CONTACT_LAST $last
        SetText $c $IDC_CONTACT_ADDRESS $address
        Click $c $IDC_CONTACT_ADD
        [void](WaitFor { (ListBoxCount ([Native.Win]::GetDlgItem($c, $IDC_CONTACT_ADDRESSES))) -eq 1 } 5)
        Click $c 1
        [void](WaitFor { -not [Native.Win]::IsWindow($c) } 10)
        [void](WaitFor { (BookRow $b "$first $last") -ge 0 } 10)
    }
    function CardProperties([IntPtr]$b, [string]$name) {
        $row = BookRow $b $name
        if ($row -lt 0) { return $null }
        $l = [Native.Win]::GetDlgItem($b, $IDC_BOOK_LIST)
        Key $l $VK_HOME
        for ($i = 0; $i -lt $row; $i++) { Key $l $VK_DOWN }
        Start-Sleep -Milliseconds 300
        Click $b $IDC_BOOK_PROPERTIES
        WaitShown 'InboxClassicContact' 10
    }
    function CloseContact([IntPtr]$c) {
        Click $c 2
        [void](WaitFor { -not [Native.Win]::IsWindow($c) } 5)
    }
    # me.asc's fingerprint without spaces, as Properties of the "Alex Morgan" key imported from a file says it; that key
    # selected
    function SelectFixtureKey([IntPtr]$keys) {
        $l = [Native.Win]::GetDlgItem($keys, $IDC_KEYS_LIST)
        for ($i = 0; $i -lt (ListCount $l); $i++) {
            if ([Native.Win]::RemoteListText($l, $i, 0) -ne 'Alex Morgan') { continue }
            Key $l $VK_HOME
            for ($j = 0; $j -lt $i; $j++) { Key $l $VK_DOWN }
            Start-Sleep -Milliseconds 300
            Click $keys $IDC_KEYS_PROPERTIES
            $p = WaitShown 'InboxClassicKeyProperties'
            if (-not $p) { continue }
            $fromFile = (GetText $p $IDC_KEY_SOURCE) -match 'file'
            $fpr = (GetText $p $IDC_KEY_FINGERPRINT) -replace ' ', ''
            Click $p 2
            [void](WaitFor { -not [Native.Win]::IsWindow($p) } 5)
            if ($fromFile) { return $fpr }
        }
        $null
    }

    # Publish: greyed for a contact's key; the account's key asks first, then keys.openpgp.org has it
    $keys = OpenKeys
    if ($keys) {
        Check ((SelectKey $keys 'Alice Example') -ge 0 -and -not (Enabled $keys $IDC_KEYS_PUBLISH)) "Publish is greyed for Alice's key, a contact's ($(GetText $keys $IDC_KEYS_PUBLISH))"
        $fixtureFpr = SelectFixtureKey $keys
        Check ($null -ne $fixtureFpr -and (Enabled $keys $IDC_KEYS_PUBLISH)) "and can be used for the account's key ($fixtureFpr)"
        Check ((GetText $keys $IDC_KEYS_PUBLISH) -eq 'P&ublish...') "its label has its access key ($(GetText $keys $IDC_KEYS_PUBLISH))"
        Click $keys $IDC_KEYS_PUBLISH
        $ask = WaitWindow '#32770' 'Publish' 10
        $question = if ($ask) { WaitFor { $t = Statics $ask; if ($t -match 'keys\.openpgp\.org') { $t } } 5 }
        Check ($question -match [regex]::Escape('Publish your public key on keys.openpgp.org so others can find it? Addresses on the key: testuser@inboxclassic.test. Each address must be confirmed through a link sent there before it is listed.')) "it asks first, naming the address ($question)"
        Check ($ask -and (GetText $ask 6) -match 'Yes' -and (GetText $ask 7) -match 'No') "with Yes and No ($(if ($ask) { "$(GetText $ask 6) / $(GetText $ask 7)" }))"
        if ($ask) {
            Shot $keys 'keys-12-publish' $ask
            Click $ask 6
            [void](WaitFor { -not [Native.Win]::IsWindow($ask) } 5)
        }
        $said = (Told 'Publish' 'confirmation link').Trim()
        Check ($said -match [regex]::Escape('keys.openpgp.org sent a confirmation link to these addresses: testuser@inboxclassic.test. Confirm each address so your key can be found using that address.')) "Yes publishes it and says what the server did ($said)"
        $uploads = @((Invoke-RestMethod "$pgpBase/pgp/uploads") | ForEach-Object { $_ })
        $upload = $uploads | Select-Object -First 1
        Check ($uploads.Count -eq 1 -and $upload.fingerprint -eq $fixtureFpr -and (@($upload.addresses) -join ',') -eq 'testuser@inboxclassic.test' -and (@($upload.asked) -join ',') -eq 'testuser@inboxclassic.test') "the server got me.asc's key and was asked to confirm its address ($(($uploads | ConvertTo-Json -Compress)))"

        # Import from Clipboard: plain text is no key; Judy's key is imported as Pasted
        Set-Clipboard -Value 'not a key'
        Check ((GetText $keys $IDC_KEYS_PASTE) -eq 'Import from C&lipboard') "Import from Clipboard is there ($(GetText $keys $IDC_KEYS_PASTE))"
        Click $keys $IDC_KEYS_PASTE
        $said = (Told 'Import Key' 'clipboard').Trim()
        Check ($said -eq 'The clipboard holds no OpenPGP key.') "plain text on the clipboard: it says there is no key ($said)"
        Check ((KeyRowNamed $keys 'Judy Example') -eq '') 'and imports nothing'
        $judyText = [IO.File]::ReadAllText((Join-Path $pgpFiles 'judy.asc'))
        Set-Clipboard -Value $judyText
        Check ([bool](WaitFor { (Get-Clipboard -Raw) -match 'BEGIN PGP PUBLIC KEY BLOCK' } 5)) "the test put Judy's key on the clipboard ($(((Get-Clipboard -Raw) + '').Length) characters)"
        Click $keys $IDC_KEYS_PASTE
        $said = (Told 'Import Key' 'imported').Trim()
        Check ($said -eq 'One key was imported.') "Judy's key on the clipboard is imported ($said)"
        $row = WaitFor { $r = KeyRowNamed $keys 'Judy Example'; if ($r) { $r } } 5
        Check ($row -eq 'Judy Example | judy@example.net | Contact | Valid') "and listed as a contact's, Valid ($row)"
        [void](SelectKey $keys 'Judy Example')
        Shot $keys 'keys-13-paste'
        $source = KeySource $keys 'Judy Example'
        Check ($source -eq 'Pasted') "her Properties say Pasted ($source)"
        Set-Clipboard -Value ' '
        CloseKeys $keys
    }

    # Find Key beside the label of a part signed by a key not known here: asked by its fingerprint alone
    $daveKey = ServeKey 'dave.asc'
    $words = ShowSecure 'secure-no-key.eml' 'A key you do not have'
    Check ($words -eq 'Signed, but the key is not known') "Dave's signature: the key is not known ($words)"
    $from = (Lookups).Count
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    [void](FindKeyLook)
    Start-Sleep -Milliseconds 300
    $p = WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, 'findkey'); if ($v -gt 0) { "$v" } } 5
    Check ($null -ne $p) 'the label has Find Key beside it'
    Shot $main 'keys-14a-find-key-offered'
    if ($p) {
        $p = [int64]$p
        [Native.Win]::MouseClick([int][Math]::Floor($p / 100000), [int]($p % 100000))
    }
    $words = WaitFor { $t = WindowText $securityBar; if ($t -match '^Signed by dave') { $t } } 20
    Check ($words -eq 'Signed by dave@example.com (key not verified)') "found, the bar names the signer ($(WindowText $securityBar))"
    Check ((BarFill) -eq $fills.good) "and is blue ($(BarFill))"
    $asked = @(LookupsSince $from)
    Check ($asked.Count -eq 1 -and $asked[0].kind -eq 'fingerprint' -and $asked[0].value -eq $daveKey.fingerprint -and $asked[0].found) "it was asked by the fingerprint alone, no address ($(LookupText $asked))"
    Check ([bool](WaitFor { (FindKeyLook) -eq 0 } 10)) 'and the label has no Find Key any more'
    $status = StatusPart $secureStatus 0
    Write-Host "   the status bar: $status"
    Shot $main 'keys-14-find-signer'
    $dave = KeyListed 'Dave'
    Check ($dave.Row -eq 'Dave | dave@example.com | Contact | Valid' -and $dave.Source -eq 'From keys.openpgp.org') "Encryption Keys lists Dave's key, from keys.openpgp.org ($($dave.Row); $($dave.Source))"
    RemoveSecure 'secure-no-key.eml' 'A key you do not have'

    # Find Key in a contact's Properties: her provider's directory answers, the key server is not asked
    [void](ServeKey 'grace.asc' 'grace@example.net' $true)
    $book = OpenBook
    if ($book) {
        AddCard $book 'Grace' 'Example' 'grace@example.net'
        $contact = CardProperties $book 'Grace Example'
        Check ($null -ne $contact) "Grace's card opens"
        if ($contact) {
            Check ((GetText $contact $IDC_CONTACT_KEY) -eq 'No key' -and (Enabled $contact $IDC_CONTACT_FIND_KEY)) "her Properties say No key, with Find Key ($(GetText $contact $IDC_CONTACT_KEY))"
            Check ((GetText $contact $IDC_CONTACT_FIND_KEY) -eq '&Find Key') "Find Key has its access key ($(GetText $contact $IDC_CONTACT_FIND_KEY))"
            $from = (Lookups).Count
            Click $contact $IDC_CONTACT_FIND_KEY
            $line = WaitFor { $t = GetText $contact $IDC_CONTACT_KEY; if ($t -match '([0-9A-F]{4} ){9}[0-9A-F]{4}') { $t } } 20
            Check ($line -match '^grace@example\.net:\s+([0-9A-F]{4} ){9}[0-9A-F]{4} \(Valid\)$') "found, the key's fingerprint and Valid ($($line -replace "`r`n", ' / '))"
            Check ((Visible $contact $IDC_CONTACT_KEY_VERIFY)) 'with Verify beside it'
            Write-Host "   what it says: $(GetText $contact $IDC_CONTACT_KEY_SAID)"
            $asked = @(LookupsSince $from)
            Check ($asked.Count -eq 1 -and $asked[0].kind -eq 'wkd' -and $asked[0].value -eq 'grace@example.net' -and $asked[0].found) "her provider's directory answered alone ($(LookupText $asked))"
            Shot $contact 'keys-15-contact-find'
            CloseContact $contact
        }
        CloseBook $book
    }
    $grace = KeyListed 'Grace Example'
    Check ($grace.Row -eq 'Grace Example | grace@example.net | Contact | Valid' -and $grace.Source -match 'mail provider') "Encryption Keys lists Grace's key, from her mail provider ($($grace.Row); $($grace.Source))"

    # a key attached to a message: Import Key in its menu, which a picture does not have
    $words = ShowSecure 'secure-previews.eml' 'Two pictures, one sealed'
    $labels = KeyStripMenu 0
    Check ($labels -ne '(no menu)' -and $labels -notmatch 'Import Key') "a picture's menu has no Import Key ($labels)"
    RemoveSecure 'secure-previews.eml' 'Two pictures, one sealed'
    Check (ShowPlain 'key-attached.eml' 'My public key') "Erin's message is shown"
    $files = WaitFor { if ((ListCount $keyStrip) -ge 1) { [Native.Win]::RemoteListText($keyStrip, 0, 0) } } 10
    Check ($files -like 'Erin Example public key.asc (*') "the strip shows her key ($files)"
    # the menu open for the picture, then the menu chosen from
    [void](WaitFor { (ListCount $keyStrip) -ge 1 } 5)
    Key $keyStrip 0x24
    Start-Sleep -Milliseconds 300
    [void][Native.Win]::PostMessage($keyStrip, 0x007B, $keyStrip, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    if ($menu) {
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero))) -join '|'
        Check ($labels -eq 'Open|Save As...||Save All...||Import Key...') "its menu has Import Key... ($labels)"
        Shot $main 'keys-16-attached-key' $menu
        Key $menu $VK_UP
        Key $menu $VK_RETURN
        $said = (Told 'Import Key' 'imported').Trim()
        Check ($said -eq 'One key was imported.') "chosen, it imports her key ($said)"
    } else {
        Check $false "the key's menu opens"
    }
    $erin = KeyListed 'Erin Example'
    Check ($erin.Row -eq 'Erin Example | erin@example.org | Contact | Valid' -and $erin.Source -eq 'From a message') "Encryption Keys lists Erin's key, from a message ($($erin.Row); $($erin.Source))"
    RemoveSecure 'key-attached.eml' 'My public key'

    # the Address Book's key marks: Alice's verified, Grace's found, Bob's none
    $book = OpenBook
    if ($book) {
        AddCard $book 'Alice' 'Example' 'alice@example.org'
        AddCard $book 'Bob' 'Example' 'bob@example.net'
        $bookList = [Native.Win]::GetDlgItem($book, $IDC_BOOK_LIST)
        $mark = { param($name) $r = BookRow $book $name; if ($r -ge 0) { "$([AccLook]::Description($bookList, $r + 1))" } else { '(no row)' } }
        Check ((& $mark 'Alice Example') -eq 'Has a verified encryption key') "Alice's row has the verified key mark ($(& $mark 'Alice Example'))"
        Check ((& $mark 'Grace Example') -eq 'Has an encryption key') "Grace's the key mark ($(& $mark 'Grace Example'))"
        Check ((& $mark 'Bob Example') -eq '') "Bob's none ($(& $mark 'Bob Example'))"
        # drawn apart: the dark pixels before each name differ, and Bob's row has none
        $iconOf = {
            param($name)
            $r = BookRow $book $name
            $rect = [Native.Win]::RemoteRect($bookList, 0x100E, [IntPtr]$r, 1)
            [void][Native.Win]::SetWindowPos($book, [IntPtr](-1), 0, 0, 0, 0, 0x13)
            [void][Native.Win]::SetForegroundWindow($book)
            Start-Sleep -Milliseconds 400
            $w = $rect.Right - $rect.Left; $h = $rect.Bottom - $rect.Top
            $dark = @()
            if ($w -gt 0 -and $h -gt 0) {
                $picture = New-Object System.Drawing.Bitmap $w, $h
                CopyScreen $picture $rect.Left $rect.Top
                for ($x = 0; $x -lt $w; $x++) { for ($y = 0; $y -lt $h; $y++) { $q = $picture.GetPixel($x, $y); if ($q.R -lt 120 -and $q.G -lt 120 -and $q.B -lt 120) { $dark += "$x,$y" } } }
            }
            [void][Native.Win]::SetWindowPos($book, [IntPtr](-2), 0, 0, 0, 0, 0x13)
            $dark -join ' '
        }
        $aliceIcon = & $iconOf 'Alice Example'; $graceIcon = & $iconOf 'Grace Example'; $bobIcon = & $iconOf 'Bob Example'
        Check ($aliceIcon -ne '' -and $graceIcon -ne '' -and $aliceIcon -ne $graceIcon -and $bobIcon -eq '') 'the two marks are drawn differently, Bob has none'
        Shot $book 'keys-17-book-marks'
        CloseBook $book
    }

    # a key learned from a message's Autocrypt header, without a question
    Check (ShowPlain 'autocrypt-frank-1.eml' 'Hello from Frank') "Frank's message is shown"
    $frank = WaitFor { $f = KeyListed 'Frank Example'; if ($f.Row) { $f } } 20
    Check ($frank -and $frank.Row -eq 'Frank Example | frank@example.org | Contact | Valid' -and $frank.Source -eq "From a message's Autocrypt header") "opened, his key is learned from its Autocrypt header ($(if ($frank) { "$($frank.Row); $($frank.Source)" }))"
    $frankLine = $null
    $book = OpenBook
    if ($book) {
        AddCard $book 'Frank' 'Example' 'frank@example.org'
        $contact = CardProperties $book 'Frank Example'
        if ($contact) {
            $frankLine = GetText $contact $IDC_CONTACT_KEY
            Check ($frankLine -match '^frank@example\.org:\s+([0-9A-F]{4} ){9}[0-9A-F]{4} \(Valid\)$') "his Properties show the key and Valid ($($frankLine -replace "`r`n", ' / '))"
            Shot $contact 'keys-18-learned'
            CloseContact $contact
        }
        CloseBook $book
    }
    RemoveSecure 'autocrypt-frank-1.eml' 'Hello from Frank'

    # another key of his: nothing asked in the reading pane, it waits in his Properties; Keep keeps the one in use
    Check (ShowPlain 'autocrypt-frank-2.eml' "Frank's new computer") "Frank's second message is shown"
    Check ($null -eq (WaitWindow 'InboxClassicAsk' $null 2) -and $null -eq (OwnBox $main)) 'nothing is asked in the reading pane'
    $book = OpenBook
    if ($book) {
        $contact = CardProperties $book 'Frank Example'
        if ($contact) {
            $pending = WaitFor { if (Visible $contact $IDC_CONTACT_KEY_PENDING) { GetText $contact $IDC_CONTACT_KEY_PENDING } } 10
            Check ((GetText $contact $IDC_CONTACT_KEY) -eq $frankLine) "the key noted is still in use ($((GetText $contact $IDC_CONTACT_KEY) -replace "`r`n", ' / '))"
            Check ($pending -match '^A different key for frank@example\.org was found on .+\.$') "a different key waits ($pending)"
            Check ((GetText $contact $IDC_CONTACT_KEY_USE_NEW) -eq 'Use the &New Key' -and (GetText $contact $IDC_CONTACT_KEY_KEEP) -eq '&Keep the Current One') 'with Use the New Key and Keep the Current One'
            Shot $contact 'keys-19-changed-key'
            Click $contact $IDC_CONTACT_KEY_KEEP
            Check ([bool](WaitFor { -not (Visible $contact $IDC_CONTACT_KEY_PENDING) -and -not (Visible $contact $IDC_CONTACT_KEY_KEEP) } 5)) 'Keep the Current One takes the note and its buttons away'
            CloseContact $contact
        }
        $contact = CardProperties $book 'Frank Example'
        if ($contact) {
            Check ((GetText $contact $IDC_CONTACT_KEY) -eq $frankLine -and [Native.Win]::GetDlgItem($contact, $IDC_CONTACT_KEY_PENDING) -eq [IntPtr]::Zero) 'opened again, his key is the one noted, nothing waits'
            CloseContact $contact
        }
        # the cards of this step go again: the Address Book's steps start with an empty book
        $bookList = [Native.Win]::GetDlgItem($book, $IDC_BOOK_LIST)
        while ((ListCount $bookList) -gt 0) {
            $n = ListCount $bookList
            Key $bookList $VK_HOME
            Start-Sleep -Milliseconds 200
            Click $book $IDC_BOOK_DELETE
            $ask = BoxOf $book 10
            if ($ask) { Click $ask 6 }
            if (-not (WaitFor { (ListCount $bookList) -lt $n } 5)) { break }
        }
        Check ((ListCount $bookList) -eq 0) 'the cards of the step are deleted again'
        CloseBook $book
    }
    RemoveSecure 'autocrypt-frank-2.eml' "Frank's new computer"

    # with Encrypt on, a recipient without a key is looked up at once, and the message goes encrypted to the key found
    [void](ServeKey 'heidi.asc' 'heidi@example.net')
    $heidiKey = [IO.File]::ReadAllText((Join-Path $pgpFiles 'heidi.asc'))
    $compose = NewMessageTo 'Heidi Example <heidi@example.net>' 'Found as you write' 'For Heidi only.'
    if ($compose) {
        $from = (Lookups).Count
        Command $compose $IDM_COMPOSE_ENCRYPT
        # (the harness answers at once: the grey look is seen when it is caught)
        $looking = WaitFor { $t = KeysRow $compose; if ($t -match 'Looking for a key') { $t } } 2
        Write-Host "   while it is looked up: $(if ($looking) { $looking } else { '(answered before it was seen)' })"
        $row = WaitFor { $t = KeysRow $compose; if ($t -match 'Heidi Example, Key not verified') { $t } } 20
        Check ($null -ne $row) "found, Heidi's lock says Key not verified ($(KeysRow $compose))"
        $line = WaitFor { $t = SecurityLine $compose; if ($t -match '^Will be encrypted') { $t } } 10
        Check ($line -eq 'Will be encrypted and signed for you and Heidi Example.') "the line says it will be encrypted to her ($line)"
        Check ((LineFill $compose) -eq $fills.good) "in blue ($(LineFill $compose))"
        $asked = @(LookupsSince $from)
        Check ($asked.Count -eq 2 -and $asked[0].kind -eq 'wkd' -and $asked[0].value -eq 'heidi@example.net' -and -not $asked[0].found -and
            $asked[1].kind -eq 'email' -and $asked[1].value -eq 'heidi@example.net' -and $asked[1].found) "her provider's directory first, then the key server ($(LookupText $asked))"
        Shot $compose 'write-36-found-on-encrypt'
        $before = NewestUid
        Command $compose $IDC_SEND
        Check ($null -eq (WaitShown 'InboxClassicRecipientKeys' 3)) "Send sends it at once, without Recipients' Keys"
        $sent = SentSince $before
        $body = if ($sent) { @{ raw = $sent.raw; key = $ownKey; passphrase = $ownPassphrase; recipients = @($heidiKey) } | ConvertTo-Json }
        $said = if ($body) {
            try { Invoke-RestMethod -Method Post -ContentType 'application/json' "$pgpBase/pgp/check" -Body $body } catch { [pscustomobject]@{ kind = 'unreadable'; error = "$_" } }
        }
        Check ($said -and $said.kind -eq 'encrypted' -and $said.signed -and $said.valid -and (@($said.to) -join ',') -eq 'True') "OpenPGP.js finds it encrypted to Heidi's key and signed ($(if ($said) { "$($said.kind) $($said.signed) $($said.valid) $($said.to) $($said.error)" }))"
        TakeAway $sent
    }
    $heidi = KeyListed 'Heidi Example'
    Check ($heidi.Row -eq 'Heidi Example | heidi@example.net | Contact | Valid' -and $heidi.Source -eq 'From keys.openpgp.org') "Encryption Keys lists Heidi's key, from keys.openpgp.org ($($heidi.Row); $($heidi.Source))"

    # ---- opening attachments ----

    Step 'opening an attachment'
    # the attachment strip under the header, in its frame (app.h), its items read as the list's rows are
    $IDC_ATTACHMENT_STRIP = 242; $IDC_ATTACHMENT_FRAME = 243; $WM_LBUTTONDOWN = 0x0201; $WM_LBUTTONUP = 0x0202; $WM_LBUTTONDBLCLK = 0x0203
    function StripOf([IntPtr]$window) { [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($window, $IDC_ATTACHMENT_FRAME), $IDC_ATTACHMENT_STRIP) }
    $strip = StripOf $main
    # where the core writes the files it opens: a folder of its own in the user's temporary folder
    $privateRoot = (Join-Path ([IO.Path]::GetFullPath([IO.Path]::GetTempPath())) 'InboxClassic').ToLowerInvariant()
    # the files opened after the first `before`, once there is a new one (the newest), or $null
    function NewlyOpened([int]$before) { WaitFor { $o = @(OpenedFiles); if ($o.Count -gt $before) { $o[-1] } } 10 }
    function InPrivateFolder([string]$path) { ([IO.Path]::GetFullPath($path)).ToLowerInvariant().StartsWith("$privateRoot\open-") }
    # a double-click on the first item of a strip, as the mouse does it
    function DoubleClickFirst([IntPtr]$s) {
        $point = [IntPtr]((10 -shl 16) -bor 12)
        [void][Native.Win]::PostMessage($s, $WM_LBUTTONDOWN, [IntPtr]1, $point)
        [void][Native.Win]::PostMessage($s, $WM_LBUTTONUP, [IntPtr]::Zero, $point)
        [void][Native.Win]::PostMessage($s, $WM_LBUTTONDBLCLK, [IntPtr]1, $point)
        [void][Native.Win]::PostMessage($s, $WM_LBUTTONUP, [IntPtr]::Zero, $point)
    }
    $stripTexts = { param($s) @(0..([Math]::Max(0, (ListCount $s) - 1)) | ForEach-Object { [Native.Win]::RemoteListText($s, $_, 0) }) }
    # a PDF, a program, and files of other kinds, one with a long name
    $exe64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("MZ not really a program, from scripts/ui-e2e.ps1`n"))
    $note64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("Bring boots.`n"))
    # and pages, which a browser would run the scripts of: one by its extension, one by what it holds
    $page64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("<!DOCTYPE html><html><script>alert(1)</script></html>`n"))
    $filesSubject = 'Files for the walking weekend'
    $part = { param($name, $type, $data) "--f`r`nContent-Type: $type; name=`"$name`"`r`nContent-Disposition: attachment; filename=`"$name`"`r`nContent-Transfer-Encoding: base64`r`n`r`n$data`r`n" }
    $filesMessage = "From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $filesSubject`r`n" +
        "Message-ID: <files@example.com>`r`nDate: Thu, 9 Oct 2025 09:00:00 +0000`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: multipart/mixed; boundary=`"f`"`r`n`r`n--f`r`nContent-Type: text/plain; charset=utf-8`r`n`r`n" +
        "The route and everything else for the weekend are attached.`r`n" +
        (& $part 'route.pdf' 'application/pdf' $pdf64) + (& $part 'setup.exe' 'application/octet-stream' $exe64) +
        (& $part 'Itinerary for the autumn walking weekend in the Lake District, final version.docx' 'application/octet-stream' $note64) +
        (& $part 'budget.xlsx' 'application/octet-stream' $note64) + (& $part 'lake.jpg' 'image/jpeg' $note64) +
        (& $part 'packing list.txt' 'text/plain' $note64) + (& $part 'statement.xht' 'application/octet-stream' $note64) +
        (& $part 'statement' 'application/octet-stream' $page64) + "--f--`r`n"
    AddMessage $filesMessage @('\Seen')
    Command $main $IDM_SYNC
    SelectFolder 0
    $row = WaitFor { $r = @(SubjectRows $filesSubject); if ($r.Count -gt 0) { "$($r[0])" } } 30
    if ($null -ne $row) { SelectRow ([int]$row) }
    $shown = WaitFor { if ([Native.Win]::IsWindowVisible($strip) -and (ListCount $strip) -eq 8) { $true } } 20
    $texts = & $stripTexts $strip
    Check ([bool]$shown) "the strip under the header shows each file ($($texts -join ' | '))"
    Check (($texts[0] -match '^route\.pdf \(.*\d.*\)$') -and ($texts[1] -like 'setup.exe (*)')) "each with its name and size ($($texts[0]))"
    Check ($texts[2].Contains('...') -and ($texts[2] -like 'Itinerary*docx (*)')) "a long name is shortened, its start and extension kept ($($texts[2]))"
    Check ([bool]([Native.Win]::GetWindowLong($strip, -16) -band 0x00010000)) 'the strip is a Tab stop'
    Start-Sleep -Milliseconds 800
    Shot $main 'attach-1-strip'

    # a double-click opens the PDF: the file handed over is the one sent, in the private folder
    $before = (OpenedFiles).Count
    DoubleClickFirst $strip
    $opened = NewlyOpened $before
    Check ($null -ne $opened) 'double-clicking the PDF opens it'
    if ($opened) {
        Check (InPrivateFolder $opened) "from a private folder ($opened)"
        Check ((Split-Path -Leaf $opened) -eq 'route.pdf') "under its own name ($(Split-Path -Leaf $opened))"
        # (read once nothing else has it open: an antivirus may look at a new file first)
        $content = WaitFor { try { [IO.File]::ReadAllText($opened) } catch { $null } } 10
        Check ($content -eq [Text.Encoding]::ASCII.GetString([Convert]::FromBase64String($pdf64))) "byte for byte what was sent ($($content.Length) bytes)"
        # opened again: the same file, no second copy
        $before = (OpenedFiles).Count
        DoubleClickFirst $strip
        $again = NewlyOpened $before
        Check ($again -eq $opened) "opened again, the same file ($again)"
    }

    # the keys: the arrows move between the files, Enter opens the one chosen
    Key $strip $VK_DOWN
    Key $strip $VK_DOWN
    $before = (OpenedFiles).Count
    Key $strip $VK_RETURN
    $opened = NewlyOpened $before
    Check ($opened -and (Split-Path -Leaf $opened) -like 'Itinerary*.docx') "the arrow keys choose a file and Enter opens it ($opened)"

    # the program's menu: Open greyed, Save As... and Save All...
    Key $strip $VK_UP
    [void][Native.Win]::PostMessage($strip, 0x007B, $strip, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    Check ($null -ne $menu) 'the menu key opens the menu of the file chosen'
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = @([Native.Win]::MenuLabels($hmenu))
        Check (($labels -join '|') -eq 'Open|Save As...||Save All...') "it offers Open, Save As... and Save All... ($($labels -join '|'))"
        Check (([Native.Win]::GetMenuState($hmenu, 0, 0x400) -band 0x3) -ne 0) "a program's Open is greyed"
        Shot $main 'attach-2-menu' $menu
        Key $menu $VK_ESCAPE
        if (-not (WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 3)) {
            [void][Native.Win]::SetForegroundWindow($main)
            [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
        }
    }
    # trying to open it anyway says why, and nothing is opened
    $before = (OpenedFiles).Count
    Key $strip $VK_RETURN
    $box = BoxOf $main 10
    $said = if ($box) { Statics $box } else { '' }
    Check ($said -match 'program') "opening a program is refused, with why ($said)"
    if ($box) {
        Shot $main 'attach-3-refused' $box
        Click $box 2
        [void](WaitFor { -not [Native.Win]::IsWindow($box) } 5)
    }
    Start-Sleep -Milliseconds 500
    Check ((OpenedFiles).Count -eq $before) 'and nothing is opened'
    # pages: Open greyed for one known by its extension and for one known by what it holds, and refused naming it
    foreach ($page in @(@{ Key = 0x23; Name = 'statement' }, @{ Key = $VK_UP; Name = 'statement.xht' })) {
        Key $strip $page.Key
        [void][Native.Win]::PostMessage($strip, 0x007B, $strip, [IntPtr](-1))
        $menu = WaitWindow '#32768' $null 10
        if ($menu) {
            $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
            Check (([Native.Win]::GetMenuState($hmenu, 0, 0x400) -band 0x3) -ne 0) "a page's Open is greyed ($($page.Name))"
            Key $menu $VK_ESCAPE
            [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 3)
        } else {
            Check $false "the menu of $($page.Name) opens"
        }
        Key $strip $VK_RETURN
        $box = BoxOf $main 10
        $said = if ($box) { Statics $box } else { '' }
        Check ($said -match [regex]::Escape("$($page.Name)") -and $said -match 'program') "opening $($page.Name) is refused, naming it ($said)"
        if ($box) {
            Click $box 2
            [void](WaitFor { -not [Native.Win]::IsWindow($box) } 5)
        }
    }
    Check ((OpenedFiles).Count -eq $before) 'and no page is opened'

    # in a message window of its own, the strip is there and opens the same way (Enter in the list, which has the
    # keyboard again)
    SelectRow ([int]$row)
    [void][Native.Win]::SetForegroundWindow($main)
    Key $list $VK_RETURN
    $filesWindow = WaitShown 'InboxClassicMessage' 10
    if ($filesWindow) {
        $windowStrip = StripOf $filesWindow
        Check ([bool](WaitFor { [Native.Win]::IsWindowVisible($windowStrip) -and (ListCount $windowStrip) -eq 8 } 10)) 'the message window has the strip'
        $before = (OpenedFiles).Count
        DoubleClickFirst $windowStrip
        $opened = NewlyOpened $before
        Check ($opened -and (Split-Path -Leaf $opened) -eq 'route.pdf' -and (InPrivateFolder $opened)) "and opens a file from it ($opened)"
        Shot $filesWindow 'attach-5-window'
        Key $filesWindow $VK_ESCAPE
        [void](WaitFor { -not [Native.Win]::IsWindow($filesWindow) } 10)
    } else {
        Check $false 'the message window opens'
    }
    $added = Find 'INBOX' 'files@example\.com'
    if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    Command $main $IDM_SYNC
    [void](WaitFor { @(SubjectRows $filesSubject).Count -eq 0 } 20)

    # an encrypted message's file: a note the first time it opens, none after
    $words = ShowSecure 'secure-attachment.eml' 'An encrypted file'
    Check ([bool](WaitFor { [Native.Win]::IsWindowVisible($strip) -and (ListCount $strip) -eq 1 } 10)) "the encrypted message's file is in the strip ($words; $(& $stripTexts $strip))"
    $before = (OpenedFiles).Count
    DoubleClickFirst $strip
    $note = WaitWindow '#32770' 'Opening this file' 10
    Check ($null -ne $note) 'the first time, a note says the file is stored decrypted'
    if ($note) {
        Shot $main 'attach-4-encrypted-note' $note
        Click $note 2
        [void](WaitFor { -not [Native.Win]::IsWindow($note) } 5)
    }
    $opened = NewlyOpened $before
    $content = if ($opened) { WaitFor { try { [IO.File]::ReadAllText($opened) } catch { $null } } 10 }
    Check ($opened -and (InPrivateFolder $opened) -and "$content".Trim() -eq 'the secret plan, in a file') "then the decrypted file opens ($opened)"
    $before = (OpenedFiles).Count
    DoubleClickFirst $strip
    $again = WaitWindow '#32770' 'Opening this file' 3
    if ($again) { Click $again 2 }
    Check ($null -eq $again -and $null -ne (NewlyOpened $before)) 'the second time it opens without the note'
    RemoveSecure 'secure-attachment.eml' 'An encrypted file'

    # ---- pictures and PDF files in the message ----

    Step 'pictures and PDF files in the message'
    # the reading pane's looks at its previews (main.cpp kTestPreviews: "state", or the middle of a file's first
    # picture on the screen; "window:" first for a message window's), the test switch of a PDF file that ended the app,
    # and the Reading page's two settings (app.h)
    $kTestPreviews = 0x50565753; $kTestPdfCrashed = 0x50444643
    $IDM_OPTIONS = 137; $IDC_OPTIONS_APPLY = 681; $IDC_OPTIONS_PREVIEWS = 687; $IDC_OPTIONS_PREVIEWS_NOTE = 688; $IDC_OPTIONS_PDF_PREVIEWS = 689
    $BM_GETCHECK = 0x00F0; $BM_SETCHECK = 0x00F1
    $previewFiles = Resolve-Path (Join-Path $PSScriptRoot 'ui-e2e\previews')
    $photoSubject = 'Photos and the invoice'; $manualSubject = "The kettle's manual"
    # a look of the pane, once it answered one (each look answers the one before); -1 for none
    function PreviewsLook([string]$query) {
        $v = WaitFor { $a = [Native.Win]::SendText($main, $kTestPreviews, $query); if ($a -ge 0) { "$a" } } 5
        if ($v) { [int64]$v } else { -1 }
    }
    # the pictures of the message shown: how many, how many have loaded, how many are PDF pages, and the notice
    function PreviewsState([string]$window = '') {
        $v = PreviewsLook "$($window)state"
        if ($v -lt 0) { return [pscustomobject]@{ Total = -1; Loaded = -1; Pages = -1; Notice = $false } }
        [pscustomobject]@{ Total = [int][Math]::Floor($v / 1000000); Loaded = [int]([Math]::Floor($v / 10000) % 100)
            Pages = [int]([Math]::Floor($v / 100) % 100); Notice = ($v % 100) -eq 1 }
    }
    # the state once it is $total pictures, all loaded, $pages of them PDF pages, with or without the notice
    function PreviewsShown([int]$total, [int]$pages, [bool]$notice = $false, [string]$window = '') {
        WaitFor { $s = PreviewsState $window; if ($s.Total -eq $total -and $s.Loaded -eq $total -and $s.Pages -eq $pages -and $s.Notice -eq $notice) { $s } } 20
    }
    # a click of the mouse on a file's first picture ("photo", "second") or on the link to all of a PDF file's pages
    function ClickPreview([string]$which) {
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 300
        # asked twice: scrolled into view by the first look, where it is told by the second
        [void](PreviewsLook $which)
        Start-Sleep -Milliseconds 300
        $p = WaitFor { $v = [Native.Win]::SendText($main, $kTestPreviews, $which); if ($v -gt 0) { "$v" } } 5
        if (-not $p) { return $false }
        $p = [int64]$p
        [Native.Win]::MouseClick([int][Math]::Floor($p / 100000), [int]($p % 100000))
        $true
    }
    # a file of a message of scripts/ui-e2e/previews as sent, in base64 (arrays of bytes do not leave a function whole)
    function SentBase64([string]$file, [string]$name) {
        $raw = [IO.File]::ReadAllText((Join-Path $previewFiles $file))
        if ($raw -notmatch "filename=`"$([regex]::Escape($name))`"\r?\n(?:[^\r\n]+\r?\n)*\r?\n([A-Za-z0-9+/=\r\n]+)") { return $null }
        [Convert]::ToBase64String([Convert]::FromBase64String(($Matches[1] -replace '\s', '')))
    }
    # the file opened is byte for byte the one sent (read once nothing else has it open: an antivirus may look first)
    function SameBytes([string]$path, [string]$sent) {
        [bool](WaitFor { try { $sent -and [Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) -eq $sent } catch { $false } } 10)
    }
    function SelectPreviews([string]$subject) {
        $row = WaitFor { $r = @(SubjectRows $subject); if ($r.Count -gt 0) { "$($r[0])" } } 30
        if ($null -ne $row) { SelectRow ([int]$row) }
        $null -ne $row
    }
    foreach ($file in 'photo-and-pdf.eml', 'long-pdf.eml') { AddMessage ([IO.File]::ReadAllText((Join-Path $previewFiles $file))) @('\Seen') }
    Command $main $IDM_SYNC
    SelectFolder 0

    # the photo and the invoice's three pages after the text, every picture loaded
    Check (SelectPreviews $photoSubject) 'the message with a photo and an invoice is in the Inbox'
    $state = PreviewsShown 4 3
    Check ($null -ne $state) "the photo and the invoice's three pages show after the text, each loaded ($(PreviewsState))"
    $texts = & $stripTexts $strip
    Check ((ListCount $strip) -eq 2 -and $texts[0] -like 'lake.jpg (*)' -and $texts[1] -like 'invoice-2026-118.pdf (*)') "the strip still lists both files ($($texts -join ' | '))"
    Start-Sleep -Milliseconds 500
    Shot $main 'read-30-previews'

    # a click on the photo opens it as a double-click in the strip does: the file sent, from the private folder
    $before = (OpenedFiles).Count
    Check (ClickPreview 'photo') 'the photo is on the screen'
    $opened = NewlyOpened $before
    Check ($opened -and (Split-Path -Leaf $opened) -eq 'lake.jpg' -and (InPrivateFolder $opened)) "clicking the photo opens it ($opened)"
    if ($opened) { Check (SameBytes $opened (SentBase64 'photo-and-pdf.eml' 'lake.jpg')) 'byte for byte what was sent' }
    # the click left the keyboard on the photo's link: Tab goes on to the invoice's, Enter opens it
    $before = (OpenedFiles).Count
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    [Native.Win]::keybd_event(0x09, 0, 0, [IntPtr]::Zero); [Native.Win]::keybd_event(0x09, 0, 2, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 300
    Shot $main 'read-30b-previews-focus'
    [Native.Win]::keybd_event($VK_RETURN, 0, 0, [IntPtr]::Zero); [Native.Win]::keybd_event($VK_RETURN, 0, 2, [IntPtr]::Zero)
    $opened = NewlyOpened $before
    Check ($opened -and (Split-Path -Leaf $opened) -eq 'invoice-2026-118.pdf') "Tab reaches the invoice, and Enter opens it ($opened)"
    if ($opened) { Check (SameBytes $opened (SentBase64 'photo-and-pdf.eml' 'invoice-2026-118.pdf')) 'the invoice as it was sent' }

    # the manual: its first five pages, and the link to all twelve, which opens it
    Check (SelectPreviews $manualSubject) 'the message with a long manual is in the Inbox'
    Check ($null -ne (PreviewsShown 5 5)) "a long PDF file shows its first five pages ($(PreviewsState))"
    Start-Sleep -Milliseconds 500
    Shot $main 'read-30c-previews-long'
    $before = (OpenedFiles).Count
    Check (ClickPreview 'more') 'the link to all its pages is there'
    $opened = NewlyOpened $before
    Check ($opened -and (Split-Path -Leaf $opened) -eq 'kettle-manual.pdf') "and opens the file ($opened)"
    Shot $main 'read-30d-previews-long-end'

    # many pictures: twenty previews in the strip's order, the rest in the strip only; a long name wraps; nothing is
    # wider than the pane, also a narrow one
    $manySubject = 'Twenty-four pictures from the walk'
    $parts = ''
    for ($i = 1; $i -le 24; $i++) {
        $bitmap = New-Object System.Drawing.Bitmap 480, 320
        $g = [System.Drawing.Graphics]::FromImage($bitmap)
        $g.Clear([System.Drawing.Color]::FromArgb(40 + $i * 8, 110, 200 - $i * 5))
        $g.DrawString("$i", (New-Object System.Drawing.Font 'Segoe UI', 48), [System.Drawing.Brushes]::White, 20, 20)
        $g.Dispose()
        $stream = New-Object IO.MemoryStream
        $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png); $bitmap.Dispose()
        $name = if ($i -eq 2) { 'A very long name of a picture from the autumn walk around the lake, the view from the hill at sunset.png' } else { "walk-$i.png" }
        $parts += "--m`r`nContent-Type: image/png; name=`"$name`"`r`nContent-Disposition: attachment; filename=`"$name`"`r`n" +
            "Content-Transfer-Encoding: base64`r`n`r`n" + [Convert]::ToBase64String($stream.ToArray(), 'InsertLineBreaks') + "`r`n"
    }
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $manySubject`r`n" +
        "Message-ID: <previews-3@example.com>`r`nDate: Mon, 16 Nov 2026 11:00:00 +0000`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: multipart/mixed; boundary=`"m`"`r`n`r`n--m`r`nContent-Type: text/plain; charset=utf-8`r`n`r`n" +
        "All the pictures of the walk.`r`n" + $parts + "--m--`r`n") @('\Seen')
    Command $main $IDM_SYNC
    Check (SelectPreviews $manySubject) 'a message with twenty-four pictures is in the Inbox'
    Check ($null -ne (PreviewsShown 20 0)) "the first twenty show, every one loaded ($(PreviewsState))"
    Check ((ListCount $strip) -eq 24) "the strip lists all twenty-four ($(ListCount $strip))"
    Start-Sleep -Milliseconds 500
    Shot $main 'read-30g-previews-many'
    [void](PreviewsLook 'last'); [void](PreviewsLook 'last')
    Start-Sleep -Milliseconds 500
    Check ((PreviewsLook 'overflow') -eq 0 -and (PreviewsLook 'overflow') -eq 0) 'nothing is wider than the pane'
    Shot $main 'read-30h-previews-many-end'
    $box = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($main, [ref]$box)
    [void][Native.Win]::SetWindowPos($main, [IntPtr]::Zero, 0, 0, 760, $box.Bottom - $box.Top, 0x16)
    Start-Sleep -Seconds 1
    [void](PreviewsLook 'overflow')
    Check ((PreviewsLook 'overflow') -eq 0) 'nor in a narrow window'
    Shot $main 'read-30i-previews-narrow'
    [void][Native.Win]::SetWindowPos($main, [IntPtr]::Zero, 0, 0, $box.Right - $box.Left, $box.Bottom - $box.Top, 0x16)
    $added = Find 'INBOX' 'previews-3@example\.com'
    if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    Command $main $IDM_SYNC
    # gone from the list before a row is chosen, or its row going would leave another message selected
    [void](WaitFor { @(SubjectRows $manySubject).Count -eq 0 } 20)

    # in a message window of its own, the previews are there too
    [void](SelectPreviews $photoSubject)
    [void](PreviewsShown 4 3)
    [void][Native.Win]::SetForegroundWindow($main)
    Key $list $VK_RETURN
    $previewWindow = WaitShown 'InboxClassicMessage' 10
    Check ($null -ne $previewWindow) 'Enter opens the message in a window of its own'
    if ($previewWindow) {
        Check ($null -ne (PreviewsShown 4 3 $false 'window:')) "with its previews ($(PreviewsState 'window:'))"
        Start-Sleep -Milliseconds 500
        Shot $previewWindow 'read-30e-previews-window'
        Key $previewWindow $VK_ESCAPE
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($previewWindow) } 10)) 'Esc closes it'
    }

    # signed and encrypted mail: each part's pictures in the part's own frame, the plain part's harbour in frame 1 and
    # the encrypted part's floor plan in frame 2, none in the page around them (SCENARIO.md 19i)
    $words = ShowSecure 'secure-previews.eml' 'Two pictures, one sealed'
    Check ($words -match '2 parts: 1 encrypted, 1 without a confirmed signature') "a message of a plain and an encrypted part has the bar, counting them ($words)"
    # the strip: the floor plan, from the encrypted part, with the lock over its icon (overlay 1, LVM_GETITEMSTATE) and
    # its part for a screen reader; the harbour, from the plain part, without it
    $LVM_GETITEMSTATE = 0x102C
    function StripOverlay([int]$item) { ([int][Native.Win]::SendMessage($strip, $LVM_GETITEMSTATE, [IntPtr]$item, [IntPtr]0x0F00) -shr 8) }
    $texts = & $stripTexts $strip
    Check ($texts.Count -eq 2 -and $texts[0] -like 'harbour.png (*)' -and $texts[1] -like 'floor-plan.png (*)') "the strip lists both files ($($texts -join ' | '))"
    Check ((StripOverlay 1) -eq 1 -and (StripOverlay 0) -eq 0) "the floor plan has the lock, the harbour not ($(StripOverlay 0), $(StripOverlay 1))"
    $described = @(0, 1 | ForEach-Object { [AccLook]::Description($strip, $_ + 1) })
    Check ("$($described[1])" -like '*From part 2: Encrypted. Not signed' -and "$($described[0])" -like '*From part 1: Not signed') "each file says its part to a screen reader ($($described -join ' | '))"
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 500
    Shot $main 'secure-15-strip-parts'
    # a frame's pictures: how many, how many loaded, its file the one named (part:N:name in preview.cpp)
    function PartLook([int]$n, [string]$name) { WaitFor { $v = PreviewsLook "part:$($n):$name"; if ($v -eq 111) { $v } } 20 }
    Check ($null -ne (PartLook 1 'harbour.png')) "frame 1 shows harbour.png, loaded ($(PreviewsLook 'part:1:harbour.png'))"
    Check ($null -ne (PartLook 2 'floor-plan.png')) "frame 2 shows floor-plan.png, loaded ($(PreviewsLook 'part:2:floor-plan.png'))"
    # (asked twice: a look answers with the one before it)
    [void](PreviewsState)
    Check ((PreviewsState).Total -eq 0) "the page around the frames shows no preview ($(PreviewsState))"
    $sealed = FramesFit 2
    Check ($null -ne $sealed -and $sealed.Height -ge 300) "two frames, each as tall as its part with its picture, no scroll bar inside ($(Frames))"
    Start-Sleep -Milliseconds 500
    Shot $main 'secure-14a-plain-part'
    # scrolled to the encrypted part: its label over its text and the floor plan
    [void](PreviewsLook 'partframe:2'); [void](PreviewsLook 'partframe:2')
    Start-Sleep -Milliseconds 500
    Shot $main 'secure-14-attachment-previews'
    # a click on the floor plan in its frame opens the decrypted file, without the note: it is given once ever, and
    # the encrypted file of 'opening an attachment' gave it already
    $before = (OpenedFiles).Count
    Check (ClickPreview 'partpoint:2') 'the floor plan is on the screen'
    $note = WaitWindow '#32770' 'Opening this file' 3
    if ($note) { Click $note 2 }
    $opened = NewlyOpened $before
    Check ($opened -and (Split-Path -Leaf $opened) -eq 'floor-plan.png' -and (InPrivateFolder $opened)) "clicking the floor plan in frame 2 opens it ($opened)"
    Check ($null -eq $note) 'without the decrypted-file note again, which was given once already'
    $before = (OpenedFiles).Count
    Check (ClickPreview 'partpoint:1') 'the harbour is on the screen'
    $opened = NewlyOpened $before
    Check ($opened -and (Split-Path -Leaf $opened) -eq 'harbour.png') "and the harbour in frame 1 opens its file ($opened)"
    # Print: each part's picture after that part's text, named with its part
    $kTestPrint = 0x50524E54
    $printed = "The harbour, as promised.`nPart 1: harbour.png`nThe floor plan, for your eyes only.`nPart 2: floor-plan.png"
    Command $main $IDM_PRINT
    $print = WaitWindow 'InboxClassicPrint' $null 20
    Check ($null -ne $print) 'Print opens the print preview'
    if ($print) {
        $looked = WaitFor { $v = [Native.Win]::SendText($main, $kTestPrint, $printed); if ($v -eq 21) { $v } } 20
        Check ($null -ne $looked) "the printout has each picture after its part's text, captioned with its part ($([Native.Win]::SendText($main, $kTestPrint, $printed)))"
        Start-Sleep -Seconds 3
        Shot $print 'secure-14b-print-previews'
        [void][Native.Win]::PostMessage($print, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($print) } 10)
    }
    RemoveSecure 'secure-previews.eml' 'Two pictures, one sealed'
    # the photo and the invoice shown again, for the settings
    Check (SelectPreviews $photoSubject) 'the message with a photo and an invoice is selected again'
    [void](PreviewsShown 4 3)

    # Options, Reading: both settings, on, the PDF one under the other; off, the message shows no previews
    function PreviewsCheck([IntPtr]$o, [int]$id) { [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $id), $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 }
    function PreviewsSet([IntPtr]$o, [int]$id, [bool]$on) {
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $id), $BM_SETCHECK, [IntPtr]([int]$on), [IntPtr]::Zero)
        Click $o $id
        $apply = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_APPLY)
        [void](WaitFor { [Native.Win]::IsWindowEnabled($apply) } 5)
        Click $o $IDC_OPTIONS_APPLY
        [void](WaitFor { -not [Native.Win]::IsWindowEnabled($apply) } 5)
    }
    # two readers of one message, the pane and a window of its own, both built again when the setting changes (as
    # dark messages does on the Mac and Linux): neither says the message could not be shown
    [void][Native.Win]::SetForegroundWindow($main)
    Key $list $VK_RETURN
    $twoReaders = WaitShown 'InboxClassicMessage' 10
    Check ($null -ne $twoReaders -and $null -ne (PreviewsShown 4 3 $false 'window:')) "the message in a window of its own beside the pane ($(PreviewsState 'window:'))"
    function NotShown([IntPtr]$w) { (Statics $w) -match 'could not be shown' }
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    Check ($null -ne $o) 'Tools > Options opens'
    if ($o) {
        OptionsPage $o 1
        $show = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_PREVIEWS); $pdfs = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_PDF_PREVIEWS)
        Check (((WindowText $show) -replace '&', '') -eq 'Show attachments in messages' -and (PreviewsCheck $o $IDC_OPTIONS_PREVIEWS) -and (Visible $o $IDC_OPTIONS_PREVIEWS_NOTE)) "Reading has $(WindowText $show), on, with its note"
        Check (((WindowText $pdfs) -replace '&', '') -eq 'Show PDF files in messages' -and (PreviewsCheck $o $IDC_OPTIONS_PDF_PREVIEWS) -and [Native.Win]::IsWindowEnabled($pdfs)) "and $(WindowText $pdfs) under it, on"
        $a = New-Object Native.Win+RECT; $b = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($show, [ref]$a); [void][Native.Win]::GetWindowRect($pdfs, [ref]$b)
        Check ($b.Left -gt $a.Left -and $b.Top -gt $a.Top) 'the PDF setting is under the other, indented'
        Shot $o 'read-30f-previews-options'
        PreviewsSet $o $IDC_OPTIONS_PREVIEWS $false
        Check (-not [Native.Win]::IsWindowEnabled($pdfs) -and (PreviewsCheck $o $IDC_OPTIONS_PDF_PREVIEWS)) 'off, the PDF setting is disabled and keeps its value'
        Check ($null -ne (WaitFor { $s = PreviewsState; if ($s.Total -eq 0) { $s } } 20)) "and the message shows no previews ($(PreviewsState))"
        PreviewsSet $o $IDC_OPTIONS_PREVIEWS $true
        Check ($null -ne (PreviewsShown 4 3)) "on again, they are back ($(PreviewsState))"
        if ($twoReaders) {
            Check ($null -ne (PreviewsShown 4 3 $false 'window:')) "in the message's own window too ($(PreviewsState 'window:'))"
            Check (-not (NotShown $main) -and -not (NotShown $twoReaders)) 'neither the pane nor the window says the message could not be shown'
        }
        PreviewsSet $o $IDC_OPTIONS_PDF_PREVIEWS $false
        Check ($null -ne (PreviewsShown 1 0)) "PDF files off: the photo shows, the invoice not, and nothing says why ($(PreviewsState))"
        PreviewsSet $o $IDC_OPTIONS_PDF_PREVIEWS $true
        Check ($null -ne (PreviewsShown 4 3)) "on again, the invoice is back ($(PreviewsState))"
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
    }
    if ($twoReaders) {
        Key $twoReaders $VK_ESCAPE
        [void](WaitFor { -not [Native.Win]::IsWindow($twoReaders) } 10)
    }

    # PDF previews off as after a PDF file ended the app: the photo, and the notice naming the setting
    Check ([Native.Win]::SendText($main, $kTestPdfCrashed, '') -eq 1) 'PDF previews turned off as after a crash'
    [void](SelectPreviews $manualSubject)
    [void](SelectPreviews $photoSubject)
    Check ($null -ne (PreviewsShown 1 0 $true)) "opened again, the photo shows with the notice ($(PreviewsState))"
    Start-Sleep -Milliseconds 500
    Shot $main 'read-31-previews-pdf-off'
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 1
        Check (-not (PreviewsCheck $o $IDC_OPTIONS_PDF_PREVIEWS)) 'Options shows PDF files off'
        Shot $o 'read-31b-previews-pdf-off-options'
        $pdfs = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_PDF_PREVIEWS)
        [void][Native.Win]::SendMessage($pdfs, $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $o $IDC_OPTIONS_PDF_PREVIEWS
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
    }
    Check ($null -ne (PreviewsShown 4 3)) "turned on, the notice is gone and the pages are back ($(PreviewsState))"

    # tiles: the HEIC picture and the booking that wants a password, each a tile that says why, the photo between them
    $tilesSubject = 'The boat trip, and the booking'
    AddMessage ([IO.File]::ReadAllText((Join-Path $previewFiles 'tiles.eml'))) @('\Seen')
    Command $main $IDM_SYNC
    Check (SelectPreviews $tilesSubject) 'the message with a HEIC picture and a protected PDF file is in the Inbox'
    Check ($null -ne (PreviewsShown 1 0)) "the photo shows ($(PreviewsState))"
    $tiles = WaitFor { $t = PreviewsLook 'tiles'; if ($t -eq 202) { $t } } 10
    Check ($null -ne $tiles) "the HEIC picture and the protected PDF file are tiles, each saying why ($(PreviewsLook 'tiles'))"
    Start-Sleep -Milliseconds 500
    Shot $main 'read-32-previews-tiles'
    # the photo (the second file) clicked, then Tab: the booking's tile has the keyboard, and Enter opens it
    $before = (OpenedFiles).Count
    [void](ClickPreview 'second')
    [void](NewlyOpened $before)
    $before = (OpenedFiles).Count
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    [Native.Win]::keybd_event(0x09, 0, 0, [IntPtr]::Zero); [Native.Win]::keybd_event(0x09, 0, 2, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 300
    [Native.Win]::keybd_event($VK_RETURN, 0, 0, [IntPtr]::Zero); [Native.Win]::keybd_event($VK_RETURN, 0, 2, [IntPtr]::Zero)
    $opened = NewlyOpened $before
    Check ($opened -and (Split-Path -Leaf $opened) -eq 'booking-4471.pdf') "Tab reaches the booking's tile, and Enter opens the file ($opened)"
    # the strip's menu of a file: Show in Message after Save All, as the file is shown
    function StripMenuOf([int]$item) {
        Key $strip 0x24
        for ($i = 0; $i -lt $item; $i++) { Key $strip $VK_DOWN }
        Start-Sleep -Milliseconds 300
        [void][Native.Win]::PostMessage($strip, 0x007B, $strip, [IntPtr](-1))
        WaitWindow '#32768' $null 10
    }
    # the menu's labels and its last item's state (checked 0x8, greyed 0x3), closed or that item chosen
    function ShowInMessageItem([IntPtr]$menu, [bool]$choose) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = @([Native.Win]::MenuLabels($hmenu))
        $state = [Native.Win]::GetMenuState($hmenu, $labels.Count - 1, 0x400)
        $item = [pscustomobject]@{ Labels = $labels -join '|'; Checked = ($state -band 0x8) -ne 0; Greyed = ($state -band 0x3) -ne 0 }
        if ($choose) { Key $menu $VK_UP; Key $menu $VK_RETURN } else { Key $menu $VK_ESCAPE }
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
        $item
    }
    $menu = StripMenuOf 0
    Check ($null -ne $menu) "the HEIC picture's menu opens"
    if ($menu) {
        Shot $main 'read-32b-previews-menu-greyed' $menu
        $item = ShowInMessageItem $menu $false
        Check ($item.Labels -eq 'Open|Save As...||Save All...||Show in Message' -and $item.Greyed -and -not $item.Checked) "it offers Show in Message, greyed ($($item.Labels))"
    }

    # Show in Message on the invoice: checked; chosen, the invoice is taken out and the text stays where it was; chosen
    # again, it is back
    [void](SelectPreviews $photoSubject)
    Check ($null -ne (PreviewsShown 4 3)) "the photo and the invoice ($(PreviewsState))"
    [void](PreviewsLook 'scroll:80')
    $scrolled = WaitFor { $y = PreviewsLook 'scroll'; if ($y -gt 1) { $y } } 5
    $menu = StripMenuOf 1
    if ($menu) {
        Shot $main 'read-32c-previews-menu' $menu
        $item = ShowInMessageItem $menu $true
        Check ($item.Labels -eq 'Open|Save As...||Save All...||Show in Message' -and $item.Checked -and -not $item.Greyed) "the invoice's menu has Show in Message, checked ($($item.Labels))"
    } else {
        Check $false "the invoice's menu opens"
    }
    Check ($null -ne (PreviewsShown 1 0)) "chosen, the invoice is taken out of the message, the photo stays ($(PreviewsState))"
    Start-Sleep -Milliseconds 500
    $y = PreviewsLook 'scroll'; $y = PreviewsLook 'scroll'
    Check ($scrolled -and $y -eq $scrolled) "and the text stays where it was scrolled to ($($scrolled - 1) px, now $($y - 1))"
    Check ((ListCount $strip) -eq 2) 'the strip still lists it'
    $menu = StripMenuOf 1
    if ($menu) {
        $item = ShowInMessageItem $menu $true
        Check (-not $item.Checked -and -not $item.Greyed) 'now Show in Message is not checked'
    }
    Check ($null -ne (PreviewsShown 4 3)) "chosen again, the invoice is back ($(PreviewsState))"
    Start-Sleep -Milliseconds 500
    $y = PreviewsLook 'scroll'; $y = PreviewsLook 'scroll'
    Check ($y -eq $scrolled) "and the text is still where it was ($($y - 1) px)"

    # with "Show attachments in messages" off, Show in Message draws one file (the choices made above are forgotten
    # once no window shows the message)
    [void](SelectPreviews $tilesSubject)
    [void](SelectPreviews $photoSubject)
    [void](PreviewsShown 4 3)
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 1
        PreviewsSet $o $IDC_OPTIONS_PREVIEWS $false
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
    }
    Check ($null -ne (WaitFor { $s = PreviewsState; if ($s.Total -eq 0) { $s } } 20)) "with the setting off the message shows no previews ($(PreviewsState))"
    $menu = StripMenuOf 1
    if ($menu) {
        $item = ShowInMessageItem $menu $true
        Check (-not $item.Checked -and -not $item.Greyed) "the invoice's Show in Message is not checked ($($item.Labels))"
    }
    Check ($null -ne (PreviewsShown 3 3)) "chosen, the invoice alone shows ($(PreviewsState))"
    Start-Sleep -Milliseconds 500
    Shot $main 'read-32d-previews-one-shown'
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 1
        PreviewsSet $o $IDC_OPTIONS_PREVIEWS $true
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
    }
    Check ($null -ne (PreviewsShown 4 3)) "the setting on again, both files show ($(PreviewsState))"

    # Print: the photo in the printout as a picture, and a line naming the invoice, which is not printed
    $kTestPrint = 0x50524E54
    Command $main $IDM_PRINT
    $print = WaitWindow 'InboxClassicPrint' $null 40
    Check ($null -ne $print) 'Print of a message with previews opens the print preview'
    if ($print) {
        $looked = WaitFor { $v = [Native.Win]::SendText($main, $kTestPrint, 'invoice-2026-118.pdf (3 pages'); if ($v -eq 11) { $v } } 20
        Check ($null -ne $looked) "the printout has the photo, loaded, and the line naming the invoice ($([Native.Win]::SendText($main, $kTestPrint, 'invoice-2026-118.pdf (3 pages')))"
        Start-Sleep -Seconds 5
        Shot $print 'read-33-previews-print'
        [void][Native.Win]::PostMessage($print, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($print) } 10)
    }

    foreach ($id in 'previews-1', 'previews-2', 'previews-4') {
        $added = Find 'INBOX' "$id@example\.com"
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { @(SubjectRows $photoSubject).Count -eq 0 -and @(SubjectRows $manualSubject).Count -eq 0 -and @(SubjectRows $tilesSubject).Count -eq 0 } 20)

    # ---- getting new mail ----

    Step 'Send/Recv'
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: One more thing`r`n" +
        "Message-ID: <later@example.com>`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`n`r`nArrived later.`r`n")
    Command $main $IDM_SYNC
    Check ($null -ne (WaitFor { if ((Rows) -ge 7) { Rows } } 30)) 'the new mail is in the list'
    Shot $main 'main-2-new-mail'
    SelectFolder 1
    Check ($null -ne (WaitFor { if ((Rows) -ge 2) { Rows } })) 'Sent Items has what was sent'
    SelectRow 0
    $firstTo = [Native.Win]::RemoteListText($list, 0, $COL_FROM)
    # the newest sent: a recipient (Fay, or one of the later steps'), never the account's own name
    Check ($firstTo -and $firstTo -ne 'Alex Morgan') "Sent Items names whom each message went to, in a To column ($firstTo)"
    Shot $main 'main-3-sent-items'
    SelectFolder 0

    # ---- finding ----

    Step 'finding'
    SelectFolder 0
    $all = WaitFor { if ((Rows) -ge 7) { Rows } }
    $IDC_FIND_FIELD = 205; $IDC_FIND_CLEAR = 207
    $field = [Native.Win]::GetDlgItem($main, $IDC_FIND_FIELD)
    $find = [Native.Win]::GetDlgItem($field, 204)
    Check ($find -ne [IntPtr]::Zero) 'there is a Find box, in a search field'
    # a click anywhere in the field, not only on the line of text, starts typing in it: at its left end (the
    # magnifier), its right end and its top edge
    [void][Native.Win]::SetForegroundWindow($main)
    $box = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($field, [ref]$box)
    $listBox = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($list, [ref]$listBox)
    $middle = [int](($box.Top + $box.Bottom) / 2)
    foreach ($point in @(@(($box.Left + 6), $middle, 'its left end'), @(($box.Right - 6), $middle, 'its right end'), @([int](($box.Left + $box.Right) / 2), ($box.Top + 4), 'its top edge'))) {
        # somewhere else first: below the rows of the list
        [Native.Win]::MouseClick($listBox.Left + 60, $listBox.Bottom - 10)
        [void](WaitFor { [Native.Win]::FocusOf($main) -eq $list } 3)
        [Native.Win]::MouseClick($point[0], $point[1])
        Check ([bool](WaitFor { [Native.Win]::FocusOf($main) -eq $find } 3)) "a click at $($point[2]) of the search field gives the Find box the focus"
    }
    $listHeader = [Native.Win]::SendMessage($list, 0x101F, [IntPtr]::Zero, [IntPtr]::Zero)
    $columns = { [int][Native.Win]::SendMessage($listHeader, 0x1200, [IntPtr]::Zero, [IntPtr]::Zero) }
    Check ((& $columns) -eq $FOLDER_COLUMNS) 'a folder has no Folder column'
    # the folder bar: the static whose text starts with a space
    $folderBar = { ([Native.Win]::FindDescendants($main, 'Static') | ForEach-Object { WindowText $_ } | Where-Object { $_.StartsWith(' ') } | Select-Object -First 1) }
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'lunch')
    Check ([bool](WaitFor { (Rows) -eq 1 })) 'typing in it narrows the list to what has it (the subject)'
    Check ([bool](WaitFor { (& $columns) -eq ($FOLDER_COLUMNS + 1) } 5)) 'it searches every folder: the list has a Folder column'
    # the search bar over the list says what was found for what, the folder bar where
    $IDC_SEARCH_BAR = 208; $IDC_SEARCH_CLEAR = 209
    $searchBar = { WindowText ([Native.Win]::GetDlgItem($main, $IDC_SEARCH_BAR)) }
    Check ([bool](WaitFor { (Visible $main $IDC_SEARCH_BAR) -and (& $searchBar) -match '^1 result for .lunch. in all folders' } 5)) "the search bar says what was found for what ($(& $searchBar))"
    Check ([bool](WaitFor { (& $folderBar) -eq ' All Folders' } 5)) "the folder bar says where ($(& $folderBar))"
    Check ((WindowText $main) -match '^All Folders') 'and so does the title'
    Shot $main 'find-1-results'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'ann@example.com')
    Check ([bool](WaitFor { (Rows) -ge 2 })) 'the sender address is found too'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'nothing has this')
    Check ([bool](WaitFor { (Rows) -eq 0 })) 'and nothing when nothing has it'
    # the list then says so in its middle, and what to try
    Check ([bool](WaitFor { $b = & $searchBar; foreach ($id in 'win-search-found-all[0]', 'win-search-found-in[0]') { if ($b -match (Pattern $en[$id] @{ words = 'nothing has this' })) { $true } } } 5)) "the search bar says there are no results ($(& $searchBar))"
    Shot $main 'find-3-no-results'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, '')
    Check ([bool](WaitFor { (Rows) -eq $all -and (& $columns) -eq $FOLDER_COLUMNS })) 'clearing it shows the folder again, without the Folder column'
    Check (-not (Visible $main $IDC_SEARCH_BAR)) 'and without the search bar'
    # the clear button is there only while there is something to clear, and clears it
    Check (-not (Visible $field $IDC_FIND_CLEAR)) 'an empty Find box has no clear button'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'lunch')
    Check ([bool](WaitFor { (Rows) -eq 1 -and (Visible $field $IDC_FIND_CLEAR) })) 'with text in it, it has'
    Click $field $IDC_FIND_CLEAR
    Check ([bool](WaitFor { (Rows) -eq $all -and (WindowText $find) -eq '' -and -not (Visible $field $IDC_FIND_CLEAR) })) 'which empties it and shows the folder'
    # the text of messages is found too, once the search has read it (in the background after a sync; only the text
    # parts are fetched)
    Command $main $IDM_SYNC
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'agreed dates')
    Check ([bool](WaitFor { (Rows) -eq 1 } 40)) 'words of the text are found'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'from:carol')
    Check ([bool](WaitFor { (Rows) -eq 1 })) 'Gmail operators work: from:'
    # what is in other folders is found as well; in: narrows it to one
    # from the folder (the whole of it), so what is counted is what this search found
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, '')
    [void](WaitFor { (Rows) -eq $all })
    # the messages found, as the search bar counts them: grouped by conversation a reply in Sent Items shares a row
    # with the message it answers, so the rows do not tell
    $foundCount = { if ((& $searchBar) -match '^(\d+) results? for') { [int]$Matches[1] } else { 0 } }
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos in:inbox')
    $inInbox = WaitFor { if ((Rows) -ge 1 -and (& $searchBar) -match ' in Inbox' -and (& $foundCount) -ge 1) { & $foundCount } }
    Check ([bool](WaitFor { (& $folderBar) -eq ' Inbox' -and (& $searchBar) -match ' in Inbox$' } 5)) "in:inbox: the folder bar and the search bar say the Inbox ($(& $folderBar), $(& $searchBar))"
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos')
    $everywhere = WaitFor { if ((& $searchBar) -match ' in all folders' -and (& $foundCount) -gt $inInbox) { & $foundCount } }
    Check ([bool]$inInbox -and [bool]$everywhere) "the messages of other folders are found too ($everywhere), in:inbox narrows them to the Inbox ($inInbox)"
    Shot $main 'find-2-every-folder'
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'is:unread')
    Check ([bool](WaitFor { (Rows) -ge 1 -and (Rows) -lt $all })) 'is:unread lists the unread messages'
    # a result from another folder opens where it is
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos')
    [void](WaitFor { (Rows) -ge 1 -and (& $foundCount) -eq $everywhere })
    SelectRow 0
    Check ([bool](WaitFor { (WindowText ([Native.Win]::FindDescendants($main, 'Static') | Where-Object { (WindowText $_) -match 'From:' } | Select-Object -First 1)) -match 'Subject:' } 10)) 'a result is shown in the reading pane'
    # Clear search on the search bar ends it
    Click $main $IDC_SEARCH_CLEAR
    Check ([bool](WaitFor { (Rows) -eq $all -and (WindowText $find) -eq '' -and -not (Visible $main $IDC_SEARCH_BAR) })) 'Clear search on the search bar ends the search'
    # and so does Esc, back in the folder
    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'photos')
    [void](WaitFor { (Rows) -ge 1 -and (& $foundCount) -eq $everywhere })
    Key $find $VK_ESCAPE
    Check ([bool](WaitFor { (Rows) -eq $all -and (& $columns) -eq $FOLDER_COLUMNS })) 'Esc ends the search: the folder again, without the Folder column'

    # ---- files ----

    Step 'words without spaces'
    # SCENARIO 21a: words of Japanese, Chinese and Korean, which have no spaces between them (or endings on them), found
    # inside the subject; in a folder of their own, deleted at the end
    [void](Invoke-RestMethod -Method Post -ContentType 'application/json' -Body '{"path":"CJK"}' "$rest")
    AddMessage ("From: Lee <lee@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: =?UTF-8?B?5piO5pel44Gu5Lya6K2w44Gu6LOH5paZ44Gr44Gk44GE44Gm?=`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <cjk-ja@example.com>`r`nContent-Type: text/plain; charset=utf-8`r`n" +
        "Content-Transfer-Encoding: base64`r`n`r`n5Lya6K2w44Gu6LOH5paZ44KS5re75LuY44GX44G+44GZ44CC`r`n") @() 'CJK'
    AddMessage ("From: Lee <lee@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: =?UTF-8?B?5YWz5LqO5piO5aSp5Lya6K6u55qE5a6J5o6S?=`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <cjk-zh@example.com>`r`nContent-Type: text/plain; charset=utf-8`r`n" +
        "Content-Transfer-Encoding: base64`r`n`r`n6K+35p+l55yL5Lya6K6u5a6J5o6S44CC`r`n") @() 'CJK'
    AddMessage ("From: Lee <lee@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: =?UTF-8?B?64K07J28IO2ajOydmOyXkOyEnCDrsJztkZztlaAg7J6Q66OM?=`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <cjk-ko@example.com>`r`nContent-Type: text/plain; charset=utf-8`r`n" +
        "Content-Transfer-Encoding: base64`r`n`r`n7ZqM7J2YIOyekOujjOyeheuLiOuLpC4=`r`n") @() 'CJK'
    Command $main $IDM_SYNC
    # the words as base64 of their UTF-8: this script is read as ANSI by Windows PowerShell, which garbles them
    $cjkFound = { param($words) [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($words))); [bool](WaitFor { (Rows) -eq 1 } 20) }
    Check (& $cjkFound '5Lya6K2w') 'a Japanese word inside the subject finds its message'
    SelectRow 0
    Shot $main 'find-4-cjk'
    Check (& $cjkFound '5Lya6K6u') 'a Chinese word inside the subject finds its message'
    Check (& $cjkFound '7ZqM7J2Y') 'a Korean word with its ending left off finds its message'
    Check (& $cjkFound '6K2w') 'one character alone finds it too'
    Key $find $VK_ESCAPE
    [void](Invoke-RestMethod -Method Delete "$rest/CJK")
    Command $main $IDM_SYNC
    # gone from the tree before the next step picks a folder and a row, which its reload would take away
    [void](WaitFor { (FolderItem 'CJK') -eq [IntPtr]::Zero } 20)
    Settled

    Step 'saving and importing a message as a file'
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 7) { Rows } })
    # Carol's reply, the last row (the oldest)
    SelectRow ((Rows) - 1)
    $eml = Join-Path (Resolve-Path $Out) 'saved-message.eml'
    Remove-Item -Force -ErrorAction SilentlyContinue $eml
    Command $main $IDM_SAVE_AS
    Check (AnswerFileDialog 'Save Message As' $eml 'files-1-save-as' 'Re*Lunch on Friday*') 'Save As asks where, with the subject as the name'
    Check ([bool](WaitFor { (Test-Path $eml) -and (Get-Content -Raw $eml) -match 'Subject: Re: Lunch on Friday' } 10)) 'and saves the message as it came'
    SelectFolder 3
    Command $main $IDM_IMPORT
    Check (AnswerFileDialog 'Import Messages' $eml 'files-2-import') 'Import Messages asks for files'
    Check ($null -ne (WaitFor { Find 'Archive' 'Subject: Re: Lunch on Friday' } 20)) 'and puts the message in the folder, on the server'
    SelectFolder 0

    # ---- flag, delete, move ----

    Step 'flagging, deleting and moving'
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 7) { Rows } })
    # the newest message, "One more thing"
    SelectRow 0
    Check (-not (Visible $main $IDC_PICTURES)) 'a plain text message does not offer Download pictures'
    Command $main $IDM_FLAG
    Check ([bool](WaitFor { (Find 'INBOX' 'Subject: One more thing').flags -contains '\Flagged' })) 'Flag Message flags it on the server'
    Shot $main 'organize-1-flagged'
    $listed = Rows
    Command $main $IDM_DELETE
    Check ($null -ne (WaitFor { Find 'Trash' 'Subject: One more thing' } 20)) 'Delete puts it in Deleted Items'
    Check ($null -eq (Find 'INBOX' 'Subject: One more thing')) 'and takes it out of the Inbox'
    Check ([bool](WaitFor { (Rows) -eq $listed - 1 })) 'the list has one less'
    # the next one is selected, and shown: move it to Archive through the dialog
    $selected = WaitFor { $s = SelectedRow; if ($s -ge 0 -and (Shown)) { "$s" } } 10
    $next = if ($null -ne $selected) { [Native.Win]::RemoteListText($list, [int]$selected, $COL_SUBJECT) } else { '' }
    Check ($next -ne '') "after Delete the next message is selected and shown ($next)"
    Command $main $IDM_MOVE
    $move = WaitPicker 'Move Message'
    Check ($null -ne $move) 'Move to Folder asks where'
    if ($move) {
        Check (PickIn $move 'inboxclassic.test' 'Archive') 'Archive can be chosen'
        Shot $move 'organize-2-move'
        Click $move 1
        # the one selected after the delete, the newest left
        Check ($null -ne (WaitFor { Find 'Archive' "Subject: $next" } 20)) "the selected message is in Archive ($next)"
        Check ([bool](WaitFor { (Rows) -eq $listed - 2 })) 'and out of the list'
    }
    Shot $main 'organize-3-after'
    # from Deleted Items it is gone for good, after asking
    SelectFolder 5
    [void](WaitFor { if ((Rows) -ge 1) { Rows } })
    SelectRow 0
    Command $main $IDM_DELETE
    $sure = BoxOf $main 10
    Check ($null -ne $sure) 'deleting for good asks first'
    if ($sure) {
        Shot $sure 'organize-4-for-good'
        Click $sure 6
    }
    Check ([bool](WaitFor { -not (Find 'Trash' 'Subject: One more thing') } 20)) 'and then it is gone from the server'
    SelectFolder 0


    Step 'the Flagged folder'
    $flaggedRow = @(TreeTexts ([Native.Win]::GetDlgItem($main, $IDC_TREE)) | Where-Object { $_ -like 'Flagged*' })
    $topRows = @(ChildRows ([IntPtr]::Zero) | ForEach-Object { Bare $_ })
    Check ($flaggedRow.Count -eq 1 -and $topRows[0] -eq 'Inbox' -and $topRows[1] -eq 'Flagged') "Flagged is in the folder list right under the Inbox ($($topRows -join ', '))"
    # opened, it lists as many messages as it counts, with the Folder column's names
    $flaggedCount = if ($flaggedRow.Count -eq 1 -and $flaggedRow[0] -match '\((\d+)\)') { [int]$Matches[1] } else { 0 }
    $flaggedItem = NamedRow ([IntPtr]::Zero) 'Flagged'
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $flaggedItem)
    Check ([bool](WaitFor { (Rows) -gt 0 -and (Rows) -eq $flaggedCount } 15)) "Flagged lists the flagged messages of every folder ($(Rows) of $flaggedCount)"
    Shot $main 'main-10-flagged'
    SelectFolder 0

    Step 'a folder opens with a message'
    # Fresh, a folder of its own, has never been opened; its newest message is not its first or last by UID
    [void](Invoke-RestMethod -Method Post -ContentType 'application/json' -Body '{"path":"Fresh"}' "$rest")
    foreach ($fresh in @(@(1, -300), @(2, -100), @(3, -200))) {
        $date = [DateTime]::UtcNow.AddMinutes($fresh[1]).ToString('r')
        AddMessage ("From: Fresh Sender <fresh@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Fresh $($fresh[0])`r`n" +
            "Date: $date`r`nMessage-ID: <fresh-$($fresh[0])@example.com>`r`n`r`nA fresh one.`r`n") @() 'Fresh'
    }
    Command $main $IDM_SYNC
    $freshItem = WaitFor { $item = FolderItem 'Fresh'; if ($item -ne [IntPtr]::Zero) { $item } } 30
    # the subject of the row selected once the list is drawn and the reading pane shows its message
    $openedSubject = {
        $row = WaitFor { $s = SelectedRow; if ($s -ge 0 -and (Shown)) { "$s" } } 20
        if ($null -ne $row) { [Native.Win]::RemoteListText($list, [int]$row, $COL_SUBJECT) } else { '' }
    }
    SelectFolder 0
    [void](WaitFor { (Rows) -ge 2 })
    SelectRow 1
    $leftSubject = [Native.Win]::RemoteListText($list, 1, $COL_SUBJECT)
    if ($freshItem) { [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $freshItem); Settled }
    $freshSubject = & $openedSubject
    Check ($freshSubject -eq 'Fresh 2') "a folder come to for the first time selects and shows its newest message ($freshSubject)"
    SelectFolder 0
    $backSubject = & $openedSubject
    Check ($leftSubject -ne '' -and $backSubject -eq $leftSubject) "back in the Inbox, the message shown when it was left is selected and shown ($backSubject, left $leftSubject)"
    Shot $main 'folder-1-reopen'
    # a list read again keeps its place: its top shown, scrolled to its end, then mail comes
    foreach ($n in 4..43) {
        AddMessage ("From: Fresh Sender <fresh@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Fresh $n`r`n" +
            "Date: $([DateTime]::UtcNow.AddMinutes(-1000 - $n).ToString('r'))`r`nMessage-ID: <fresh-$n@example.com>`r`n`r`nA fresh one.`r`n") @() 'Fresh'
    }
    Command $main $IDM_SYNC
    if ($freshItem) { [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $freshItem); Settled }
    [void](WaitFor { (Rows) -eq 43 } 30)
    SelectRow 0
    [void][Native.Win]::SendMessage($list, 0x1013, [IntPtr]42, [IntPtr]0)
    AddMessage ("From: Fresh Sender <fresh@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Fresh newest`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <fresh-newest@example.com>`r`n`r`nThe newest.`r`n") @() 'Fresh'
    Command $main $IDM_SYNC
    $grew = [bool](WaitFor { (Rows) -eq 44 } 30)
    Settled
    Start-Sleep -Milliseconds 500
    $selectedNow = SelectedRow
    $inSight = $selectedNow -ge 0 -and [int][Native.Win]::SendMessage($list, 0x10B6, [IntPtr]$selectedNow, [IntPtr]::Zero) -ne 0
    Check ($grew -and -not $inSight) 'a list read again as mail came stays where it was scrolled, not at the message shown'
    [void](Invoke-RestMethod -Method Delete "$rest/Fresh")
    Command $main $IDM_SYNC
    [void](WaitFor { (FolderItem 'Fresh') -eq [IntPtr]::Zero } 20)
    Step 'unsubscribing'
    # the list's server: a socket of the test, answered by hand
    $listServer = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback, 0)
    $listServer.Start()
    $listPort = $listServer.LocalEndpoint.Port
    $accepted = $listServer.AcceptTcpClientAsync()
    $listRaw = "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=list.example.com`r`n" +
        "DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; b=y`r`n" +
        "From: Weekly List <news@list.example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Weekly list news`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <weekly-list@list.example.com>`r`n" +
        "List-Unsubscribe: <mailto:leave@list.example.com>, <http://127.0.0.1:$listPort/u/42>`r`n" +
        "List-Unsubscribe-Post: List-Unsubscribe=One-Click`r`n`r`nThis week on the list.`r`n"
    AddMessage $listRaw
    Command $main $IDM_SYNC
    SelectFolder 0
    $findBox = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Weekly list news') } 20)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Weekly list news"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    SelectRow 0
    $IDC_UNSUBSCRIBE = 210; $IDC_LIST_BAR = 957; $IDM_UNSUBSCRIBE = 178
    Check ([bool](WaitFor { Visible $main $IDC_LIST_BAR } 15)) 'a message of a mailing list has the mailing-list bar over its text'
    $barText = GetText $main $IDC_LIST_BAR
    $offer = GetText $main $IDC_UNSUBSCRIBE
    Check ($barText -match '\(list\.example\.com\)' -and $offer -eq $en['ui-unsubscribe-ask'] -and (Visible $main $IDC_UNSUBSCRIBE)) "it names the list by its domain and offers Unsubscribe... ($barText, $offer)"
    $header = (Statics $main)
    Check ($header -notmatch '(?m)^Unsubscribe$') 'the header has no Unsubscribe link'
    # the Message menu as it opens (the fifth)
    $messageMenu = [Native.Win]::GetSubMenu([Native.Win]::GetMenu($main), 4)
    [void][Native.Win]::SendMessage($main, 0x0117, $messageMenu, [IntPtr]4)
    Check ((([Native.Win]::GetMenuState($messageMenu, $IDM_UNSUBSCRIBE, 0) -band 0x3) -eq 0)) 'Message > Unsubscribe from List is on for it'
    Shot $main 'read-8-unsubscribe'
    [void][Native.Win]::PostMessage($main, $WM_COMMAND, [IntPtr]$IDC_UNSUBSCRIBE, [Native.Win]::GetDlgItem($main, $IDC_UNSUBSCRIBE))
    $sure = WaitWindow '#32770' 'Unsubscribe' 10
    Check ($null -ne $sure -and (Statics $sure) -match '127\.0\.0\.1') "it asks first, naming where it goes ($(if ($sure) { Statics $sure }))"
    if ($sure) {
        Shot $sure 'read-9-unsubscribe-ask'
        Click $sure 7
    }
    Start-Sleep -Milliseconds 1000
    Check (-not $accepted.IsCompleted -and (GetText $main $IDC_UNSUBSCRIBE) -eq $en['ui-unsubscribe-ask']) 'Cancel asks the list nothing'
    [void][Native.Win]::PostMessage($main, $WM_COMMAND, [IntPtr]$IDM_UNSUBSCRIBE, [IntPtr]::Zero)
    $sure = WaitWindow '#32770' 'Unsubscribe' 10
    if ($sure) { Click $sure 6 }
    # the POST of RFC 8058, answered 200
    $sent = ''
    if ($accepted.Wait(15000)) {
        $client = $accepted.Result
        $stream = $client.GetStream()
        $stream.ReadTimeout = 5000
        $buffer = New-Object byte[] 4096
        while ($sent -notmatch 'One-Click') {
            $read = $stream.Read($buffer, 0, $buffer.Length)
            if ($read -le 0) { break }
            $sent += [Text.Encoding]::ASCII.GetString($buffer, 0, $read)
        }
        $answer = [Text.Encoding]::ASCII.GetBytes("HTTP/1.0 200 OK`r`nContent-Length: 2`r`n`r`nok")
        $stream.Write($answer, 0, $answer.Length)
        $client.Close()
    }
    $listServer.Stop()
    Check ($sent -match '^POST /u/42 ' -and $sent -match 'List-Unsubscribe=One-Click') "Unsubscribe posts List-Unsubscribe=One-Click to the list ($(($sent -split "`r`n")[0]))"
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'The mailing list has accepted the unsubscribe request' } 10)) "and the status bar says it is done ($(StatusPart $mainStatus 0))"
    $asked = [bool](WaitFor { (GetText $main $IDC_LIST_BAR).Trim() -match (Pattern $en['ui-list-bar-asked']) -and -not (Visible $main $IDC_UNSUBSCRIBE) } 10)
    Check $asked "the bar then says when the list was asked, without a button ($(GetText $main $IDC_LIST_BAR))"
    [void][Native.Win]::SendMessage($main, 0x0117, $messageMenu, [IntPtr]4)
    Check ((([Native.Win]::GetMenuState($messageMenu, $IDM_UNSUBSCRIBE, 0) -band 0x3) -ne 0)) 'and Unsubscribe from List is off'
    Shot $main 'read-9b-unsubscribe-asked'
    # another message of the list that the server got three days later, with a picture on the internet: the list did
    # not stop
    AddMessage ("Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=list.example.com`r`n" +
        "DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:subject:list-unsubscribe:list-unsubscribe-post; bh=x; b=y`r`n" +
        "From: Weekly List <news@list.example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Weekly list news again`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <weekly-list-2@list.example.com>`r`n" +
        "List-Unsubscribe: <mailto:leave@list.example.com>, <http://127.0.0.1:$listPort/u/42>`r`n" +
        "List-Unsubscribe-Post: List-Unsubscribe=One-Click`r`nContent-Type: text/html`r`n`r`n" +
        "<p>Still here.</p><img src=`"https://pictures.example.com/news.png`" width=`"10`" height=`"10`">`r`n") @() 'INBOX' $rest ([DateTime]::UtcNow.AddDays(3))
    Command $main $IDM_SYNC
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Weekly list news again') } 20)
    # the search before ended first, so its one row is not taken for the new search's
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')
    [void](WaitFor { (Rows) -gt 1 } 20)
    Settled
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Weekly list news again"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    Settled
    SelectRow 0
    $both = [bool](WaitFor { (Visible $main $IDC_LIST_BAR) -and (Visible $main $IDC_PICTURES) } 15)
    Check $both 'a list message with pictures blocked shows both bars'
    $picturesBox = New-Object Native.Win+RECT; $listBox = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($main, $IDC_PICTURES), [ref]$picturesBox)
    [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($main, $IDC_LIST_BAR), [ref]$listBox)
    Check ($picturesBox.Top -lt $listBox.Top) 'the pictures bar above the mailing-list bar'
    $barText = GetText $main $IDC_LIST_BAR
    Check ($barText.Trim() -match (Pattern $en['ui-list-bar-came-after']) -and (GetText $main $IDC_UNSUBSCRIBE) -eq $en['ui-unsubscribe-again']) "a message that came more than two days after the request offers Unsubscribe Again... ($barText)"
    Shot $main 'read-9c-two-bars'
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')

    Step 'a calendar invitation'
    # a point of the reading pane in a colour of the card, in screen pixels: the middle of the pixels of that colour
    # in the band where it is first found, from the top; $null when there is none
    $pane = [Native.Win]::FindDescendants($main, 'Chrome_RenderWidgetHostHWND') | Select-Object -First 1
    $cardPoint = {
        param([int]$r, [int]$g, [int]$b)
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 500
        $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($pane, [ref]$box)
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        $w = [Math]::Min(560, $box.Right - $box.Left); $h = [Math]::Min(320, $box.Bottom - $box.Top)
        if ($w -le 0 -or $h -le 0) { return $null }
        $picture = New-Object System.Drawing.Bitmap $w, $h
        CopyScreen $picture $box.Left $box.Top
        $first = -1; $xs = @(); $ys = @()
        for ($y = 0; $y -lt $h; $y++) {
            if ($first -ge 0 -and $y -gt $first + 14) { break }
            for ($x = 0; $x -lt $w; $x++) {
                $p = $picture.GetPixel($x, $y)
                if ([Math]::Abs($p.R - $r) -lt 28 -and [Math]::Abs($p.G - $g) -lt 28 -and [Math]::Abs($p.B - $b) -lt 28) {
                    if ($first -lt 0) { $first = $y }
                    $xs += $x; $ys += $y
                }
            }
        }
        if ($first -lt 0) { return $null }
        $xs = @($xs | Sort-Object); $ys = @($ys | Sort-Object)
        @(($box.Left + $xs[[int]($xs.Count / 2)]), ($box.Top + $ys[[int]($ys.Count / 2)]))
    }
    # words of the message shown found by Find in This Message
    $foundInMessage = {
        param([string]$words)
        (FindInShown $words) -gt 0
    }

    $invite = "From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Invitation: Quarterly planning`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <planning-invite@example.com>`r`n" +
        "Content-Type: multipart/mixed; boundary=inv`r`n`r`n--inv`r`nContent-Type: text/plain`r`n`r`nLet us plan the quarter.`r`n" +
        "--inv`r`nContent-Type: text/calendar; method=REQUEST; charset=utf-8`r`n`r`n" +
        "BEGIN:VCALENDAR`r`nMETHOD:REQUEST`r`nBEGIN:VEVENT`r`nUID:planning@example.com`r`nSUMMARY:Quarterly planning`r`n" +
        "DTSTART:20261201T100000Z`r`nDTEND:20261201T113000Z`r`nLOCATION:Room 2`r`nORGANIZER;CN=Ann Example:mailto:ann@example.com`r`n" +
        "ATTENDEE;CN=Test:mailto:testuser@inboxclassic.test`r`nRRULE:FREQ=WEEKLY;BYDAY=TU;COUNT=4`r`nEND:VEVENT`r`nEND:VCALENDAR`r`n--inv--`r`n"
    AddMessage $invite
    Command $main $IDM_SYNC
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Invitation: Quarterly planning') } 20)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Quarterly planning"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    SelectRow 0
    # the event is a card in the message, in the blue of the app's information (selected again while the search's
    # last reload may still take the selection away)
    Check ([bool](WaitFor { if ((SelectedRow) -ne 0) { SelectRow 0 }; $null -ne (& $cardPoint 15 95 179) } 15)) 'a message with an invitation shows the event in a card above the text'
    Shot $main 'read-10-invitation'
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')

    Step 'a brand logo (BIMI)'
    $logoSvg = '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny-ps" viewBox="0 0 100 100"><title>Brand</title>' +
        '<rect width="100" height="100" rx="22" fill="#0a5bd3"/><circle cx="50" cy="50" r="26" fill="#ffffff"/><circle cx="50" cy="50" r="13" fill="#0a5bd3"/></svg>'
    $indicator = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($logoSvg))
    $branded = "Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example`r`n" +
        "BIMI-Indicator: $indicator`r`nFrom: Brand <hello@brand.example>`r`nTo: testuser@inboxclassic.test`r`nSubject: News from the brand`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <brand-news@brand.example>`r`n`r`nOur news.`r`n"
    AddMessage $branded
    Command $main $IDM_SYNC
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: News from the brand') } 20)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"News from the brand"')
    [void](WaitFor { (Rows) -eq 1 } 20)
    $IDC_LOGO = 213
    # selected again while the search's last reload may still take the selection away
    Check ([bool](WaitFor { if ([int][Native.Win]::SendMessage($list, 0x100C, [IntPtr](-1), [IntPtr]2) -ne 0) { SelectRow 0 }; Visible $main $IDC_LOGO } 15)) 'a sender whose logo the server passed has it beside the header'
    Shot $main 'read-11-logo'
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')

    Step 'the folder list of one account'
    $TVM_GETITEMSTATE = 0x1127; $TVIS_BOLD = 0x10; $VK_LEFT = 0x25; $VK_RIGHT = 0x27
    $bold = { param($item) ([int][Native.Win]::SendMessage($tree, $TVM_GETITEMSTATE, $item, [IntPtr]$TVIS_BOLD) -band $TVIS_BOLD) -ne 0 }
    $topNames = { @(ChildRows ([IntPtr]::Zero) | ForEach-Object { Bare $_ }) }
    $serverFolders = { @(Invoke-RestMethod $rest) | ForEach-Object { $_.path } }
    # a folder kept in the Inbox on the server, as another client would make it
    [void](Invoke-RestMethod -Method Post -ContentType 'application/json' $rest -Body (@{ path = 'INBOX/Receipts'; subscribed = $true } | ConvertTo-Json))
    Command $main $IDM_SYNC
    [void](WaitFor { (& $topNames) -contains 'Receipts' } 20)
    $names = & $topNames
    Check ($names[0] -eq 'Inbox' -and $names[1] -eq 'Flagged' -and $names -contains 'Sent Items' -and $names -contains 'Archive') "the Inbox is the first row of the tree, Flagged the second, then the account's other folders ($($names -join ', '))"
    Check (-not ($names -contains 'inboxclassic.test') -and -not ($names -contains 'All Inboxes')) "there is no row for the account ($($names -join ', '))"
    $inboxRow = FolderItem 'Inbox'
    Check ($names[2] -eq 'Receipts' -and [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $inboxRow) -eq [IntPtr]::Zero) "the Inbox holds no folders: a folder the server keeps in the Inbox is listed a level up, after Flagged ($($names -join ', '))"
    Check ((& $bold $inboxRow) -eq ([Native.Win]::RemoteTreeText($tree, $inboxRow) -match '\(\d+\)$')) "the Inbox is bold while it counts unread mail ($([Native.Win]::RemoteTreeText($tree, $inboxRow)))"
    Check (-not (& $bold (NamedRow ([IntPtr]::Zero) 'Flagged'))) 'Flagged is never bold'
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $inboxRow)
    Check ([bool](WaitFor { (WindowText $main) -eq 'Inbox - Inbox Classic' } 10)) "the title names the Inbox alone ($(WindowText $main))"
    Shot $main 'folders-6-one-account'
    # the Inbox's right-click menu: the folder's, no account commands
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    $box = [Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $inboxRow.ToInt64())
    $at = @([int](($box.Left + $box.Right) / 2), [int](($box.Top + $box.Bottom) / 2))
    foreach ($button in @(0, 0x0008, 0x0010)) { [Native.Win]::Mouse($at[0], $at[1], $button) }
    $menu = WaitWindow '#32768' $null 10
    if (-not $menu) { Shot ([Native.Win]::GetDesktopWindow()) 'debug-inbox-menu-missing'; Write-Host "   (the Inbox row at $($at -join "," ))" }
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    $labels = if ($menu) { @([Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero))) } else { @() }
    Check (($labels -contains 'New Folder...') -and $labels[-1] -eq $en['ui-account-properties-of'] -and -not ($labels -contains 'Send and Receive')) "right-clicking the Inbox gives the folder's menu, ending with Account Properties, no other account commands ($($labels -join ', '))"
    if ($menu) {
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    # Flagged has no right-click menu: its messages are of every folder
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    $flaggedBox = [Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, (NamedRow ([IntPtr]::Zero) 'Flagged').ToInt64())
    $at = @([int](($flaggedBox.Left + $flaggedBox.Right) / 2), [int](($flaggedBox.Top + $flaggedBox.Bottom) / 2))
    foreach ($button in @(0, 0x0008, 0x0010)) { [Native.Win]::Mouse($at[0], $at[1], $button) }
    $menu = WaitWindow '#32768' $null 3
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    Check ($null -eq $menu -and [Native.Win]::RemoteTreeText($tree, [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]9, [IntPtr]::Zero)) -like 'Flagged*') "Flagged has no right-click menu: its messages are of every folder (the right-click selected $([Native.Win]::RemoteTreeText($tree, [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]9, [IntPtr]::Zero))))"
    if ($menu) {
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    # New Folder with Flagged selected: at the top
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, (NamedRow ([IntPtr]::Zero) 'Flagged'))
    Command $main $IDM_NEW_FOLDER
    $form = WaitFor {
        $f = [Native.Win]::FindWindow('InboxClassicForm', 'New Folder')
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 100) -ne [IntPtr]::Zero) { $f }
    }
    Check ($null -ne $form -and (Statics $form) -match 'top') "New Folder asks for a name, at the top ($(if ($form) { Statics $form }))"
    if ($form) {
        SetText $form 100 'Trips'
        Click $form 1
    }
    Check ([bool](WaitFor { (& $serverFolders) -contains 'Trips' } 20)) "New Folder with Flagged selected makes the folder at the top of the list ($((& $serverFolders) -join ', '))"
    Check ([bool](WaitFor { (& $topNames) -contains 'Trips' } 20)) "and it is a top row of the tree ($((& $topNames) -join ', '))"
    # the folders made here go again, for the steps after (ImapKit may keep listing Receipts)
    foreach ($path in @('Trips', 'INBOX/Receipts')) {
        [void](Invoke-RestMethod -Method Delete "$rest/$([uri]::EscapeDataString($path))")
    }
    Command $main $IDM_SYNC
    [void](WaitFor { -not ((& $topNames) -contains 'Trips') } 20)
    SelectFolder 0

    Step 'an AI agent'
    $IDC_AGENT_LEVEL = 600; $IDC_AGENT_PATH = 611; $IDC_AGENT_RECIPIENTS = 612; $IDC_AGENT_WARNING = 614; $IDC_AGENT_SEND = 615
    $IDC_AGENT_LISTS = 618; $IDC_AGENT_UNSUBSCRIBE = 619; $IDC_AGENT_DONT_UNSUBSCRIBE = 620
    $IDC_AGENTS_HOSTS = 631; $IDC_AGENTS_LOG = 634; $IDC_AGENTS_UNDO = 635; $BM_GETCHECK = 0x00F0; $BM_SETCHECK = 0x00F1
    $IDC_AGENTS_CLEAR = 636; $IDC_AGENTS_READS = 638; $IDC_AGENTS_READS_LABEL = 639
    $inboxBefore = @(Messages 'INBOX').Count
    # two mailing lists the agent asks to leave at the end, read already so the agent's unread two are the ones below;
    # signed by the list as the provider says, with the one-click way
    foreach ($mailing in @(@('Weekly Digest <digest@list.example.com>', 'Weekly digest: five things to read', 1),
                        @('Shop Offers <offers@list.example.com>', 'Monthly offers for you', 2))) {
        AddMessage ("Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=list.example.com`r`n" +
            "DKIM-Signature: v=1; d=list.example.com; s=s1; h=from:list-unsubscribe:list-unsubscribe-post; bh=x; b=y`r`n" +
            "From: $($mailing[0])`r`nTo: testuser@inboxclassic.test`r`nSubject: $($mailing[1])`r`n" +
            "Date: $([DateTime]::UtcNow.AddHours(-1).ToString('r'))`r`nMessage-ID: <list-$($mailing[2])@list.example.com>`r`n" +
            "List-Unsubscribe: <https://list.example.com/u/$($mailing[2])>`r`nList-Unsubscribe-Post: List-Unsubscribe=One-Click`r`n`r`n" +
            "This month on the list.`r`n") @('\Seen')
    }
    # two new messages for the agent to read, whatever the steps before left unread
    foreach ($new in @(@('Maria Lopez <maria@example.org>', 'Quarterly report draft', 'Here is the draft of the quarterly report. Comments by Thursday?'),
                       @('Sam Lee <sam@example.org>', 'Team lunch on Friday', 'Who is in for lunch on Friday at noon?'))) {
        AddMessage ("From: $($new[0])`r`nTo: testuser@inboxclassic.test`r`nSubject: $($new[1])`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`n" +
            "Message-ID: <$([guid]::NewGuid())@example.org>`r`n`r`n$($new[2])`r`n")
    }
    SelectFolder 0
    Command $main $IDM_SYNC
    # the messages the status bar counts: the rows are fewer where replies share a conversation's row
    [void](WaitFor { (StatusPart $mainStatus 2) -match '^(\d+) message' -and [int]$Matches[1] -ge $inboxBefore + 4 } 20)
    $unreadBefore = @(Messages 'INBOX' | Where-Object { $_.flags -notcontains '\Seen' }).Count
    Start-Sleep -Seconds 1
    Shot $main 'agents-1-before'
    # the agent: Node.js under a name of its own, as an agent host would be, starting the relay (--mcp)
    $agentOut = Join-Path $Out 'agent.jsonl'
    $agentExe = Join-Path $Out 'My AI agent.exe'
    Copy-Item -Force (Get-Command node).Source $agentExe
    $env:APP = (Resolve-Path $Exe).Path; $env:STORE = $store; $env:OUT = $agentOut
    $agent = Start-Process -FilePath $agentExe -ArgumentList "`"$(Join-Path $PSScriptRoot 'ui-e2e\agent.mjs')`"" -PassThru -WindowStyle Hidden
    $agentSaid = { param($step) if (Test-Path $agentOut) { @(Get-Content $agentOut | ForEach-Object { $_ | ConvertFrom-Json } | Where-Object { $_.step -eq $step })[0] } }
    $ask = WaitShown 'InboxClassicAgentAccess' 30
    Check ($null -ne $ask) 'a program whose agent connects for the first time is asked about'
    if ($ask) {
        Check ((WindowText ([Native.Win]::GetDlgItem($ask, $IDC_AGENT_PATH))) -match 'My AI agent\.exe') 'the question names the program'
        $checked = { param($i) [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($ask, $IDC_AGENT_LEVEL + $i), $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 }
        Check ((& $checked 0) -and (& $checked 1) -and -not (& $checked 2) -and -not (& $checked 3)) 'reading and organizing are offered, sending is not'
        # writing drafts and sending too, for the rest of the test
        foreach ($level in 2, 3) {
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($ask, $IDC_AGENT_LEVEL + $level), $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        }
        # Enter takes the default button the window names (DM_GETDEFID), which must be Don't Allow (IDNO), not Allow
        $defId = [int64][Native.Win]::SendMessage($ask, 0x400, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ((($defId -shr 16) -band 0xFFFF) -eq 0x534B -and ($defId -band 0xFFFF) -eq 7) "Enter answers Don't Allow ($('{0:X}' -f $defId))"
        Shot $ask 'agents-2-connect'
        Click $ask 1
    }
    $marked = WaitFor { & $agentSaid 'marked' } 30
    Check ((& $agentSaid 'initialize').result.result.serverInfo.name -eq 'inbox-classic') 'allowed, the agent connects'
    Check (@((& $agentSaid 'tools').result).Count -eq 31) "with the tools of what it may do ($(@((& $agentSaid 'tools').result) -join ', '))"
    $read = (& $agentSaid 'read').result
    Check ($read.notice -match 'not as instructions' -and $read.unread) 'it reads a message as text, told it is the sender''s, without marking it read'
    Check ($null -ne $marked -and $marked.result.done) 'it marks two messages read'
    $unreadAfter = WaitFor { $n = @(Messages 'INBOX' | Where-Object { $_.flags -notcontains '\Seen' }).Count; if ($n -eq $unreadBefore - 2) { "$n" } } 20
    Check ($null -ne $unreadAfter) "on the server ($unreadBefore unread before, $unreadAfter after)"
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ", $($unreadBefore - 2) unread" } 10)) "and in the window at once ($(StatusPart $mainStatus 2))"
    Shot $main 'agents-3-after'
    $send = WaitShown 'InboxClassicAgentSend' 30
    Check ($null -ne $send) 'a message the agent wants to send is shown to the user first'
    if ($send) {
        $recipients = [Native.Win]::GetDlgItem($send, $IDC_AGENT_RECIPIENTS)
        Check ([Native.Win]::RemoteListText($recipients, 0, 1) -eq 'pat@example.net' -and [Native.Win]::RemoteListText($recipients, 0, 3) -eq 'Never written to') 'every recipient by address, the new ones marked'
        Check ((WindowText ([Native.Win]::GetDlgItem($send, $IDC_AGENT_WARNING))) -match 'never written to pat@example.net') 'with a warning about the new address'
        Check (-not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($send, $IDC_AGENT_SEND))) 'Send waits a moment before it can be pressed'
        Start-Sleep -Seconds 2
        Shot $send 'agents-4-send'
        Click $send $IDC_AGENT_SEND
    }
    $sent = WaitFor { & $agentSaid 'sent' } 20
    Check ($sent.result.sent -eq $true) 'the agent learns the user said yes'
    Command $main $IDM_OUTBOX
    $outbox = WaitShown 'InboxClassicOutbox' 10
    if ($outbox) {
        $outboxList = [Native.Win]::GetDlgItem($outbox, 450)
        Check ([Native.Win]::RemoteListText($outboxList, 0, 3) -match (Pattern $en['ui-outbox-status-agent'])) 'it waits in the Outbox, where it can still be deleted'
        Shot $outbox 'agents-5-outbox'
        [void][Native.Win]::PostMessage($outbox, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($outbox) } 10)
    }
    Command $main $IDM_AI_AGENTS
    $agents = WaitShown 'InboxClassicAgents' 10
    Check ($null -ne $agents) 'Tools > AI Agents opens'
    if ($agents) {
        $hosts = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_HOSTS)
        $log = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_LOG)
        Check ([Native.Win]::RemoteListText($hosts, 0, 0) -eq 'My AI agent' -and [Native.Win]::RemoteListText($hosts, 0, 1) -match '^Read, organize, write drafts and send with your yes') "it lists the program and what it may do ($([Native.Win]::RemoteListText($hosts, 0, 1)))"
        # what it may do is not cut off: its column as wide as its words, and no scroll bar sideways
        $access = [Native.Win]::RemoteListText($hosts, 0, 1)
        $hostFont = [System.Drawing.Font]::FromHfont([Native.Win]::SendMessage($hosts, 0x0031, [IntPtr]::Zero, [IntPtr]::Zero))
        $needed = [System.Windows.Forms.TextRenderer]::MeasureText($access, $hostFont).Width
        $accessShown = [int][Native.Win]::SendMessage($hosts, 0x101D, [IntPtr]1, [IntPtr]::Zero)
        Check ($accessShown -ge $needed + 6 -and -not ([Native.Win]::GetWindowLong($hosts, -16) -band 0x00100000)) "what it may do is shown whole ($accessShown for $needed)"
        $logged = { param($row) [Native.Win]::RemoteListText($log, $row, 2) }
        # after the send the agent saved a draft (opened below)
        [void](WaitFor { (& $logged 0) -match (Pattern $en['agent-log-draft']) } 20)
        Check ((& $logged 0) -match (Pattern $en['agent-log-draft'] @{ subject = 'Agenda for Friday' }) -and
               (& $logged 1) -match (Pattern $en['agent-log-sent'] @{ subject = 'Lunch on Friday?'; to = 'pat@example.net' }) -and (& $logged 4) -match (Pattern $en['agent-log-read'])) "and what its agent did, newest first ($(@(0..4 | ForEach-Object { & $logged $_ }) -join '; '))"
        # the colour of a flag and a conversation watched, by the agent
        Check ((& $logged 2) -match "^Watched the conversation $([char]0x201C)" -and (& $logged 3) -match "^Flagged $([char]0x201C).+$([char]0x201D) blue$") "a flag's colour and a watched conversation are listed ($(& $logged 2); $(& $logged 3))"
        $IDC_AGENTS_SETUP = 637
        Check (PushButton $agents $IDC_AGENTS_SETUP) 'How to Connect an Agent is a push button'
        Shot $agents 'agents-6-window'
        # the message sent selected (the row under the draft): Undo takes it out of the Outbox before it goes
        Key $log $VK_HOME
        Key $log $VK_DOWN
        Start-Sleep -Milliseconds 300
        Click $agents $IDC_AGENTS_UNDO
        $takenBack = { @(0..3 | ForEach-Object { & $logged $_ }) -match 'taken back' }
        Check ([bool](WaitFor { & $takenBack } 10)) "Undo takes the message back ($(& $takenBack))"
        # what the agent read: one row for the program's hour, under what it did then; selected, the list under the log
        # shows each read with its time: the subjects, never what the messages say
        $reads = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_READS)
        $readsLabel = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_READS_LABEL)
        Check ((WindowText $readsLabel) -match (Pattern $en['win-agent-reads-hint']) -and (ListCount $reads) -eq 0) "with another row selected, the list under the log says to select a row of reads ($(WindowText $readsLabel))"
        $rows = @(0..([Math]::Max(0, (ListCount $log) - 1)) | ForEach-Object { & $logged $_ })
        $readsRow = [Array]::FindIndex([string[]]$rows, [Predicate[string]] { param($r) $r -match '^Read \d+ messages?\b' })
        Check ($readsRow -gt 4 -and $rows[$readsRow] -match 'looked at (a )?message lists?') "what it read is one row, under what it did after ($($rows -join '; '))"
        if ($readsRow -ge 0) {
            Key $log $VK_HOME
            for ($i = 0; $i -lt $readsRow; $i++) { Key $log $VK_DOWN }
            $readTexts = WaitFor { if ((ListCount $reads) -gt 0) { , @(0..((ListCount $reads) - 1) | ForEach-Object { [Native.Win]::RemoteListText($reads, $_, 1) }) } } 10
            $readOf = @('Quarterly report draft', 'Team lunch on Friday' | ForEach-Object { (Pattern $en['agent-read-message'] @{ subject = $_ }) + '$' }) -join '|'
            $lookedAt = @('agent-read-list[one]', 'agent-read-list[*]' | ForEach-Object { Pattern $en[$_] }) -join '|'
            Check (@($readTexts) -match $readOf -and @($readTexts) -match $lookedAt) "selected, the list under it shows each read: the subject, the message list ($($readTexts -join '; '))"
            Check (-not (@($readTexts) -match 'Comments by Thursday|Who is in for lunch')) 'never what a message says'
            Check ((WindowText $readsLabel) -match ((Pattern $en['win-agent-reads']) + '$')) "over it, the hour it covers ($(WindowText $readsLabel))"
            Check (-not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($agents, $IDC_AGENTS_UNDO))) 'reading can not be undone'
            Shot $agents 'agents-9-reads'
        }
        [void][Native.Win]::PostMessage($agents, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($agents) } 10)
    }
    Command $main $IDM_OUTBOX
    $outbox = WaitShown 'InboxClassicOutbox' 10
    if ($outbox) {
        Check ((ListCount ([Native.Win]::GetDlgItem($outbox, 450))) -eq 0) 'and the Outbox is empty'
        [void][Native.Win]::PostMessage($outbox, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($outbox) } 10)
    }
    # the draft the agent wrote in Markdown, opened from Drafts: the window says which agent wrote it
    $IDC_COMPOSE_AGENT_NOTE = 354
    $agentDraft = & $agentSaid 'draft'
    Check ($null -ne $agentDraft -and $agentDraft.result.draft_id) "the agent writes a draft in Markdown ($($agentDraft | ConvertTo-Json -Compress -Depth 6))"
    $draftSource = WaitFor { $d = Find 'Drafts' 'Subject: Agenda for Friday'; if ($d) { RawText $d } } 30
    Check ($draftSource -match '<strong>Agenda</strong>' -and $draftSource -match '<li>lunch</li>' -and $draftSource -match '<li>the plan</li>') 'its Markdown is formatted: Agenda in bold and a list'
    SelectFolder 2
    $agentRow = WaitFor { $r = @(SubjectRows 'Agenda for Friday'); if ($r.Count -eq 1) { "$($r[0])" } } 30
    Check ($null -ne $agentRow) 'the agent''s draft is in Drafts'
    if ($null -ne $agentRow) {
        SelectRow ([int]$agentRow)
        $compose = WaitCompose { Key $list $VK_RETURN }
        Check ($null -ne $compose) 'opening it opens a compose window'
        if ($compose) {
            $note = GetText $compose $IDC_COMPOSE_AGENT_NOTE
            Check ((Visible $compose $IDC_COMPOSE_AGENT_NOTE) -and $note -match '^My AI agent, an AI agent, wrote this draft\.' -and $note -match 'Check the recipients and the text') "it says which agent wrote it and asks to check the recipients and the text ($note)"
            # under the fields and over the format bar, as wide as the fields
            $noteBox = New-Object Native.Win+RECT; $subjectBox = New-Object Native.Win+RECT
            [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($compose, $IDC_COMPOSE_AGENT_NOTE), [ref]$noteBox)
            [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($compose, $IDC_SUBJECT), [ref]$subjectBox)
            Check ($noteBox.Top -ge $subjectBox.Bottom -and $noteBox.Right -eq $subjectBox.Right) "under the fields ($($noteBox.Top) >= $($subjectBox.Bottom))"
            Check ((GetText $compose $IDC_SUBJECT) -eq 'Agenda for Friday' -and (GetText $compose $IDC_TO) -like '*pat@example.net*') 'with the subject and recipient the agent wrote'
            Start-Sleep -Milliseconds 800
            Shot $compose 'agents-8-draft'
            # in a narrow window the line wraps, taller, the editor still under it
            $noteHeight = $noteBox.Bottom - $noteBox.Top
            $wide = New-Object Native.Win+RECT
            [void][Native.Win]::GetWindowRect($compose, [ref]$wide)
            [void][Native.Win]::SetWindowPos($compose, [IntPtr]::Zero, 0, 0, 440, $wide.Bottom - $wide.Top, 0x16)
            Start-Sleep -Milliseconds 800
            [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($compose, $IDC_COMPOSE_AGENT_NOTE), [ref]$noteBox)
            $editorBox = New-Object Native.Win+RECT
            [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($compose, $IDC_BODY), [ref]$editorBox)
            Check (($noteBox.Bottom - $noteBox.Top) -gt $noteHeight -and $editorBox.Top -gt $noteBox.Bottom) "in a narrow window the line wraps over the text ($noteHeight to $($noteBox.Bottom - $noteBox.Top), the text from $($editorBox.Top))"
            Shot $compose 'agents-8b-draft-narrow'
            [void][Native.Win]::SetWindowPos($compose, [IntPtr]::Zero, 0, 0, $wide.Right - $wide.Left, $wide.Bottom - $wide.Top, 0x16)
            # closed without saving: the draft stays the agent's
            Check (CloseCompose $compose) 'closed without saving'
            Start-Sleep -Seconds 1
            $kept = Find 'Drafts' 'Subject: Agenda for Friday'
            Check ($kept -and (RawText $kept) -eq $draftSource -and $draftSource -match 'X-Inbox-Classic-Agent: My AI agent') 'the draft stays the agent''s, unchanged'
        }
    }
    # the draft stays in Drafts: the steps in German and in the pseudo-language open it again (they start the app
    # again without the passwords, so from what this one keeps)
    SelectFolder 0
    # the agent's go: it asks to leave the two mailing lists added above
    Set-Content -Path "$agentOut.unsubscribe" -Value ''
    $leave = WaitShown 'InboxClassicAgentUnsubscribe' 30
    Check ($null -ne $leave) 'the agent asks to unsubscribe from two mailing lists'
    if ($leave) {
        $heading = Statics $leave
        Check ($heading -match 'My AI agent wants to unsubscribe you from 2 mailing lists') "one question names the program and the count ($heading)"
        $lists = [Native.Win]::GetDlgItem($leave, $IDC_AGENT_LISTS)
        $listed = @(0..1 | ForEach-Object { "$([Native.Win]::RemoteListText($lists, $_, 0))|$([Native.Win]::RemoteListText($lists, $_, 1))|$([Native.Win]::RemoteListText($lists, $_, 3))" })
        Check ((ListCount $lists) -eq 2 -and ($listed -join ';') -match 'digest@list\.example\.com' -and ($listed -join ';') -match 'offers@list\.example\.com' -and
               @($listed | Where-Object { $_ -match "$([char]0x2192) list\.example\.com$" }).Count -eq 2) "it lists both senders and where the requests go ($($listed -join '; '))"
        # the address first and alone in its column, the name beside it, so a name can not hide who it is; the column
        # wide enough for the whole address
        $addressShown = [int][Native.Win]::SendMessage($lists, 0x101D, [IntPtr]0, [IntPtr]::Zero)
        Check ((@($listed | Where-Object { $_ -match '^digest@list\.example\.com\|Weekly Digest\|' -or $_ -match '^offers@list\.example\.com\|Shop Offers\|' }).Count -eq 2) -and $addressShown -ge 200) "each list shows its address whole, first, and the name apart ($($listed -join '; '); $addressShown)"
        # every column fits: no scroll bar sideways for lists of ordinary addresses
        Check (-not ([Native.Win]::GetWindowLong($lists, -16) -band 0x00100000)) 'the columns fit the list, with no scroll bar sideways'
        Check (-not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($leave, $IDC_AGENT_UNSUBSCRIBE))) 'Unsubscribe waits a moment before it can be pressed'
        Start-Sleep -Seconds 2
        # another window in front and back again, as a question raised while the app is behind: the safe answer keeps
        # the keyboard (the picture brings the question to the front)
        $taskbar = [Native.Win]::FindWindow('Shell_TrayWnd', [NullString]::Value)
        if ($taskbar -ne [IntPtr]::Zero) { [void][Native.Win]::SetForegroundWindow($taskbar); Start-Sleep -Milliseconds 500 }
        Shot $leave 'agents-7-unsubscribe'
        $dontButton = [Native.Win]::GetDlgItem($leave, $IDC_AGENT_DONT_UNSUBSCRIBE)
        Check ([bool](WaitFor { [Native.Win]::FocusOf($leave) -eq $dontButton } 5)) "back in front, Don't Unsubscribe has the keyboard ($([Native.Win]::FocusOf($leave)) $dontButton)"
        $defId = [int64][Native.Win]::SendMessage($leave, 0x400, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ((($defId -shr 16) -band 0xFFFF) -eq 0x534B -and ($defId -band 0xFFFF) -eq $IDC_AGENT_DONT_UNSUBSCRIBE) "Don't Unsubscribe is the default ($('{0:X}' -f $defId))"
        # Enter where the keyboard is
        $focused = [Native.Win]::FocusOf($leave)
        Key $(if ($focused -ne [IntPtr]::Zero) { $focused } else { $leave }) 0x0D
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($leave) } 10)) 'Enter answers it'
    }
    $unsubscribed = WaitFor { & $agentSaid 'unsubscribe' } 20
    Check ($null -ne $unsubscribed -and $unsubscribed.result.unsubscribed -eq $false) "the agent learns the user said no ($($unsubscribed | ConvertTo-Json -Compress -Depth 6))"
    Command $main $IDM_AI_AGENTS
    $agents = WaitShown 'InboxClassicAgents' 10
    if ($agents) {
        $log = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_LOG)
        $newest = [Native.Win]::RemoteListText($log, 0, 2)
        Check ($newest -match (Pattern $en['agent-log-unsubscribe-refused']) -and $newest -match 'digest@list\.example\.com' -and $newest -match 'offers@list\.example\.com') "and no list was asked ($newest)"
        Check (-not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($agents, $IDC_AGENTS_UNDO))) 'which can not be undone'
        [void][Native.Win]::PostMessage($agents, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($agents) } 10)
    }
    # the agent's next go: two newsletters it changes at once, and an invitation it answers
    $IDC_AGENT_COMPOSE = 616; $IDC_AGENT_DONT_SEND = 617; $IDC_AGENT_BODY = 613; $IDC_AGENT_INVITATION = 621
    $IDC_AGENTS_UNDO_SINCE = 640; $IDC_AGENT_UNDO_SPAN = 641; $IDC_AGENT_UNDO_TITLE = 642; $IDC_AGENT_UNDO_DETAIL = 643; $IDC_AGENT_TAKE_BACK = 644
    SelectFolder 0
    $countBefore = if ((StatusPart $mainStatus 2) -match '^(\d+) message') { [int]$Matches[1] } else { 0 }
    foreach ($n in 1, 2) {
        AddMessage ("From: Book Club <club@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: Club newsletter $n`r`n" +
            "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <club-$n@example.org>`r`n`r`nThe club's news, part $n.`r`n")
    }
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Invitation: Roadmap review`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <roadmap-review@example.com>`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: multipart/alternative; boundary=inv`r`n`r`n--inv`r`nContent-Type: text/plain`r`n`r`nLet us plan.`r`n" +
        "--inv`r`nContent-Type: text/calendar; method=REQUEST; charset=utf-8`r`n`r`n" +
        "BEGIN:VCALENDAR`r`nMETHOD:REQUEST`r`nBEGIN:VEVENT`r`nUID:roadmap-review@example.com`r`nSEQUENCE:0`r`nSUMMARY:Roadmap review`r`n" +
        "DTSTART:$([DateTime]::UtcNow.AddDays(7).ToString('yyyyMMdd'))T100000Z`r`nDTEND:$([DateTime]::UtcNow.AddDays(7).ToString('yyyyMMdd'))T110000Z`r`n" +
        "ORGANIZER;CN=Ann Example:mailto:ann@example.com`r`nATTENDEE;CN=Test;RSVP=TRUE;PARTSTAT=NEEDS-ACTION:mailto:testuser@inboxclassic.test`r`n" +
        "END:VEVENT`r`nEND:VCALENDAR`r`n--inv--`r`n")
    Command $main $IDM_SYNC
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Invitation: Roadmap review') -and @(Messages 'INBOX' | Where-Object { (RawText $_) -match 'Subject: Club newsletter' }).Count -eq 2 } 20)
    # in the app's store too, where the agent searches for them
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match '^(\d+) message' -and [int]$Matches[1] -ge $countBefore + 3 } 30)) "the newsletters and the invitation arrive ($(StatusPart $mainStatus 2))"
    $newsletters = { @(Messages 'INBOX' | Where-Object { (RawText $_) -match 'Subject: Club newsletter' }) }
    $newslettersRead = { $n = & $newsletters; $n.Count -eq 2 -and @($n | Where-Object { $_.flags -contains '\Seen' }).Count -eq 2 }
    $newslettersUnread = { $n = & $newsletters; $n.Count -eq 2 -and @($n | Where-Object { $_.flags -contains '\Seen' }).Count -eq 0 }
    Set-Content -Path "$agentOut.bulk" -Value ''
    # the answer to the invitation: the Send question says what it answers, over the text, and has no Edit First
    $send = WaitShown 'InboxClassicAgentSend' 30
    Check ($null -ne $send) 'the agent''s answer to an invitation is shown to the user first'
    if ($send) {
        $invitationLine = WindowText ([Native.Win]::GetDlgItem($send, $IDC_AGENT_INVITATION))
        Check ((Visible $send $IDC_AGENT_INVITATION) -and $invitationLine -match "^This message accepts the invitation $([char]0x201C)Roadmap review$([char]0x201D) \(.+\)\." -and
               $invitationLine -match 'once the mail server accepts the message') "a line says what it answers ($invitationLine)"
        $lineBox = New-Object Native.Win+RECT; $bodyBox = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($send, $IDC_AGENT_INVITATION), [ref]$lineBox)
        [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($send, $IDC_AGENT_BODY), [ref]$bodyBox)
        Check ($lineBox.Bottom -le $bodyBox.Top -and [Native.Win]::FitsOwnFont([Native.Win]::GetDlgItem($send, $IDC_AGENT_INVITATION), $invitationLine)) "above the text, whole ($($lineBox.Bottom) <= $($bodyBox.Top))"
        Check ([Native.Win]::GetDlgItem($send, $IDC_AGENT_COMPOSE) -eq [IntPtr]::Zero) 'it has no Edit First'
        $defId = [int64][Native.Win]::SendMessage($send, 0x400, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ((($defId -shr 16) -band 0xFFFF) -eq 0x534B -and ($defId -band 0xFFFF) -eq $IDC_AGENT_DONT_SEND) "Don't Send is the default ($('{0:X}' -f $defId))"
        Start-Sleep -Seconds 2
        Shot $send 'agents-13-invitation'
        Click $send $IDC_AGENT_SEND
    }
    $answered = WaitFor { & $agentSaid 'invitation-status' } 30
    Check ((& $agentSaid 'invitation').result.sent -eq $true) "the agent learns it was sent ($((& $agentSaid 'invitation') | ConvertTo-Json -Compress -Depth 6))"
    Check ($null -ne $answered -and $answered.result.your_status -eq 'needs-action') "the invitation's status is unchanged while the answer waits in the Outbox ($($answered | ConvertTo-Json -Compress -Depth 6))"
    # the change of many messages: a dry run that changes nothing, then the change, taken back by the agent, made again
    $again = WaitFor { & $agentSaid 'bulk-again' } 60
    $preview = (& $agentSaid 'bulk-preview').result
    Check ($preview.dry_run -eq $true -and $preview.matches -eq 2 -and $preview.token) "the agent's dry run counts the two newsletters ($($preview | ConvertTo-Json -Compress -Depth 6))"
    Check ((& $agentSaid 'bulk').result.changed -eq 2 -and (& $agentSaid 'bulk-undone').result.messages_taken_back -eq 2) "with its token it marks both read, and takes that back ($((& $agentSaid 'bulk-undone') | ConvertTo-Json -Compress -Depth 6))"
    Check ($null -ne $again -and $again.result.changed -eq 2 -and [bool](WaitFor { & $newslettersRead } 20)) "the second change marks both read on the server ($($again | ConvertTo-Json -Compress -Depth 6))"
    # the answer leaves the Outbox before Undo Since, which would take it out of there
    $reply = WaitFor { Find 'Sent' 'Subject: Accepted: Roadmap review' } 90
    Check ($null -ne $reply -and (RawText $reply) -match 'method=REPLY') 'the answer goes out with its calendar reply'
    Command $main $IDM_AI_AGENTS
    $agents = WaitShown 'InboxClassicAgents' 10
    Check ($null -ne $agents) 'Tools > AI Agents opens again'
    if ($agents) {
        $log = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_LOG)
        $logged = { param($row) [Native.Win]::RemoteListText($log, $row, 2) }
        # the catalog's words of the log's row of the change of the two newsletters, and of it taken back
        $bulkWords = $en['agent-log-bulk-read[other]']
        $bulkRow = (Pattern $bulkWords @{ count = 2; query = 'subject:"Club newsletter"' }) + '$'
        $bulkBack = (Pattern $en['agent-log-taken-back'].Replace('{ $entry }', $bulkWords) @{ count = 2; query = 'subject:"Club newsletter"' }) + '$'
        $anyBulkBack = (Pattern $en['agent-log-taken-back'].Replace('{ $entry }', $bulkWords) @{ count = 2 }) + '$'
        # newest first: the change made again, over the one the agent took back (a row of reads may be over both, its
        # hour still going)
        $topRows = { @(0..4 | ForEach-Object { & $logged $_ }) }
        [void](WaitFor { @(& $topRows) -match $bulkRow } 10)
        $rows = @(& $topRows)
        $bulkAt = [Array]::FindIndex([string[]]$rows, [Predicate[string]] { param($r) $r -match $bulkRow })
        Check ($bulkAt -ge 0 -and $bulkAt -le 1 -and $rows[$bulkAt + 1] -match $anyBulkBack) "the change of many messages is one row of the log ($($rows -join '; '))"
        Key $log $VK_HOME
        for ($i = 0; $i -lt $bulkAt; $i++) { Key $log $VK_DOWN }
        Start-Sleep -Milliseconds 300
        Check ([Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($agents, $IDC_AGENTS_UNDO))) 'with one Undo'
        Shot $agents 'agents-11-bulk'
        # Undo Since, for the program selected
        $hosts = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_HOSTS)
        [void][Native.Win]::SetForegroundWindow($agents)
        Key $hosts $VK_HOME
        Start-Sleep -Milliseconds 300
        Check ([Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($agents, $IDC_AGENTS_UNDO_SINCE))) 'Undo Since is there for the program selected'
        Click $agents $IDC_AGENTS_UNDO_SINCE
        $since = WaitShown 'InboxClassicAgentUndoSince' 10
        Check ($null -ne $since) 'Undo Since asks first'
        if ($since) {
            $span = [Native.Win]::GetDlgItem($since, $IDC_AGENT_UNDO_SPAN)
            $spans = [int][Native.Win]::SendMessage($span, 0x0146, [IntPtr]::Zero, [IntPtr]::Zero)
            Check ((Statics $since) -match (Pattern $en['ui-undo-since-span']) -and $spans -eq 6 -and (WindowText $span) -eq $en['agent-undo-span[quarter]']) "which span to take back, the shortest first ($spans; $(WindowText $span))"
            $title = WindowText ([Native.Win]::GetDlgItem($since, $IDC_AGENT_UNDO_TITLE))
            $asked = ((Pattern $en['agent-undo-since-question[*]'] @{ count = 'COUNT'; program = 'My AI agent' }) + '$').Replace('COUNT', '(\d+)')
            $count = if ($title -match $asked) { [int]$Matches[1] } else { 0 }
            Check ($count -ge 2 -and (WindowText ([Native.Win]::GetDlgItem($since, $IDC_AGENT_UNDO_DETAIL))) -match (Pattern $en['agent-undo-since-detail'])) "with the count of the changes and what taking back does ($title)"
            $defId = [int64][Native.Win]::SendMessage($since, 0x400, [IntPtr]::Zero, [IntPtr]::Zero)
            Check ((($defId -shr 16) -band 0xFFFF) -eq 0x534B -and ($defId -band 0xFFFF) -eq 2 -and (Visible $since $IDC_AGENT_TAKE_BACK)) "Take Back beside Cancel, the default ($('{0:X}' -f $defId))"
            $cut = @([Native.Win]::FindDescendants($since, 'Static') | Where-Object { $t = WindowText $_; $t -and -not [Native.Win]::FitsOwnFont($_, $t) } | ForEach-Object { WindowText $_ })
            Check ($cut.Count -eq 0) "nothing in it is cut off ($($cut -join ' | '))"
            Shot $since 'agents-12-undo-since'
            Click $since $IDC_AGENT_TAKE_BACK
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($since) } 10)) 'Take Back takes them back'
            # what it took back, in a message box of the window (GW_ENABLEDPOPUP): all it offered, as the answer that
            # already went is no longer offered
            $report = WaitFor { $w = [Native.Win]::GetWindow($agents, 6); if ($w -ne [IntPtr]::Zero -and $w -ne $agents) { $w } } 20
            $said = if ($report) { Statics $report } else { '' }
            Check ($said.Trim() -eq "Took back $count recorded changes, wholly or in part.") "and says what it took back ($said)"
            if ($report) { Shot $report 'agents-12b-undo-since-report'; [void][Native.Win]::PostMessage($report, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero) }
            [void](WaitFor { [Native.Win]::GetWindow($agents, 6) -eq $agents -or [Native.Win]::GetWindow($agents, 6) -eq [IntPtr]::Zero } 10)
            Check ([bool](WaitFor { @(& $topRows) -match $bulkBack } 10)) "the log shows the change taken back ($((& $topRows) -join '; '))"
            Check ([bool](WaitFor { & $newslettersUnread } 20)) 'and the newsletters are unread again'
            # asked again, nothing is left to take back: only Close
            Click $agents $IDC_AGENTS_UNDO_SINCE
            $again = WaitShown 'InboxClassicAgentUndoSince' 10
            if ($again) {
                $title = WindowText ([Native.Win]::GetDlgItem($again, $IDC_AGENT_UNDO_TITLE))
                Check ($title -eq 'My AI agent has no changes in this period that can be taken back.' -and -not (Visible $again $IDC_AGENT_TAKE_BACK) -and
                       (WindowText ([Native.Win]::GetDlgItem($again, 2))) -eq 'Close') "asked again, nothing is left to take back, only Close ($title)"
                Click $again 2
                [void](WaitFor { -not [Native.Win]::IsWindow($again) } 10)
            } else {
                Check $false 'Undo Since opens again'
            }
        }
        [void][Native.Win]::PostMessage($agents, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($agents) } 10)
    }
    # the newsletters and the invitation (whose answer in Sent makes it a conversation of two) out of the Inbox again,
    # so the steps after find its rows as before
    $added = @(Messages 'INBOX' | Where-Object { (RawText $_) -match 'Subject: (Club newsletter|Invitation: Roadmap review)' })
    foreach ($message in $added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($message.uid)") }
    Command $main $IDM_SYNC
    [void](WaitFor { -not @(Messages 'INBOX' | Where-Object { (RawText $_) -match 'Subject: (Club newsletter|Invitation: Roadmap review)' }).Count } 10)
    SelectFolder 0
    [void](WaitFor { (StatusPart $mainStatus 2) -match '^(\d+) message' -and [int]$Matches[1] -le $countBefore } 20)
    if ($agent -and -not $agent.HasExited) { $agent | Stop-Process -Force -ErrorAction SilentlyContinue }
    # the flag the agent set comes off again on the server, so the steps after count the Inbox's flags as before
    $agentFlagged = @(Messages 'INBOX' | Where-Object { $_.flags -contains '\Flagged' -and (RawText $_) -match 'Subject: Quarterly report draft' })
    if ($agentFlagged.Count) {
        [void](Invoke-RestMethod -Method Post -ContentType 'application/json' "$rest/INBOX/messages/flags" -Body (@{
            uids = @($agentFlagged | ForEach-Object { $_.uid }); flags = @('\Flagged', '$MailFlagBit2'); mode = 'remove' } | ConvertTo-Json))
        Command $main $IDM_SYNC
        [void](WaitFor { -not @(Messages 'INBOX' | Where-Object { $_.flags -contains '\Flagged' -and (RawText $_) -match 'Subject: Quarterly report draft' }).Count } 10)
    }

    # an agent started from a terminal: the relay's parent is the terminal's program (here a copy of Node.js under the
    # name of Windows Terminal's, `$terminal`.exe, running ui-e2e\terminal.mjs, which starts the relay as its child and
    # sends the first request; a copy of cmd.exe asked nothing on the CI runner), so every agent started there would
    # share one access. The question says so in the language in use, with how to give one an access of its own
    # (--name), nothing cut off (shot `$shot`; with `$pseudo` nothing left in English). Answered `$answer`: Don't Allow
    # (7), or closed (2), which decides nothing.
    function TerminalQuestion([string]$terminal, [string]$shot, [int]$answer, [bool]$pseudo) {
        $terminalExe = Join-Path $Out "$terminal.exe"
        $relayErrors = Join-Path $Out "$terminal-relay.txt"
        Copy-Item -Force (Get-Command node).Source $terminalExe
        $start = New-Object System.Diagnostics.ProcessStartInfo $terminalExe
        $start.Arguments = "`"$(Join-Path $PSScriptRoot 'ui-e2e\terminal.mjs')`""
        $start.EnvironmentVariables['APP'] = (Resolve-Path $Exe).Path
        $start.EnvironmentVariables['STORE'] = $store
        $start.EnvironmentVariables['ERR'] = $relayErrors
        $start.UseShellExecute = $false; $start.RedirectStandardInput = $true; $start.CreateNoWindow = $true
        $shell = [System.Diagnostics.Process]::Start($start)
        # the question comes with the agent's first request
        $ask = WaitShown 'InboxClassicAgentAccess' 30
        $said = if (Test-Path $relayErrors) { (Get-Content -Raw $relayErrors) -replace '\s+', ' ' } else { '' }
        $ended = if ($shell.HasExited) { "terminal ended with $($shell.ExitCode)" } else { 'terminal running' }
        Check ($null -ne $ask) "an agent started from a terminal is asked about ($shot$(if (-not $ask) { "; $ended; relay: $said" }))"
        if ($ask) {
            $texts = @([Native.Win]::FindDescendants($ask, 'Static') | ForEach-Object { WindowText $_ })
            if (-not $pseudo) {
                $heading = $texts[0]
                Check ($heading -match "\($terminal\)" -and $texts[1] -match '--name') "it names the terminal's programs together and says how to give one its own access ($shot`: $heading | $($texts[1]))"
            }
            # every text whole, the heading in its own larger font, wrapped over the lines it needs
            $cut = @()
            foreach ($static in [Native.Win]::FindDescendants($ask, 'Static')) {
                $text = WindowText $static
                $style = [Native.Win]::GetWindowLong($static, -16)
                # the program's file is cut in its middle, as a path is (SS_PATHELLIPSIS)
                if ([string]::IsNullOrWhiteSpace($text) -or ($style -band 0xC000) -eq 0x8000) { continue }
                if (-not [Native.Win]::FitsOwnFont($static, $text)) { $cut += $text }
            }
            Check ($cut.Count -eq 0) "nothing in the question is cut off ($shot`: $($cut -join ' | '))"
            if ($pseudo) {
                $english = @($texts | Where-Object { $_ -and -not $_.TrimStart().StartsWith('[') })
                Check ($english.Count -eq 0) "no word of the question left in English ($($english -join ' | '))"
            }
            Shot $ask $shot
            if ($answer -eq 2) {
                [void][Native.Win]::PostMessage($ask, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            } else {
                Click $ask $answer
            }
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($ask) } 10)) "answered, it closes ($shot)"
        }
        try { $shell.StandardInput.Close() } catch {}
        if (-not $shell.WaitForExit(5000)) { $shell.Kill() }
    }
    TerminalQuestion 'WindowsTerminal' 'agents-10-terminal' 7 $false
    Command $main $IDM_AI_AGENTS
    $agents = WaitShown 'InboxClassicAgents' 10
    if ($agents) {
        $hosts = [Native.Win]::GetDlgItem($agents, $IDC_AGENTS_HOSTS)
        $names = @(0..((ListCount $hosts) - 1) | ForEach-Object { [Native.Win]::RemoteListText($hosts, $_, 0) })
        Check ($names -contains 'Programs started from a terminal (WindowsTerminal)') "turned away, the terminal's programs are listed under one name ($($names -join '; '))"
        [void][Native.Win]::PostMessage($agents, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($agents) } 10)
    }

    Step 'marking all read'
    $IDM_MARK_ALL_READ = 126
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 5) { Rows } })
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    $unreadOnServer = { @(Messages 'INBOX' | Where-Object { $_.flags -notcontains '\Seen' }).Count }
    Check ((& $unreadOnServer) -ge 1) "the Inbox has unread messages ($(& $unreadOnServer))"
    Command $main $IDM_MARK_ALL_READ
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ', 0 unread' } 10)) "Edit > Mark All Read: none unread in the folder ($(StatusPart $mainStatus 2))"
    Check ([bool](WaitFor { (& $unreadOnServer) -eq 0 } 20)) 'and none on the server'
    Shot $main 'organize-5-all-read'

    Step 'dragging a message onto a folder'
    # a message of its own, the newest, so it is the first row
    # Drag me the newest, Copy me a minute older: the first two rows, over what the test sent this minute
    foreach ($pair in @(@('Drag me', 3), @('Copy me', 2))) {
        $date = [DateTime]::UtcNow.AddMinutes($pair[1]).ToString('r')
        AddMessage "From: Dana <dana@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $($pair[0])`r`nDate: $date`r`nMessage-ID: <$($pair[0] -replace ' ', '-')@example.com>`r`n`r`nDragged in the UI test.`r`n"
    }
    Command $main $IDM_SYNC
    SelectFolder 0
    $inInbox = WaitFor { if ((Rows) -ge 2 -and [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -eq 'Drag me' -and [Native.Win]::RemoteListText($list, 1, $COL_SUBJECT) -eq 'Copy me') { Rows } } 30
    # the first row and Archive on the screen
    $archiveItem = FolderItem 'Archive'
    function Middle($rect) { @([int](($rect.Left + $rect.Right) / 2), [int](($rect.Top + $rect.Bottom) / 2)) }
    [void][Native.Win]::SetForegroundWindow($main)
    function DragFirstRow([bool]$copy, [string]$shot) {
        $row = Middle ([Native.Win]::RemoteRect($list, 0x100E, [IntPtr]0, 0))
        $row[0] = ([Native.Win]::RemoteRect($list, 0x100E, [IntPtr]0, 0)).Left + 120
        $folder = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $archiveItem.ToInt64()))
        if ($copy) { [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero) }
        [Native.Win]::MouseDragTo($row[0], $row[1], $folder[0], $folder[1])
        if ($shot) { Shot $main $shot }
        [Native.Win]::Mouse($folder[0], $folder[1], 0x0004)
        if ($copy) { [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero) }
    }
    $first = 'Drag me'
    DragFirstRow $false 'organize-6-drag'
    Check ($null -ne (WaitFor { Find 'Archive' "Subject: $first" } 20)) "a message dragged onto Archive is moved there ($first)"
    Check ([bool](WaitFor { -not (Find 'INBOX' "Subject: $first") } 10)) 'and out of the Inbox'
    # by its subject: mail arriving meanwhile changes the number of rows
    $listed = { param($subject) (SubjectRows $subject).Count -gt 0 }
    Check ([bool](WaitFor { -not (& $listed $first) } 10)) "and out of the list ($(Rows) rows, $inInbox before)"
    $second = 'Copy me'
    DragFirstRow $true ''
    Check ($null -ne (WaitFor { Find 'Archive' "Subject: $second" } 20)) "with Ctrl it is copied there ($second)"
    Check ($null -ne (Find 'INBOX' "Subject: $second")) 'and stays in the Inbox'
    # onto the folder it is in: nothing happens
    $inboxItem = FolderItem 'Inbox'
    $row = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]0, 0)
    $inbox = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $inboxItem.ToInt64()))
    $before = Rows
    [Native.Win]::MouseDragTo($row.Left + 120, [int](($row.Top + $row.Bottom) / 2), $inbox[0], $inbox[1])
    [Native.Win]::Mouse($inbox[0], $inbox[1], 0x0004)
    Start-Sleep -Seconds 2
    Check ((Rows) -eq $before -and $null -ne (Find 'INBOX' "Subject: $second")) 'dropped on its own folder, it stays'

    Step 'several messages'
    $IDM_SELECT_ALL = 134; $IDM_UNDO = 135; $TB_ISBUTTONENABLED = 0x0409
    $buttons = [Native.Win]::FindDescendants($main, 'ToolbarWindow32') | Where-Object { [int][Native.Win]::SendMessage($_, 0x0419, [IntPtr]$IDM_SYNC, [IntPtr]::Zero) -ge 0 } | Select-Object -First 1
    $enabled = { param($id) [int][Native.Win]::SendMessage($buttons, $TB_ISBUTTONENABLED, [IntPtr]$id, [IntPtr]::Zero) -ne 0 }
    SelectFolder 0
    $before = WaitFor { if ((Rows) -ge 3) { Rows } }
    SelectRow 0
    # Ctrl+click on the next two rows adds them
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    foreach ($i in 1, 2) {
        $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]$i, 0)
        [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    }
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    $subjects = @(0, 1, 2 | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
    $onServer = { param($mailbox) @($subjects | Where-Object { $s = $_; Find $mailbox "Subject: $([regex]::Escape($s))" }).Count }
    # Archive may have one of them already (the copy the drag made)
    $inArchive = & $onServer 'Archive'
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ', 3 selected$' } 10)) "Ctrl+click adds two more messages: three are selected ($(StatusPart $mainStatus 2))"
    Command $main $IDM_MARK_UNREAD
    $allUnread = { @($subjects | Where-Object { (Find 'INBOX' "Subject: $([regex]::Escape($_))").flags -notcontains '\Seen' }).Count -eq 3 }
    Check ([bool](WaitFor $allUnread 20)) 'Mark as Unread marks the three unread on the server'
    Check ((StatusPart $mainStatus 0) -eq 'Marked 3 messages as unread') "the status bar says what was done ($(StatusPart $mainStatus 0))"
    Check ((StatusPart $mainStatus 2) -match ', 3 selected$') 'the status bar says 3 selected'
    Check (-not (& $enabled $IDM_REPLY) -and (& $enabled $IDM_MARK_READ)) 'Reply is off for several, Mark as Read is on'
    Shot $main 'select-1-several'
    Command $main $IDM_MARK_READ
    $allRead = { @($subjects | Where-Object { (Find 'INBOX' "Subject: $([regex]::Escape($_))").flags -contains '\Seen' }).Count -eq 3 }
    Check ([bool](WaitFor $allRead 20)) 'Mark as Read marks the three read on the server'
    Command $main $IDM_MOVE
    $move = WaitPicker 'Move 3 Messages'
    Check ($null -ne $move) 'Move to Folder asks where'
    if ($move) {
        [void](PickIn $move 'inboxclassic.test' 'Archive')
        Click $move 1
    }
    Check ([bool](WaitFor { -not (& $onServer 'INBOX') -and (& $onServer 'Archive') -eq 3 } 20)) 'Move to Folder moves the three to Archive'
    Check ([bool](WaitFor { (Rows) -eq $before - 3 } 10)) 'and out of the list'
    Check ((StatusPart $mainStatus 0) -eq 'Moved 3 messages to Archive') "the status bar says they were moved to Archive ($(StatusPart $mainStatus 0))"
    Command $main $IDM_UNDO
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Moved 3 messages back to Inbox' } 10)) "Edit > Undo Move brings them back to the Inbox ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { (& $onServer 'INBOX') -eq 3 -and (& $onServer 'Archive') -eq $inArchive } 20)) "and on the server ($(& $onServer 'INBOX') in the Inbox, $(& $onServer 'Archive') in Archive)"
    [void](WaitFor { (Rows) -eq $before } 20)
    # the rows selected (LVM_GETNEXTITEM, LVNI_SELECTED), and whether the first of them is in view
    $selectedRows = {
        $found = @(); $i = -1
        while (($i = [int][Native.Win]::SendMessage($list, 0x100C, [IntPtr]$i, [IntPtr]2)) -ge 0) { $found += $i }
        $found
    }
    $restored = {
        $rows = @(& $selectedRows)
        $names = @($rows | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) } | Sort-Object)
        $top = [int][Native.Win]::SendMessage($list, 0x1027, [IntPtr]::Zero, [IntPtr]::Zero)
        $page = [int][Native.Win]::SendMessage($list, 0x1028, [IntPtr]::Zero, [IntPtr]::Zero)
        $rows.Count -eq 3 -and (($names -join '|') -eq (($subjects | Sort-Object) -join '|')) -and $rows[0] -ge $top -and $rows[0] -lt $top + $page
    }
    Check ([bool](WaitFor $restored 20)) "and selects them, in view ($((& $selectedRows) -join ', '))"
    Shot $main 'select-2-undo'
    [void][Native.Win]::PostMessage($list, 0x0201, [IntPtr]1, [IntPtr]((28 -shl 16) -bor 60))
    [void][Native.Win]::PostMessage($list, 0x0202, [IntPtr]::Zero, [IntPtr]((28 -shl 16) -bor 60))
    Start-Sleep -Milliseconds 300
    Command $main $IDM_SELECT_ALL
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ", $(Rows) selected$" } 10)) "Select All selects every message of the list ($(StatusPart $mainStatus 2))"
    SelectRow 0
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -notmatch 'selected' -and (& $enabled $IDM_REPLY) } 10)) 'one message selected again is shown in the reading pane'

    Step 'many messages at once'
    # a folder of its own, its messages made on the server as another client would, and a folder about to go
    $IDC_UNDONE_BAR = 244; $IDC_UNDONE_CLOSE = 245
    $topNames = { @(ChildRows ([IntPtr]::Zero) | ForEach-Object { Bare $_ }) }
    foreach ($path in @('Bulk', 'Gone')) {
        [void](Invoke-RestMethod -Method Post -ContentType 'application/json' $rest -Body (@{ path = $path; subscribed = $true } | ConvertTo-Json))
    }
    foreach ($i in 1..4) {
        $date = [DateTime]::UtcNow.AddMinutes(-$i).ToString('r')
        AddMessage "From: Bulk Sender <bulk@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Bulk $i`r`nDate: $date`r`nMessage-ID: <bulk-$i@example.com>`r`n`r`nOne of many.`r`n" @('\Seen') 'Bulk'
    }
    Command $main $IDM_SYNC
    [void](WaitFor { (& $topNames) -contains 'Bulk' -and (& $topNames) -contains 'Gone' } 30)
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, (NamedRow ([IntPtr]::Zero) 'Bulk'))
    $bulk = WaitFor { if ((Rows) -eq 4 -and [Native.Win]::SendText($main, $kTestListOrder, '') -ne 9) { Rows } } 30
    Check ($bulk -eq 4) "a folder chosen lists its messages once its list is read off the window thread ($(Rows) rows)"
    # another client deletes Gone: the server refuses a move there, and the message comes back with why over the list
    SelectRow 0
    $refused = [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT)
    # the core done with opening it (its read mark), so the bar says the move's refusal and nothing that followed the
    # message into Gone
    $kTestDeep = 0x44454550
    [void](WaitFor { [Native.Win]::SendText($main, $kTestDeep, 'quiet') -eq 11 } 20)
    Command $main $IDM_MOVE
    $move = WaitPicker 'Move Message'
    Check ($null -ne $move -and (PickIn $move 'inboxclassic.test' 'Gone')) 'the Move window offers Gone'
    # deleted on the server once chosen: deleted before, a sync could take it out of the window first
    [void](Invoke-RestMethod -Method Delete "$rest/Gone")
    if ($move) { Click $move 1 }
    $undoneBar = [Native.Win]::GetDlgItem($main, $IDC_UNDONE_BAR)
    $said = WaitFor { if ([Native.Win]::IsWindowVisible($undoneBar)) { WindowText $undoneBar } } 30
    Check ($said -match (@('undone-move[one]', 'undone-move[*]' | ForEach-Object { Pattern $en[$_] @{ folder = 'Gone'; from = 'Bulk' } }) -join '|')) "a move the server refuses is taken back, a bar over the list saying why in the core's words ($said)"
    Check ([bool](WaitFor { (Rows) -eq 4 -and (SubjectRows $refused).Count -eq 1 } 20)) "and its row is back in the list ($(Rows) rows)"
    Check ((StatusPart $mainStatus 0) -notmatch 'to Gone') "the status bar no longer says it moved ($(StatusPart $mainStatus 0))"
    # selected again, in view, as what Undo brings back is
    $reselected = {
        $rows = @(& $selectedRows)
        $names = @($rows | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
        $top = [int][Native.Win]::SendMessage($list, 0x1027, [IntPtr]::Zero, [IntPtr]::Zero)
        $page = [int][Native.Win]::SendMessage($list, 0x1028, [IntPtr]::Zero, [IntPtr]::Zero)
        $rows.Count -eq 1 -and ($names -join '|') -eq $refused -and $rows[0] -ge $top -and $rows[0] -lt $top + $page
    }
    Check ([bool](WaitFor $reselected 20)) "and the message that came back is selected, in view ($((& $selectedRows) -join ', '))"
    Shot $main 'many-1-refused'
    Click $main $IDC_UNDONE_CLOSE
    Check ([bool](WaitFor { -not [Native.Win]::IsWindowVisible($undoneBar) } 5)) 'the bar closes with its button'
    # Select All counts the list at once; Delete moves them all off the window thread and says so
    Command $main $IDM_SELECT_ALL
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match ', 4 selected$' } 10)) "Select All selects the four ($(StatusPart $mainStatus 2))"
    Command $main $IDM_DELETE
    Check ([bool](WaitFor { (Rows) -eq 0 } 20)) "Select All, then Delete: the list is empty ($(Rows) rows)"
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match '^Moved 4 messages to Deleted Items' } 10)) "the status bar says what was done ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { @(Messages 'Bulk').Count -eq 0 } 20)) 'and the server has them in Deleted Items'
    Shot $main 'many-2-deleted'
    [void](Invoke-RestMethod -Method Delete "$rest/Bulk")
    Command $main $IDM_SYNC
    [void](WaitFor { -not ((& $topNames) -contains 'Bulk') -and -not ((& $topNames) -contains 'Gone') } 20)
    SelectFolder 0

    Step 'messages as files'
    $kDragOut = 0x44524F55; $kDropFiles = 0x44524F50
    # one not downloaded yet: it arrives now and is never opened
    $notOpened = 'Not opened yet'
    $added = Invoke-RestMethod -Method Post -ContentType 'application/json' "$rest/INBOX/messages" -Body (@{
        raw = "From: Ferry Office <ferry@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $notOpened`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <not-opened@example.com>`r`n`r`nThe ferry times for the weekend.`r`n"
        flags = @() } | ConvertTo-Json)
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { (Rows) -ge 3 -and @(0..2 | Where-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) -eq $notOpened }).Count -eq 1 } 30)
    # the newest three, the one not downloaded among them
    SelectRow 0
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    foreach ($i in 1, 2) {
        $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]$i, 0)
        [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    }
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    [void](WaitFor { (StatusPart $mainStatus 2) -match ', 3 selected$' } 10)
    $three = @(0, 1, 2 | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
    # the file a subject becomes: what Windows does not allow in a name taken out
    $fileOf = { param($subject) (($subject -replace '[/\\]', '-') -replace '[<>:"|?*]', '') + '.eml' }
    $sameBytes = { param($dir)
        @($three | Where-Object {
            $path = Join-Path $dir (& $fileOf $_)
            $server = Find 'INBOX' "Subject: $([regex]::Escape($_))"
            # (an antivirus on the test machine may add its own header to what it fetches over IMAP: not compared)
            $plain = { param($text) (($text -replace "`r`n", "`n") -split "`n" | Where-Object { $_ -notmatch '^X-EsetId:' }) -join "`n" }
            (Test-Path -LiteralPath $path) -and $server -and (& $plain ([IO.File]::ReadAllText($path))) -eq (& $plain (RawText $server))
        }).Count -eq 3
    }
    # dropped into a folder as Explorer drops it: the one not downloaded makes them files fetched at the drop
    $out1 = Join-Path (Resolve-Path $Out) 'dragged-out'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $out1
    [void](New-Item -ItemType Directory -Force $out1)
    $written = [Native.Win]::SendText($main, $kDragOut, $out1)
    Check ($written -eq 3 -and @($three | Where-Object { Test-Path -LiteralPath (Join-Path $out1 (& $fileOf $_)) }).Count -eq 3) "three messages dragged out become three .eml files where they are dropped, named after their subjects ($written)"
    Check (& $sameBytes $out1) 'with what each message is, byte for byte'
    Check ($three -contains $notOpened) 'one not downloaded yet is downloaded for it'
    Shot $main 'files-4-drag-out'
    # all downloaded now: written at once, as files that keep the mark of a download from the internet
    $out2 = Join-Path (Resolve-Path $Out) 'dragged-out-again'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $out2
    [void](New-Item -ItemType Directory -Force $out2)
    $written = [Native.Win]::SendText($main, $kDragOut, $out2)
    $zone = Get-Content -LiteralPath (Join-Path $out2 (& $fileOf $three[0])) -Stream Zone.Identifier -ErrorAction SilentlyContinue
    Check ($written -eq 3 -and (& $sameBytes $out2) -and (($zone -join "`n") -match 'ZoneId=3')) "downloaded, they are files marked as from the internet ($written)"
    # Save As with three: a folder, never over a file there
    $saveDir = Join-Path (Resolve-Path $Out) 'saved-three'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $saveDir
    [void](New-Item -ItemType Directory -Force $saveDir)
    $theirs = Join-Path $saveDir (& $fileOf $three[1])
    Set-Content -LiteralPath $theirs -Value 'mine' -NoNewline
    Command $main $IDM_SAVE_AS
    Check (AnswerFolderDialog 'Save Messages In' $saveDir) 'Save As with three selected asks for a folder'
    $savedAll = WaitFor { (@(Get-ChildItem -LiteralPath $saveDir -Filter '*.eml').Count -eq 4) } 30
    Check ([bool]$savedAll -and (Get-Content -Raw -LiteralPath $theirs) -eq 'mine') "and saves the three there, never over a file that is there ($(@(Get-ChildItem -LiteralPath $saveDir).Count) files)"
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Saved 3 messages to saved-three' } 10)) "the status bar says where ($(StatusPart $mainStatus 0))"
    # Forward with three: one new message with them attached
    $compose = WaitCompose { Command $main $IDM_FORWARD }
    Check ($null -ne $compose) 'Forward with three selected writes one new message'
    if ($compose) {
        $attached = [Native.Win]::GetDlgItem($compose, $IDC_FILES)
        $files = WaitFor { if ((ListBoxCount $attached) -eq 3) { 3 } } 10
        Check ($files -eq 3) 'with the three attached as .eml files'
        Check ((GetText $compose $IDC_SUBJECT) -eq "Fw: $($three[0])") "its subject is the first one's, with Fw: ($(GetText $compose $IDC_SUBJECT))"
        # the mouse out of the way: no tooltip of the format bar in the picture
        [Native.Win]::Mouse(2, 2, 0)
        Start-Sleep -Milliseconds 300
        Shot $compose 'files-5-forward'
        [void](CloseCompose $compose)
    }
    # .eml files dropped onto Archive are put in it; a file that is not a message is turned away
    $dropDir = Join-Path (Resolve-Path $Out) 'to-drop'
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $dropDir
    [void](New-Item -ItemType Directory -Force $dropDir)
    $dropped = @('Dropped one', 'Dropped two', 'Dropped three') | ForEach-Object {
        $path = Join-Path $dropDir "$_.eml"
        $raw = "From: Files <files@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $_`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <$($_ -replace ' ', '-')@example.com>`r`n`r`nDropped from a folder.`r`n"
        [IO.File]::WriteAllText($path, $raw)
        $path
    }
    $text = Join-Path $dropDir 'notes.txt'
    Set-Content -LiteralPath $text -Value 'not a message'
    $archive = TreeRow $tree 'inboxclassic.test' 'Archive'
    $effect = [Native.Win]::SendText($main, $kDropFiles, "$($archive.ToInt64())|$($dropped -join '|')")
    $inArchive = { @('Dropped one', 'Dropped two', 'Dropped three' | Where-Object { Find 'Archive' "Subject: $_" }).Count }
    Check ($effect -eq 1 -and [bool](WaitFor { (& $inArchive) -eq 3 } 20)) ".eml files dropped onto Archive in the folder tree are put in it, on the server ($effect, $(& $inArchive))"
    $effect = [Native.Win]::SendText($main, $kDropFiles, "$($archive.ToInt64())|$text")
    Check ($effect -eq 0) "a file that is not a message is turned away ($effect)"
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $archive)
    [void](WaitFor { @(0..([Math]::Max(0, (Rows) - 1)) | Where-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) -like 'Dropped*' }).Count -eq 3 } 20)
    # one of them shown
    $droppedRow = @(SubjectRows 'Dropped one')[0]
    if ($null -ne $droppedRow) { SelectRow $droppedRow }
    [void](WaitFor { (StatusPart $mainStatus 2) -notmatch 'selected' } 5)
    Shot $main 'files-6-drop-in'
    # the message added for this step goes, so the Inbox is as the steps after expect it
    [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)")
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -ne $notOpened } 20)

    Step 'flag colours'
    $IDM_FLAG_COLOR = 900; $IDM_FLAG_CLEAR = 908; $MF_CHECKED = 0x8
    # a message Apple Mail flagged purple: \Flagged with $MailFlagBit0 and $MailFlagBit2
    $apple = 'Flagged in Apple Mail'
    AddMessage ("From: Mira Lind <mira@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $apple`r`nMessage-ID: <apple-flag@example.com>`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`n`r`nFlagged purple in Apple Mail.`r`n") @('\Flagged', '$MailFlagBit0', '$MailFlagBit2')
    Command $main $IDM_SYNC
    SelectFolder 0
    $rowOf = { param($subject) @(SubjectRows $subject)[0] }
    [void](WaitFor { $null -ne (& $rowOf $apple) } 20)
    # LVM_GETSUBITEMRECT of the flag column, its bounds
    $flagCell = { param($row) [Native.Win]::RemoteRect($list, 0x1038, [IntPtr]$row, ([long]$COL_FLAG -shl 32)) }
    # the colour of a row's flag: the most coloured pixel of its flag cell, as the screen shows it
    $flagColor = {
        param($row)
        $found = @{ best = $null; most = -1 }
        $null = ScanCell $row $flagCell {
            param($p)
            $spread = [Math]::Max($p.R, [Math]::Max($p.G, $p.B)) - [Math]::Min($p.R, [Math]::Min($p.G, $p.B))
            if ($spread -gt $found.most) { $found.most = $spread; $found.best = $p }
        }
        $found.best
    }
    $near = { param($c, $r, $g, $b) $c -and [Math]::Abs($c.R - $r) -lt 40 -and [Math]::Abs($c.G - $g) -lt 40 -and [Math]::Abs($c.B - $b) -lt 40 }
    # another row selected, so the flag is drawn on the list's white
    SelectRow ([int](& $rowOf $apple) + 1)
    $purple = & $flagColor (& $rowOf $apple)
    Check (& $near $purple 136 23 152) "a message flagged purple by another program (Apple Mail) shows a purple flag ($purple)"

    # three rows without a flag for the colours
    $plain = @(0..([Math]::Min(8, (Rows) - 1)) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) } |
        Where-Object { $_ -and $_ -ne $apple -and ((Find 'INBOX' "Subject: $([regex]::Escape($_))").flags -notcontains '\Flagged') } | Select-Object -First 3)
    $flagsOf = { param($subject) @((Find 'INBOX' "Subject: $([regex]::Escape($subject))").flags) }

    # the menu: the seven colours and Clear Flag
    Check (SelectSubject $plain[0]) "the reading pane shows the message selected ($($plain[0]))"
    $WM_CONTEXTMENU = 0x007B
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = [Native.Win]::MenuLabels($hmenu)
        $at = [array]::IndexOf($labels, 'Flag')
        $colours = if ($at -ge 0) { [Native.Win]::MenuLabels([Native.Win]::GetSubMenu($hmenu, $at)) } else { @() }
        Check (($colours -join ',') -eq 'Red,Orange,Yellow,Green,Blue,Purple,Gray,,Clear Flag') "the message menu's Flag has the seven colours of Apple Mail and Clear Flag ($($colours -join ', '))"
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    } else {
        Check $false 'the message list has a right-click menu'
    }

    # orange: \Flagged and $MailFlagBit0
    Command $main ($IDM_FLAG_COLOR + 2)
    Check ([bool](WaitFor { $f = & $flagsOf $plain[0]; ($f -contains '\Flagged') -and ($f -contains '$MailFlagBit0') -and ($f -notcontains '$MailFlagBit1') -and ($f -notcontains '$MailFlagBit2') } 20)) "Orange flags the message orange: \Flagged and `$MailFlagBit0 on the server ($((& $flagsOf $plain[0]) -join ' '))"
    Check ((StatusPart $mainStatus 0) -eq 'Flagged 1 message orange') "the status bar says so ($(StatusPart $mainStatus 0))"
    Check (SelectSubject $apple) "the reading pane shows the message selected ($($apple))"
    $orange = & $flagColor (& $rowOf $plain[0])
    Check (& $near $orange 247 99 12) "the flag column shows it in orange ($orange)"

    # blue on two selected
    Check (SelectSubject $plain[1]) "the reading pane shows the message selected ($($plain[1]))"
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr](& $rowOf $plain[2]), 0)
    [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    [void](WaitFor { (StatusPart $mainStatus 2) -match ', 2 selected$' } 10)
    Command $main ($IDM_FLAG_COLOR + 5)
    $blue = { param($s) $f = & $flagsOf $s; ($f -contains '\Flagged') -and ($f -contains '$MailFlagBit2') -and ($f -notcontains '$MailFlagBit0') -and ($f -notcontains '$MailFlagBit1') }
    Check ([bool](WaitFor { (& $blue $plain[1]) -and (& $blue $plain[2]) } 20)) 'Blue on two selected messages flags both blue: $MailFlagBit2'
    # on the selected rows' highlight the flag is drawn white, as the Mac shows it: a blue one would not be seen
    $selectedFlag = {
        param($row)
        # the lightest pixel of the cell
        $found = @{ best = $null; most = -1 }
        $null = ScanCell $row $flagCell {
            param($p)
            $light = [Math]::Min($p.R, [Math]::Min($p.G, $p.B))
            if ($light -gt $found.most) { $found.most = $light; $found.best = $p }
        }
        $found.best
    }
    $white = & $selectedFlag (& $rowOf $plain[1])
    Check ($white -and $white.R -gt 200 -and $white.G -gt 200 -and $white.B -gt 200) "a selected row's flag is drawn white on its highlight ($white)"
    # the menu checks Blue: its Flag submenu opened as the keys open it
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    $sub = [IntPtr]::Zero
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = [Native.Win]::MenuLabels($hmenu)
        # with two selected, what acts on one message alone is greyed (MF_GRAYED | MF_DISABLED)
        $greyed = { param($id) ([Native.Win]::GetMenuState($hmenu, $id, 0) -band 0x3) -ne 0 }
        Check ((& $greyed $IDM_REPLY) -and (& $greyed $IDM_VIEW_SOURCE) -and (& $greyed $IDM_PROPERTIES) -and -not (& $greyed $IDM_FORWARD)) 'with two selected the menu greys Reply to Sender, View Source and Properties, not Forward'
        $at = [array]::IndexOf($labels, 'Flag')
        # Flag clicked where the menu shows it opens its submenu
        $item = New-Object Native.Win+RECT
        if ([Native.Win]::GetMenuItemRect([IntPtr]::Zero, $hmenu, [uint32]$at, [ref]$item)) {
            [Native.Win]::MouseClick([int](($item.Left + $item.Right) / 2), [int](($item.Top + $item.Bottom) / 2))
        }
        # the submenu: another menu window, besides the one opened first
        $otherMenu = {
            $next = [IntPtr]::Zero
            while (($next = [Native.Win]::FindWindowEx([IntPtr]::Zero, $next, '#32768', [NullString]::Value)) -ne [IntPtr]::Zero) {
                if ($next -ne $menu -and [Native.Win]::IsWindowVisible($next)) { return $next }
            }
        }
        $sub = WaitFor $otherMenu 5
        $flagMenu = [Native.Win]::GetSubMenu($hmenu, $at)
        Check ((([Native.Win]::GetMenuState($flagMenu, $IDM_FLAG_COLOR + 5, 0) -band $MF_CHECKED) -ne 0) -and
            (([Native.Win]::GetMenuState($flagMenu, $IDM_FLAG_COLOR + 2, 0) -band $MF_CHECKED) -eq 0)) 'the Flag menu checks Blue, the colour both have'
        if ($sub) { Shot $main 'flags-1-colors' $sub } else { Shot $main 'flags-1-colors' $menu }
        Key $menu $VK_ESCAPE
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }

    # Clear Flag takes the flag and its colour away
    Check (SelectSubject $plain[0]) "the reading pane shows the message selected ($($plain[0]))"
    [void][Native.Win]::SetForegroundWindow($main)
    [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
    foreach ($s in $plain[1], $plain[2], $apple) {
        $box = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr](& $rowOf $s), 0)
        [Native.Win]::MouseClick($box.Left + 120, [int](($box.Top + $box.Bottom) / 2))
    }
    [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
    [void](WaitFor { (StatusPart $mainStatus 2) -match ', 4 selected$' } 10)
    Command $main $IDM_FLAG_CLEAR
    $cleared = { param($s) $f = & $flagsOf $s; ($f -notcontains '\Flagged') -and ($f -notcontains '$MailFlagBit0') -and ($f -notcontains '$MailFlagBit1') -and ($f -notcontains '$MailFlagBit2') }
    Check ([bool](WaitFor { @($plain + $apple | Where-Object { & $cleared $_ }).Count -eq 4 } 20)) 'Clear Flag takes the flag and its colour away on the server'
    # the message added for this step goes, so the Inbox is as the steps after expect it
    $added = Find 'INBOX' "Subject: $apple"
    if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { $null -eq (& $rowOf $apple) } 20)

    Step 'junk and not junk'
    $IDM_JUNK = 127; $IDM_NOT_JUNK = 128; $TB_COMMANDTOINDEX = 0x0419
    # the main toolbar: the one with Send/Recv
    $toolbar = [Native.Win]::FindDescendants($main, 'ToolbarWindow32') | Where-Object { [int][Native.Win]::SendMessage($_, $TB_COMMANDTOINDEX, [IntPtr]$IDM_SYNC, [IntPtr]::Zero) -ge 0 } | Select-Object -First 1
    $hasButton = { param($id) [int][Native.Win]::SendMessage($toolbar, $TB_COMMANDTOINDEX, [IntPtr]$id, [IntPtr]::Zero) -ge 0 }
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } })
    Check ((& $hasButton $IDM_JUNK) -and -not (& $hasButton $IDM_NOT_JUNK)) 'the toolbar has Junk in the Inbox'
    # the first row: the message copied by the drag
    SelectRow 0
    Command $main $IDM_JUNK
    $junked = WaitFor { Find 'Junk' 'Subject: Copy me' } 20
    Check ($null -ne $junked) 'Junk moves the message to Junk E-mail'
    Check ($junked -and $junked.flags -contains '$Junk') "with the `$Junk keyword ($($junked.flags -join ' '))"
    Check ($null -eq (Find 'INBOX' 'Subject: Copy me')) 'and out of the Inbox'
    SelectFolder 4
    [void](WaitFor { if ((Rows) -ge 1) { Rows } } 20)
    Check ([bool](WaitFor { (& $hasButton $IDM_NOT_JUNK) -and -not (& $hasButton $IDM_JUNK) } 5)) 'in Junk E-mail the toolbar has Not Junk in its place'
    # the toolbar redrawn with the new button leaves the search field on it alone: its sunken edge and white inside
    # still there, not the toolbar's face
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 700
    $fieldBox = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($main, 205), [ref]$fieldBox)
    $fieldPicture = New-Object System.Drawing.Bitmap ($fieldBox.Right - $fieldBox.Left), ($fieldBox.Bottom - $fieldBox.Top)
    CopyScreen $fieldPicture $fieldBox.Left $fieldBox.Top
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    $edgePixel = $fieldPicture.GetPixel(0, [int]($fieldPicture.Height / 2))
    $insidePixel = $fieldPicture.GetPixel([int]($fieldPicture.Width / 2), 3)
    Check ($edgePixel.R -lt 200 -and $insidePixel.R -eq 255 -and $insidePixel.G -eq 255 -and $insidePixel.B -eq 255) "the search field is still drawn over the toolbar (edge $edgePixel, inside $insidePixel)"
    SelectRow 0
    Shot $main 'organize-7-junk'
    Command $main $IDM_NOT_JUNK
    $back = WaitFor { Find 'INBOX' 'Subject: Copy me' } 20
    Check ($null -ne $back) 'Not Junk moves it back to the Inbox'
    Check ($back -and $back.flags -contains '$NotJunk' -and $back.flags -notcontains '$Junk') "with `$NotJunk in place of `$Junk ($($back.flags -join ' '))"
    SelectFolder 0

    # ---- archive ----

    Step 'archive'
    $IDM_ARCHIVE = 138; $IDM_UNDO = 135; $TB_ISBUTTONENABLED = 0x0409
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    [void](WaitFor { if ((Rows) -ge 3) { Rows } })
    # as text: row 0 would read as nothing found
    $copyRow = WaitFor { $r = @(SubjectRows 'Copy me'); if ($r.Count) { "$($r[0])" } } 20
    SelectRow ([int]$copyRow)
    $archiveOn = WaitFor { [int][Native.Win]::SendMessage($toolbar, $TB_ISBUTTONENABLED, [IntPtr]$IDM_ARCHIVE, [IntPtr]::Zero) -ne 0 } 5
    Check ([bool]$archiveOn) 'Archive is on for a message of the Inbox'
    Command $main $IDM_ARCHIVE
    $archived = WaitFor { Find 'Archive' 'Subject: Copy me' } 20
    Check ($null -ne $archived) 'Archive moves the message to Archive on the server'
    Check ($null -eq (Find 'INBOX' 'Subject: Copy me')) 'and out of the Inbox'
    $said = WaitFor { $t = StatusPart $mainStatus 0; if ($t -like 'Archived 1 message*') { $t } } 10
    Check ($null -ne $said) "the status bar says it was archived ($(StatusPart $mainStatus 0))"
    Shot $main 'organize-8-archive'
    Command $main $IDM_UNDO
    Check ($null -ne (WaitFor { Find 'INBOX' 'Subject: Copy me' } 20)) 'Undo puts it back in the Inbox'

    # ---- empty folder ----

    Step 'empty folder'
    $IDM_EMPTY_FOLDER = 139; $IDM_SYNC = 102
    AddMessage "From: Spammer <spam@example.net>`r`nTo: testuser@inboxclassic.test`r`nSubject: Win a prize`r`n`r`nClick.`r`n" @() 'Junk'
    SelectFolder 4
    Command $main $IDM_SYNC
    [void](WaitFor { if ((Rows) -ge 1) { Rows } } 20)
    Command $main $IDM_EMPTY_FOLDER
    $sure = BoxOf $main 10
    Check ($null -ne $sure) 'Empty Folder asks first, saying how many go'
    if ($sure) {
        Shot $sure 'organize-9-empty'
        Click $sure 6
    }
    Check ($null -ne (WaitFor { if (@(Messages 'Junk').Count -eq 0) { $true } } 20)) 'Junk E-mail is empty on the server'
    Check ([bool](WaitFor { (Rows) -eq 0 } 10)) 'and in the list'
    SelectFolder 0

    # ---- a message in a window of its own ----

    Step 'message window'
    $IDC_PREVIOUS = 231; $IDC_NEXT = 232
    [void](WaitFor { if ((Rows) -ge 2) { Rows } } 20)
    $firstSubject = [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT)
    $secondSubject = [Native.Win]::RemoteListText($list, 1, $COL_SUBJECT)
    $firstPattern = "Subject: $([regex]::Escape($firstSubject))"
    SelectRow 0
    # unread again, so that the window is what marks it read
    [void](WaitFor { Seen $firstPattern } 10)
    Command $main $IDM_MARK_UNREAD
    Check ([bool](WaitFor { -not (Seen $firstPattern) } 20)) "the first message is unread before it is opened ($firstSubject)"
    [void][Native.Win]::SetForegroundWindow($main)
    Key $list $VK_RETURN
    $messageWindow = WaitShown 'InboxClassicMessage' 10
    Check ($null -ne $messageWindow) 'Enter opens the message in a window of its own'
    if ($messageWindow) {
        Check ([Native.Win]::GetWindow($messageWindow, 4) -eq [IntPtr]::Zero) 'a window of its own, not owned by the main window'
        $windowTitle = WindowText $messageWindow
        Check ($windowTitle -eq "$firstSubject - Inbox Classic") "titled with its subject ($windowTitle)"
        Check ([bool](WaitFor { Seen $firstPattern } 20)) 'opening it marked it read on the server'
        Command $messageWindow $IDC_NEXT
        Check ([bool](WaitFor { (WindowText $messageWindow) -eq "$secondSubject - Inbox Classic" } 10)) "Next shows the message after it, the title follows ($(WindowText $messageWindow))"
        Command $messageWindow $IDC_PREVIOUS
        Check ([bool](WaitFor { (WindowText $messageWindow) -eq "$firstSubject - Inbox Classic" } 10)) "Previous goes back ($(WindowText $messageWindow))"
        Start-Sleep -Milliseconds 1000
        Shot $messageWindow 'read-16-window'
        $compose = WaitCompose { Command $messageWindow $IDM_REPLY }
        Check ($null -ne $compose) 'Reply in the window opens a compose window'
        if ($compose) {
            $replySubject = GetText $compose $IDC_SUBJECT
            Check ($replySubject -eq "Re: $firstSubject" -or ($firstSubject -like 'Re:*' -and $replySubject -eq $firstSubject)) "a reply to that message ($replySubject)"
            [void](CloseCompose $compose)
        }
        Key $messageWindow $VK_ESCAPE
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($messageWindow) } 10)) 'Esc closes the window'
        Check ((WindowText $main) -eq 'Inbox - Inbox Classic') "the main window is as it was ($(WindowText $main))"
    }

    # ---- reading with the keyboard ----

    Step 'keyboard reading'
    $IDM_NEXT_MESSAGE = 140; $IDM_PREVIOUS_MESSAGE = 141; $IDM_NEXT_UNREAD = 142; $IDM_GO_TO_FOLDER = 143; $IDM_FIND_IN_MESSAGE = 144
    $IDM_MARK_ALL_READ = 126; $LVM_GETNEXTITEM = 0x100C
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } } 20)
    SelectRow 0
    Command $main $IDM_NEXT_MESSAGE
    Check ([bool](WaitFor { (SelectedRow) -eq 1 } 5)) "Next Message selects the message below ($(SelectedRow))"
    Command $main $IDM_PREVIOUS_MESSAGE
    Check ([bool](WaitFor { (SelectedRow) -eq 0 } 5)) "Previous Message selects the one above ($(SelectedRow))"
    # one unread message in the Inbox, the third, and one in Archive to go on to
    Command $main $IDM_MARK_ALL_READ
    AddMessage "From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Unread in Archive`r`n`r`nStill unread.`r`n" @() 'Archive'
    Command $main $IDM_SYNC
    $thirdSubject = [Native.Win]::RemoteListText($list, 2, $COL_SUBJECT)
    $thirdPattern = "Subject: $([regex]::Escape($thirdSubject))"
    [void](WaitFor { Seen $thirdPattern } 20)
    SelectRow 2
    [void](WaitFor { Seen $thirdPattern } 10)
    Command $main $IDM_MARK_UNREAD
    [void](WaitFor { -not (Seen $thirdPattern) } 20)
    SelectRow 0
    Command $main $IDM_NEXT_UNREAD
    Check ([bool](WaitFor { (SelectedRow) -eq 2 } 5)) "Next Unread Message selects the next unread message ($(SelectedRow))"
    [void](WaitFor { Seen $thirdPattern } 20)
    Command $main $IDM_NEXT_UNREAD
    $goOn = BoxOf $main 10
    $asked = if ($goOn) { Statics $goOn } else { '' }
    Check ($asked -match 'Archive') "with none left it asks to go on to the next folder with unread mail ($asked)"
    if ($goOn) {
        Click $goOn 6
        Check ([bool](WaitFor { (WindowText $main) -eq 'Archive - Inbox Classic' -and (SelectedRow) -ge 0 } 10)) "and Yes goes there, to its unread message ($(WindowText $main))"
    }
    Command $main $IDM_GO_TO_FOLDER
    $goTo = WaitPicker 'Go to Folder'
    Check ($null -ne $goTo) 'Go to Folder opens'
    if ($goTo) {
        $pickerTree = [Native.Win]::GetDlgItem($goTo, 102)
        $texts = @(TreeTexts $pickerTree)
        # with one account, no row for it: its folders at the top
        Check (-not ($texts -contains 'inboxclassic.test') -and ($texts -contains 'Sent Items') -and ($texts -contains 'Inbox')) "it shows the folders of the account, with no row for the one account ($($texts -join ', '))"
        Check (-not (Visible $goTo 103)) 'without New Folder'
        SetText $goTo 101 'sent'
        $narrowed = @(TreeTexts $pickerTree)
        Check (($narrowed -contains 'Sent Items') -and -not ($narrowed -contains 'Drafts')) "typing narrows them ($($narrowed -join ', '))"
        Shot $goTo 'read-18-go-to'
        Check (PickIn $goTo 'inboxclassic.test' 'Sent Items') 'Sent Items can be chosen'
        Click $goTo 1
        Check ([bool](WaitFor { (WindowText $main) -eq 'Sent Items - Inbox Classic' } 10)) "choosing Sent Items shows Sent Items ($(WindowText $main))"
    }
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } } 20)
    Check (SelectSubject $newsletter) "the reading pane shows the message selected ($newsletter)"
    Command $main $IDM_FIND_IN_MESSAGE
    $findForm = WaitForm 'Find in This Message' 10
    Check ($null -ne $findForm) 'Find in This Message asks for the words'
    if ($findForm) {
        SetText $findForm 100 'larches'
        Click $findForm 1
        [void](WaitFor { -not [Native.Win]::IsWindow($findForm) } 10)
        $count = WaitFor { $n = [Native.Win]::SendText($main, $kTestFound, ''); if ($n -ne 9) { "$($n - 10)" } } 10
        Check ([int]$count -gt 0) "it finds a word of the message shown ($count places; $(StatusPart $mainStatus 0))"
        Shot $main 'read-17-find'
    }
    Command $main $IDM_FIND_IN_MESSAGE
    $findForm = WaitForm 'Find in This Message' 10
    if ($findForm) {
        SetText $findForm 100 'zeppelins'
        Click $findForm 1
        $said = WaitFor { $t = StatusPart $mainStatus 0; if ($t -match (Pattern $en['ui-find-not-found'] @{ words = 'zeppelins' })) { $t } } 10
        Check ($null -ne $said) "and says when it is not there ($(StatusPart $mainStatus 0))"
    } else {
        Check $false 'Find in This Message asks again'
    }

    # ---- conversations ----

    Step 'conversations'
    $IDM_EXPAND_ALL_THREADS = 145; $IDM_COLLAPSE_ALL_THREADS = 146; $IDM_OPTIONS = 137; $IDC_OPTIONS_THREADS = 663
    # Tools > Options with Group messages by conversation turned on or off, and OK; whether the box was there. With
    # $applied, Apply first, and $applied is checked with Options still open
    function SetGrouping([bool]$on, [scriptblock]$applied = $null) {
        Command $main $IDM_OPTIONS
        $o = WaitShown 'InboxClassicOptions' 10
        if (-not $o) { return $false }
        OptionsPage $o 1
        $box = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_THREADS)
        [void][Native.Win]::SendMessage($box, $BM_SETCHECK, [IntPtr]([int]$on), [IntPtr]::Zero)
        if ($applied) {
            # as a click on the box sets it, then Apply (app.h: IDC_OPTIONS_APPLY)
            Click $o $IDC_OPTIONS_THREADS
            [void](WaitFor { [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($o, 681)) } 5)
            Click $o 681
            Check ([bool](WaitFor { (& $applied) -and [Native.Win]::IsWindowVisible($o) } 10)) "Apply regroups the list at once, Options still open ($(Rows) rows)"
        }
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
        $box -ne [IntPtr]::Zero
    }
    # Tools > Options: the notifications can name a message's sign-in code, off until chosen, kept for the next start
    $IDC_OPTIONS_CODES = 664
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 0
        $codes = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_CODES)
        Check ($codes -ne [IntPtr]::Zero -and [int][Native.Win]::SendMessage($codes, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 0) 'Options can show sign-in codes in new mail notifications, off at first'
        # under Notify me when new mail arrives, and only with it on: cleared (as a click clears it), the codes are disabled
        $IDC_OPTIONS_NOTIFY = 661
        $notifyBox = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_NOTIFY)
        $notifyWas = [int][Native.Win]::SendMessage($notifyBox, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ($notifyWas -eq 1 -and [Native.Win]::IsWindowEnabled($codes)) 'with the notifications on, the codes can be chosen'
        [void][Native.Win]::SendMessage($notifyBox, $BM_SETCHECK, [IntPtr]0, [IntPtr]::Zero)
        Click $o $IDC_OPTIONS_NOTIFY
        Check ([bool](WaitFor { -not [Native.Win]::IsWindowEnabled($codes) } 5)) 'with them off, the codes are disabled'
        [void][Native.Win]::SendMessage($notifyBox, $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $o $IDC_OPTIONS_NOTIFY
        Check ([bool](WaitFor { [Native.Win]::IsWindowEnabled($codes) } 5)) 'and enabled again with them on'
        [void][Native.Win]::SendMessage($codes, $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
        Check ((Get-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue).CodesInNotifications -eq 1) 'turned on, that is kept for the next start'
    } else {
        Check $false 'Tools > Options opens'
    }
    $topic = 'Trip to the coast'
    $coast = @('coast1@example.com', 'coast2@example.com', 'coast3@example.com')
    $coastSeen = { @($coast | Where-Object { Seen "Message-ID: <$([regex]::Escape($_))>" }).Count }
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3) { Rows } } 20)
    # three messages of one conversation, each answering the one before
    $date = [DateTime]::UtcNow
    AddMessage ("From: Ann Example <ann@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $topic`r`n" +
        "Message-ID: <$($coast[0])>`r`nDate: $($date.AddMinutes(1).ToString('r'))`r`n`r`nShall we go to the coast on Sunday?`r`n")
    AddMessage ("From: Bob Harris <bob@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $topic`r`n" +
        "Message-ID: <$($coast[1])>`r`nIn-Reply-To: <$($coast[0])>`r`nReferences: <$($coast[0])>`r`n" +
        "Date: $($date.AddMinutes(2).ToString('r'))`r`n`r`nI am in.`r`n")
    AddMessage ("From: Carol <carol@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $topic`r`n" +
        "Message-ID: <$($coast[2])>`r`nIn-Reply-To: <$($coast[1])>`r`nReferences: <$($coast[0])> <$($coast[1])>`r`n" +
        "Date: $($date.AddMinutes(3).ToString('r'))`r`n`r`nMe too, I will bring the sandwiches.`r`n")
    Command $main $IDM_SYNC
    # grouped, as it is out of the box: the three are one row, on the first message
    $grouped = WaitFor { if ((SubjectRows $topic).Count -eq 1 -and (SubjectRows "Re: $topic").Count -eq 0 -and
        (StatusPart $mainStatus 2) -match '^(\d+) message' -and [int]$Matches[1] -eq @(Messages 'INBOX').Count) { Rows } } 30
    # every message of the Inbox, a row each when nothing is grouped
    $flat = @(Messages 'INBOX').Count
    $head = @(SubjectRows $topic)
    Check ($null -ne $grouped -and $head.Count -eq 1 -and $grouped -lt $flat) "the Inbox lists the conversation once, on its first message ($(Rows) rows of $flat messages)"
    if ($head.Count -eq 1) {
        $at = [int]$head[0]
        # the list may open the conversation by itself as new mail comes (and read it): another row selected, the three
        # unread again on the server, as they came
        SelectRow ([int](@(0..([math]::Max(0, (Rows) - 1))) | Where-Object { $_ -ne $at } | Select-Object -First 1))
        # what the app marked read itself on showing them reaches the server first, or it would mark them read again
        [void](WaitFor { -not @(Messages 'INBOX' | Where-Object { $m = $_; @($coast | Where-Object { (RawText $m) -match [regex]::Escape("<$_>") }).Count -and $m.flags -notcontains '\Seen' }).Count } 10)
        $coastUids = @(Messages 'INBOX' | Where-Object { $m = $_; @($coast | Where-Object { (RawText $m) -match [regex]::Escape("<$_>") }).Count } | ForEach-Object { $_.uid })
        [void](Invoke-RestMethod -Method Post -ContentType 'application/json' "$rest/INBOX/messages/flags" -Body (@{
            uids = $coastUids; flags = @('\Seen'); mode = 'remove' } | ConvertTo-Json))
        Command $main $IDM_SYNC
        # the count drawn beside the subject (not the row's text): what the core says for three, three of them new
        $kTestRowField = 0x544C424C
        $label = '(3, 3 new)'
        $labelled = WaitFor { if ((& $coastSeen) -eq 0 -and [Native.Win]::SendText($main, $kTestRowField, "$topic`nthread_label`n$label") -eq 1) { 1 } } 20
        Check ($null -ne $labelled) "with the count of its messages and of the new ones ($($label): $([Native.Win]::SendText($main, $kTestRowField, "$topic`nthread_label`n$label")))"
        SelectRow $at
        Check ((SelectedRow) -eq $at) "its row can be selected ($(SelectedRow))"
        # the whole conversation in the reading pane: all three unread, so all three open, each a frame sized to it
        $kTestFrames = 0x46524D53
        $framed = WaitFor { $v = [Native.Win]::SendText($main, $kTestFrames, ''); if (($v % 1000) -eq 103) { $v } } 20
        Check ($null -ne $framed) "selecting it shows the whole conversation, its three unread messages open, each sized to its document ($([Native.Win]::SendText($main, $kTestFrames, '')))"
        Check ([bool](WaitFor { (& $coastSeen) -eq 3 } 20)) "after a moment on screen, the messages it showed open are read on the server ($(& $coastSeen) of 3)"
        Shot $main 'threads-1-collapsed'
        # a line clicked: that message folds, two frames left
        $kTestLink = 0x4C494E4B
        Check ([Native.Win]::SendText($main, $kTestLink, 'inboxclassic:conversation-0') -eq 1) 'a line of the conversation is its own link'
        Check ([bool](WaitFor { $v = [Native.Win]::SendText($main, $kTestFrames, ''); ($v % 1000) -eq 102 } 20)) "a click on an open message's line folds it"
        Shot $main 'threads-6-conversation-line'
        # Print Conversation: the three messages, one after another
        $kTestPrint = 0x50524E54
        Command $main $IDM_PRINT_CONVERSATION
        $print = WaitWindow 'InboxClassicPrint' $null 20
        if ($print) {
            $printedAll = "Shall we go to the coast on Sunday?`nI am in.`nMe too, I will bring the sandwiches."
            $looked = WaitFor { $v = [Native.Win]::SendText($main, $kTestPrint, $printedAll); if ($v -ge 0 -and ($v % 10) -eq 1) { $v } } 20
            Check ($null -ne $looked) 'Print Conversation prints all three messages'
            [void][Native.Win]::PostMessage($print, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            [void](WaitFor { -not [Native.Win]::IsWindow($print) } 10)
        } else {
            Check $false 'Print Conversation opens the print preview'
        }
        Key $list $VK_RIGHT
        Check ([bool](WaitFor { (Rows) -eq $grouped + 2 } 10)) "Right expands it ($(Rows) rows)"
        $under = @(($at + 1), ($at + 2) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
        Check (($under | Where-Object { $_ -eq "Re: $topic" }).Count -eq 2) "its replies are under it ($($under -join ', '))"
        Shot $main 'threads-2-expanded'
        Key $list $VK_LEFT
        Check ([bool](WaitFor { (Rows) -eq $grouped } 10)) "Left collapses it again ($(Rows) rows)"
        Check ((SelectedRow) -eq $at) "its row stays selected ($(SelectedRow))"
        Command $main $IDM_EXPAND_ALL_THREADS
        Check ([bool](WaitFor { (Rows) -eq $flat } 10)) "Expand All Conversations shows every message ($(Rows) of $flat)"
        Command $main $IDM_COLLAPSE_ALL_THREADS
        Check ([bool](WaitFor { (Rows) -eq $grouped } 10)) "Collapse All Conversations hides the replies again ($(Rows))"
        # shown whole, its open messages were read; one unread again on the server for Mark Read to read
        [void](Invoke-RestMethod -Method Post -ContentType 'application/json' "$rest/INBOX/messages/flags" -Body (@{
            uids = @($coastUids | Select-Object -Last 1); flags = @('\Seen'); mode = 'remove' } | ConvertTo-Json))
        Command $main $IDM_SYNC
        Check ([bool](WaitFor { (& $coastSeen) -eq 2 } 20)) "one of the conversation unread again ($(& $coastSeen) of 3 read)"
        $at = [int](@(SubjectRows $topic)[0])
        SelectRow $at
        Command $main $IDM_MARK_READ
        Check ([bool](WaitFor { (& $coastSeen) -eq 3 } 20)) "Mark Read on the collapsed row marks all three read on the server ($(& $coastSeen))"
    }
    Check (SetGrouping $false { (Rows) -eq $flat -and (SubjectRows "Re: $topic").Count -eq 2 }) 'Group messages by conversation can be turned off'
    Check ([bool](WaitFor { (Rows) -eq $flat -and (SubjectRows "Re: $topic").Count -eq 2 } 10)) "with it off the three messages are three rows ($(Rows))"
    Check ((Get-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue).GroupByConversation -eq 0) 'and that is kept for the next start'
    Shot $main 'threads-3-options-off'
    Check (SetGrouping $true) 'and on again'
    Check ([bool](WaitFor { (Rows) -eq $grouped -and (SubjectRows $topic).Count -eq 1 -and (SubjectRows "Re: $topic").Count -eq 0 } 10)) "turned on again, the conversation is one row again ($(Rows))"
    # ---- watch and ignore conversation ----

    Step 'watch and ignore conversation'
    $IDM_WATCH_CONVERSATION = 151; $IDM_IGNORE_CONVERSATION = 152; $IDM_HIDE_IGNORED = 153
    $kTestNotification = 0x4E4F5445; $VK_K = 0x4B
    $WM_INITMENUPOPUP = 0x0117; $WM_SYSCOMMAND = 0x0112; $SC_MINIMIZE = 0xF020; $WM_TRAY = 0x8000 + 60; $NIN_SELECT = 0x0400
    $bar = [Native.Win]::GetMenu($main)
    # whether an item of a menu of the bar (View is the third, Message the fifth) is checked, as the menu opens
    function MenuChecked([int]$position, [int]$id) {
        $sub = [Native.Win]::GetSubMenu($bar, $position)
        [void][Native.Win]::SendMessage($main, $WM_INITMENUPOPUP, $sub, [IntPtr]$position)
        ([Native.Win]::GetMenuState($sub, $id, 0) -band 0x8) -ne 0
    }
    # whether the last new mail notification since the last ask had this heading ('' for none)
    function Notified([string]$heading) { [Native.Win]::SendText($main, $kTestNotification, $heading) -eq 1 }
    # the window minimized, so new mail is announced, and back
    function Minimize { [void][Native.Win]::PostMessage($main, $WM_SYSCOMMAND, [IntPtr]$SC_MINIMIZE, [IntPtr]::Zero); Start-Sleep -Seconds 1 }
    function Restore {
        [void][Native.Win]::PostMessage($main, $WM_TRAY, [IntPtr]::Zero, [IntPtr]$NIN_SELECT)
        [void](WaitFor { -not [Native.Win]::IsIconic($main) } 10)
        SelectFolder 0
        Start-Sleep -Seconds 1
    }
    # whether an item of the selected row's right-click menu is checked: the list has no Watch column, the menu says it
    function ContextChecked([int]$id) {
        # WM_CONTEXTMENU from the keyboard: the menu at the selected row
        [void][Native.Win]::PostMessage($main, 0x007B, $list, [IntPtr](-1))
        $menu = WaitWindow '#32768' $null 10
        $checked = $false
        if ($menu) {
            $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
            $checked = ([Native.Win]::GetMenuState($hmenu, $id, 0) -band 0x8) -ne 0
            Key $menu $VK_ESCAPE
            [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
        }
        [void][Native.Win]::SetForegroundWindow($main)
        $checked
    }
    # the message list's columns, Watch and Size gone, Subject the widest
    $width = { param($column) [int][Native.Win]::SendMessage($list, 0x101D, [IntPtr]$column, [IntPtr]::Zero) }
    Check ((& $width $COL_SUBJECT) -gt (& $width $COL_FROM) -and (& $width $COL_SUBJECT) -gt (& $width $COL_RECEIVED)) "the list has no Watch or Size column, and Subject takes the room ($(& $width $COL_SUBJECT) wide)"
    # the darkest pixel of a row's From cell: black for its words, grey for an ignored conversation's
    $fromCell = { param($row) [Native.Win]::RemoteRect($list, 0x1038, [IntPtr]$row, ([long]$COL_FROM -shl 32)) }
    $darkest = {
        param($row)
        $found = @{ least = 255 }
        $null = ScanCell $row $fromCell { param($p) $found.least = [Math]::Min($found.least, [Math]::Max($p.R, [Math]::Max($p.G, $p.B))) }
        $found.least
    }
    $coastRow = { @(SubjectRows $topic)[0] }
    SelectRow (& $coastRow)
    Command $main $IDM_WATCH_CONVERSATION
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'Watching' } 10)) "Watch Conversation says so ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { ContextChecked $IDM_WATCH_CONVERSATION } 10)) 'the right-click menu checks Watch Conversation'
    Check (MenuChecked 4 $IDM_WATCH_CONVERSATION) 'and Watch Conversation is checked in the Message menu'
    Check (-not (MenuChecked 4 $IDM_IGNORE_CONVERSATION)) 'Ignore Conversation is not'
    Shot $main 'threads-4-watch'
    # a reply to it while the window is minimized: announced as a watched conversation
    [void](Notified '')
    $toolbarHeight = { $r = New-Object Native.Win+RECT; [void][Native.Win]::GetWindowRect($toolbar, [ref]$r); $r.Bottom - $r.Top }
    $tallBefore = & $toolbarHeight
    Minimize
    $coast += 'coast4@example.com'
    AddMessage ("From: Dan <dan@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $topic`r`n" +
        "Message-ID: <$($coast[3])>`r`nIn-Reply-To: <$($coast[2])>`r`nReferences: <$($coast[0])> <$($coast[2])>`r`n" +
        "Date: $($date.AddMinutes(4).ToString('r'))`r`n`r`nCount me in as well.`r`n")
    Command $main $IDM_SYNC
    Check ([bool](WaitFor { Notified 'Watched conversation' } 30)) 'a new reply to it is announced as a watched conversation'
    Restore
    Check ([bool](WaitFor { (& $toolbarHeight) -eq $tallBefore } 5)) "minimized and restored, the toolbar keeps its labels ($(& $toolbarHeight), was $tallBefore)"
    SelectRow (& $coastRow)
    Command $main $IDM_WATCH_CONVERSATION
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'Stopped watching' } 10)) "Watch Conversation again stops watching it ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { -not (ContextChecked $IDM_WATCH_CONVERSATION) } 10)) 'and the right-click menu no longer checks it'
    Check (-not (MenuChecked 4 $IDM_WATCH_CONVERSATION)) 'and the menu item is no longer checked'

    # another conversation, ignored with K
    $party = 'Garden party'
    $garden = @('garden1@example.com', 'garden2@example.com', 'garden3@example.com')
    $gardenSeen = { @($garden | Where-Object { Seen "Message-ID: <$([regex]::Escape($_))>" }).Count }
    AddMessage ("From: Erin <erin@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $party`r`n" +
        "Message-ID: <$($garden[0])>`r`nDate: $($date.AddMinutes(5).ToString('r'))`r`n`r`nA garden party on Saturday, who is coming?`r`n")
    AddMessage ("From: Frank <frank@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $party`r`n" +
        "Message-ID: <$($garden[1])>`r`nIn-Reply-To: <$($garden[0])>`r`nReferences: <$($garden[0])>`r`n" +
        "Date: $($date.AddMinutes(6).ToString('r'))`r`n`r`nI will bring a cake.`r`n")
    Command $main $IDM_SYNC
    $partyRow = { @(SubjectRows $party)[0] }
    Check ([bool](WaitFor { $null -ne (& $partyRow) } 30)) 'a second conversation is in the Inbox'
    SelectRow (& $partyRow)
    Key $list $VK_K
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match 'Ignoring' } 10)) "K ignores the conversation ($(StatusPart $mainStatus 0))"
    Check ([bool](WaitFor { (& $gardenSeen) -eq 2 } 20)) "and marks its messages read on the server ($(& $gardenSeen))"
    Check ([bool](WaitFor { ContextChecked $IDM_IGNORE_CONVERSATION } 10)) 'the right-click menu checks Ignore Conversation'
    Check (MenuChecked 4 $IDM_IGNORE_CONVERSATION) 'and Ignore Conversation is checked in the Message menu'
    # another row selected, so the ignored one is drawn on the list's white
    SelectRow (& $coastRow)
    $grey = & $darkest (& $partyRow)
    Check ($grey -gt 60) "its row is grey (darkest $grey, $(& $darkest (& $coastRow)) for another)"
    Shot $main 'threads-5-ignore'
    # a reply to it while the window is minimized: read on the server, not announced
    [void](Notified '')
    Minimize
    AddMessage ("From: Gail <gail@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $party`r`n" +
        "Message-ID: <$($garden[2])>`r`nIn-Reply-To: <$($garden[1])>`r`nReferences: <$($garden[0])> <$($garden[1])>`r`n" +
        "Date: $($date.AddMinutes(7).ToString('r'))`r`n`r`nCan I bring my dog?`r`n")
    Command $main $IDM_SYNC
    Check ([bool](WaitFor { (& $gardenSeen) -eq 3 } 30)) "a new reply to it arrives read on the server ($(& $gardenSeen))"
    Start-Sleep -Seconds 2
    Check (Notified '') 'without a notification'
    Restore
    # View > Hide Ignored Conversations leaves it out, kept for the next start
    Command $main $IDM_HIDE_IGNORED
    Check ([bool](WaitFor { (SubjectRows $party).Count -eq 0 -and (SubjectRows $topic).Count -eq 1 } 10)) 'Hide Ignored Conversations leaves the ignored conversation out of the list'
    Check (MenuChecked 2 $IDM_HIDE_IGNORED) 'and is checked in the View menu'
    Check ((Get-ItemProperty -Path $preferencesKey -Name HideIgnoredConversations -ErrorAction SilentlyContinue).HideIgnoredConversations -eq 1) 'and that is kept for the next start'
    Command $main $IDM_HIDE_IGNORED
    Check ([bool](WaitFor { (SubjectRows $party).Count -eq 1 } 10)) 'turned off again, it is back'
    Check (-not (MenuChecked 2 $IDM_HIDE_IGNORED)) 'and the menu item is no longer checked'
    $coast += $garden

    # the Inbox as the steps after expect it, without the conversations
    foreach ($id in $coast) {
        $m = Find 'INBOX' "Message-ID: <$([regex]::Escape($id))>"
        if ($m) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($m.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { (SubjectRows $topic).Count -eq 0 } 20)

    # ---- unread messages only ----

    Step 'unread messages only'
    $IDM_HIDE_READ = 154; $TB_ISBUTTONCHECKED = 0x040A
    # two unread messages and one read, each a conversation of its own
    $unreadOnly = @('Unread only: still to read', 'Unread only: read in the list', 'Unread only: read before')
    $unreadAt = [DateTime]::UtcNow
    for ($i = 0; $i -lt 3; $i++) {
        AddMessage ("From: Ivy <ivy@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $($unreadOnly[$i])`r`n" +
            "Message-ID: <unread-only-$i@example.com>`r`nDate: $($unreadAt.AddMinutes(-$i).ToString('r'))`r`n`r`nA message for the filter.`r`n") @(if ($i -eq 2) { '\Seen' })
    }
    Command $main $IDM_SYNC
    SelectFolder 0
    $listed = { param($subject) (SubjectRows $subject).Count -eq 1 }
    Check ([bool](WaitFor { @($unreadOnly | Where-Object { & $listed $_ }).Count -eq 3 } 30)) 'three messages for the filter are in the Inbox, one of them read'
    $allRows = Rows
    Command $main $IDM_HIDE_READ
    Check ([bool](WaitFor { (& $listed $unreadOnly[0]) -and (& $listed $unreadOnly[1]) -and -not (& $listed $unreadOnly[2]) } 10)) "View > Hide Read Messages lists the unread ones only ($allRows rows before, $(Rows) now)"
    Check (MenuChecked 2 $IDM_HIDE_READ) 'and is checked in the View menu'
    Check ([int][Native.Win]::SendMessage($toolbar, $TB_ISBUTTONCHECKED, [IntPtr]$IDM_HIDE_READ, [IntPtr]::Zero) -ne 0) "the toolbar's Unread button is pressed"
    Check ((Get-ItemProperty -Path $preferencesKey -Name HideReadMessages -ErrorAction SilentlyContinue).HideReadMessages -eq 1) 'and that is kept for the next start'
    # one read in the reading pane stays in the list until the folder changes
    Check (SelectSubject $unreadOnly[1]) "the reading pane shows the message selected ($($unreadOnly[1]))"
    Check ([bool](WaitFor { Seen "Subject: $([regex]::Escape($unreadOnly[1]))" } 20)) 'reading one marks it read on the server'
    Start-Sleep -Seconds 1
    Check (& $listed $unreadOnly[1]) 'and it stays in the list while the folder is shown'
    Shot $main 'list-unread-only'
    SelectFolder 1
    Start-Sleep -Seconds 1
    SelectFolder 0
    Check ([bool](WaitFor { (& $listed $unreadOnly[0]) -and -not (& $listed $unreadOnly[1]) } 10)) 'another folder and back: the one read is gone, the unread one is there'
    Command $main $IDM_HIDE_READ
    Check ([bool](WaitFor { @($unreadOnly | Where-Object { & $listed $_ }).Count -eq 3 } 10)) 'turned off, every message is listed again'
    Check (-not (MenuChecked 2 $IDM_HIDE_READ)) 'and the menu item is no longer checked'
    Check ([int][Native.Win]::SendMessage($toolbar, $TB_ISBUTTONCHECKED, [IntPtr]$IDM_HIDE_READ, [IntPtr]::Zero) -eq 0) 'and the button is up'
    for ($i = 0; $i -lt 3; $i++) {
        $m = Find 'INBOX' "Message-ID: <unread-only-$i@example.com>"
        if ($m) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($m.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { @($unreadOnly | Where-Object { & $listed $_ }).Count -eq 0 } 20)

    # ---- the folder list hidden ----

    Step 'the folder list hidden and shown again'
    $IDM_FOLDER_LIST = 155; $IDC_FOLDER_BAR = 235; $IDC_FOLDER_CAPTION = 236; $STN_CLICKED = 0
    Check ((Visible $main $IDC_TREE) -and (Visible $main $IDC_FOLDER_CAPTION) -and (MenuChecked 2 $IDM_FOLDER_LIST)) 'the folder list starts beside the messages under its Folders caption, View > Folder List checked'
    Check ([int][Native.Win]::SendMessage($toolbar, $TB_ISBUTTONCHECKED, [IntPtr]$IDM_FOLDER_LIST, [IntPtr]::Zero) -ne 0) "and the toolbar's Folders button is pressed"
    Command $main $IDM_FOLDER_LIST
    Check ([bool](WaitFor { -not (Visible $main $IDC_TREE) -and -not (Visible $main $IDC_FOLDER_CAPTION) } 5)) 'View > Folder List hides the list and its caption'
    Check (-not (MenuChecked 2 $IDM_FOLDER_LIST)) 'and the menu item is no longer checked'
    Check ([int][Native.Win]::SendMessage($toolbar, $TB_ISBUTTONCHECKED, [IntPtr]$IDM_FOLDER_LIST, [IntPtr]::Zero) -eq 0) "and the toolbar's Folders button is up"
    Check ((Get-ItemProperty -Path $preferencesKey -Name FolderList -ErrorAction SilentlyContinue).FolderList -eq 0) 'and that is kept for the next start'
    $listRect = New-Object Native.Win+RECT; $mainRect = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($list, [ref]$listRect); [void][Native.Win]::GetWindowRect($main, [ref]$mainRect)
    Check (($listRect.Left - $mainRect.Left) -lt 40) 'the messages take the width'
    Shot $main 'layout-3-folders-hidden'
    # the folder bar drops the list down; Esc closes it again
    [void][Native.Win]::SendMessage($main, $WM_COMMAND, [IntPtr]($IDC_FOLDER_BAR -bor ($STN_CLICKED -shl 16)), [Native.Win]::GetDlgItem($main, $IDC_FOLDER_BAR))
    $drop = WaitFor { $d = [Native.Win]::FindWindow('InboxClassicFolderDrop', [NullString]::Value); if ($d -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($d)) { $d } } 5
    Check ([bool]$drop -and [Native.Win]::IsWindowVisible($tree)) 'a click on the folder bar drops the folder list down'
    if ($drop) {
        Shot $drop 'layout-3b-folder-drop'
        [void][Native.Win]::PostMessage($drop, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($drop) -and -not (Visible $main $IDC_TREE) } 5)) 'and it closes, the list hidden again'
    }
    Command $main $IDM_FOLDER_LIST
    Check ([bool](WaitFor { (Visible $main $IDC_TREE) -and (Visible $main $IDC_FOLDER_CAPTION) } 5)) 'turned on, the folder list is back beside the messages'
    Check ([int][Native.Win]::SendMessage($toolbar, $TB_ISBUTTONCHECKED, [IntPtr]$IDM_FOLDER_LIST, [IntPtr]::Zero) -ne 0) "and the Folders button is pressed again"
    Check ((Get-ItemProperty -Path $preferencesKey -Name FolderList -ErrorAction SilentlyContinue).FolderList -eq 1) 'and that is kept'

    # ---- the column layout ----

    Step 'the column layout'
    $IDM_LAYOUT_AUTOMATIC = 156; $IDM_LAYOUT_CLASSIC = 157; $IDM_LAYOUT_COLUMNS = 158
    $IDM_SORT_DATE = 159; $IDM_SORT_SUBJECT = 161; $IDC_SORT_BUTTON = 238
    $GWL_STYLE = -16; $LVS_NOCOLUMNHEADER = 0x4000
    $columnsShown = { (([Native.Win]::GetWindowLong($list, $GWL_STYLE) -band $LVS_NOCOLUMNHEADER) -ne 0) -and (Visible $main $IDC_SORT_BUTTON) }
    $listRect = New-Object Native.Win+RECT; $mainRect = New-Object Native.Win+RECT
    # the list beside the reading pane: as tall as the panes, in the left part of the window
    $beside = {
        [void][Native.Win]::GetWindowRect($list, [ref]$listRect); [void][Native.Win]::GetWindowRect($main, [ref]$mainRect)
        ($listRect.Bottom - $listRect.Top) -gt ($mainRect.Bottom - $mainRect.Top) / 2 -and
            ($listRect.Right - $mainRect.Left) -lt ($mainRect.Right - $mainRect.Left) * 0.7
    }
    # a conversation of two, for the conversation's row
    $ferry = @('ferry1@example.com', 'ferry2@example.com')
    $ferryAt = [DateTime]::UtcNow
    AddMessage ("From: Petra Holm <petra@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Ferry times`r`n" +
        "Message-ID: <$($ferry[0])>`r`nDate: $($ferryAt.ToString('r'))`r`n`r`nThe first ferry leaves at nine, the last one at six.`r`n")
    AddMessage ("From: Jaan Kask <jaan@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: Ferry times`r`n" +
        "Message-ID: <$($ferry[1])>`r`nIn-Reply-To: <$($ferry[0])>`r`nReferences: <$($ferry[0])>`r`n" +
        "Date: $($ferryAt.AddMinutes(1).ToString('r'))`r`n`r`nNine works for me.`r`n")
    Command $main $IDM_SYNC
    SelectFolder 0
    Check ([bool](WaitFor { (SubjectRows 'Ferry times').Count -eq 1 } 30)) 'a conversation of two is in the Inbox'
    Check (-not (& $columnsShown)) 'the test starts in Classic, the list over the reading pane'
    Command $main $IDM_LAYOUT_COLUMNS
    Check ([bool](WaitFor { (& $columnsShown) -and (& $beside) } 5)) 'View > Layout > Columns puts the list beside the reading pane, without headings, "Sorted by" over it'
    Check ((Get-ItemProperty -Path $preferencesKey -Name Layout -ErrorAction SilentlyContinue).Layout -eq 2) 'and that is kept for the next start'
    $sortText = { GetText $main $IDC_SORT_BUTTON }
    Check ((& $sortText) -match 'Date') "it says the list is sorted by date ($(& $sortText))"
    $first = @(SubjectRows 'Ferry times')
    if ($first.Count -eq 1) { SelectRow ([int]$first[0]) }
    # the top row right under "Sorted by": no header window, nothing of its room left above the rows
    $kListTop = 0x4C544F50
    $listTop = { [int][Native.Win]::SendText($main, $kListTop, '') }
    Check ((& $listTop) -ge 1000 -and (& $listTop) -le 1003) "the rows start at the top of the list, no header's room above them ($(& $listTop))"
    Shot $main 'layout-1-columns'
    # sorted by subject from the menu of "Sorted by" (the View menu's Sort By), A to Z, and back to the dates
    Command $main $IDM_SORT_SUBJECT
    Check ([bool](WaitFor { (& $sortText) -match 'Subject' } 5)) "Sort By Subject: the button says so ($(& $sortText))"
    $subjects = @(0..([Math]::Min(4, (Rows) - 1)) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
    $inOrder = $true
    for ($i = 1; $i -lt $subjects.Count; $i++) { if ([string]::Compare($subjects[$i - 1], $subjects[$i], $true) -gt 0) { $inOrder = $false } }
    Check $inOrder "the rows are in the order of their subjects ($($subjects -join ' | '))"
    Shot $main 'layout-4-sort'
    Command $main $IDM_SORT_DATE
    Check ([bool](WaitFor { (& $sortText) -match 'Date' } 5)) 'and back to the dates'
    # a conversation opened in Columns: its message under it, indented
    $head = @(SubjectRows 'Ferry times')
    if ($head.Count -eq 1) {
        $rowsBefore = Rows
        SelectRow ([int]$head[0])
        Key $list $VK_RIGHT
        Check ([bool](WaitFor { (Rows) -eq $rowsBefore + 1 } 10)) "Right opens the conversation in Columns too ($(Rows) rows)"
        Shot $main 'layout-5-conversation'
        Key $list $VK_LEFT
        [void](WaitFor { (Rows) -eq $rowsBefore } 10)
    } else {
        Check $false 'the conversation has one row'
    }
    # the senders' pictures beside the rows: a brand's logo the provider passed (from a server of the test on the
    # loopback address, which the app takes with --test-hooks; downloaded once, when its row is drawn), or the initials
    # on a quiet square; the Options box takes them away and brings them back
    $kRowPicture = 0x50494354; $IDM_OPTIONS = 137; $IDC_OPTIONS_LIST_PICTURES = 676
    $rowPicture = { param($subject) [int][Native.Win]::SendText($main, $kRowPicture, $subject) }
    $brandSvg = '<svg xmlns="http://www.w3.org/2000/svg" version="1.2" baseProfile="tiny-ps" viewBox="0 0 100 100"><title>Brand</title>' +
        '<rect width="100" height="100" fill="#1f6b3a"/><path d="M28 72V28h24c10 0 17 6 17 14s-6 13-14 14l16 16H58L44 57h-4v15z' +
        'M40 47h11c4 0 6-2 6-5s-2-5-6-5H40z" fill="#fff"/></svg>'
    $logoServer = New-Object System.Net.Sockets.TcpListener ([System.Net.IPAddress]::Loopback, 0)
    $logoServer.Start()
    $logoPort = $logoServer.LocalEndpoint.Port
    $script:logoAccepted = $logoServer.AcceptTcpClientAsync()
    $script:logoServed = 0
    # a request that came answered with the logo, by hand: an HTTP/1.1 reply that closes
    $serveLogo = {
        if (-not $script:logoAccepted.IsCompleted) { return }
        $client = $script:logoAccepted.Result
        $stream = $client.GetStream()
        $buffer = New-Object byte[] 4096
        [void]$stream.Read($buffer, 0, $buffer.Length)
        $body = [Text.Encoding]::UTF8.GetBytes($brandSvg)
        $head = [Text.Encoding]::ASCII.GetBytes("HTTP/1.1 200 OK`r`nContent-Type: image/svg+xml`r`nContent-Length: $($body.Length)`r`nConnection: close`r`n`r`n")
        $stream.Write($head, 0, $head.Length)
        $stream.Write($body, 0, $body.Length)
        $client.Close()
        $script:logoServed++
        $script:logoAccepted = $logoServer.AcceptTcpClientAsync()
    }
    $branded = 'Autumn collection'
    AddMessage ("Authentication-Results: mx.inboxclassic.test; dmarc=pass header.from=brand.example; bimi=pass header.d=brand.example`r`n" +
        "BIMI-Location: v=BIMI1; l=http://127.0.0.1:$logoPort/logo.svg`r`nFrom: Northwind <news@brand.example>`r`n" +
        "To: testuser@inboxclassic.test`r`nSubject: $branded`r`nMessage-ID: <autumn@brand.example>`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`n`r`nThe new collection is here.`r`n")
    Command $main $IDM_SYNC
    Check ([bool](WaitFor { (SubjectRows $branded).Count -eq 1 } 30)) 'a message whose provider passed its brand logo is in the Inbox'
    Check ([bool](WaitFor { & $serveLogo; (& $rowPicture $branded) -eq 12 } 40)) "its row shows the brand's logo ($(& $rowPicture $branded), downloaded $script:logoServed times)"
    Check ((& $rowPicture 'Ferry times') -eq 11) "a sender without a logo has the initials beside the row ($(& $rowPicture 'Ferry times'))"
    $ferryRow = @(SubjectRows 'Ferry times')
    if ($ferryRow.Count -eq 1) { SelectRow ([int]$ferryRow[0]) }
    Shot $main 'pictures-4-list'
    function SetListPictures([bool]$on) {
        Command $main $IDM_OPTIONS
        $o = WaitShown 'InboxClassicOptions' 10
        if (-not $o) { return $false }
        OptionsPage $o 1
        $box = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_LIST_PICTURES)
        $was = [int][Native.Win]::SendMessage($box, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero)
        [void][Native.Win]::SendMessage($box, $BM_SETCHECK, [IntPtr]([int]$on), [IntPtr]::Zero)
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
        $box -ne [IntPtr]::Zero -and $was -eq [int](-not $on)
    }
    Check (SetListPictures $false) 'Options shows the senders'' pictures, on at first, and turns them off'
    Check ((& $rowPicture 'Ferry times') -eq 10 -and (Get-ItemProperty -Path $preferencesKey -Name ListPictures -ErrorAction SilentlyContinue).ListPictures -eq 0) 'off: the rows have none, and that is kept'
    Check (SetListPictures $true) 'and turns them on again'
    Check ((& $rowPicture 'Ferry times') -eq 11) 'on: the initials are back'
    # Automatic: Columns in a wide window, Classic in a narrow one
    $kept = New-Object Native.Win+RECT
    [void][Native.Win]::GetWindowRect($main, [ref]$kept)
    Command $main $IDM_LAYOUT_AUTOMATIC
    [void][Native.Win]::SetWindowPos($main, [IntPtr]::Zero, 0, 0, 1500, 900, 0x0016)
    Check ([bool](WaitFor { (& $columnsShown) -and (& $beside) } 5)) 'Automatic: a window 1500 wide shows Columns'
    Shot $main 'layout-2-automatic'
    [void][Native.Win]::SetWindowPos($main, [IntPtr]::Zero, 0, 0, 1100, 760, 0x0016)
    Check ([bool](WaitFor { -not (& $columnsShown) } 5)) 'and one 1100 wide Classic'
    Command $main $IDM_LAYOUT_CLASSIC
    [void][Native.Win]::SetWindowPos($main, [IntPtr]::Zero, $kept.Left, $kept.Top, $kept.Right - $kept.Left, $kept.Bottom - $kept.Top, 0x0014)
    Check ([bool](WaitFor { -not (& $columnsShown) } 5)) 'Classic again: the list over the reading pane'
    $logoServer.Stop()
    foreach ($id in $ferry + @('autumn@brand.example')) {
        $m = Find 'INBOX' "Message-ID: <$([regex]::Escape($id))>"
        if ($m) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($m.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { (SubjectRows 'Ferry times').Count -eq 0 } 20)

    # ---- a message that bounced ----

    Step 'a message that bounced'
    # a message in Sent Items, a report that it could not be delivered to one of its recipients and a notice that it
    # is delayed for the other, in the forms of pe-bounce's fixtures (Postfix's report, a delay notice)
    $bounced = 'Plans for the weekend'
    $failedSubject = 'Undelivered Mail Returned to Sender'
    $delayedSubject = 'Delayed Mail (still being retried)'
    $serverWords = 'The email account that you tried to reach does not exist'
    $now = [DateTime]::UtcNow
    $original = @(
        'From: Alex Morgan <testuser@inboxclassic.test>', 'To: Sam Nobody <sam.nobody@example.org>, Kim <kim@example.net>',
        "Subject: $bounced", 'Message-ID: <bounce-original@inboxclassic.test>', "Date: $($now.AddMinutes(-10).ToString('r'))")
    AddMessage (($original -join "`r`n") + "`r`n`r`nShall we go to the lake on Saturday?`r`n") @('\Seen') 'Sent'
    AddMessage ((@(
        'From: MAILER-DAEMON@mail.inboxclassic.test (Mail Delivery System)', 'To: testuser@inboxclassic.test',
        "Subject: $failedSubject", 'Message-ID: <bounce-failed@mail.inboxclassic.test>', "Date: $($now.ToString('r'))",
        'Auto-Submitted: auto-replied', 'MIME-Version: 1.0',
        'Content-Type: multipart/report; report-type=delivery-status; boundary="failed"', '',
        'This is a MIME-encapsulated message.', '', '--failed', 'Content-Description: Notification',
        'Content-Type: text/plain; charset=us-ascii', '', 'This is the mail system at host mail.inboxclassic.test.', '',
        "I'm sorry to have to inform you that your message could not", "be delivered to one or more recipients. It's attached below.", '',
        '                   The mail system', '', '--failed', 'Content-Description: Delivery report',
        'Content-Type: message/delivery-status', '', 'Reporting-MTA: dns; mail.inboxclassic.test', '',
        'Final-Recipient: rfc822; sam.nobody@example.org', 'Original-Recipient: rfc822;sam.nobody@example.org', 'Action: failed',
        'Status: 5.1.1', 'Remote-MTA: dns; mx.example.org', "Diagnostic-Code: smtp; 550 5.1.1 $serverWords. Please try double-checking the recipient's email address for typos", '',
        '--failed', 'Content-Description: Undelivered Message Headers', 'Content-Type: text/rfc822-headers', '') + $original +
        @('', '--failed--', '')) -join "`r`n")
    AddMessage ((@(
        'From: Mail Delivery System <MAILER-DAEMON@mail.inboxclassic.test>', 'To: testuser@inboxclassic.test',
        "Subject: $delayedSubject", 'Message-ID: <bounce-delayed@mail.inboxclassic.test>', "Date: $($now.AddMinutes(-1).ToString('r'))",
        'MIME-Version: 1.0', 'Content-Type: multipart/report; report-type=delivery-status; boundary="delayed"', '',
        '--delayed', 'Content-Type: text/plain', '', 'This is a warning message only. Delivery is still being retried.', '',
        '--delayed', 'Content-Type: message/delivery-status', '', 'Reporting-MTA: dns; mail.inboxclassic.test', '',
        'Final-Recipient: rfc822; kim@example.net', 'Action: delayed', 'Status: 4.4.1',
        "Will-Retry-Until: $($now.AddDays(5).ToString('r'))", 'Diagnostic-Code: smtp; 421 4.4.1 Connection timed out', '',
        '--delayed', 'Content-Type: text/rfc822-headers', '') + $original + @('', '--delayed--', '')) -join "`r`n")
    Command $main $IDM_SYNC
    # the message that bounced in the store, so the card can link to it
    SelectFolder 1
    Check ([bool](WaitFor { $null -ne (& $rowOf $bounced) } 20)) 'the message is in Sent Items'
    SelectFolder 0
    Check ([bool](WaitFor { ($null -ne (& $rowOf $failedSubject)) -and ($null -ne (& $rowOf $delayedSubject)) } 20)) 'the report and the delay notice are in the Inbox'

    # the dark pixels of a row's attachment column (0), as the screen shows them: where its icon is
    $markCell = {
        param($row)
        $bounds = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]$row, 0)
        # LVM_GETCOLUMNWIDTH
        $width = [int][Native.Win]::SendMessage($list, 0x101D, [IntPtr]0, [IntPtr]::Zero)
        [pscustomobject]@{ Left = $bounds.Left; Top = $bounds.Top; Right = $bounds.Left + $width; Bottom = $bounds.Bottom }
    }
    $markOf = {
        param($row)
        $picture = CellPicture $row $markCell
        if (-not $picture) { return '' }
        $dark = @()
        for ($x = 0; $x -lt $picture.Width; $x++) {
            for ($y = 0; $y -lt $picture.Height; $y++) {
                $p = $picture.GetPixel($x, $y)
                if ($p.R -lt 120 -and $p.G -lt 120 -and $p.B -lt 120) { $dark += "$x,$y" }
            }
        }
        $dark -join ' '
    }
    # another row selected, so the marks are drawn on the list's white
    $failedRow = & $rowOf $failedSubject
    $delayedRow = & $rowOf $delayedSubject
    $clipRow = & $rowOf $newsletter
    $otherRow = @(0..((Rows) - 1) | Where-Object { $_ -ne $failedRow -and $_ -ne $delayedRow -and $_ -ne $clipRow })[0]
    SelectRow $otherRow
    $failedMark = & $markOf $failedRow
    $clipMark = if ($null -ne $clipRow) { & $markOf $clipRow } else { '' }
    Check ($failedMark -ne '' -and $failedMark -ne $clipMark) 'the report has the undelivered mark in the attachment column, not a paper clip'
    Check ((& $markOf $delayedRow) -eq $failedMark) 'and so has the delay notice'

    SelectRow $failedRow
    Check ([bool](WaitFor { $null -ne (& $cardPoint 196 43 28) } 15)) 'opening the report shows the red card of a message not delivered'
    # Show the message that bounced: the card's button, followed as a click on it would be
    Check ([bool](WaitFor { & $foundInMessage 'Show the message that bounced' } 5)) 'the card has Show the message that bounced'
    Check ([Native.Win]::SendText($main, 0x4C494E4B, 'inboxclassic:bounced-message') -eq 1) 'which is a link of the card'
    Check ([bool](WaitFor { (WindowText $main) -eq 'Sent Items - Inbox Classic' -and (SelectedRow) -ge 0 -and [Native.Win]::RemoteListText($list, (SelectedRow), $COL_SUBJECT) -eq $bounced } 10)) "and it selects the message in Sent Items ($(WindowText $main))"
    SelectFolder 0
    [void](WaitFor { $null -ne (& $rowOf $failedSubject) } 20)
    Check (SelectSubject $failedSubject) "the reading pane shows the message selected ($($failedSubject))"
    [void](WaitFor { $null -ne (& $cardPoint 196 43 28) } 15)
    Check ([bool](WaitFor { & $foundInMessage 'Your message was not delivered' } 5)) 'the card says the message was not delivered'
    Check ([bool](WaitFor { & $foundInMessage 'sam.nobody@example.org' } 5)) 'it names the recipient'
    Check ([bool](WaitFor { & $foundInMessage 'The address does not exist' } 5)) 'why'
    Check ([bool](WaitFor { & $foundInMessage 'Check the spelling of the address' } 5)) 'and what to do'
    # Details, folded, opened by the find
    Check ([bool](WaitFor { & $foundInMessage $serverWords } 5)) "its Details show the server's own words"
    Shot $main 'bounce-1-failed'

    Check (SelectSubject $delayedSubject) "the reading pane shows the message selected ($($delayedSubject))"
    Check ([bool](WaitFor { $null -ne (& $cardPoint 154 91 0) } 15)) 'a delay notice shows the amber card'
    Check ([bool](WaitFor { & $foundInMessage 'Your message has not been delivered yet' } 5)) 'it says the message is not delivered yet'
    Check ([bool](WaitFor { & $foundInMessage 'still trying to deliver it' } 5)) 'and that it is still being tried'
    Shot $main 'bounce-2-delayed'

    [void][Native.Win]::SendMessage($find, $WM_SETTEXT, [IntPtr]::Zero, 'is:bounce')
    $both = WaitFor {
        $found = @(0..([Math]::Max(0, (Rows) - 1)) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_SUBJECT) })
        if ((Rows) -eq 2 -and $found -contains $failedSubject -and $found -contains $delayedSubject) { $true }
    } 15
    Check ([bool]$both) "is:bounce finds the two notices and nothing else ($(Rows))"
    Shot $main 'bounce-3-list'
    Click $main $IDC_SEARCH_CLEAR
    [void](WaitFor { -not (Visible $main $IDC_SEARCH_BAR) } 10)
    # the messages of this step go, so the folders are as the steps after expect them
    foreach ($added in @((Find 'INBOX' "Subject: $([regex]::Escape($failedSubject))"), (Find 'INBOX' "Subject: $([regex]::Escape($delayedSubject))"))) {
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    $sentCopy = Find 'Sent' "Subject: $bounced"
    if ($sentCopy) { [void](Invoke-RestMethod -Method Delete "$rest/Sent/messages/$($sentCopy.uid)") }
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { $null -eq (& $rowOf $failedSubject) -and $null -eq (& $rowOf $delayedSubject) } 20)

    # ---- a one-time code ----

    Step 'a one-time code'
    # a code in the text of a message the provider says example.com signed, one in an OTP-Token header, one unsigned
    $kTestLink = 0x4C494E4B
    $codeMessage = {
        param([bool]$verdict, [string]$extra, [string]$subject, [string]$id, [string]$body)
        $head = if ($verdict) { "Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=example.com`r`n" } else { '' }
        $head + $extra + "From: Example Accounts <no-reply@accounts.example.com>`r`nTo: testuser@inboxclassic.test`r`n" +
            "Subject: $subject`r`nDate: $($now.AddHours(-3).ToString('r'))`r`nMessage-ID: <$id@example.com>`r`n" +
            "MIME-Version: 1.0`r`nContent-Type: text/plain; charset=utf-8`r`n`r`n$body`r`n"
    }
    $codeText = { param($digits) "Hello,`r`n`r`nYour verification code is $digits.`r`n`r`nIt expires in 10 minutes. If you did not ask for it, ignore this email." }
    $codeSubjects = @('Your sign-in code', 'Sign in to Example', 'Your code, unsigned')
    AddMessage (& $codeMessage $true '' $codeSubjects[0] 'code-body' (& $codeText '482913')) @('\Seen')
    AddMessage (& $codeMessage $true "OTP-Token: `"917355`"; origin=`"https://login.example.com`"`r`n" $codeSubjects[1] 'code-header' 'Use the code at the top of this message to sign in.') @('\Seen')
    AddMessage (& $codeMessage $false '' $codeSubjects[2] 'code-unsigned' (& $codeText '771204')) @('\Seen')
    Command $main $IDM_SYNC
    SelectFolder 0
    $codesIn = WaitFor { if (@($codeSubjects | Where-Object { $null -ne (& $rowOf $_) }).Count -eq 3) { $true } } 30
    Check ([bool]$codesIn) 'three messages with codes are in the Inbox'
    # Copy on the card, as a click on it: the link followed, the code on the clipboard
    $copied = {
        param($subject)
        Set-Clipboard -Value 'nothing'
        Check (SelectSubject $subject) "the reading pane shows the message selected ($($subject))"
        [void](WaitFor { (WindowText $main) -match 'Inbox' } 5)
        Start-Sleep -Seconds 2
        [void][Native.Win]::SendText($main, $kTestLink, 'inboxclassic:copy-code')
        Start-Sleep -Milliseconds 500
        (Get-Clipboard -Raw)
    }
    $first = & $copied $codeSubjects[0]
    Check ($first -eq '482913') "Copy on the card of a signed message puts its code on the clipboard ($first)"
    Check ((StatusPart $mainStatus 0) -eq 'Copied the code') "and the status bar says so ($(StatusPart $mainStatus 0))"
    # a sync in the background (the timer's) replaces only its own words, never the answer to what the user did
    [void][Native.Win]::PostMessage($main, 0x0113, [IntPtr]2, [IntPtr]::Zero)
    Start-Sleep -Seconds 3
    Check ((StatusPart $mainStatus 0) -eq 'Copied the code') "a sync in the background leaves those words ($(StatusPart $mainStatus 0))"
    Shot $main 'otp-1-card'
    $second = & $copied $codeSubjects[1]
    Check ($second -eq '917355') "an OTP-Token header gives the code ($second)"
    $third = & $copied $codeSubjects[2]
    Check ($third -eq 'nothing') "an unsigned message has no card, so nothing is copied ($third)"
    foreach ($subject in $codeSubjects) {
        $added = Find 'INBOX' "Subject: $([regex]::Escape($subject))"
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { @($codeSubjects | Where-Object { $null -ne (& $rowOf $_) }).Count -eq 0 } 20)

    # ---- emoji reactions ----

    Step 'emoji reactions'
    $IDC_REACTIONS = 246; $kTestRowField = 0x544C424C
    $thumb = [char]::ConvertFromUtf32(0x1F44D)
    $reacted = 'Furniture'
    AddMessage ("From: Kate Kalda <kate@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $reacted`r`n" +
        "Date: $($now.AddHours(-2).ToString('r'))`r`nMessage-ID: <furniture-prices@example.com>`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: text/plain; charset=utf-8`r`n`r`nThe prices for the new chairs are in.`r`n") @('\Seen')
    Command $main $IDM_SYNC
    SelectFolder 0
    Check ([bool](WaitFor { $null -ne (& $rowOf $reacted) } 30)) 'a message from Kate is in the Inbox'
    # Gmail's reaction to it from Kate, whose domain the provider says signed it: plain text, the reaction part, HTML
    AddMessage ("Authentication-Results: mx.inboxclassic.test; dkim=pass header.d=example.com`r`n" +
        "From: Kate Kalda <kate@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Re: $reacted`r`n" +
        "Date: $($now.AddHours(-1).ToString('r'))`r`nMessage-ID: <furniture-reaction@example.com>`r`n" +
        "In-Reply-To: <furniture-prices@example.com>`r`nReferences: <furniture-prices@example.com>`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: multipart/alternative; boundary=`"r`"`r`n`r`n" +
        "--r`r`nContent-Type: text/plain; charset=UTF-8`r`nContent-Transfer-Encoding: quoted-printable`r`n`r`n" +
        "=F0=9F=91=8D`r`n`r`nKate Kalda reacted via Gmail`r`n" +
        "--r`r`nContent-Type: text/vnd.google.email-reaction+json; charset=UTF-8`r`nContent-Transfer-Encoding: quoted-printable`r`n`r`n" +
        "{`"emoji`": `"=F0=9F=91=8D`", `"version`": 1}`r`n" +
        "--r`r`nContent-Type: text/html; charset=UTF-8`r`n`r`n<p style=`"font-size:50px`">&#x1F44D;</p><p>Kate Kalda reacted via Gmail</p>`r`n--r--`r`n")
    Command $main $IDM_SYNC
    $badged = WaitFor { if ([Native.Win]::SendText($main, $kTestRowField, "$reacted`nreactions`n$thumb") -eq 1) { $true } } 30
    Check ([bool]$badged) "the message's row carries the reaction's badge ($([Native.Win]::SendText($main, $kTestRowField, "$reacted`nreactions`n$thumb")))"
    # grouped by conversation, a reply listed would make the message's row a conversation's
    $listedAgain = { $null -ne (& $rowOf "Re: $reacted") -or [Native.Win]::SendText($main, $kTestRowField, "$reacted`nthread_label`n-") -ne 0 }
    Check (-not (& $listedAgain)) 'the reaction email is not in the Inbox list'
    Check ([bool](WaitFor { Seen 'Message-ID: <furniture-reaction@example\.com>' } 20)) 'and it is read on the server'
    Shot $main 'reactions-1-list'
    Check (SelectSubject $reacted) 'the reading pane shows the reacted message'
    $line = WaitFor { if (Visible $main $IDC_REACTIONS) { GetText $main $IDC_REACTIONS } } 10
    Check ("$line" -like "*$thumb Kate Kalda*") "its header has a Reactions line with Kate's reaction ($line)"
    Shot $main 'reactions-2-header'
    # the line's menu from the keyboard (the menu key): one person, so their items at once
    $reactionLine = [Native.Win]::GetDlgItem($main, $IDC_REACTIONS)
    $reactionMenu = {
        param([string]$choose, [string]$shot)
        [void][Native.Win]::PostMessage($reactionLine, 0x007B, $reactionLine, [IntPtr](-1))
        $menu = WaitWindow '#32768' $null 10
        if (-not $menu) { return @() }
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)))
        if ($shot) { Shot $main $shot $menu }
        $at = if ($choose) { [array]::IndexOf($labels, $choose) } else { -1 }
        if ($at -lt 0) {
            Key $menu $VK_ESCAPE
        } else {
            for ($i = 0; $i -le $at; $i++) { if ($labels[$i]) { Key $menu $VK_DOWN } }
            Key $menu $VK_RETURN
        }
        if (-not (WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 3)) {
            # where the menu does not take posted keys: real keystrokes, the app in front
            [void][Native.Win]::SetForegroundWindow($main)
            $keys = if ($at -lt 0) { '{ESC}' } else { ('{DOWN}' * @($labels[0..$at] | Where-Object { $_ }).Count) + '{ENTER}' }
            [System.Windows.Forms.SendKeys]::SendWait($keys)
            [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
        }
        $labels
    }
    $labels = & $reactionMenu 'Open Reaction Email' 'reactions-3-menu'
    Check (($labels -contains 'Open Reaction Email') -and ($labels -contains 'Show as Email') -and @($labels | Where-Object { $_ -like 'Reacted *' }).Count -eq 1) "the line's menu offers the reaction email and when ($($labels -join ' | '))"
    $reactionWindow = WaitWindow 'InboxClassicMessage' "Re: $reacted - Inbox Classic" 15
    Check ($null -ne $reactionWindow) 'Open Reaction Email shows the email in a message window'
    if ($reactionWindow) {
        Shot $reactionWindow 'reactions-4-email'
        [void][Native.Win]::PostMessage($reactionWindow, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { [Native.Win]::FindWindow('InboxClassicMessage', "Re: $reacted - Inbox Classic") -eq [IntPtr]::Zero } 5)
    }
    [void](& $reactionMenu 'Show as Email' $null)
    Check ([bool](WaitFor { & $listedAgain } 20)) 'Show as Email lists the reaction email again'
    Check ([bool](WaitFor { -not (Visible $main $IDC_REACTIONS) } 10)) 'and the Reactions line goes'
    Check ([Native.Win]::SendText($main, $kTestRowField, "$reacted`nreactions`n") -eq 1) 'and so does the badge'
    foreach ($pattern in 'Message-ID: <furniture-prices@example\.com>', 'Message-ID: <furniture-reaction@example\.com>') {
        $added = Find 'INBOX' $pattern
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { $null -eq (& $rowOf $reacted) -and $null -eq (& $rowOf "Re: $reacted") } 20)

    # ---- pictures from trusted senders ----

    Step 'pictures from trusted senders'
    $IDC_PICTURES_MENU = 234; $IDM_OPTIONS = 137; $IDC_OPTIONS_PICTURES = 665; $IDC_OPTIONS_TRUSTED = 667
    $IDC_TRUSTED_LIST = 669; $IDC_TRUSTED_REMOVE = 670; $IDC_TRUSTED_EMPTY = 671; $BM_SETCHECK = 0x00F1; $BM_GETCHECK = 0x00F0
    # a shop's newsletter with a picture on the internet: one the provider says shop.example signed, one it does not
    $shopMessage = {
        param([string]$verdict, [string]$subject, [string]$id)
        "Authentication-Results: mx.inboxclassic.test; dkim=$verdict header.d=shop.example; dmarc=$verdict header.from=shop.example`r`n" +
            "From: Shop Example <news@shop.example>`r`nTo: testuser@inboxclassic.test`r`nSubject: $subject`r`n" +
            "Date: $($now.AddHours(-4).ToString('r'))`r`nMessage-ID: <$id@shop.example>`r`nMIME-Version: 1.0`r`n" +
            "Content-Type: text/html; charset=utf-8`r`n`r`n<p>Our autumn sale starts today.</p>" +
            '<p><img src="https://nodemailer.com/img/nm_logo_200x136.png" width="200" height="136" alt="Sale"></p>' + "`r`n"
    }
    $shopSubjects = @('Autumn sale', 'Autumn sale, forged')
    AddMessage (& $shopMessage 'pass' $shopSubjects[0] 'sale-signed') @('\Seen')
    AddMessage (& $shopMessage 'fail' $shopSubjects[1] 'sale-forged') @('\Seen')
    Command $main $IDM_SYNC
    SelectFolder 0
    Check ([bool](WaitFor { @($shopSubjects | Where-Object { $null -ne (& $rowOf $_) }).Count -eq 2 } 30)) "two shop newsletters are in the Inbox"
    # a message shown, and whether the pictures bar is over it once it is there
    $showShop = {
        param($subject)
        Check (SelectSubject $subject) "the reading pane shows the message selected ($($subject))"
        Start-Sleep -Seconds 2
        Visible $main $IDC_PICTURES
    }
    # the bar's arrow menu: its labels, then the item $choose (by its label, none for Esc) chosen with the keys
    $pictureMenu = {
        param([string]$choose, [string]$shot)
        Command $main $IDC_PICTURES_MENU
        $menu = WaitWindow '#32768' $null 10
        if (-not $menu) { return @() }
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = @([Native.Win]::MenuLabels($hmenu))
        if ($shot) { Shot $main $shot $menu }
        $at = if ($choose) { [array]::IndexOf($labels, $choose) } else { -1 }
        if ($at -lt 0) {
            Key $menu $VK_ESCAPE
        } else {
            for ($i = 0; $i -le $at; $i++) { if ($labels[$i]) { Key $menu $VK_DOWN } }
            Key $menu $VK_RETURN
        }
        if (-not (WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 3)) {
            # where the menu does not take posted keys: real keystrokes, the app in front
            [void][Native.Win]::SetForegroundWindow($main)
            $keys = if ($at -lt 0) { '{ESC}' } else { ('{DOWN}' * @($labels[0..$at] | Where-Object { $_ }).Count) + '{ENTER}' }
            [System.Windows.Forms.SendKeys]::SendWait($keys)
            [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
        }
        $labels
    }
    $alwaysSender = 'Always download pictures from news@shop.example'
    $alwaysDomain = 'Always download pictures from everyone at shop.example'
    Check (& $showShop $shopSubjects[0]) 'a signed newsletter has its pictures blocked at first'
    Check (Visible $main $IDC_PICTURES_MENU) "and the bar has its arrow"
    $labels = & $pictureMenu $alwaysDomain 'pictures-2-trusted'
    Check (($labels -contains $alwaysSender) -and ($labels -contains $alwaysDomain) -and ($labels -contains 'Download Pictures')) "the arrow offers Always for the sender and their domain, and Download Pictures ($($labels -join ', '))"
    Check ([bool](WaitFor { -not (Visible $main $IDC_PICTURES) } 10)) 'Always from everyone at shop.example shows the pictures, and the bar goes'
    Check (& $showShop $shopSubjects[1]) 'a forged one from the same domain still has the bar'
    $labels = & $pictureMenu $null $null
    Check ((@($labels | Where-Object { $_ -like 'Always*' }).Count -eq 0) -and (@($labels | Where-Object { $_ -like '*shop.example*' }).Count -eq 1)) "its arrow has no Always, but says why ($($labels -join ', '))"
    Check (-not (& $showShop $shopSubjects[0])) 'the signed one shows its pictures by itself when opened again'
    # Options lists the domain, and Remove takes it away: back after Cancel, gone after OK
    function RemoveTrusted([string]$then, [string]$shot = $null) {
        Command $main $IDM_OPTIONS
        $o = WaitShown 'InboxClassicOptions' 10
        Check ($null -ne $o) 'Tools > Options opens'
        if (-not $o) { return }
        OptionsPage $o 1
        $always = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_PICTURES)
        Check ($always -ne [IntPtr]::Zero -and [int][Native.Win]::SendMessage($always, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 0) 'Options can download pictures in all messages, off at first'
        Click $o $IDC_OPTIONS_TRUSTED
        $trusted = WaitShown 'InboxClassicTrustedSenders' 10
        Check ($null -ne $trusted) 'Trusted Senders... opens the list'
        if ($trusted) {
            $senders = [Native.Win]::GetDlgItem($trusted, $IDC_TRUSTED_LIST)
            Check ((ListCount $senders) -eq 1 -and [Native.Win]::RemoteListText($senders, 0, 0) -eq 'Everyone at shop.example') "with the domain chosen ($([Native.Win]::RemoteListText($senders, 0, 0)))"
            if ($shot) { Shot $trusted $shot }
            # a click on its row, as the mouse would, then Remove
            $point = [IntPtr]((8 -shl 16) -bor 30)
            [void][Native.Win]::PostMessage($senders, 0x0201, [IntPtr]1, $point)
            [void][Native.Win]::PostMessage($senders, 0x0202, [IntPtr]::Zero, $point)
            [void](WaitFor { [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($trusted, $IDC_TRUSTED_REMOVE)) } 5)
            Click $trusted $IDC_TRUSTED_REMOVE
            Check ([bool](WaitFor { (Visible $trusted $IDC_TRUSTED_EMPTY) -and -not (Visible $trusted $IDC_TRUSTED_LIST) } 5)) "Remove takes it away, and the window says nobody is trusted ($(GetText $trusted $IDC_TRUSTED_EMPTY))"
            Click $trusted 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($trusted) } 5)) 'Close closes it'
            Check ([bool](WaitFor { [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($o, 681)) } 5)) 'and Options can apply that'
        }
        Click $o $(if ($then -eq 'OK') { 1 } else { 2 })
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 5)
    }
    RemoveTrusted 'Cancel' 'pictures-3-options'
    Check (-not (& $showShop $shopSubjects[0])) 'Cancel in Options keeps the sender trusted: the signed one still shows its pictures'
    RemoveTrusted 'OK'
    Check (& $showShop $shopSubjects[0]) 'removed, the signed one asks again'
    # every message's pictures
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 1
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $IDC_OPTIONS_PICTURES), $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 5)
    }
    Check (-not (& $showShop $shopSubjects[1])) 'with pictures in all messages on, the forged one shows them too'
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 1
        $always = [Native.Win]::GetDlgItem($o, $IDC_OPTIONS_PICTURES)
        Check ([int][Native.Win]::SendMessage($always, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1) 'Options shows it on'
        [void][Native.Win]::SendMessage($always, $BM_SETCHECK, [IntPtr]0, [IntPtr]::Zero)
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 5)
    }
    Check (& $showShop $shopSubjects[0]) 'turned off, pictures are blocked again'
    # 34g2a: what is downloaded before it is opened, and how much each account keeps (app.h, after IDC_TRUSTED_EMPTY);
    # --test-hooks turned it off when the app started
    $IDC_OPTIONS_DOWNLOAD_AHEAD = 672; $IDC_OPTIONS_DOWNLOAD_LIMIT = 673; $IDC_OPTIONS_DOWNLOAD_NOTE = 674; $CB_GETCURSEL = 0x0147
    $selected = { param($dialog, $id) [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($dialog, $id), $CB_GETCURSEL, [IntPtr]::Zero, [IntPtr]::Zero) }
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 2
        Check ((& $selected $o $IDC_OPTIONS_DOWNLOAD_AHEAD) -eq 2 -and (& $selected $o $IDC_OPTIONS_DOWNLOAD_LIMIT) -eq 2) 'Options shows what is downloaded ahead (Only when opened) and 1 GB kept for each account'
        Check ((GetText $o $IDC_OPTIONS_DOWNLOAD_NOTE) -match 'oldest') "with what that means under them ($(GetText $o $IDC_OPTIONS_DOWNLOAD_NOTE))"
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $IDC_OPTIONS_DOWNLOAD_AHEAD), $CB_SETCURSEL, [IntPtr]0, [IntPtr]::Zero)
        Shot $o 'download-1-options'
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 5)
    }
    Command $main $IDM_OPTIONS
    $o = WaitShown 'InboxClassicOptions' 10
    if ($o) {
        OptionsPage $o 2
        Check ((& $selected $o $IDC_OPTIONS_DOWNLOAD_AHEAD) -eq 0) 'Recent messages up to 1 MB is kept when chosen'
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $IDC_OPTIONS_DOWNLOAD_AHEAD), $CB_SETCURSEL, [IntPtr]2, [IntPtr]::Zero)
        Click $o 1
        [void](WaitFor { -not [Native.Win]::IsWindow($o) } 5)
    }
    foreach ($id in @('sale-signed', 'sale-forged')) {
        $added = Find 'INBOX' "Message-ID: <$id@shop.example>"
        if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    }
    Command $main $IDM_SYNC
    [void](WaitFor { @($shopSubjects | Where-Object { $null -ne (& $rowOf $_) }).Count -eq 0 } 20)

    # ---- folders ----

    Step 'folders'
    function Mailboxes { @(Invoke-RestMethod $rest) | ForEach-Object { $_.path } }
    # a folder of the form that asks for a name: its name typed and OK clicked
    function AnswerName([string]$title, [string]$name, [string]$shot) {
        $form = WaitFor {
            $f = [Native.Win]::FindWindow('InboxClassicForm', $title)
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 100) -ne [IntPtr]::Zero) { $f }
        }
        Check ($null -ne $form) "$title asks for a name"
        if ($form) {
            SetText $form 100 $name
            if ($shot) { Shot $form $shot }
            Click $form 1
        }
    }
    SelectFolder 3
    Command $main $IDM_NEW_FOLDER
    AnswerName 'New Folder' 'Projects' 'folders-1-new'
    Check ([bool](WaitFor { (Mailboxes) -contains 'Archive/Projects' } 20)) 'New Folder makes Archive/Projects on the server'
    # the first folder in Archive, found again each time: the tree is built anew when the folders change
    function ArchiveChild {
        $child = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, (FolderItem 'Archive'))
        if ($child -ne [IntPtr]::Zero) { $child }
    }
    $projects = WaitFor { ArchiveChild }
    Check ($null -ne $projects) 'and it is in the tree'
    if ($projects) {
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $projects)
        Shot $main 'folders-2-tree'
        Command $main $IDM_RENAME_FOLDER
        AnswerName 'Rename Folder' 'Plans' $null
        Check ([bool](WaitFor { (Mailboxes) -contains 'Archive/Plans' -and (Mailboxes) -notcontains 'Archive/Projects' } 20)) 'Rename renames it on the server'
        Start-Sleep -Milliseconds 500
        $plans = WaitFor { ArchiveChild }
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $plans)
        Command $main $IDM_DELETE_FOLDER
        $sure = BoxOf $main 10
        Check ($null -ne $sure) 'deleting a folder asks first'
        if ($sure) {
            Shot $sure 'folders-3-delete'
            Click $sure 6
        }
        Check ([bool](WaitFor { (Mailboxes) -notcontains 'Archive/Plans' } 20)) 'and Yes deletes it on the server'
    }
    # the Inbox is not renamed
    SelectFolder 0
    Command $main $IDM_RENAME_FOLDER
    AnswerName 'Rename Folder' 'Mail' $null
    $refused = BoxOf $main 10
    Check ($null -ne $refused) 'renaming the Inbox is refused with the reason'
    if ($refused) {
        Shot $refused 'folders-4-inbox'
        [void][Native.Win]::PostMessage($refused, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { [Native.Win]::FindWindow('#32770', 'Inbox Classic') -eq [IntPtr]::Zero })
    }

    Step 'closing a message that was written'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    [void](TypeInEditor $compose 'Never mind.')
    [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    $ask = BoxOf $compose 10
    Check ($null -ne $ask) 'closing asks before throwing the text away'
    if ($ask) {
        Shot $ask 'write-6-close'
        # No: closed without saving
        Click $ask 7
    }
    Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) })) 'No closes it'
    Start-Sleep -Seconds 1
    Check ($null -eq (Find 'Drafts' 'Never mind')) 'without saving it'

    # ---- a provider found by its MX, one that wants an app password ----

    Step 'an e-mail link'
    # Windows starts the default mail program with the link: the app already open for the store takes it over
    $link = 'mailto:gina@example.com?subject=From%20a%20link&body=Hello%20Gina%2C'
    $second = Start-Process -FilePath $Exe -ArgumentList ($arguments + @("`"$link`"")) -PassThru
    Check ($second.WaitForExit(15000)) 'a second start with a mailto: link hands it over and ends'
    $linked = WaitFor {
        $c = [Native.Win]::FindWindow('InboxClassicCompose', [NullString]::Value)
        if ($c -ne [IntPtr]::Zero -and (GetText $c $IDC_SUBJECT) -eq 'From a link') { $c }
    } 15
    Check ($null -ne $linked) 'the running app opens a new message from it'
    if ($linked) {
        Check ((GetText $linked $IDC_TO) -eq 'gina@example.com') "to the link's address ($(GetText $linked $IDC_TO))"
        Shot $linked 'write-18-mailto'
        Check (CloseCompose $linked) 'the message closes without saving'
    }

    Step 'completing an address'
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    if ($compose) {
        $to = [Native.Win]::GetDlgItem($compose, $IDC_TO)
        foreach ($c in 'ann'.ToCharArray()) { [void][Native.Win]::PostMessage($to, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero) }
        # the list under the field: a list box of the app's own, shown
        $appPid = [uint32]0
        [void][Native.Win]::GetWindowThreadProcessId($compose, [ref]$appPid)
        $completion = WaitFor {
            $w = [IntPtr]::Zero
            do {
                $w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'ListBox', [NullString]::Value)
                $owner = [uint32]0
                if ($w -ne [IntPtr]::Zero) { [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner) }
            } while ($w -ne [IntPtr]::Zero -and -not ($owner -eq $appPid -and [Native.Win]::IsWindowVisible($w)))
            if ($w -ne [IntPtr]::Zero) { $w }
        } 10
        Check ($null -ne $completion) 'typing in To lists the people it may be'
        Check ($completion -and (ListBoxCount $completion) -ge 1) 'with someone heard from'
        if ($completion) { Shot $compose 'write-17-complete' $completion }
        Key $to $VK_RETURN
        Check ([bool](WaitFor { (GetText $compose $IDC_TO) -eq 'Ann Example <ann@example.com>, ' } 5)) "Enter takes the first, with a comma for the next ($(GetText $compose $IDC_TO))"
        Check ($completion -and -not [Native.Win]::IsWindowVisible($completion)) 'and closes the list'
        Check (CloseCompose $compose) 'the message closes without saving'
    }

    Step 'a signature'
    $IDC_ACCOUNT_SIGNATURE = 406
    Command $main $IDM_ACCOUNTS
    $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
    Check ($null -ne $accounts) 'File > Accounts opens the accounts'
    if ($accounts) {
        # the first account is selected when the list opens
        Click $accounts $IDC_ACCOUNT_SIGNATURE
        $signature = WaitWindow 'InboxClassicSignature' $null 20
        Check ($null -ne $signature) 'Signature opens the signature editor of the account'
        if ($signature) {
            Check ((WindowText $signature) -match '^Signature: ') "titled with the account ($(WindowText $signature))"
            Check (TypeInEditor $signature 'Ann, signed by the UI test') 'the signature editor takes typing'
            Shot $signature 'signature-1-editor'
            Click $signature 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($signature) } 10)) 'OK saves it and closes the editor'
        }
        Click $accounts 404
        [void](WaitFor { -not [Native.Win]::IsWindow($accounts) } 10)
    }
    # a new message starts with it, under the line to write on
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    if ($compose) {
        SetText $compose $IDC_TO 'Fay <fay@example.com>'
        SetText $compose $IDC_SUBJECT 'Signed in the UI test'
        Check (TypeInEditor $compose 'Hello Fay.') 'a new message takes typing above the signature'
        Shot $compose 'signature-2-new'
        Command $compose $IDC_SEND
    }
    $signed = WaitFor { Find 'INBOX' 'Subject: Signed in the UI test' } 30
    $raw = if ($signed) { RawText $signed } else { '' }
    Check ($raw -match 'Ann, signed by the UI test') 'the message went with the signature'
    Check ($raw.IndexOf('Hello Fay') -ge 0 -and $raw.IndexOf('Hello Fay') -lt $raw.IndexOf('-- ') -and $raw.IndexOf('-- ') -lt $raw.IndexOf('Ann, signed by the UI test')) 'after what was written and the "-- " line'
    # a reply has it above the quote
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 1) { Rows } } 20)
    [void](WaitFor { $null -ne (Find 'INBOX' 'Subject: Signed in the UI test') } 10)
    # found with the search, as other messages of the test are newer
    $findBox = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Signed in the UI test"')
    # the search's rows: the message, and its copy in Sent Items when the search has every folder
    [void](WaitFor { $n = Rows; $n -ge 1 -and @(SubjectRows 'Signed in the UI test').Count -eq $n } 20)
    SelectRow 0
    $compose = WaitCompose { Command $main $IDM_REPLY }
    if ($compose) {
        Check (TypeInEditor $compose 'Thanks.') 'a reply takes typing'
        Command $compose $IDC_SEND
    }
    $reply = WaitFor { Find 'INBOX' 'Subject: Re: Signed in the UI test' } 30
    $raw = if ($reply) { RawText $reply } else { '' }
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')
    if ($compose -and [Native.Win]::IsWindow($compose)) {
        Shot $compose 'signature-3-reply-left'
        [void](CloseCompose $compose)
        $left = WaitWindow '#32770' $null 5
        if ($left) { Click $left 7 }
    }
    # in the text part, with its lines as they are (the HTML part may wrap them)
    $plain = ($raw -replace "=`r`n", '')
    $at = $plain.IndexOf('Ann, signed by the UI test'); $quoteAt = $plain.IndexOf('Original Message')
    Check ($at -ge 0 -and $quoteAt -ge 0 -and $at -lt $quoteAt) "a reply has the signature above the quote ($at, $quoteAt)"
    if (-not ($at -ge 0 -and $at -lt $quoteAt)) { Set-Content (Join-Path $out 'signature-reply.eml') $raw }

    Step 'the Address Book'
    # core/commands.toml and app/src/app.h, compose.cpp
    $IDM_ADDRESS_BOOK = 147; $IDM_ADD_SENDER_TO_BOOK = 148; $IDM_IMPORT_ADDRESS_BOOK = 149; $IDM_EXPORT_ADDRESS_BOOK = 150
    $IDC_BOOK_TREE = 700; $IDC_BOOK_LIST = 701; $IDC_BOOK_FIND = 702; $IDC_BOOK_TOOLBAR = 703
    $IDC_BOOK_NEW_CONTACT = 710; $IDC_BOOK_NEW_GROUP = 711; $IDC_BOOK_PROPERTIES = 712; $IDC_BOOK_DELETE = 713; $IDC_BOOK_WRITE_TO = 714
    $IDC_CONTACT_FIRST = 720; $IDC_CONTACT_LAST = 721; $IDC_CONTACT_ADDRESS = 725; $IDC_CONTACT_ADD = 726; $IDC_CONTACT_ADDRESSES = 727
    $IDC_GROUP_NAME = 750; $IDC_GROUP_MEMBERS = 751; $IDC_GROUP_SELECT = 752; $IDC_GROUP_ADDRESS = 754; $IDC_GROUP_ADD = 755
    $IDC_PICK_LIST = 771; $IDC_PICK_TO = 772; $IDC_PICK_TO_LIST = 780; $IDC_PICK_TO_BUTTON = 313
    $TVM_SELECTITEM_CARET = [IntPtr]9
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    # the Name column of a list of the book, top to bottom
    function Names([IntPtr]$l) {
        $n = ListCount $l
        if ($n -eq 0) { return @() }
        @(0..($n - 1) | ForEach-Object { [Native.Win]::RemoteListText($l, $_, 0) })
    }
    Command $main $IDM_ADDRESS_BOOK
    $book = WaitShown 'InboxClassicAddressBook' 10
    Check ($null -ne $book) 'Tools > Address Book opens the Address Book'
    if ($book) {
        $bookList = [Native.Win]::GetDlgItem($book, $IDC_BOOK_LIST)
        $bookTree = [Native.Win]::GetDlgItem($book, $IDC_BOOK_TREE)
        $bookBar = [Native.Win]::GetDlgItem($book, $IDC_BOOK_TOOLBAR)
        # TB_GETBUTTONTEXTW of each button
        $buttons = @($IDC_BOOK_NEW_CONTACT, $IDC_BOOK_NEW_GROUP, $IDC_BOOK_PROPERTIES, $IDC_BOOK_DELETE, $IDC_BOOK_WRITE_TO) |
            ForEach-Object { [Native.Win]::RemoteText($bookBar, 0x044B, [IntPtr]$_) }
        Check (($buttons -join ', ') -eq 'New Contact, New Group, Properties, Delete, Write To') "with New Contact, New Group, Properties, Delete and Write To ($($buttons -join ', '))"
        Check ((ListCount $bookList) -eq 0) 'it starts empty'
        Check ((TreeTexts $bookTree) -contains 'All Contacts') "the groups start with All Contacts ($((TreeTexts $bookTree) -join ', '))"

        # a person with two addresses, the first the default
        Click $book $IDC_BOOK_NEW_CONTACT
        $contact = WaitShown 'InboxClassicContact' 10
        Check ($null -ne $contact) 'New Contact opens Contact Properties'
        if ($contact) {
            SetText $contact $IDC_CONTACT_FIRST 'Mary'
            SetText $contact $IDC_CONTACT_LAST 'Smith'
            # Click only posts the press: each address is in the list before the next is typed, or the first Add
            # would read the second address
            $addresses = [Native.Win]::GetDlgItem($contact, $IDC_CONTACT_ADDRESSES)
            SetText $contact $IDC_CONTACT_ADDRESS 'mary@example.com'
            Click $contact $IDC_CONTACT_ADD
            [void](WaitFor { (ListBoxCount $addresses) -eq 1 } 5)
            SetText $contact $IDC_CONTACT_ADDRESS 'mary.smith@work.example'
            Click $contact $IDC_CONTACT_ADD
            Check ([bool](WaitFor { (ListBoxCount $addresses) -eq 2 } 5)) 'it takes two addresses'
            Check ((ListBoxText $addresses 0) -eq 'mary@example.com (default)' -and (ListBoxText $addresses 1) -eq 'mary.smith@work.example') "the first the default ($(ListBoxText $addresses 0); $(ListBoxText $addresses 1))"
            Shot $contact 'contacts-2-person'
            Click $contact 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($contact) } 10)) 'OK saves the contact'
        }
        Check ([bool](WaitFor { (ListCount $bookList) -eq 1 -and [Native.Win]::RemoteListText($bookList, 0, 0) -eq 'Mary Smith' -and [Native.Win]::RemoteListText($bookList, 0, 1) -eq 'mary@example.com' } 10)) "the book lists her: Mary Smith, mary@example.com ($(Names $bookList))"
        Shot $book 'contacts-1-book'
        SetText $book $IDC_BOOK_FIND 'smi'
        Check ([bool](WaitFor { (ListCount $bookList) -eq 1 } 5)) 'the find box finds her by "smi"'
        SetText $book $IDC_BOOK_FIND 'zed'
        Check ([bool](WaitFor { (ListCount $bookList) -eq 0 } 5)) 'and lists no one for "zed"'
        SetText $book $IDC_BOOK_FIND ''
        [void](WaitFor { (ListCount $bookList) -eq 1 } 5)

        # a group of her and an address typed
        Click $book $IDC_BOOK_NEW_GROUP
        $group = WaitShown 'InboxClassicGroup' 10
        Check ($null -ne $group) 'New Group opens Group Properties'
        if ($group) {
            SetText $group $IDC_GROUP_NAME 'Team'
            Click $group $IDC_GROUP_SELECT
            $members = WaitShown 'InboxClassicPick' 10
            Check ($null -ne $members) 'Select Members opens the book'
            if ($members) {
                $pickList = [Native.Win]::GetDlgItem($members, $IDC_PICK_LIST)
                [void](WaitFor { (ListCount $pickList) -ge 1 } 5)
                Key $pickList $VK_HOME
                Start-Sleep -Milliseconds 300
                Click $members $IDC_PICK_TO
                [void](WaitFor { (ListBoxCount ([Native.Win]::GetDlgItem($members, $IDC_PICK_TO_LIST))) -eq 1 } 5)
                Click $members 1
                [void](WaitFor { -not [Native.Win]::IsWindow($members) } 10)
            }
            SetText $group $IDC_GROUP_ADDRESS 'dave@example.com'
            Click $group $IDC_GROUP_ADD
            $memberList = [Native.Win]::GetDlgItem($group, $IDC_GROUP_MEMBERS)
            Check ([bool](WaitFor { (ListBoxCount $memberList) -eq 2 } 5)) "with Mary Smith from Select Members and dave@example.com typed ($(ListBoxText $memberList 0); $(ListBoxText $memberList 1))"
            Shot $group 'contacts-3-group'
            Click $group 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($group) } 10)) 'OK saves the group'
        }
        Check ([bool](WaitFor { (TreeTexts $bookTree) -contains 'Team' } 5)) "it is listed on the left ($((TreeTexts $bookTree) -join ', '))"
        Check ([bool](WaitFor { (ListCount $bookList) -eq 2 } 5)) "with its two members ($(Names $bookList))"
        # back to everyone
        [void][Native.Win]::SendMessage($bookTree, $TVM_SELECTITEM, $TVM_SELECTITEM_CARET, [Native.Win]::SendMessage($bookTree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero))
        [void](WaitFor { (ListCount $bookList) -eq 1 } 5)
    }

    # the To button of a message: Select Recipients
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    if ($compose) {
        Click $compose $IDC_PICK_TO_BUTTON
        $pick = WaitShown 'InboxClassicPick' 10
        Check ($null -ne $pick) 'in a new message, To opens Select Recipients'
        if ($pick) {
            $pickList = [Native.Win]::GetDlgItem($pick, $IDC_PICK_LIST)
            [void](WaitFor { (ListCount $pickList) -ge 2 } 5)
            Check ((((Names $pickList) -join ', ')) -eq 'Team, Mary Smith') "it lists the group and the contact ($((Names $pickList) -join ', '))"
            Key $pickList $VK_HOME
            Start-Sleep -Milliseconds 300
            Click $pick $IDC_PICK_TO
            Key $pickList $VK_DOWN
            Start-Sleep -Milliseconds 300
            Click $pick $IDC_PICK_TO
            $toList = [Native.Win]::GetDlgItem($pick, $IDC_PICK_TO_LIST)
            Check ([bool](WaitFor { (ListBoxCount $toList) -eq 2 } 5)) "To -> puts the group and the contact in the message's recipients ($(ListBoxText $toList 0); $(ListBoxText $toList 1))"
            Shot $pick 'contacts-4-pick'
            Click $pick 1
            [void](WaitFor { -not [Native.Win]::IsWindow($pick) } 10)
        }
        Check ([bool](WaitFor { (GetText $compose $IDC_TO) -eq 'Mary Smith <mary@example.com>, dave@example.com' } 5)) "OK puts them in To, each address once ($(GetText $compose $IDC_TO))"
        # a group completes by its name, to its members
        Click $compose $IDC_SHOW_CC
        $cc = [Native.Win]::GetDlgItem($compose, $IDC_CC)
        foreach ($c in 'tea'.ToCharArray()) { [void][Native.Win]::PostMessage($cc, 0x0102, [IntPtr][int]$c, [IntPtr]::Zero) }
        $appPid = [uint32]0
        [void][Native.Win]::GetWindowThreadProcessId($compose, [ref]$appPid)
        $completion = WaitFor {
            $w = [IntPtr]::Zero
            do {
                $w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'ListBox', [NullString]::Value)
                $owner = [uint32]0
                if ($w -ne [IntPtr]::Zero) { [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner) }
            } while ($w -ne [IntPtr]::Zero -and -not ($owner -eq $appPid -and [Native.Win]::IsWindowVisible($w)))
            if ($w -ne [IntPtr]::Zero) { $w }
        } 10
        Check ($completion -and (ListBoxText $completion 0) -eq 'Team') "typing ""tea"" in Cc offers the group by its name ($(if ($completion) { ListBoxText $completion 0 }))"
        Key $cc $VK_RETURN
        Check ([bool](WaitFor { (GetText $compose $IDC_CC) -eq 'Mary Smith <mary@example.com>, dave@example.com, ' } 5)) "taking it puts its members in Cc ($(GetText $compose $IDC_CC))"
        [void][Native.Win]::PostMessage($compose, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        $ask = BoxOf $compose 5
        if ($ask) { Click $ask 7 }
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($compose) } 10)) 'the message is closed without saving'
    }

    # the sender of a message into the book, once
    AddMessage ("From: Sender <sender@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Add me to the Address Book`r`n" +
        "Message-ID: <book-sender@example.com>`r`nDate: Thu, 9 Oct 2025 08:00:00 +0000`r`nMIME-Version: 1.0`r`n" +
        "Content-Type: text/html; charset=utf-8`r`n`r`n<p>Please keep my address.</p>`r`n")
    Command $main $IDM_SYNC
    SelectFolder 0
    $findBox = [Native.Win]::GetDlgItem([Native.Win]::GetDlgItem($main, 205), 204)
    [void](WaitFor {
        [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, 'subject:"Add me to the Address Book"')
        Start-Sleep -Milliseconds 800
        (Rows) -eq 1
    } 30)
    SelectRow 0
    $WM_CONTEXTMENU = 0x007B
    [void][Native.Win]::PostMessage($main, $WM_CONTEXTMENU, $list, [IntPtr](-1))
    $menu = WaitWindow '#32768' $null 10
    if ($menu) {
        $labels = [Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero))
        Check ($labels -contains 'Add Sender to Address Book') "the message list's right-click menu has Add Sender to Address Book ($($labels -join ', '))"
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    Command $main $IDM_ADD_SENDER_TO_BOOK
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Sender was added to the Address Book.' } 10)) "Add Sender to Address Book adds Sender ($(StatusPart $mainStatus 0))"
    Command $main $IDM_ADD_SENDER_TO_BOOK
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Sender is already in the Address Book.' } 10)) "and again says the sender is in it already ($(StatusPart $mainStatus 0))"
    [void][Native.Win]::SendMessage($findBox, $WM_SETTEXT, [IntPtr]::Zero, '')
    if ($book) {
        Check ([bool](WaitFor { (ListCount $bookList) -eq 2 } 5)) "without a second card ($((Names $bookList) -join ', '))"
        Check (@(Names $bookList | Where-Object { $_ -eq 'Sender' }).Count -eq 1) 'Sender is listed once'
    }

    # a vCard file of two contacts, one in the book already
    $vcf = Join-Path (Resolve-Path $Out) 'contacts-import.vcf'
    $cards = "BEGIN:VCARD`r`nVERSION:3.0`r`nFN:Mary Smith`r`nN:Smith;Mary;;;`r`nEMAIL:mary@example.com`r`nEND:VCARD`r`n" +
        "BEGIN:VCARD`r`nVERSION:3.0`r`nFN:John Doe`r`nN:Doe;John;;;`r`nEMAIL:john@example.org`r`nTEL;TYPE=CELL:+1 555 0100`r`nEND:VCARD`r`n"
    [IO.File]::WriteAllText($vcf, $cards, (New-Object Text.UTF8Encoding $false))
    Command $main $IDM_IMPORT_ADDRESS_BOOK
    Check (AnswerFileDialog 'Import Address Book' $vcf $null) 'File > Import Address Book asks for a file'
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Added 1 contact, skipped 1 already in the Address Book.' } 10)) "it added 1 and skipped 1 ($(StatusPart $mainStatus 0))"
    if ($book) {
        Check ([bool](WaitFor { ((Names $bookList) -join ', ') -eq 'John Doe, Mary Smith, Sender' } 5)) "the book lists John Doe beside Mary Smith and Sender ($((Names $bookList) -join ', '))"
        Shot $book 'contacts-5-import'
    }
    $exported = Join-Path (Resolve-Path $Out) 'contacts-export.vcf'
    Remove-Item -Force -ErrorAction SilentlyContinue $exported
    Command $main $IDM_EXPORT_ADDRESS_BOOK
    Check (AnswerFileDialog 'Export Address Book' $exported $null 'Address Book*') 'File > Export Address Book asks where, as "Address Book"'
    Check ([bool](WaitFor { (StatusPart $mainStatus 0) -match '^3 contacts saved to ' } 10)) "it says how many it saved ($(StatusPart $mainStatus 0))"
    $vcards = if (Test-Path $exported) { Get-Content -Raw $exported } else { '' }
    Check ($vcards -match 'FN:Mary Smith' -and $vcards -match 'FN:John Doe' -and $vcards -match 'FN:Sender' -and $vcards -match 'mary.smith@work.example') 'the vCard file has Mary Smith (both addresses), John Doe and Sender'

    # Delete asks first
    if ($book) {
        Key $bookList $VK_HOME
        Start-Sleep -Milliseconds 300
        Key $bookList $VK_DELETE
        $ask = BoxOf $book 10
        Check ($ask -and (Statics $ask) -match 'Delete this contact from the Address Book\?') "Delete asks first ($(if ($ask) { Statics $ask }))"
        if ($ask) { Click $ask 6 }
        Check ([bool](WaitFor { ((Names $bookList) -join ', ') -eq 'Mary Smith, Sender' } 10)) "then removes the selected contact ($((Names $bookList) -join ', '))"
        [void][Native.Win]::PostMessage($book, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($book) } 10)) 'the Address Book closes'
    }

    # ---- a contact's picture ----

    Step "a contact's picture"
    $IDC_CONTACT_PICTURE = 736; $IDC_CONTACT_PICTURE_CHOOSE = 737; $IDC_CONTACT_PICTURE_REMOVE = 738; $IDC_LOGO = 213
    $face = Join-Path (Resolve-Path $Out) 'contact-face.png'
    [IO.File]::WriteAllBytes($face, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAIAAADYYG7QAAAAe0lEQVR42u3XUQ2AMAyE4QqbCJ5RMhEoQcnkIAEMbMlKVm7jT07Al/ThrlbyJhUDBAgQoFVAVzm/Bz2IWqJBDcpLlo3T+Ew2VOMwTQ5yaHpNgFYGuTVdJk4GKBZEdczY9op7SHExim5q3iARUNqPyAACBAgQIECAfga6AVZYJmMqfvr9AAAAAElFTkSuQmCC'))
    # Contact Properties of Mary Smith, from the Address Book
    function MaryProperties {
        Command $main $IDM_ADDRESS_BOOK
        $b = WaitShown 'InboxClassicAddressBook' 10
        if (-not $b) { return $null }
        $l = [Native.Win]::GetDlgItem($b, $IDC_BOOK_LIST)
        [void](WaitFor { (Names $l) -contains 'Mary Smith' } 5)
        $at = [array]::IndexOf(@(Names $l), 'Mary Smith')
        if ($at -lt 0) { return $null }
        Key $l $VK_HOME
        for ($i = 0; $i -lt $at; $i++) { Key $l $VK_DOWN }
        Start-Sleep -Milliseconds 300
        Click $b $IDC_BOOK_PROPERTIES
        $c = WaitShown 'InboxClassicContact' 10
        @($b, $c)
    }
    $removeEnabled = { param($c) [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($c, $IDC_CONTACT_PICTURE_REMOVE)) }
    $opened = MaryProperties
    if ($opened -and $opened[1]) {
        $contact = $opened[1]
        Check ((Visible $contact $IDC_CONTACT_PICTURE) -and -not (& $removeEnabled $contact)) 'Contact Properties has a picture well, its initials until a picture is chosen, Remove off'
        Click $contact $IDC_CONTACT_PICTURE_CHOOSE
        Check (AnswerFileDialog 'Choose' $face $null) 'Choose... asks for a picture file'
        Check ([bool](WaitFor { & $removeEnabled $contact } 10)) 'the well has the picture, and Remove is on'
        Shot $contact 'contacts-6-picture'
        Click $contact 1
        [void](WaitFor { -not [Native.Win]::IsWindow($contact) } 10)
        [void][Native.Win]::PostMessage($opened[0], $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($opened[0]) } 10)
    } else {
        Check $false 'Contact Properties of Mary Smith opens'
    }
    # her messages: the provider confirmed one comes from her domain, the other is forged; the column layout shows her
    # picture beside the confirmed one only, and the reading pane beside its header
    $confirmed = 'Lunch with Mary'; $forged = 'Mary asks for your password'
    foreach ($m in @(@($confirmed, 'pass', 'confirmed'), @($forged, 'fail', 'forged'))) {
        AddMessage ("Authentication-Results: mx.inboxclassic.test; dmarc=$($m[1]) header.from=example.com`r`n" +
            "From: Mary Smith <mary@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: $($m[0])`r`n" +
            "Message-ID: <$($m[2])@example.com>`r`nDate: $([DateTime]::UtcNow.ToString('r'))`r`n`r`nSee you at noon.`r`n")
    }
    Command $main $IDM_SYNC
    SelectFolder 0
    Command $main $IDM_LAYOUT_COLUMNS
    Check ([bool](WaitFor { (SubjectRows $confirmed).Count -eq 1 -and (SubjectRows $forged).Count -eq 1 } 30)) 'two messages from her address are in the Inbox'
    Check ([bool](WaitFor { (& $rowPicture $confirmed) -eq 13 } 40)) "the one the provider confirmed shows her picture ($(& $rowPicture $confirmed))"
    Check ((& $rowPicture $forged) -eq 11) "the forged one shows initials ($(& $rowPicture $forged))"
    $maryRow = @(SubjectRows $confirmed)
    if ($maryRow.Count -eq 1) { SelectRow ([int]$maryRow[0]) }
    Check ([bool](WaitFor { Visible $main $IDC_LOGO } 15)) 'the reading pane shows her picture beside the header'
    Check ((& $listTop) -ge 1000 -and (& $listTop) -le 1003) "switched to Columns again, the rows still start at the top ($(& $listTop))"
    Shot $main 'pictures-5-contact'
    $opened = MaryProperties
    if ($opened -and $opened[1]) {
        Click $opened[1] $IDC_CONTACT_PICTURE_REMOVE
        Check ([bool](WaitFor { -not (& $removeEnabled $opened[1]) } 10)) 'Remove takes the picture away'
        Click $opened[1] 1
        [void](WaitFor { -not [Native.Win]::IsWindow($opened[1]) } 10)
        [void][Native.Win]::PostMessage($opened[0], $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($opened[0]) } 10)
    }
    Check ([bool](WaitFor { (& $rowPicture $confirmed) -eq 11 } 20)) "and her row has initials again ($(& $rowPicture $confirmed))"
    Command $main $IDM_LAYOUT_CLASSIC
    foreach ($id in @('confirmed', 'forged')) {
        $m = Find 'INBOX' "Message-ID: <$id@example.com>"
        if ($m) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($m.uid)") }
    }
    Command $main $IDM_SYNC

    Step 'a Gmail address'
    Command $main $IDM_NEW_ACCOUNT
    $first = StartPage $true
    SetText $first 100 'Gmail Test'
    SetText $first 101 'inboxclassic.test@gmail.com'
    Click $first 1
    # the built-in Google client is off out of the box and no sign-in app is added yet: no browser sign-in to offer,
    # the app password way follows at once (Sign in with Google is offered further down, once it is turned on)
    $hint = WaitWindow '#32770' 'Add Mail Account' 40
    Check ($null -ne $hint) 'without it, Gmail wants an app password, and that is said'
    Check ([Native.Win]::FindWindow('InboxClassicAccountStart', 'Add Mail Account') -eq [IntPtr]::Zero) 'with Google turned off, a Gmail address goes to the app password way'
    if ($hint) {
        Shot $hint 'account-5-app-password'
        # No: not now to the instructions
        Click $hint 7
    }
    $servers = WaitFor {
        $f = [Native.Win]::FindWindow('InboxClassicForm', 'Add Mail Account')
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
    } 20
    Check ($servers -and (GetText $servers 105) -eq 'imap.gmail.com' -and (GetText $servers 108) -eq 'smtp.gmail.com') 'its servers were found'
    Check ($servers -and (GetText $servers 100) -eq 'Gmail') "the Account name starts as the provider's ($(if ($servers) { GetText $servers 100 }))"
    if ($servers) {
        Shot $servers 'account-6-gmail'
        Click $servers 2
        [void](WaitFor { -not [Native.Win]::IsWindow($servers) })
    }

    # ---- a wrong password ----

    Step 'a wrong password'
    # the second account's mail, on a server of its own, unread, dated a little ahead so it is the newest in the list
    # (over what the steps before added), around the first account's message of the next step
    foreach ($mail in @(
            @('Priya Shah <priya@work.example>', 'Contract renewal for next year', 'The renewal is ready to sign. Could you look it over before Friday?', 10),
            @('Tom Becker <tom@work.example>', 'Offsite agenda', 'Here is the agenda for the offsite. Add anything you want to talk about.', 8))) {
        $date = [DateTime]::UtcNow.AddMinutes($mail[3]).ToString('r')
        AddMessage "From: $($mail[0])`r`nTo: testuser2@inboxclassic.test`r`nSubject: $($mail[1])`r`nDate: $date`r`nMessage-ID: <$($mail[1] -replace ' ', '-')@work.example>`r`n`r`n$($mail[2])`r`n" @() 'INBOX' $rest2
    }
    Command $main $IDM_NEW_ACCOUNT
    AddAccount 'Work' 'testuser2' 'not-the-password' $false $true
    $logon = WaitForm 'Logon' 30
    Check ($null -ne $logon) 'a refused password is asked for again'
    if ($logon) {
        $status = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
        $status = WindowText $status
        Check ($status -match 'authentication') "the status bar says why ($status)"
        Shot $main 'trouble-1-password'
        # the right password, and the account syncs
        SetText $logon 100 'testpass2'
        Click $logon 1
        $synced = WaitFor {
            # the second account's heading, with its folders under it
            $work = NamedRow ([IntPtr]::Zero) 'Work'
            if ($work -ne [IntPtr]::Zero -and [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $work) -ne [IntPtr]::Zero) { $work }
        } 30
        Check ($null -ne $synced) 'with the right password typed, the account syncs'
    }

    # ---- All Inboxes ----

    Step 'All Inboxes'
    # a new message for the first account too, so both have unread mail
    $date = [DateTime]::UtcNow.AddMinutes(9).ToString('r')
    AddMessage "From: Maria Lopez <maria@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: Photos from the trip`r`nDate: $date`r`nMessage-ID: <trip-photos@example.org>`r`n`r`nThe photos from the trip are in the shared album.`r`n"
    Command $main $IDM_SYNC
    $top = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
    $tops = @(ChildRows ([IntPtr]::Zero) | ForEach-Object { Bare $_ })
    Check (($tops -join '|') -eq 'All Inboxes|All Sent|All Drafts|Flagged|inboxclassic.test|Work') "All Inboxes is at the top of the tree, then All Sent, All Drafts and Flagged, then each account's heading ($($tops -join ', '))"
    # the folders under each heading; ImapKit keeps a deleted folder of the Inbox (Receipts of step 27) listed
    $foldersUnder = { param($name) @(ChildRows (NamedRow ([IntPtr]::Zero) $name) | ForEach-Object { Bare $_ } | Where-Object { $_ -ne 'Receipts' }) }
    $underAll = @(ChildRows $top | ForEach-Object { Bare $_ })
    $headingsOk = $true
    foreach ($name in @('inboxclassic.test', 'Work')) {
        $under = @(& $foldersUnder $name)
        $headingsOk = $headingsOk -and $under.Count -gt 0 -and -not ($under | Where-Object { $_ -in @('Inbox', 'Sent Items', 'Drafts') })
    }
    Check ($headingsOk -and ($underAll -join '|') -eq 'inboxclassic.test|Work') "the Inbox of each account is under All Inboxes only: an account's heading lists its other folders, without Sent Items and Drafts ($($underAll -join ', '); $((& $foldersUnder 'inboxclassic.test') -join ', ') / $((& $foldersUnder 'Work') -join ', '))"
    # chosen with a key, as a click chooses it: the row is highlighted and painted before its list is read, which then
    # follows (the app's hook: 12 the highlight painted first, 11 the list read before it, 9 not read yet). Held unread
    # for a moment by the test, the list before stays dimmed, with "Loading..." over it after 400 ms
    $kTestListOrder = 0x4C4F5244; $kTestHoldList = 0x484F4C44
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, (ChildRows $top)[0])
    [void](WaitFor { (Rows) -ge 1 } 10)
    [void][Native.Win]::SendText($main, $kTestHoldList, '1')
    Key $tree $VK_HOME
    [void](WaitFor { [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]9, [IntPtr]::Zero) -eq $top } 5)
    Shot $main 'folder-click-waiting'
    Check ([Native.Win]::SendText($main, $kTestListOrder, '') -eq 9) 'while it waits, the list of the folder chosen is not read'
    # opening a menu does not read it: the Message menu (the fifth) is for nothing selected meanwhile
    $messageMenu = [Native.Win]::GetSubMenu([Native.Win]::GetMenu($main), 4)
    [void][Native.Win]::SendMessage($main, 0x0117, $messageMenu, [IntPtr]4)
    $replyOff = ([Native.Win]::GetMenuState($messageMenu, $IDM_REPLY, 0) -band 0x3) -ne 0
    Check ($replyOff -and [Native.Win]::SendText($main, $kTestListOrder, '') -eq 9) 'opening a menu leaves it waiting, with Reply greyed as nothing is selected in it'
    [void][Native.Win]::SendText($main, $kTestHoldList, '0')
    $order = WaitFor { $o = [Native.Win]::SendText($main, $kTestListOrder, ''); if ($o -ge 11) { $o } } 10
    Check ($order -eq 12) "a folder chosen in the tree is highlighted before its list is read ($order)"
    Check ([Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]9, [IntPtr]::Zero) -eq $top) 'and the key chose All Inboxes'
    $expected = (Messages 'INBOX').Count + (Messages 'INBOX' $rest2).Count
    # grouped by conversation the rows are fewer (replies share a row): the messages the list has are counted
    $mainStatus = [Native.Win]::FindWindowEx($main, [IntPtr]::Zero, 'msctls_statusbar32', [NullString]::Value)
    Check ([bool](WaitFor { (Rows) -ge 1 -and (StatusPart $mainStatus 2) -match "^$expected message" } 20)) "it lists the mail of both accounts' Inboxes ($(Rows) rows, $(StatusPart $mainStatus 2) of $expected)"
    $places = @(0..([Math]::Min(4, (Rows)) - 1) | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_FOLDER) })
    Check (($places -contains 'Work') -and ($places -contains 'inboxclassic.test')) "newest first, the two accounts' messages among each other, the Account column naming each ($($places -join ', '))"
    Check ((StatusPart $mainStatus 2) -match "^$expected message") "the status bar counts both Inboxes ($(StatusPart $mainStatus 2))"
    SelectRow 0
    Shot $main 'all-inboxes-1-list'
    # its right-click menu, as a right-click on its row opens it: Mark All Read alone, no folder commands
    # topmost for the click, as SetForegroundWindow alone is refused to a background process on a shared desktop
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    $at = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $top.ToInt64()))
    foreach ($button in @(0, 0x0008, 0x0010)) { [Native.Win]::Mouse($at[0], $at[1], $button) }
    $menu = WaitWindow '#32768' $null 10
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    Check ($null -ne $menu) 'All Inboxes has a right-click menu'
    if ($menu) {
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)))
        Check ($labels.Count -eq 1 -and $labels[0] -eq 'Mark All Read') "with Mark All Read alone ($($labels -join ', '))"
        Shot $main 'all-inboxes-2-menu' $menu
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    SelectRow ([array]::IndexOf($places, 'Work'))
    $compose = WaitCompose { Command $main $IDM_REPLY }
    Check ($null -ne $compose) 'Reply opens a compose window'
    if ($compose) {
        $from = GetText $compose $IDC_FROM
        Check ($from -eq 'Work <testuser2@inboxclassic.test>') "a reply goes from the account of the message ($from)"
        [void](CloseCompose $compose)
    }
    Command $main $IDM_MARK_ALL_READ
    $unreadOn = { param($server) @(Messages 'INBOX' $server | Where-Object { $_.flags -notcontains '\Seen' }).Count }
    Check ([bool](WaitFor { (& $unreadOn $rest) -eq 0 -and (& $unreadOn $rest2) -eq 0 } 20)) "Mark All Read marks both Inboxes read on the servers ($(& $unreadOn $rest) and $(& $unreadOn $rest2) unread)"

    # ---- All Sent and All Drafts ----

    Step 'All Sent and All Drafts'
    $TVIS_EXPANDED = 0x20
    $isOpen = { param($item) ([int][Native.Win]::SendMessage($tree, $TVM_GETITEMSTATE, $item, [IntPtr]$TVIS_EXPANDED) -band $TVIS_EXPANDED) -ne 0 }
    # a message in each account's Sent Items, a draft in the first account's Drafts
    $sentFirst = 'Notes from the planning call'; $sentWork = 'Slides for the review'; $drafted = 'Draft in All Drafts'
    AddMessage ("From: Alex Morgan <testuser@inboxclassic.test>`r`nTo: Nina Park <nina@example.org>`r`nSubject: $sentFirst`r`n" +
        "Date: $([DateTime]::UtcNow.AddMinutes(-2).ToString('r'))`r`nMessage-ID: <planning-notes@inboxclassic.test>`r`n`r`nThe notes are attached.`r`n") @('\Seen') 'Sent'
    AddMessage ("From: Work <testuser2@inboxclassic.test>`r`nTo: Omar Haddad <omar@work.example>`r`nSubject: $sentWork`r`n" +
        "Date: $([DateTime]::UtcNow.AddMinutes(-1).ToString('r'))`r`nMessage-ID: <review-slides@inboxclassic.test>`r`n`r`nHere are the slides.`r`n") @('\Seen') 'Sent' $rest2
    AddMessage ("From: Alex Morgan <testuser@inboxclassic.test>`r`nTo: Fay <fay@example.com>`r`nSubject: $drafted`r`n" +
        "Date: $([DateTime]::UtcNow.ToString('r'))`r`nMessage-ID: <all-drafts@inboxclassic.test>`r`nMIME-Version: 1.0`r`nContent-Type: text/plain; charset=utf-8`r`n`r`nStarted in the first account.`r`n") @('\Seen', '\Draft') 'Drafts'
    Command $main $IDM_SYNC
    $allSent = NamedRow ([IntPtr]::Zero) 'All Sent'
    $allDrafts = NamedRow ([IntPtr]::Zero) 'All Drafts'
    Check ($allSent -ne [IntPtr]::Zero -and $allDrafts -ne [IntPtr]::Zero -and -not (& $isOpen $allSent) -and -not (& $isOpen $allDrafts)) 'All Sent and All Drafts follow All Inboxes, before Flagged, closed at first'
    # a folder under a closed row chosen from elsewhere: the row opens so the folder is seen, selected
    Command $main $IDM_GO_TO_FOLDER
    $goTo = WaitPicker 'Go to Folder'
    Check ($goTo -and (PickIn $goTo 'inboxclassic.test' 'Sent Items')) 'Go to Folder offers the first account''s Sent Items'
    if ($goTo) {
        Click $goTo 1
        [void](WaitFor { -not [Native.Win]::IsWindow($goTo) } 10)
    }
    $firstSent = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $allSent)
    $chosen = WaitFor { $c = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]9, [IntPtr]::Zero); if ($c -eq $firstSent) { $c } } 10
    Check ($null -ne $chosen -and (& $isOpen $allSent) -and (& $folderBar) -eq ' Sent Items - inboxclassic.test') "Sent Items chosen by Go to Folder while All Sent is closed: All Sent opens and its row is selected ($(& $folderBar))"
    # closed again with the keyboard, which selects All Sent
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $allSent)
    [void][Native.Win]::SetForegroundWindow($main)
    [void][Native.Win]::SendMessage($tree, $WM_KEYDOWN, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
    [void][Native.Win]::SendMessage($tree, $WM_KEYUP, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
    Check (-not (& $isOpen $allSent)) 'and closes again with the Left key'
    # opened with the keyboard, as a user would, so the tree tells the window
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $allSent)
    [void][Native.Win]::SetForegroundWindow($main)
    [void][Native.Win]::SendMessage($tree, $WM_KEYDOWN, [IntPtr]$VK_RIGHT, [IntPtr]::Zero)
    [void][Native.Win]::SendMessage($tree, $WM_KEYUP, [IntPtr]$VK_RIGHT, [IntPtr]::Zero)
    $sentRows = @(ChildRows $allSent | ForEach-Object { Bare $_ })
    $draftRows = @(ChildRows $allDrafts | ForEach-Object { Bare $_ })
    Check ((& $isOpen $allSent) -and ($sentRows -join '|') -eq 'inboxclassic.test|Work' -and ($draftRows -join '|') -eq 'inboxclassic.test|Work') "opened, each has a row per account named as the account is ($($sentRows -join ', '); $($draftRows -join ', '))"
    $headingFolders = @(@('inboxclassic.test', 'Work') | ForEach-Object { ChildRows (NamedRow ([IntPtr]::Zero) $_) } | ForEach-Object { Bare $_ })
    Check (-not ($headingFolders -contains 'Sent Items') -and -not ($headingFolders -contains 'Drafts')) "the account headings list neither Sent Items nor Drafts ($($headingFolders -join ', '))"
    $listed = WaitFor { if (@(SubjectRows $sentFirst).Count -eq 1 -and @(SubjectRows $sentWork).Count -eq 1) { Rows } } 30
    Check ($null -ne $listed) "All Sent lists both accounts' sent messages ($(Rows) rows)"
    $at = { param($s) @(SubjectRows $s) | Select-Object -First 1 }
    $iFirst = & $at $sentFirst; $iWork = & $at $sentWork
    if ($null -ne $iFirst -and $null -ne $iWork) {
        Check ($iWork -lt $iFirst) "newest first ($sentWork at $iWork, $sentFirst at $iFirst)"
        $to = @([Native.Win]::RemoteListText($list, $iFirst, $COL_FROM), [Native.Win]::RemoteListText($list, $iWork, $COL_FROM))
        $accountsShown = @([Native.Win]::RemoteListText($list, $iFirst, $COL_FOLDER), [Native.Win]::RemoteListText($list, $iWork, $COL_FOLDER))
        Check (($to -join '|') -eq 'Nina Park|Omar Haddad') "with the To column, naming whom each went to ($($to -join ', '))"
        Check ((& $columns) -eq ($FOLDER_COLUMNS + 1) -and ($accountsShown -join '|') -eq 'inboxclassic.test|Work') "and the Account column ($($accountsShown -join ', '))"
        SelectRow $iFirst
    }
    Check ((& $folderBar) -eq ' All Sent' -and (WindowText $main) -eq 'All Sent - Inbox Classic') "the folder bar and the title say All Sent ($(& $folderBar); $(WindowText $main))"
    Shot $main 'all-sent-1-list'
    # the second account's row under All Sent: its Sent Items alone
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, (NamedRow $allSent 'Work'))
    $alone = [bool](WaitFor { @(SubjectRows $sentWork).Count -eq 1 -and @(SubjectRows $sentFirst).Count -eq 0 } 20)
    Check ($alone -and (& $folderBar) -eq ' Sent Items - Work') "the row of one account under All Sent lists its Sent Items alone, named with the account ($(& $folderBar))"
    # right-clicks: none on All Sent, the folder's menu on a row under it
    $menuOf = {
        param($item)
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
        [void][Native.Win]::SetForegroundWindow($main)
        Start-Sleep -Milliseconds 300
        $point = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $item.ToInt64()))
        foreach ($button in @(0, 0x0008, 0x0010)) { [Native.Win]::Mouse($point[0], $point[1], $button) }
        $m = WaitWindow '#32768' $null 3
        [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
        if (-not $m) { return $null }
        $labels = @([Native.Win]::MenuLabels([Native.Win]::SendMessage($m, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)))
        Key $m $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
        return , $labels
    }
    $noMenu = & $menuOf $allSent
    $folderMenu = & $menuOf (NamedRow $allSent 'inboxclassic.test')
    Check ($null -eq $noMenu) "All Sent has no right-click menu ($($noMenu -join ', '))"
    Check ($folderMenu -and $folderMenu[0] -eq 'Mark All Read' -and $folderMenu -contains 'New Folder...') "a row under it has the folder's menu ($($folderMenu -join ', '))"
    $noMenu = & $menuOf $allDrafts
    Check ($null -eq $noMenu) "All Drafts has none either ($($noMenu -join ', '))"
    # All Drafts lists the draft; opening it opens the compose window from the first account
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $allDrafts)
    Check ([bool](WaitFor { @(SubjectRows $drafted).Count -eq 1 } 30)) "All Drafts lists the draft ($(Rows) rows)"
    Check ((& $folderBar) -eq ' All Drafts') "the folder bar says All Drafts ($(& $folderBar))"
    $draftRow = & $at $drafted
    if ($null -ne $draftRow) { SelectRow $draftRow }
    Shot $main 'all-drafts-1-list'
    $compose = WaitCompose { Key $list $VK_RETURN }
    Check ($null -ne $compose) 'opening the draft opens a compose window'
    if ($compose) {
        $from = GetText $compose $IDC_FROM
        Check ((GetText $compose $IDC_SUBJECT) -eq $drafted -and (GetText $compose $IDC_TO) -like '*fay@example.com*') "with the draft's subject and recipient ($(GetText $compose $IDC_SUBJECT))"
        Check ($from -like '*testuser@inboxclassic.test*') "from the first account ($from)"
        Start-Sleep -Milliseconds 800
        Shot $compose 'all-drafts-2-open'
        # written on and saved, it replaces the draft in the first account's Drafts, the draft's text kept
        [void](TypeInEditor $compose 'Finished in All Drafts. ')
        Command $compose $IDC_SAVE
        $resaved = WaitFor { $d = @(Messages 'Drafts' | Where-Object { (RawText $_) -match "Subject: $drafted" }); if ($d.Count -eq 1 -and (RawText $d[0]) -match 'Started in the first account' -and (RawText $d[0]) -match 'Finished in All Drafts') { $d } } 30
        Check ($null -ne $resaved) "with the draft's text: written on and saved, it replaces the draft in the first account's Drafts"
        Check (@(Messages 'Drafts' $rest2).Count -eq 0) "and nothing goes to the second account's Drafts"
        [void](CloseCompose $compose)
    }
    # what the step added taken away again, All Sent and All Drafts closed again as they start
    foreach ($m in @(@('Sent', $rest, $sentFirst), @('Sent', $rest2, $sentWork), @('Drafts', $rest, $drafted))) {
        foreach ($found in @(Messages $m[0] $m[1] | Where-Object { (RawText $_) -match "Subject: $($m[2])" })) {
            [void](Invoke-RestMethod -Method Delete "$($m[1])/$($m[0])/messages/$($found.uid)")
        }
    }
    foreach ($row in @($allSent, $allDrafts)) {
        if (& $isOpen $row) {
            [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $row)
            [void][Native.Win]::SendMessage($tree, $WM_KEYDOWN, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
            [void][Native.Win]::SendMessage($tree, $WM_KEYUP, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
        }
    }
    Command $main $IDM_SYNC

    Step 'moving between accounts'
    $IDM_COPY = 136
    $across = 'Across the accounts'; $copied = 'Copied across'; $dragged = 'Dragged across'
    foreach ($pair in @(@($across, 12), @($copied, 11), @($dragged, 10))) {
        $date = [DateTime]::UtcNow.AddMinutes($pair[1]).ToString('r')
        AddMessage "From: Sam Lee <sam@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: $($pair[0])`r`nDate: $date`r`nMessage-ID: <$($pair[0] -replace ' ', '-')@example.org>`r`n`r`nMoved between the accounts in the UI test.`r`n" @('\Flagged')
    }
    Command $main $IDM_SYNC
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3 -and [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -eq $across) { Rows } } 30)
    SelectRow 0
    Command $main $IDM_MOVE
    $move = WaitPicker 'Move Message'
    Check ($null -ne $move) 'Move to Folder opens'
    if ($move) {
        $pickerTree = [Native.Win]::GetDlgItem($move, 102)
        $texts = @(TreeTexts $pickerTree)
        Check (($texts -contains 'inboxclassic.test') -and ($texts -contains 'Work') -and [Native.Win]::GetDlgItem($move, 101) -ne [IntPtr]::Zero) "Move to Folder shows the folders of both accounts in a tree, with a filter box ($($texts -join ', '))"
        $current = TreeRow $pickerTree 'inboxclassic.test' 'Inbox'
        [void][Native.Win]::SendMessage($pickerTree, $TVM_SELECTITEM, [IntPtr]9, $current)
        $ok = [Native.Win]::GetDlgItem($move, 1)
        Check (([Native.Win]::RemoteTreeText($pickerTree, $current)) -eq 'Inbox (current)' -and -not [Native.Win]::IsWindowEnabled($ok)) 'the folder the message is in is shown but can not be chosen'
        Check ((WindowText $ok) -eq '&Move') "the button says Move ($(WindowText $ok))"
        SetText $move 101 'arch'
        $narrowed = @(TreeTexts $pickerTree)
        $others = @($narrowed | Where-Object { $_ -notmatch 'Archive' -and $_ -notin @('Recent', 'inboxclassic.test', 'Work') })
        Check ($narrowed.Count -ge 2 -and $others.Count -eq 0) "typing in the filter narrows the tree to the folders that match ($($narrowed -join ', '))"
        SetText $move 101 ''
        Check (PickIn $move 'Work' 'Archive') "the second account's Archive can be chosen"
        Shot $move 'move-1-dialog'
        $listed = Rows
        Click $move 1
        Check ([bool](WaitFor { (Rows) -eq $listed - 1 } 10)) 'a message of the first account moved to the second account''s Archive leaves the list at once'
        Check ((StatusPart $mainStatus 0) -match '^Mov(ing|ed) 1 ') "the status bar says how far the move is ($(StatusPart $mainStatus 0))"
        Check ([bool](WaitFor { (StatusPart $mainStatus 0) -eq 'Moved 1 message to Archive' } 30)) "and what was done once it is there ($(StatusPart $mainStatus 0))"
    }
    $there = WaitFor { (Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $across" } | Select-Object -First 1 } 30
    Check ($null -ne $there -and $there.flags -contains '\Flagged') "it is in the second account's Archive on its server, with its flags ($($there.flags -join ' '))"
    Check ([bool](WaitFor { -not (Find 'INBOX' "Subject: $across") } 20)) "and gone from the first account's server"
    # the second account's Archive in the main tree, with the message in it
    $workArchive = TreeRow $tree 'Work' 'Archive'
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $workArchive)
    [void](WaitFor { if ((Rows) -ge 1 -and [Native.Win]::RemoteListText($list, 0, $COL_SUBJECT) -eq $across) { Rows } } 20)
    SelectRow 0
    Shot $main 'move-2-accounts'
    SelectFolder 0
    Command $main $IDM_UNDO
    Check ([bool](WaitFor { $null -ne (Find 'INBOX' "Subject: $across") } 30)) 'Edit > Undo Move brings it back to the first account'
    Check ([bool](WaitFor { -not ((Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $across" }) } 20)) 'and out of the second account''s Archive'
    # Copy to Folder: the second account's Archive is under Recent now
    [void](WaitFor { if ((Rows) -ge 3 -and [Native.Win]::RemoteListText($list, 1, $COL_SUBJECT) -eq $copied) { Rows } } 30)
    SelectRow 1
    Command $main $IDM_COPY
    $copy = WaitPicker 'Copy Message'
    Check ($null -ne $copy) 'Copy to Folder opens'
    if ($copy) {
        $copyTree = [Native.Win]::GetDlgItem($copy, 102)
        $recent = TreeRow $copyTree 'Recent' 'Archive (Work)'
        Check ($recent -ne [IntPtr]::Zero) "the next Move to Folder offers Archive of the second account under Recent ($((TreeTexts $copyTree) -join ', '))"
        Check ((WindowText ([Native.Win]::GetDlgItem($copy, 1))) -eq '&Copy') 'the button says Copy'
        [void](PickIn $copy 'Work' 'Archive')
        Click $copy 1
    }
    Check ($null -ne (WaitFor { (Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $copied" } | Select-Object -First 1 } 30)) "Copy to Folder copies a message to the second account's Archive"
    Check ($null -ne (Find 'INBOX' "Subject: $copied")) 'and keeps it in the Inbox'
    # dragged onto the second account's Archive in the folder tree
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 3 -and [Native.Win]::RemoteListText($list, 2, $COL_SUBJECT) -eq $dragged) { Rows } } 30)
    SelectRow 2
    [void][Native.Win]::SetForegroundWindow($main)
    $workArchive = TreeRow $tree 'Work' 'Archive'
    [void][Native.Win]::SendMessage($tree, 0x1114, [IntPtr]0, $workArchive)
    $row = [Native.Win]::RemoteRect($list, 0x100E, [IntPtr]2, 0)
    $target = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $workArchive.ToInt64()))
    [Native.Win]::MouseDragTo($row.Left + 120, [int](($row.Top + $row.Bottom) / 2), $target[0], $target[1])
    [Native.Win]::Mouse($target[0], $target[1], 0x0004)
    Check ($null -ne (WaitFor { (Messages 'Archive' $rest2) | Where-Object { (RawText $_) -match "Subject: $dragged" } | Select-Object -First 1 } 30)) 'a message dragged onto a folder of the second account is moved there'
    Check ([bool](WaitFor { -not (Find 'INBOX' "Subject: $dragged") } 20)) 'and out of the first account'

    # ---- All Inboxes by account ----

    Step 'All Inboxes by account'
    # the account row's menu (app.h)
    $IDM_ACCOUNT_SYNC = 910; $IDM_ACCOUNT_MARK_ALL_READ = 911; $IDM_ACCOUNT_PROPERTIES = 912
    # unread mail in both accounts' Inboxes again, and in the first account's Archive for its Mark All Read
    $date = [DateTime]::UtcNow.AddMinutes(14).ToString('r')
    AddMessage "From: Priya Shah <priya@work.example>`r`nTo: testuser2@inboxclassic.test`r`nSubject: Budget for the next quarter`r`nDate: $date`r`nMessage-ID: <budget-next-quarter@work.example>`r`n`r`nThe budget is ready for a look.`r`n" @() 'INBOX' $rest2
    AddMessage "From: Maria Lopez <maria@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: Dinner on Friday`r`nDate: $date`r`nMessage-ID: <dinner-friday@example.org>`r`n`r`nAre you free on Friday?`r`n"
    AddMessage "From: Maria Lopez <maria@example.org>`r`nTo: testuser@inboxclassic.test`r`nSubject: Kept for later`r`nDate: $date`r`nMessage-ID: <kept-for-later@example.org>`r`n`r`nUnread in the Archive.`r`n" @() 'Archive'
    Command $main $IDM_SYNC
    $top = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
    # the rows under All Inboxes, top to bottom (the tree's first row read again: a change of the accounts builds it anew)
    function AllInboxesRows {
        $rows = @()
        $first = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]4, $first)
        while ($item -ne [IntPtr]::Zero) {
            $rows += $item
            $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        $rows
    }
    # an account's own row at the top level, by its name
    function AccountRow([string]$name) {
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        while ($item -ne [IntPtr]::Zero) {
            if ((([Native.Win]::RemoteTreeText($tree, $item)) -replace ' \(\d+\)$', '') -eq $name) { return $item }
            $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        [IntPtr]::Zero
    }
    # a row's name with the unread count the server has for that Inbox
    $counted = { param($name, $server) $n = & $unreadOn $server; if ($n -gt 0) { "$name ($n)" } else { $name } }
    $rowTexts = { @(AllInboxesRows | ForEach-Object { [Native.Win]::RemoteTreeText($tree, $_) }) }
    $named = [bool](WaitFor {
            $texts = & $rowTexts
            $texts.Count -eq 2 -and $texts[0] -eq (& $counted 'inboxclassic.test' $rest) -and $texts[1] -eq (& $counted 'Work' $rest2) -and (& $unreadOn $rest2) -gt 0
        } 30)
    Check $named "All Inboxes has a row for each account, in their order, named as the account with its Inbox's unread count ($((& $rowTexts) -join ', '))"
    $inboxesUnread = (& $unreadOn $rest) + (& $unreadOn $rest2)
    Check ([bool](WaitFor { ([Native.Win]::RemoteTreeText($tree, $top)) -eq "All Inboxes ($inboxesUnread)" } 10)) "All Inboxes counts the unread mail of every Inbox ($([Native.Win]::RemoteTreeText($tree, $top)), $inboxesUnread)"
    $workInbox = @(AllInboxesRows)[1]
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $workInbox)
    $workCount = (Messages 'INBOX' $rest2).Count
    $alone = [bool](WaitFor { (StatusPart $mainStatus 2) -match "^$workCount message" -and @(SubjectRows 'Budget for the next quarter').Count -eq 1 } 20)
    Check ($alone -and @(SubjectRows 'Dinner on Friday').Count -eq 0) "the second account's row lists its Inbox alone, not the first account's message ($(StatusPart $mainStatus 2) of $workCount)"
    Check ((& $folderBar) -eq ' Inbox - Work' -and (WindowText $main) -eq 'Inbox - Work - Inbox Classic') "the folder bar and the title name the Inbox and the account ($(& $folderBar); $(WindowText $main))"
    # no message selected, so the second account's mail stays unread for Mark All Read below
    Shot $main 'all-inboxes-3-accounts'
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $top)
    $both = (Messages 'INBOX').Count + (Messages 'INBOX' $rest2).Count
    Check ([bool](WaitFor { (StatusPart $mainStatus 2) -match "^$both message" } 20)) "All Inboxes again lists both accounts' Inboxes ($(StatusPart $mainStatus 2) of $both)"
    # the second account's Properties, from its row under All Inboxes: the last item of its right-click menu
    $opened = TreeRowMenu $main $tree @(AllInboxesRows)[1]
    $menu = $opened.menu; $labels = $opened.labels
    Check ($labels.Count -gt 0 -and $labels[-1] -eq $en['ui-account-properties-of']) "the account's row under All Inboxes ends its menu with Account Properties ($($labels -join ', '))"
    if ($menu) {
        Shot $main 'all-inboxes-3b-inbox-menu' $menu
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    # the right-click selected the row; its menu's command opens that account's Properties
    Command $main $IDM_ACCOUNT_PROPERTIES
    $properties = WaitFor {
        $f = PropertiesForm
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
    } 10
    Check ($properties -and (GetText $properties 100) -eq 'Work' -and (GetText $properties 102) -eq 'testuser2@inboxclassic.test') "the account's Properties opens from its row, the Account name filled with its name ($(if ($properties) { GetText $properties 100 }))"
    if ($properties) {
        SetText $properties 100 'Second'
        Click $properties 1
        [void](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)
    }
    $renamed = [bool](WaitFor { (AccountRow 'Second') -ne [IntPtr]::Zero -and @(& $rowTexts)[-1] -match '^Second( \(\d+\))?$' } 20)
    Check $renamed "set to Second, the account's heading and its row under All Inboxes say Second ($((& $rowTexts) -join ', '))"
    Check ([bool](WaitFor { (& $folderBar) -eq ' Inbox - Second' } 10)) "the folder bar names the account by its new name ($(& $folderBar))"
    # the first account collapsed with the keyboard, as a user would, so the tree tells the window (TVM_EXPAND would
    # not): it counts the unread mail of the folders it hides (Kept for later in Archive)
    $alex = AccountRow 'inboxclassic.test'
    $archiveRow = NamedRow $alex 'Archive'
    $archiveUnread = [bool](WaitFor { ([Native.Win]::RemoteTreeText($tree, $archiveRow)) -match '\((\d+)\)$' } 20)
    $hiddenUnread = if (([Native.Win]::RemoteTreeText($tree, $archiveRow)) -match '\((\d+)\)$') { [int]$Matches[1] } else { 0 }
    Check ($archiveUnread -and (& $bold $archiveRow) -and -not (& $bold $alex)) "open, the account's heading counts nothing, its Archive counts its unread mail ($([Native.Win]::RemoteTreeText($tree, $archiveRow)))"
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $alex)
    [void][Native.Win]::SetForegroundWindow($main)
    [void][Native.Win]::SendMessage($tree, $WM_KEYDOWN, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
    [void][Native.Win]::SendMessage($tree, $WM_KEYUP, [IntPtr]$VK_LEFT, [IntPtr]::Zero)
    $collapsed = WaitFor { $t = [Native.Win]::RemoteTreeText($tree, $alex); if ($t -match '\((\d+)\)$' -and [int]$Matches[1] -ge $hiddenUnread -and $hiddenUnread -gt 0) { $t } } 5
    Check ([bool]$collapsed -and (& $bold $alex)) "collapsed, the account shows the unread messages of the folders it hides, in bold ($([Native.Win]::RemoteTreeText($tree, $alex)))"
    # the list empties as the selection's change is handled, a moment after the key
    Check ([bool](WaitFor { (& $folderBar) -eq ' inboxclassic.test' -and (Rows) -eq 0 } 5)) "the account's row is selected and lists nothing ($(& $folderBar), $(Rows) rows)"
    Shot $main 'folders-5-collapsed'
    [void][Native.Win]::SendMessage($tree, $WM_KEYDOWN, [IntPtr]$VK_RIGHT, [IntPtr]::Zero)
    [void][Native.Win]::SendMessage($tree, $WM_KEYUP, [IntPtr]$VK_RIGHT, [IntPtr]::Zero)
    $expanded = WaitFor { $t = [Native.Win]::RemoteTreeText($tree, $alex); if ($t -notmatch '\(\d+\)$') { $t } } 5
    Check ([bool]$expanded -and -not (& $bold $alex) -and ([Native.Win]::RemoteTreeText($tree, $archiveRow)) -match '\(\d+\)$') "expanded again, the count goes back to the folders ($([Native.Win]::RemoteTreeText($tree, $archiveRow)))"
    # the first account's right-click menu, as a right-click on its row opens it
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    $at = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $alex.ToInt64()))
    foreach ($button in @(0, 0x0008, 0x0010)) { [Native.Win]::Mouse($at[0], $at[1], $button) }
    $menu = WaitWindow '#32768' $null 10
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    Check ($null -ne $menu) 'an account has a right-click menu'
    if ($menu) {
        $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
        $labels = @([Native.Win]::MenuLabels($hmenu))
        Check (($labels -join '|') -eq 'Send and Receive|Mark All Read||New Folder...||Move Up|Move Down||Properties...') "with Send and Receive, Mark All Read, New Folder, Move Up, Move Down and Properties ($($labels -join ', '))"
        Check ((([Native.Win]::GetMenuState($hmenu, $IDM_ACCOUNT_MARK_ALL_READ, 0) -band 0x3) -eq 0)) 'Mark All Read is on while the account has unread mail'
        Check ((([Native.Win]::GetMenuState($hmenu, 913, 0) -band 0x3) -ne 0) -and (([Native.Win]::GetMenuState($hmenu, 914, 0) -band 0x3) -eq 0)) 'for the first account Move Up is greyed, Move Down is not'
        Shot $main 'account-menu' $menu
        Key $menu $VK_ESCAPE
        [void](WaitFor { [Native.Win]::FindWindow('#32768', [NullString]::Value) -eq [IntPtr]::Zero } 5)
    }
    # the menu is for the row it was opened on, which stays selected: its commands
    Check ((& $folderBar) -eq ' inboxclassic.test') "the right-click selected the account ($(& $folderBar))"
    $archiveUnread = { @(Messages 'Archive' | Where-Object { $_.flags -notcontains '\Seen' }).Count }
    $secondUnread = & $unreadOn $rest2
    Command $main $IDM_ACCOUNT_MARK_ALL_READ
    Check ([bool](WaitFor { (& $unreadOn $rest) -eq 0 -and (& $archiveUnread) -eq 0 } 20)) "its Mark All Read marks every folder of the first account read on the server ($(& $unreadOn $rest) in the Inbox, $(& $archiveUnread) in Archive)"
    Check ((& $unreadOn $rest2) -eq $secondUnread -and $secondUnread -gt 0) "the second account's mail stays unread ($(& $unreadOn $rest2))"
    Command $main $IDM_ACCOUNT_PROPERTIES
    $properties = WaitFor {
        $f = PropertiesForm
        if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
    } 10
    Check ($properties -and (GetText $properties 102) -eq 'testuser@inboxclassic.test') "its Properties opens that account's Properties ($(if ($properties) { GetText $properties 102 }))"
    if ($properties) {
        Click $properties 2
        [void](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)
    }
    Command $main $IDM_ACCOUNT_SYNC

    # ---- the accounts' order ----

    Step 'the accounts in another order'
    $IDM_ACCOUNT_MOVE_UP = 913; $IDM_ACCOUNT_MOVE_DOWN = 914
    $bare = { param($text) $text -replace ' \(\d+\)$', '' }
    # the accounts' own rows below All Inboxes, then the rows under All Inboxes, by name: "a,b|a,b"
    function AccountOrder {
        $roots = @()
        $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero))
        while ($item -ne [IntPtr]::Zero) {
            # the accounts' rows only: All Sent, All Drafts and Flagged are under All Inboxes too
            $name = & $bare ([Native.Win]::RemoteTreeText($tree, $item))
            if ($name -notin @('All Sent', 'All Drafts', 'Flagged')) { $roots += $name }
            $item = [Native.Win]::SendMessage($tree, $TVM_GETNEXTITEM, [IntPtr]1, $item)
        }
        $inboxes = @(AllInboxesRows | ForEach-Object { & $bare ([Native.Win]::RemoteTreeText($tree, $_)) })
        "$($roots -join ',')|$($inboxes -join ',')"
    }
    $added = 'inboxclassic.test,Second|inboxclassic.test,Second'
    $swapped = 'Second,inboxclassic.test|Second,inboxclassic.test'
    Check ((AccountOrder) -eq $added) "the accounts are in the order they were added ($(AccountOrder))"
    # Move Up on the second account's row, as its menu would
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, (AccountRow 'Second'))
    Command $main $IDM_ACCOUNT_MOVE_UP
    Check ([bool](WaitFor { (AccountOrder) -eq $swapped } 10)) "Move Up puts the second account first, above the other and under All Inboxes ($(AccountOrder))"
    Check ((& $folderBar) -eq ' Second') "and its row stays selected ($(& $folderBar))"
    Shot $main 'all-inboxes-4-reorder'
    Command $main $IDM_ACCOUNT_MOVE_DOWN
    Check ([bool](WaitFor { (AccountOrder) -eq $added } 10)) "Move Down puts it back ($(AccountOrder))"
    # dragged: the second account's Inbox under All Inboxes above the first one's, the insert mark shown on the way
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-1), 0, 0, 0, 0, 0x13)
    [void][Native.Win]::SetForegroundWindow($main)
    Start-Sleep -Milliseconds 300
    $inboxRows = @(AllInboxesRows)
    $from = Middle ([Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $inboxRows[1].ToInt64()))
    $toRect = [Native.Win]::RemoteRect($tree, 0x1104, [IntPtr]1, $inboxRows[0].ToInt64())
    $to = @($from[0], ($toRect.Top + 2))
    [Native.Win]::MouseDragTo($from[0], $from[1], $to[0], $to[1])
    Shot $main 'all-inboxes-5-drag'
    [Native.Win]::Mouse($to[0], $to[1], 0x0004)
    [void][Native.Win]::SetWindowPos($main, [IntPtr](-2), 0, 0, 0, 0, 0x13)
    Check ([bool](WaitFor { (AccountOrder) -eq $swapped } 10)) "an Inbox dragged above the other under All Inboxes moves its account first in both places ($(AccountOrder))"
    Check ((& $folderBar) -eq ' Inbox - Second') "and the row dragged is selected ($(& $folderBar))"
    # from the Inbox's menu under All Inboxes too
    Command $main $IDM_ACCOUNT_MOVE_DOWN
    Check ([bool](WaitFor { (AccountOrder) -eq $added } 10)) "its Move Down puts it back ($(AccountOrder))"
    Check ((& $folderBar) -eq ' Inbox - Second') "with the Inbox's row still selected ($(& $folderBar))"
    [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, (AccountRow 'inboxclassic.test'))

    # ---- accounts ----

    Step 'accounts'
    Command $main $IDM_ACCOUNTS
    $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
    Check ($null -ne $accounts) 'File > Accounts lists the accounts'
    if ($accounts) {
        $accountList = [Native.Win]::GetDlgItem($accounts, 400)
        # filled a moment after the window appears
        Check ([bool](WaitFor { (ListCount $accountList) -eq 2 } 10)) "both accounts are listed ($(ListCount $accountList))"
        Shot $accounts 'accounts-1-list'
        # Properties of the first: a new display name
        # the first account is selected when the list opens, and stays so after a change
        Click $accounts 402
        $properties = WaitFor {
            $f = PropertiesForm
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        }
        Check ($null -ne $properties) 'Properties shows the settings'
        if ($properties) {
            Check ((GetText $properties 106) -eq "$($ports.imap)") 'with the IMAP port as it was saved'
            SetText $properties 101 'Alex Morgan Renamed'
            Shot $properties 'accounts-2-properties'
            Click $properties 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($properties) } 10)) 'OK closes Properties'
            $box = [Native.Win]::FindWindow('#32770', [NullString]::Value)
            if ($box -ne [IntPtr]::Zero) {
                Write-Host "   a message box is open: $(WindowText $box)"
                Shot $box 'accounts-unexpected'
            }
        }
        # read back in Properties (the text of a list entry does not cross processes)
        Click $accounts 402
        $again = WaitFor {
            $f = PropertiesForm
            if ($f -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($f, 110) -ne [IntPtr]::Zero) { $f }
        }
        Check ($again -and (GetText $again 101) -eq 'Alex Morgan Renamed') 'the new name is saved'
        if ($again) {
            Click $again 2
            [void](WaitFor { -not [Native.Win]::IsWindow($again) })
        }
        # Remove the second, the one with the wrong password
        $before = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
        Key $accountList $VK_DOWN
        Start-Sleep -Milliseconds 300
        # the Delete key in the list does what Remove does
        Key $accountList $VK_DELETE
        $sure = WaitWindow '#32770' 'Remove Account' 10
        Check ($null -ne $sure) 'Remove (or Delete) asks first'
        if ($sure) { Click $sure 6 }
        Check ([bool](WaitFor { (ListCount $accountList) -eq 1 })) 'and removes it'
        Click $accounts 404
        [void](WaitFor { -not [Native.Win]::IsWindow($accounts) })
        $after = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -lt $before) { $n } }
        Check ($null -ne $after) "the account leaves the tree ($before items before)"
        $tops = @(ChildRows ([IntPtr]::Zero) | ForEach-Object { Bare $_ })
        Check ($tops[0] -eq 'Inbox' -and $tops[1] -eq 'Flagged' -and -not ($tops -contains 'All Inboxes') -and -not ($tops -contains 'All Sent') -and -not ($tops -contains 'All Drafts') -and ($tops -contains 'Sent Items') -and ($tops -contains 'Drafts') -and -not ($tops -contains 'inboxclassic.test')) "All Inboxes, All Sent and All Drafts go with the second account, and the tree is the one account's again: the Inbox first, then Flagged, Sent Items and Drafts its own, no heading ($($tops -join ', '))"
        Shot $main 'accounts-3-after'
    }

    # ---- sign-in apps: an OAuth client of the user's, against ImapKit's OpenID Connect provider ----

    Step 'sign-in apps'
    $LVM_GETITEMSTATE = 0x102C
    # whether the check box of a row is checked: its state image, 1 unchecked, 2 checked
    function Checked([IntPtr]$list, [int]$row) {
        (([int][Native.Win]::SendMessage($list, $LVM_GETITEMSTATE, [IntPtr]$row, [IntPtr]0xF000)) -shr 12) -eq 2
    }
    # a row selected with the keys, from the first
    function KeyToRow([IntPtr]$list, [int]$row) {
        # keys before the rows are there are lost: the list filled first (it is filled again after a change)
        [void](WaitFor { (ListCount $list) -gt $row } 5)
        for ($try = 0; $try -lt 2; $try++) {
            Key $list $VK_HOME
            for ($i = 0; $i -lt $row; $i++) { Key $list $VK_DOWN }
            # once the list has it selected (LVM_GETNEXTITEM, LVNI_SELECTED): the buttons act on the selected row
            if (WaitFor { [int][Native.Win]::SendMessage($list, 0x100C, [IntPtr](-1), [IntPtr]2) -eq $row } 5) { break }
        }
        Start-Sleep -Milliseconds 200
    }
    function OpenSignInApps {
        Command $main $IDM_ACCOUNTS
        $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
        if (-not $accounts) { return $null }
        Click $accounts 405
        $apps = WaitWindow 'InboxClassicSignInApps' 'Sign-in Apps'
        return @($accounts, $apps)
    }
    function CloseSignInApps($windows) {
        Click $windows[1] 705
        [void](WaitFor { -not [Native.Win]::IsWindow($windows[1]) })
        Click $windows[0] 404
        [void](WaitFor { -not [Native.Win]::IsWindow($windows[0]) })
    }

    $windows = OpenSignInApps
    Check ($null -ne $windows -and $windows[1]) 'File > Accounts > Sign-in Apps opens the sign-in apps'
    if ($windows -and $windows[1]) {
        $apps = $windows[1]
        $appList = [Native.Win]::GetDlgItem($apps, 700)
        Check ((ListCount $appList) -eq 2) 'the built-in Microsoft and Google clients are listed'
        Check ((Checked $appList 0) -and -not (Checked $appList 1)) 'Microsoft is on and Google off out of the box'
        Check (-not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($apps, 702)) -and -not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($apps, 703))) 'a built-in client can not be edited or removed'
        Check ((WindowText ([Native.Win]::GetDlgItem($apps, 704))) -match 'built in') 'a built-in client says what it is'
        Shot $apps 'signin-1-apps'

        Click $apps 701
        $editor = WaitWindow 'InboxClassicSignInApp' 'Add Sign-in App'
        Check ($null -ne $editor) 'Add opens the sign-in app editor'
        if ($editor) {
            # a preset fills in everything but the client
            Click $editor 600
            Check ([bool](WaitFor { (GetText $editor 611) -eq 'https://accounts.google.com' } 5)) 'Fill in for Google fills in its issuer'
            Check ((GetText $editor 617) -eq 'imap.gmail.com' -and (GetText $editor 624) -eq 'http://127.0.0.1') 'its servers, and the redirect URI to register'
            Shot $editor 'signin-2-google-preset'
            SetText $editor 610 'ImapKit'
            SetText $editor 611 $ports.oauth
            Check ([bool](WaitFor { (GetText $editor 624) -eq 'http://localhost' } 5)) 'the redirect URI follows the issuer'
            SetText $editor 613 'imapkit-approve'
            SetText $editor 616 'openid email profile offline_access mail'
            SetText $editor 617 '127.0.0.1'
            SetText $editor 618 "$($ports.imaps)"
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($editor, 619), $CB_SETCURSEL, [IntPtr]0, [IntPtr]::Zero)
            SetText $editor 620 '127.0.0.1'
            SetText $editor 621 "$($ports.smtp)"
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($editor, 622), $CB_SETCURSEL, [IntPtr]1, [IntPtr]::Zero)
            Click $editor 612
            $found = WaitWindow '#32770' 'Sign-in App' 20
            Check ($found -and (Statics $found) -match 'can be used') "Check reads the issuer's discovery document"
            if ($found) {
                Shot $found 'signin-3-check'
                Click $found 2
                [void](WaitFor { -not [Native.Win]::IsWindow($found) })
            }
            Shot $editor 'signin-4-editor'
            Click $editor 1
            Check ([bool](WaitFor { -not [Native.Win]::IsWindow($editor) } 20)) 'OK saves the sign-in app'
        }
        Check ([bool](WaitFor { (ListCount $appList) -eq 3 } 5) -and (Checked $appList 2)) 'it is listed, turned on'
        Shot $apps 'signin-5-apps-added'
        CloseSignInApps $windows
    }

    # the first page: Google's button faded with the reason, More sign-in options with the app
    Command $main $IDM_NEW_ACCOUNT
    $first = StartPage $true
    if ($first) {
        $google = [Native.Win]::GetDlgItem($first, 120)
        Check ($google -ne [IntPtr]::Zero -and -not [Native.Win]::IsWindowEnabled($google)) 'Sign in with Google is shown turned off'
        Check ([Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($first, 121))) 'Sign in with Microsoft works'
        Check ((Statics $first) -match 'Turned off on this computer') 'the reason is under it, without hovering'
        Shot $first 'signin-6-first-page'
        Click $first 123
        $why = WaitWindow '#32770' 'Add Mail Account' 10
        Check ($why -and (Statics $why) -match 'test users') 'Why? says why it is off'
        if ($why) {
            Shot $why 'signin-7-why'
            Click $why 2
            [void](WaitFor { -not [Native.Win]::IsWindow($why) })
        }
        # the address typed goes to the provider as the account to sign in to
        SetText $first 101 'alice@example.com'
        $IDC_SIGN_IN_MORE = 122
        Check (PushButton $first $IDC_SIGN_IN_MORE) 'More sign-in options is a push button'
        Click $first $IDC_SIGN_IN_MORE
        $menu = WaitWindow '#32768' $null 10
        Check ($null -ne $menu) 'More sign-in options opens a menu'
        if ($menu) {
            $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
            Check ([Native.Win]::GetMenuItemCount($hmenu) -eq 3) 'with the sign-in app, a separator and Add a sign-in app'
            Shot $first 'signin-8-more' $menu
            Key $menu $VK_DOWN
            Key $menu $VK_RETURN
        }
        # the app writes the page instead of opening the browser; opened here, ImapKit approves and redirects back
        $page = WaitFor { if (Test-Path $signInPage) { Get-Content -Raw $signInPage } } 20
        Check ($page -and $page.StartsWith("$($ports.oauth)/authorize?") -and $page -match 'login_hint=alice%40example.com') "signing in opens the sign-in app's page for the address typed"
        if ($page) {
            $waiting = WaitWindow 'InboxClassicWait' $null 5
            if ($waiting) { Shot $waiting 'signin-9-waiting' }
            $beforeTree = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
            $answer = Invoke-WebRequest -UseBasicParsing $page.Trim()
            Check ($answer.Content -match 'You are signed in') 'the provider sends the browser back to the app, which says it is signed in'
            Remove-Item -Force $signInPage
            $grown = WaitFor { $n = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); if ($n -ge $beforeTree + 6) { $n } } 40
            Check ($null -ne $grown) 'the account signed in to is added, and its folders sync with the token'
            Shot $main 'signin-10-added'
        }
    }

    $windows = OpenSignInApps
    if ($windows -and $windows[1]) {
        $apps = $windows[1]
        $appList = [Native.Win]::GetDlgItem($apps, 700)
        # removing it is refused while the account uses it
        KeyToRow $appList 2
        [void](WaitFor { [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($apps, 703)) } 5)
        Click $apps 703
        $sure = WaitWindow '#32770' 'Remove Sign-in App' 10
        if ($sure) { Click $sure 6 }
        $refused = WaitFor {
            $box = [Native.Win]::FindWindow('#32770', 'Remove Sign-in App')
            if ($box -ne [IntPtr]::Zero -and $box -ne $sure -and (Statics $box) -match 'alice@example.com') { $box }
        } 10
        Check ($null -ne $refused) 'a sign-in app an account uses is not removed, naming the account'
        if ($refused) {
            Shot $refused 'signin-11-in-use'
            Click $refused 2
            [void](WaitFor { -not [Native.Win]::IsWindow($refused) })
        }
        # the app off, Google on: Space on a row turns it on or off (each waited for, the rows are filled again after)
        Key $appList $VK_SPACE
        $off = WaitFor { -not (Checked $appList 2) } 5
        Start-Sleep -Milliseconds 500
        KeyToRow $appList 1
        Key $appList $VK_SPACE
        Check ([bool]$off -and [bool](WaitFor { Checked $appList 1 } 5) -and -not (Checked $appList 2)) 'Google turned on, the sign-in app off'
        Shot $apps 'signin-12-toggled'
        CloseSignInApps $windows
    }

    # Properties of the account names its sign-in app
    Command $main $IDM_ACCOUNTS
    $accounts = WaitWindow 'InboxClassicAccounts' 'Accounts'
    if ($accounts) {
        # the Properties of the account signed in to: each row's tried, wherever it is in the list
        # once the window has its list, and the list its rows (the window is there a moment before them)
        $count = WaitFor {
            $accountList = [Native.Win]::GetDlgItem($accounts, 400)
            $n = ListCount $accountList
            if ($n -ge 2) { $n }
        } 10
        $accountList = [Native.Win]::GetDlgItem($accounts, 400)
        $count = [int]$count
        $said = @()
        $found = $null
        for ($row = 0; $row -lt $count -and -not $found; $row++) {
            KeyToRow $accountList $row
            Click $accounts 402
            $properties = WaitFor { $f = PropertiesForm; if ($f -ne [IntPtr]::Zero) { $f } }
            if (-not $properties) { continue }
            if (WaitFor { (Statics $properties) -match 'Sign-in app: ImapKit' } 3) {
                $found = $properties
                Shot $properties 'signin-13-properties'
            } else {
                $said += Statics $properties
            }
            Click $properties 2
            [void](WaitFor { -not [Native.Win]::IsWindow($properties) })
        }
        Check ($null -ne $found) "Properties of the account signed in to says what it signs in with ($count accounts; $($said -join ' | '))"
        Click $accounts 404
        [void](WaitFor { -not [Native.Win]::IsWindow($accounts) })
    }

    # Google turned on: its button works, and a Gmail address is offered it; the app turned off is not in the menu
    Command $main $IDM_NEW_ACCOUNT
    $first = StartPage $true
    if ($first) {
        Check ([Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($first, 120)) -and [Native.Win]::GetDlgItem($first, 123) -eq [IntPtr]::Zero) 'Sign in with Google works once turned on'
        Click $first 122
        $menu = WaitWindow '#32768' $null 10
        if ($menu) {
            $hmenu = [Native.Win]::SendMessage($menu, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)
            Check ([Native.Win]::GetMenuItemCount($hmenu) -eq 1) 'a sign-in app turned off is left out of More sign-in options'
            Key $menu $VK_ESCAPE
            [void](WaitFor { -not [Native.Win]::IsWindow($menu) } 5)
        }
        SetText $first 100 'Gmail Test'
        SetText $first 101 'inboxclassic.test@gmail.com'
        Click $first 1
        $browser = StartPage $false 40
        Check ($browser -and [Native.Win]::GetDlgItem($browser, 120) -ne [IntPtr]::Zero -and [Native.Win]::GetDlgItem($browser, 121) -eq [IntPtr]::Zero) 'a Gmail address is offered Sign in with Google'
        if ($browser) {
            Shot $browser 'account-5b-browser-sign-in'
            Click $browser 2
            [void](WaitFor { -not [Native.Win]::IsWindow($browser) } 10)
        }
    }

    # ---- settings and accounts to another computer ----

    Step 'settings and accounts to another computer'
    # core/commands.toml, app/src/app.h (SetupControlId, KeysControlId)
    $IDM_EXPORT_SETUP = 173; $IDM_IMPORT_SETUP = 174
    $IDC_SETUP_PART = 940; $IDC_SETUP_USE_PASSPHRASE = 950; $IDC_SETUP_PASSPHRASE_NOTE = 951; $IDC_SETUP_PASSPHRASE = 952
    $IDC_SETUP_PASSPHRASE_AGAIN = 953; $IDC_SETUP_PROBLEM = 954; $IDC_SETUP_FROM = 955; $IDC_SETUP_ACCOUNT = 1000
    $IDC_KEY_PASSPHRASE = 882; $IDC_KEY_PROBLEM = 884
    $BM_GETCHECK = 0x00F0; $BM_SETCHECK = 0x00F1
    function IsChecked([IntPtr]$window, [int]$id) {
        [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($window, $id), $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1
    }
    # a check box set as a click sets it, its window told
    function SetCheck([IntPtr]$window, [int]$id, [bool]$on) {
        [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($window, $id), $BM_SETCHECK, [IntPtr]([int]$on), [IntPtr]::Zero)
        Click $window $id
    }
    $setupFile = Join-Path (Resolve-Path $Out) 'setup.inboxclassic'
    Remove-Item -Force -ErrorAction SilentlyContinue $setupFile
    $treeCount = [int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
    Command $main $IDM_EXPORT_SETUP
    $export = WaitShown 'InboxClassicSetupExport' 10
    Check ($null -ne $export) 'File > Export Settings and Accounts opens'
    if ($export) {
        $parts = @(0..7 | ForEach-Object { GetText $export ($IDC_SETUP_PART + $_) })
        $chosen = @(0..7 | Where-Object { IsChecked $export ($IDC_SETUP_PART + $_) }).Count
        Check (($parts -join ', ') -eq 'Accounts, Sign-in apps, Settings, Window preferences, Contacts and groups, Encryption keys, Message rules, Trusted senders' -and $chosen -eq 8) "it lists the parts, all chosen ($($parts -join ', '); $chosen chosen)"
        Check (-not (IsChecked $export $IDC_SETUP_USE_PASSPHRASE) -and -not (Enabled $export $IDC_SETUP_PASSPHRASE) -and (WaitText $export $IDC_SETUP_PASSPHRASE_NOTE) -eq $en['ui-setup-passphrase-note']) "the passphrase is off, with the words of what it adds ($(IsChecked $export $IDC_SETUP_USE_PASSPHRASE), $(Enabled $export $IDC_SETUP_PASSPHRASE), $(GetText $export $IDC_SETUP_PASSPHRASE_NOTE))"
        Check (Enabled $export 1) 'Export can go without a passphrase'
        Shot $export 'setup-1-export'
        SetCheck $export $IDC_SETUP_USE_PASSPHRASE $true
        Check ([bool](WaitFor { (Enabled $export $IDC_SETUP_PASSPHRASE) -and -not (Enabled $export 1) } 5)) 'with the passphrase on, its fields are on and Export waits for one'
        SetText $export $IDC_SETUP_PASSPHRASE 'short'
        Check ([bool](WaitFor { (GetText $export $IDC_SETUP_PROBLEM) -eq 'Use a passphrase of at least 8 characters.' -and (Visible $export $IDC_SETUP_PROBLEM) } 5) -and -not (Enabled $export 1)) "a passphrase shorter than 8 characters is refused with words ($(GetText $export $IDC_SETUP_PROBLEM))"
        SetText $export $IDC_SETUP_PASSPHRASE 'correct horse battery'
        SetText $export $IDC_SETUP_PASSPHRASE_AGAIN 'correct horse batterz'
        Check ([bool](WaitFor { (GetText $export $IDC_SETUP_PROBLEM) -eq 'The passphrases are not the same.' } 5) -and -not (Enabled $export 1)) "typed differently the second time, it is refused with words ($(GetText $export $IDC_SETUP_PROBLEM))"
        Shot $export 'setup-2-passphrase'
        SetText $export $IDC_SETUP_PASSPHRASE_AGAIN 'correct horse battery'
        Check ([bool](WaitFor { -not (Visible $export $IDC_SETUP_PROBLEM) -and (Enabled $export 1) } 5)) 'typed the same twice, it is taken and Export is on'
        Click $export 1
        Check (AnswerFileDialog 'Export Settings and Accounts' $setupFile $null 'Inbox Classic*') 'Export asks where to save, as "Inbox Classic"'
        $exported = WaitShown 'InboxClassicSetupDone' 30
        Check ($exported -and (Statics $exported) -match '2 accounts' -and (Statics $exported) -match 'contact') "then says what the file holds ($(if ($exported) { Statics $exported }))"
        if ($exported) {
            Shot $exported 'setup-1b-exported'
            Click $exported 1
            [void](WaitFor { -not [Native.Win]::IsWindow($exported) } 10)
        }
    }
    $head = if (Test-Path $setupFile) { (Get-Content -TotalCount 1 $setupFile) } else { '' }
    Check ($head -eq '-----BEGIN PGP MESSAGE-----') "with a passphrase the file is written encrypted, an OpenPGP message ($head)"

    # a contact deleted, to come back with the import of Contacts alone
    Command $main $IDM_ADDRESS_BOOK
    $book = WaitShown 'InboxClassicAddressBook' 10
    $contactsBefore = @()
    if ($book) {
        $bookList = [Native.Win]::GetDlgItem($book, $IDC_BOOK_LIST)
        [void](WaitFor { (ListCount $bookList) -gt 0 } 5)
        $contactsBefore = @(Names $bookList)
        Key $bookList $VK_HOME
        Start-Sleep -Milliseconds 300
        Key $bookList $VK_DELETE
        $ask = BoxOf $book 10
        if ($ask) { Click $ask 6 }
        Check ($contactsBefore.Count -gt 0 -and [bool](WaitFor { (ListCount $bookList) -eq $contactsBefore.Count - 1 } 10)) "a contact is deleted before the import ($($contactsBefore -join ', '))"
        [void][Native.Win]::PostMessage($book, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($book) } 10)
    }

    Command $main $IDM_IMPORT_SETUP
    Check (AnswerFileDialog 'Import Settings and Accounts' $setupFile $null) 'File > Import Settings and Accounts asks for a file'
    $ask = WaitShown 'InboxClassicPassphrase' 30
    Check ($ask -and (Statics $ask) -match 'This file is protected by a passphrase') "it asks for the passphrase ($(if ($ask) { Statics $ask }))"
    if ($ask) {
        SetText $ask $IDC_KEY_PASSPHRASE 'not the passphrase'
        Click $ask 1
        $again = WaitFor { $w = [Native.Win]::FindWindow('InboxClassicPassphrase', [NullString]::Value); if ($w -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($w) -and [Native.Win]::GetDlgItem($w, $IDC_KEY_PROBLEM) -ne [IntPtr]::Zero) { $w } } 30
        Check ($again -and (GetText $again $IDC_KEY_PROBLEM) -eq 'That is not the passphrase this setup was saved with.') "a wrong one is refused with words, and asked again ($(if ($again) { GetText $again $IDC_KEY_PROBLEM }))"
        if ($again) {
            SetText $again $IDC_KEY_PASSPHRASE 'correct horse battery'
            Click $again 1
        }
    }
    $import = WaitShown 'InboxClassicSetupImport' 30
    Check ($null -ne $import) 'the right one shows what the file holds'
    if ($import) {
        Check ((GetText $import $IDC_SETUP_FROM) -match ((Pattern $en['ui-setup-from']) + '$')) "with when and by which version it was saved ($(GetText $import $IDC_SETUP_FROM))"
        $accountBoxes = @(0..9 | Where-Object { [Native.Win]::GetDlgItem($import, $IDC_SETUP_ACCOUNT + $_) -ne [IntPtr]::Zero })
        $here = @($accountBoxes | Where-Object { -not (IsChecked $import ($IDC_SETUP_ACCOUNT + $_)) -and -not (Enabled $import ($IDC_SETUP_ACCOUNT + $_)) })
        $words = Statics $import
        Check ((GetText $import $IDC_SETUP_ACCOUNT) -match '<testuser@inboxclassic\.test>$' -and $words -match '127\.0\.0\.1 and 127\.0\.0\.1 \(Password\)') "each account with the core's label and its servers ($(GetText $import $IDC_SETUP_ACCOUNT))"
        Check ($accountBoxes.Count -eq 2 -and $here.Count -eq 2 -and ([regex]::Matches($words, 'It is set up here already, so it is skipped\.')).Count -eq 2) "the accounts, both marked as already here and not chosen ($($accountBoxes.Count) accounts, $($here.Count) here)"
        Check (-not (IsChecked $import $IDC_SETUP_PART) -and -not (Enabled $import $IDC_SETUP_PART)) 'with no account to import, Accounts is not chosen and can not be'
        # the parts with something in them: the test has no rules and no trusted senders, which are not offered
        $present = @(1..7 | Where-Object { [Native.Win]::GetDlgItem($import, $IDC_SETUP_PART + $_) -ne [IntPtr]::Zero })
        Check ($present.Count -gt 0 -and @($present | Where-Object { IsChecked $import ($IDC_SETUP_PART + $_) }).Count -eq $present.Count -and [Native.Win]::GetDlgItem($import, $IDC_SETUP_PART + 6) -eq [IntPtr]::Zero) "the other parts with something in them are there, chosen, an empty one left out ($($present.Count))"
        Check ($words -match '\d+ contacts?, \d+ groups?' -and $words -match 'keys? of your own' -and $words -match '2 accounts') "with what each holds: the contacts, the keys and the other parts ($words)"
        Shot $import 'setup-3-import-choose'
        # Contacts alone
        foreach ($i in $present) { if ($i -ne 4) { SetCheck $import ($IDC_SETUP_PART + $i) $false } }
        Check ([bool](WaitFor { -not (Enabled $import $IDC_SETUP_ACCOUNT) } 5) -and (Enabled $import 1)) 'Contacts alone chosen'
        Click $import 1
        $imported = WaitShown 'InboxClassicSetupDone' 30
        $said = if ($imported) { Statics $imported } else { '' }
        Check ($said -match 'Added 1 contact to the address book\.' -and ($contactsBefore.Count -lt 2 -or $said -match 'in the address book already') -and $said -notmatch 'account') "the summary says what was added and skipped ($said)"
        if ($imported) {
            Shot $imported 'setup-4-imported'
            Click $imported 1
            [void](WaitFor { -not [Native.Win]::IsWindow($imported) } 10)
        }
    }
    Check ([int][Native.Win]::SendMessage($tree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -eq $treeCount) 'the accounts are left as they are'
    Command $main $IDM_ADDRESS_BOOK
    $book = WaitShown 'InboxClassicAddressBook' 10
    if ($book) {
        $bookList = [Native.Win]::GetDlgItem($book, $IDC_BOOK_LIST)
        Check ([bool](WaitFor { ((Names $bookList) -join ', ') -eq ($contactsBefore -join ', ') } 10)) "the contact deleted before is back ($((Names $bookList) -join ', '))"
        [void][Native.Win]::PostMessage($book, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($book) } 10)
    }

    # ---- settings sync ----

    Step 'settings sync'
    # app/src/app.h (SyncControlId), main.cpp (kTestSyncSecond)
    $IDM_OPTIONS = 137
    $IDC_OPTIONS_SYNC_NOTE = 960; $IDC_OPTIONS_SYNC_PLACE = 961; $IDC_OPTIONS_SYNC_STATUS = 962; $IDC_OPTIONS_SYNC_SET_UP = 963
    $IDC_OPTIONS_SYNC_NOW = 964; $IDC_OPTIONS_SYNC_COMPUTERS = 965; $IDC_OPTIONS_SYNC_HISTORY = 966; $IDC_OPTIONS_SYNC_TURN_OFF = 967
    $IDC_OPTIONS_SYNC_SWITCH = 970
    $IDC_SYNC_KIND_FOLDER = 1200; $IDC_SYNC_FOLDER = 1202; $IDC_SYNC_CHOOSE = 1203; $IDC_SYNC_PASSPHRASE = 1211
    $IDC_SYNC_PASSPHRASE_AGAIN = 1212; $IDC_SYNC_NAME = 1214; $IDC_SYNC_PROBLEM = 1216; $IDC_SYNC_BACK = 1217; $IDC_SYNC_LIST = 1218
    $IDC_SYNC_EMPTY = 1220; $IDC_SYNC_POINTS_EMPTY = 1223
    $kTestSyncSecond = 0x53594E43
    $syncPassphrase = 'correct horse battery staple'
    $vault = Join-Path $env:TEMP "inbox-classic-vault-$PID"
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $vault
    [void](New-Item -ItemType Directory -Force $vault)
    Command $main $IDM_OPTIONS
    $options = WaitShown 'InboxClassicOptions'
    Check ($null -ne $options) 'Tools > Options opens'
    if ($options) {
        OptionsPage $options 3
        Check ((Visible $options $IDC_OPTIONS_SYNC_NOTE) -and (Visible $options $IDC_OPTIONS_SYNC_SET_UP) -and -not (Visible $options $IDC_OPTIONS_SYNC_NOW) -and -not (Visible $options $IDC_OPTIONS_SYNC_SWITCH)) 'while sync is off, the Sync tab says what it is for and offers Set Up Sync, nothing else'
        Shot $options 'sync-1-off'

        # Set Up Sync: a folder, then a new passphrase
        Click $options $IDC_OPTIONS_SYNC_SET_UP
        $setUp = WaitShown 'InboxClassicSyncSetUp' 10
        Check ($null -ne $setUp) 'Set Up Sync opens'
    }
    if ($options -and $setUp) {
        Check ((Visible $setUp $IDC_SYNC_KIND_FOLDER) -and -not (Enabled $setUp 1) -and -not (Visible $setUp $IDC_SYNC_BACK)) 'it asks where to keep it, a folder chosen, Next off until there is one, no Back'
        Shot $setUp 'sync-2-where'
        # S3-compatible storage shows the bucket's fields in the folder's place (IDC_SYNC_KIND_BUCKET, IDC_SYNC_ENDPOINT)
        foreach ($kind in @(@{ On = 1201; Off = 1200 }, @{ On = 1200; Off = 1201 })) {
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($setUp, $kind.Off), 0x00F1, [IntPtr]0, [IntPtr]::Zero)
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($setUp, $kind.On), 0x00F1, [IntPtr]1, [IntPtr]::Zero)
            Click $setUp $kind.On
            if ($kind.On -eq 1201) {
                Check ([bool](WaitFor { (Visible $setUp 1204) -and -not (Visible $setUp $IDC_SYNC_FOLDER) } 5)) 'S3-compatible storage asks for the endpoint, region, bucket, folder and keys in the folder''s place'
                Shot $setUp 'sync-2b-bucket'
            }
        }
        [void](WaitFor { Visible $setUp $IDC_SYNC_FOLDER } 5)
        Click $setUp $IDC_SYNC_CHOOSE
        Check (AnswerFolderDialog 'Choose the Folder to Sync Through' $vault) 'Choose asks for the folder'
        # by its name: the runner's TEMP may be written short (RUNNER~1) where the chooser gives the long path
        $vaultName = Split-Path $vault -Leaf
        Check ([bool](WaitFor { (GetText $setUp $IDC_SYNC_FOLDER) -like "*\$vaultName" -and (Enabled $setUp 1) } 10)) "the folder chosen is in its field, Next on ($(GetText $setUp $IDC_SYNC_FOLDER), Next $(Enabled $setUp 1))"
        Click $setUp 1
        Check ([bool](WaitFor { (Visible $setUp $IDC_SYNC_PASSPHRASE_AGAIN) } 20)) 'the folder is empty: it asks for a new sync passphrase, twice'
        Check ((GetText $setUp $IDC_SYNC_NAME) -ne '' -and (Visible $setUp $IDC_SYNC_BACK) -and -not (Enabled $setUp 1)) "with the name of this computer filled in ($(GetText $setUp $IDC_SYNC_NAME)), Back, and Turn On Sync off until the passphrase is typed"
        Shot $setUp 'sync-3-start'
        SetText $setUp $IDC_SYNC_PASSPHRASE $syncPassphrase
        SetText $setUp $IDC_SYNC_PASSPHRASE_AGAIN $syncPassphrase
        SetText $setUp $IDC_SYNC_NAME 'Desktop'
        Check ([bool](WaitFor { Enabled $setUp 1 } 5)) 'typed twice the same, Turn On Sync is on'
        Click $setUp 1
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($setUp) } 20)) "Turn On Sync closes the dialog$(if ([Native.Win]::IsWindow($setUp)) { ': ' + (GetText $setUp $IDC_SYNC_PROBLEM) })"
        $written = WaitFor { (Test-Path (Join-Path $vault 'vault.json')) -and @(Get-ChildItem -ErrorAction SilentlyContinue (Join-Path $vault 'devices')).Count -eq 1 } 30
        Check ([bool]$written) 'the first sync writes the vault into the folder'
        Check ([bool](WaitFor { (Visible $options $IDC_OPTIONS_SYNC_NOW) -and (Visible $options $IDC_OPTIONS_SYNC_SWITCH) -and -not (Visible $options $IDC_OPTIONS_SYNC_SET_UP) } 10)) 'while on, the tab shows where it syncs, how it went, its buttons and what it syncs'
        Check ((GetText $options $IDC_OPTIONS_SYNC_PLACE) -match 'Desktop' -and (WaitText $options $IDC_OPTIONS_SYNC_STATUS) -ne '') "where it syncs through as which computer, and how it went ($(GetText $options $IDC_OPTIONS_SYNC_PLACE); $(GetText $options $IDC_OPTIONS_SYNC_STATUS))"
        Start-Sleep -Milliseconds 500
        Shot $options 'sync-4-on'

        # a second computer (another core in the app, a store of its own) joins with the passphrase and gets the accounts
        $joined = [Native.Win]::SendText($main, $kTestSyncSecond, "join`t$vault`t$syncPassphrase")
        Check ($joined -ge 11) "a second computer is refused a wrong passphrase, joins with the right one and gets the accounts ($($joined - 10) accounts)"
        $added = [Native.Win]::SendText($main, $kTestSyncSecond, "card`tfriend@sync.example")
        Click $options $IDC_OPTIONS_SYNC_NOW
        $arrived = WaitFor { [Native.Win]::SendText($main, $kTestSyncSecond, "has`tfriend@sync.example") -eq 11 } 30
        Check ($added -eq 11 -and [bool]$arrived) 'a contact added on the second computer arrives on Sync Now'

        # the computers of the vault
        Click $options $IDC_OPTIONS_SYNC_COMPUTERS
        $computers = WaitShown 'InboxClassicSyncComputers' 10
        Check ($null -ne $computers) 'Computers opens'
        if ($computers) {
            $listed = WaitFor { (Visible $computers $IDC_SYNC_LIST) -and (ListCount ([Native.Win]::GetDlgItem($computers, $IDC_SYNC_LIST))) -eq 2 } 15
            Check ([bool]$listed) 'Computers lists both'
            Shot $computers 'sync-5-computers'
            Click $computers 1
            [void](WaitFor { -not [Native.Win]::IsWindow($computers) } 5)
        }
        Click $options $IDC_OPTIONS_SYNC_HISTORY
        $history = WaitShown 'InboxClassicSyncHistory' 10
        Check ($null -ne $history) 'History opens'
        if ($history) {
            Check ((Visible $history $IDC_SYNC_EMPTY) -and (GetText $history $IDC_SYNC_EMPTY) -eq $en['ui-sync-history-empty']) "History says no change was replaced ($(GetText $history $IDC_SYNC_EMPTY))"
            Check (Visible $history $IDC_SYNC_POINTS_EMPTY) 'and that there is no restore point yet'
            Shot $history 'sync-6-history'
            Click $history 1
            [void](WaitFor { -not [Native.Win]::IsWindow($history) } 5)
        }

        # Turn Off Sync, asked first
        Click $options $IDC_OPTIONS_SYNC_TURN_OFF
        $ask = WaitShown 'InboxClassicAsk' 10
        Check ($ask -and (Statics $ask) -match 'Turn off sync on this computer') "Turn Off Sync asks first ($(if ($ask) { Statics $ask }))"
        if ($ask) { Click $ask 1 }
        Check ([bool](WaitFor { (Visible $options $IDC_OPTIONS_SYNC_SET_UP) -and -not (Visible $options $IDC_OPTIONS_SYNC_NOW) } 10)) 'then it is off here, the tab offers Set Up Sync again'
        [void][Native.Win]::SendText($main, $kTestSyncSecond, 'close')
    }
    if ($options) {
        Click $options 2
        [void](WaitFor { -not [Native.Win]::IsWindow($options) } 5)
    }
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $vault

    # ---- Options and the language ----

    Step 'Options and the language'
    $IDM_OPTIONS = 137; $IDC_OPTIONS_LANGUAGE = 660; $IDC_OPTIONS_NOTIFY = 661; $IDC_OPTIONS_THREADS = 663; $IDC_OPTIONS_LAYOUT = 675
    $IDC_OPTIONS_TABS = 680; $IDC_OPTIONS_APPLY = 681; $IDC_OPTIONS_DEFAULT_APP = 682; $IDC_OPTIONS_EML = 668; $TCM_GETCURSEL = 0x130B
    Command $main $IDM_OPTIONS
    $options = WaitShown 'InboxClassicOptions'
    Check ($null -ne $options) 'Tools > Options opens'
    if ($options) {
        $tabs = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_TABS)
        $apply = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_APPLY)
        Check ([int][Native.Win]::SendMessage($tabs, $TCM_GETCURSEL, [IntPtr]::Zero, [IntPtr]::Zero) -eq 0) 'it opens on General'
        Check ($apply -ne [IntPtr]::Zero -and -not [Native.Win]::IsWindowEnabled($apply)) 'Apply is disabled while nothing changed'
        Check ((Visible $options $IDC_OPTIONS_DEFAULT_APP) -and (Visible $options $IDC_OPTIONS_EML) -and -not (Visible $options $IDC_OPTIONS_THREADS)) 'General has Make Default Mail App and Open .eml Files, not Reading''s settings'
        # Ctrl+Tab, pressed as the keyboard would, to Reading
        [void][Native.Win]::SetForegroundWindow($options)
        Start-Sleep -Milliseconds 300
        [Native.Win]::keybd_event(0x11, 0, 0, [IntPtr]::Zero)
        [Native.Win]::keybd_event(0x09, 0, 0, [IntPtr]::Zero)
        [Native.Win]::keybd_event(0x09, 0, 2, [IntPtr]::Zero)
        [Native.Win]::keybd_event(0x11, 0, 2, [IntPtr]::Zero)
        Check ([bool](WaitFor { [int][Native.Win]::SendMessage($tabs, $TCM_GETCURSEL, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 } 5)) 'Ctrl+Tab goes to Reading'
        Check ((Visible $options $IDC_OPTIONS_THREADS) -and (Visible $options $IDC_OPTIONS_LAYOUT) -and -not (Visible $options $IDC_OPTIONS_LANGUAGE)) 'which shows its own settings only'
        Shot $options 'options-2-reading'
        # Group messages by conversation cleared (as a click clears it) and Apply: set with the window still open
        $threadsBox = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_THREADS)
        Check ([int][Native.Win]::SendMessage($threadsBox, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1) 'Group messages by conversation is on'
        [void][Native.Win]::SendMessage($threadsBox, $BM_SETCHECK, [IntPtr]0, [IntPtr]::Zero)
        Click $options $IDC_OPTIONS_THREADS
        Check ([bool](WaitFor { [Native.Win]::IsWindowEnabled($apply) } 5)) 'a change enables Apply'
        Click $options $IDC_OPTIONS_APPLY
        Check ([bool](WaitFor { (Get-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue).GroupByConversation -eq 0 } 5) -and [Native.Win]::IsWindowVisible($options)) 'Apply sets it, and Options stays open'
        Check ([bool](WaitFor { -not [Native.Win]::IsWindowEnabled($apply) } 5)) 'and Apply is disabled again'
        # on again, then Cancel: as Apply left it
        [void][Native.Win]::SendMessage($threadsBox, $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $options $IDC_OPTIONS_THREADS
        Click $options 2
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($options) } 5)) 'Cancel closes Options'
        Start-Sleep -Milliseconds 500
        Check ((Get-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue).GroupByConversation -eq 0) 'and leaves the setting as Apply set it'
        Command $main $IDM_OPTIONS
        $options = WaitShown 'InboxClassicOptions'
    }
    if ($options) {
        # Reading > Encryption: Search in encrypted messages and Look up keys on keys.openpgp.org, both on at first,
        # each with its note under it (app.h)
        $IDC_OPTIONS_SEARCH_ENCRYPTED = 683; $IDC_OPTIONS_SEARCH_ENCRYPTED_NOTE = 684; $IDC_OPTIONS_KEYSERVER = 685; $IDC_OPTIONS_KEYSERVER_NOTE = 686
        $apply = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_APPLY)
        $boxOn = { param($o, $id) [int][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $id), $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1 }
        OptionsPage $options 1
        Check ((Visible $options $IDC_OPTIONS_SEARCH_ENCRYPTED) -and (& $boxOn $options $IDC_OPTIONS_SEARCH_ENCRYPTED)) 'Reading has Search in encrypted messages, on'
        Check ((Visible $options $IDC_OPTIONS_KEYSERVER) -and (& $boxOn $options $IDC_OPTIONS_KEYSERVER)) 'and Look up keys on keys.openpgp.org, on'
        $searchNote = GetText $options $IDC_OPTIONS_SEARCH_ENCRYPTED_NOTE
        $keyserverNote = GetText $options $IDC_OPTIONS_KEYSERVER_NOTE
        Check ($searchNote -match 'not encrypted' -and $searchNote -match 'AI agents cannot search') "its note says the index is not encrypted and AI agents never search it ($searchNote)"
        Check ($keyserverNote -match 'address') "the keyserver's note says what is sent ($keyserverNote)"
        Shot $options 'options-4-encryption'
        # each off, with Apply, kept when Options opens again; then on again
        foreach ($id in $IDC_OPTIONS_SEARCH_ENCRYPTED, $IDC_OPTIONS_KEYSERVER) {
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($options, $id), $BM_SETCHECK, [IntPtr]0, [IntPtr]::Zero)
            Click $options $id
            Check ([bool](WaitFor { [Native.Win]::IsWindowEnabled($apply) } 5)) "turning $id off enables Apply"
            Click $options $IDC_OPTIONS_APPLY
            Check ([bool](WaitFor { -not [Native.Win]::IsWindowEnabled($apply) } 5)) 'Apply sets it'
            Click $options 2
            [void](WaitFor { -not [Native.Win]::IsWindow($options) } 5)
            Command $main $IDM_OPTIONS
            $options = WaitShown 'InboxClassicOptions'
            if (-not $options) { break }
            $apply = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_APPLY)
            OptionsPage $options 1
            Check (-not (& $boxOn $options $id)) "Options opened again shows $id off"
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($options, $id), $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
            Click $options $id
            # the click is posted: Apply is enabled once the dialog has handled it, not before
            Check ([bool](WaitFor { [Native.Win]::IsWindowEnabled($apply) } 5)) "turning $id on again enables Apply"
            Click $options $IDC_OPTIONS_APPLY
            [void](WaitFor { -not [Native.Win]::IsWindowEnabled($apply) } 5)
            Click $options 2
            [void](WaitFor { -not [Native.Win]::IsWindow($options) } 5)
            Command $main $IDM_OPTIONS
            $options = WaitShown 'InboxClassicOptions'
            if (-not $options) { break }
            $apply = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_APPLY)
            OptionsPage $options 1
            Check (& $boxOn $options $id) "on again, it stays on when Options opens again ($id)"
        }
    }
    if ($options) {
        # grouped again for the steps after, with OK
        OptionsPage $options 1
        $threadsBox = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_THREADS)
        Check ([int][Native.Win]::SendMessage($threadsBox, $BM_GETCHECK, [IntPtr]::Zero, [IntPtr]::Zero) -eq 0) 'Options opened again shows it off'
        [void][Native.Win]::SendMessage($threadsBox, $BM_SETCHECK, [IntPtr]1, [IntPtr]::Zero)
        Click $options $IDC_OPTIONS_THREADS
        OptionsPage $options 0
        $combo = [Native.Win]::GetDlgItem($options, $IDC_OPTIONS_LANGUAGE)
        $count = [int][Native.Win]::SendMessage($combo, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero)
        # CB_GETLBTEXT is one of the messages Windows copies between processes: a buffer of this one
        $items = @(for ($i = 0; $i -lt $count; $i++) {
            $item = New-Object System.Text.StringBuilder 256
            [void][Native.Win]::SendMessage($combo, $CB_GETLBTEXT, [IntPtr]$i, $item)
            $item.ToString()
        })
        # the names in themselves, from pe_i18n::LANGUAGES as core/include/languages.tsv lists them (read as UTF-8: the
        # script stays ASCII for Windows PowerShell, which reads it as ANSI)
        $names = @(foreach ($line in Get-Content -Encoding UTF8 (Join-Path $PSScriptRoot '..\core\include\languages.tsv')) {
            if ($line -and -not $line.StartsWith('#')) { ($line -split "`t")[1] }
        })
        Check ($items.Count -eq $names.Count + 1 -and $items[0] -like 'System default (*)') "Language starts with System default and the language it is now ($($items[0]))"
        Check ((($items | Select-Object -Skip 1) -join ',') -eq ($names -join ',')) "and lists every language by its own name ($($items -join ', '))"
        Check ([Native.Win]::GetDlgItem($options, $IDC_OPTIONS_NOTIFY) -ne [IntPtr]::Zero) 'Notify of New Mail is there too'
        $deutsch = [array]::IndexOf($items, 'Deutsch')
        [void][Native.Win]::SendMessage($combo, $CB_SETCURSEL, [IntPtr]$deutsch, [IntPtr]::Zero)
        Shot $options 'options-1-language'
        Click $options 1
        Check ([bool](WaitFor { (Get-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue).GroupByConversation -eq 1 } 5)) 'OK sets every page, Reading too'
        $restart = WaitShown 'InboxClassicRestart' 10
        Check ($null -ne $restart) 'a language chosen asks to restart'
        if ($restart) {
            Check ((GetText $restart 1) -eq '&Restart Now' -and (GetText $restart 2) -eq '&Later') 'with Restart Now and Later'
            Click $restart 2
        }
        Start-Sleep -Milliseconds 500
        Check ((Get-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue).Language -eq 'de') 'the language is kept for the next start'
        Check ([Native.Win]::IsWindow($main) -and -not $app.HasExited) 'Later keeps the app running'
    }

    # ---- about and help ----

    Step 'about'
    Command $main $IDM_ABOUT
    $about = WaitWindow '#32770' 'About Inbox Classic'
    Check ($null -ne $about) 'About shows the version'
    if ($about) {
        Shot $about 'help-1-about'
        [void][Native.Win]::PostMessage($about, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { [Native.Win]::FindWindow('#32770', 'About Inbox Classic') -eq [IntPtr]::Zero })
    }

    Step 'help'
    # app/src/app.h: the help window's controls
    $IDC_HELP_PANE = 810; $IDC_HELP_BACK = 811; $IDC_HELP_FORWARD = 812; $IDC_HELP_HOME = 813; $IDC_HELP_PRINT = 814
    $IDC_HELP_TABS = 820; $IDC_HELP_TREE = 821; $IDC_HELP_QUERY = 822; $IDC_HELP_SEARCH = 823; $IDC_HELP_RESULTS = 824
    $TCM_GETCURSEL = 0x130B; $LBN_SELCHANGE = 1; $VK_F1 = 0x70
    Command $main $IDM_HELP
    $help = WaitWindow 'InboxClassicHelp'
    Check ($null -ne $help) 'Help opens the help window'
    if ($help) {
        # the window is found as soon as it is made: its contents, once they are there
        $helpTree = WaitFor {
            $t = [Native.Win]::GetDlgItem($help, $IDC_HELP_TREE)
            if ($t -ne [IntPtr]::Zero -and [int][Native.Win]::SendMessage($t, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -gt 0) { $t }
        } 15
        # the row selected in the contents: the topic shown
        function HelpShown {
            $item = [Native.Win]::SendMessage($helpTree, $TVM_GETNEXTITEM, [IntPtr]9, [IntPtr]::Zero)
            if ($item -ne [IntPtr]::Zero) { [Native.Win]::RemoteTreeText($helpTree, $item) } else { '' }
        }
        # the sections (the rows at the top) and how many topics each has
        $sections = @()
        $topics = 0
        $helpTitles = @()
        $section = [Native.Win]::SendMessage($helpTree, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
        while ($section -ne [IntPtr]::Zero) {
            $sections += [Native.Win]::RemoteTreeText($helpTree, $section)
            $child = [Native.Win]::SendMessage($helpTree, $TVM_GETNEXTITEM, [IntPtr]4, $section)
            $count = 0
            while ($child -ne [IntPtr]::Zero) { $count++; $helpTitles += [Native.Win]::RemoteTreeText($helpTree, $child); $child = [Native.Win]::SendMessage($helpTree, $TVM_GETNEXTITEM, [IntPtr]1, $child) }
            Check ($count -gt 0) "the section '$($sections[-1])' has its topics"
            $topics += $count
            $section = [Native.Win]::SendMessage($helpTree, $TVM_GETNEXTITEM, [IntPtr]1, $section)
        }
        Check ($sections.Count -ge 8 -and $topics -ge 40) "the contents list the sections and their topics ($($sections.Count) sections, $topics topics)"
        Check ([int][Native.Win]::SendMessage($helpTree, $TVM_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero) -eq ($sections.Count + $topics)) 'the tree has nothing else'
        $helpHome = WaitFor { $t = HelpShown; if ($t) { $t } }
        Check ([bool]$helpHome) "the help opens at the main window's topic, selected in the contents ($helpHome)"
        # the words of a button of the help's toolbar
        $helpBar = [Native.Win]::GetDlgItem($help, 800)
        function HelpButton([int]$id) { [Native.Win]::RemoteText($helpBar, 0x044B, [IntPtr]$id) }
        foreach ($button in $IDC_HELP_PANE, $IDC_HELP_BACK, $IDC_HELP_FORWARD, $IDC_HELP_HOME, $IDC_HELP_PRINT) {
            Check ([bool](HelpButton $button)) "the help's toolbar has button $button"
        }
        # Hide takes the left pane away and is Show then, which brings it back
        $hideText = HelpButton $IDC_HELP_PANE
        $tabs = [Native.Win]::GetDlgItem($help, $IDC_HELP_TABS)
        Command $help $IDC_HELP_PANE
        Check ([bool](WaitFor { -not [Native.Win]::IsWindowVisible($tabs) } 5)) 'Hide hides the left pane'
        Check ([bool](WaitFor { (HelpButton $IDC_HELP_PANE) -ne $hideText } 5)) 'and the button is Show then'
        Command $help $IDC_HELP_PANE
        Check ([bool](WaitFor { [Native.Win]::IsWindowVisible($tabs) } 5)) 'Show brings the pane back'
        Start-Sleep -Seconds 3
        Shot $help 'help-2-contents'

        # Search: the topics with the words, listed by their titles
        SetText $help $IDC_HELP_QUERY 'junk'
        Click $help $IDC_HELP_SEARCH
        $results = [Native.Win]::GetDlgItem($help, $IDC_HELP_RESULTS)
        Check ([bool](WaitFor { (ListBoxCount $results) -gt 0 } 5)) 'a search for "junk" finds topics'
        Check ([int][Native.Win]::SendMessage($tabs, $TCM_GETCURSEL, [IntPtr]::Zero, [IntPtr]::Zero) -eq 1) 'on the Search tab'
        $found = @(0..((ListBoxCount $results) - 1) | ForEach-Object { ListBoxText $results $_ })
        Check (@($found | Where-Object { $helpTitles -notcontains $_ }).Count -eq 0) "every topic found is one of the contents ($($found -join ', '))"
        Start-Sleep -Seconds 1
        Shot $help 'help-3-search'

        # a topic found opened, then Back to the one before and Forward again
        $row = [Math]::Max(0, [array]::IndexOf($found, @($found | Where-Object { $_ -ne $helpHome })[0]))
        [void][Native.Win]::SendMessage($results, $LB_SETCURSEL, [IntPtr]$row, [IntPtr]::Zero)
        [void][Native.Win]::PostMessage($help, $WM_COMMAND, [IntPtr](($LBN_SELCHANGE -shl 16) -bor $IDC_HELP_RESULTS), $results)
        Check ([bool](WaitFor { (HelpShown) -eq $found[$row] } 5)) "a topic found opens, and the contents follow it ($($found[$row]))"
        Start-Sleep -Seconds 2
        Shot $help 'help-4-topic'
        Command $help $IDC_HELP_BACK
        Check ([bool](WaitFor { (HelpShown) -eq $helpHome } 5)) 'Back shows the topic before'
        Command $help $IDC_HELP_FORWARD
        Check ([bool](WaitFor { (HelpShown) -eq $found[$row] } 5)) 'Forward the one after'
        # F1 in the main window: the help, already open, at the main window's topic
        Key $main $VK_F1
        Check ([bool](WaitFor { (HelpShown) -eq $helpHome } 5)) "F1 in the main window shows its topic in the open help"
        $helpWindows = 0; $w = [IntPtr]::Zero
        while (($w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, 'InboxClassicHelp', [NullString]::Value)) -ne [IntPtr]::Zero) { $helpWindows++ }
        Check ($helpWindows -eq 1) 'in the one help window'
        [void][Native.Win]::PostMessage($help, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    }

    Step 'printing'
    SelectFolder 0
    [void](WaitFor { if ((Rows) -ge 1) { Rows } })
    SelectRow 1
    Command $main $IDM_PRINT
    # a window of its own over the app with the print preview in it, rather than a preview inside the reading pane
    $print = WaitWindow 'InboxClassicPrint' $null 20
    Check ($null -ne $print) 'Print opens the print preview in a window over the app'
    if (-not $print) {
        # what is there instead: the visible top-level windows with a title
        $w = [IntPtr]::Zero
        while (($w = [Native.Win]::FindWindowEx([IntPtr]::Zero, $w, [NullString]::Value, [NullString]::Value)) -ne [IntPtr]::Zero) {
            # not WM_GETTEXT: a hung window (a print dialog left behind) would block the test for good
            $text = New-Object System.Text.StringBuilder 256
            [void][Native.Win]::InternalGetWindowText($w, $text, 256)
            $title = $text.ToString()
            if ($title -and [Native.Win]::IsWindowVisible($w)) {
                $class = New-Object System.Text.StringBuilder 256
                [void][Native.Win]::GetClassName($w, $class, 256)
                Write-Host "   window: '$title' ($class)"
            }
        }
        Shot $main 'files-3-print-missing'
    }
    if ($print) {
        $printRect = New-Object Native.Win+RECT
        $mainRect = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect($print, [ref]$printRect)
        [void][Native.Win]::GetWindowRect($main, [ref]$mainRect)
        Check (($printRect.Right - $printRect.Left) -ge ($mainRect.Right - $mainRect.Left)) 'as wide as the app'
        # the preview takes a moment to lay the message out
        Start-Sleep -Seconds 5
        Shot $print 'files-3-print'
        [void][Native.Win]::PostMessage($print, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($print) } 10)) 'and closing it prints nothing'
    }

    Step 'opening a message file'
    # a .eml file opened from File Explorer: a second start with its path hands it to the app that runs
    $emlSubject = 'A message file to open'
    $emlFile = Join-Path (Resolve-Path $Out) 'opened.eml'
    Set-Content -LiteralPath $emlFile -Encoding ASCII -Value ("From: Pat Example <pat@example.com>`r`nTo: testuser@inboxclassic.test`r`n" +
        "Subject: $emlSubject`r`nDate: $([DateTime]::UtcNow.AddDays(-2).ToString('r'))`r`nMessage-ID: <opened-file@example.com>`r`n" +
        "MIME-Version: 1.0`r`nContent-Type: multipart/mixed; boundary=`"eml-boundary`"`r`n`r`n" +
        "--eml-boundary`r`nContent-Type: text/plain; charset=utf-8`r`n`r`nThis message was saved as a file and opened from it.`r`n" +
        "--eml-boundary`r`nContent-Type: text/plain; charset=utf-8`r`nContent-Disposition: attachment; filename=`"file-notes.txt`"`r`n`r`n" +
        "notes that came in the message file`r`n--eml-boundary--`r`n")
    $second = Start-Process -FilePath $Exe -ArgumentList @('--store', "`"$store`"", "`"$emlFile`"") -PassThru
    $started += $second
    $fileWindow = WaitWindow 'InboxClassicMessage' "$emlSubject - Inbox Classic" 20
    Check ($null -ne $fileWindow) 'a message window opens with the message of the file'
    Check ([bool](WaitFor { $second.HasExited } 10)) 'and the second start hands it over and ends'
    if ($fileWindow) {
        $fileBar = [Native.Win]::FindDescendants($fileWindow, 'ToolbarWindow32') | Select-Object -First 1
        $hasButton = { param($id) [int][Native.Win]::SendMessage($fileBar, $TB_COMMANDTOINDEX, [IntPtr]$id, [IntPtr]::Zero) -ge 0 }
        Check ((& $hasButton $IDM_REPLY) -and (& $hasButton $IDM_PRINT) -and (& $hasButton $IDM_SAVE_AS) -and -not (& $hasButton $IDM_DELETE)) 'its toolbar answers, prints and saves it, and has no Delete (it is no folder''s)'
        Start-Sleep -Seconds 2
        Check ([bool](WaitFor { Visible $fileWindow $IDC_ATTACHMENTS } 10)) 'the file''s message shows the paper clip of its attachment'
        Shot $fileWindow 'files-4-open-eml'
        # Save Attachments of the paper clip's menu (its last item) into a folder, as for a folder's message
        $emlSaveDir = Join-Path (Resolve-Path $Out) 'eml-attachments'
        Remove-Item -Recurse -Force -LiteralPath $emlSaveDir -ErrorAction SilentlyContinue
        [void](New-Item -ItemType Directory -Path $emlSaveDir)
        Command $fileWindow $IDC_ATTACHMENTS
        $menu = WaitWindow '#32768' $null 10
        Check ($null -ne $menu) 'its paper clip offers the file'
        if ($menu) {
            Start-Sleep -Milliseconds 500
            $menu = [Native.Win]::FindWindow('#32768', [NullString]::Value)
            if ($menu -ne [IntPtr]::Zero) {
                Key $menu $VK_UP
                Key $menu $VK_RETURN
            }
            if (-not (WaitWindow '#32770' 'Save Attachments' 5)) {
                # where the menu does not take posted keys: real keystrokes, the window in front
                [void][Native.Win]::SetForegroundWindow($fileWindow)
                [System.Windows.Forms.SendKeys]::SendWait('{UP}{ENTER}')
            }
            Check (AnswerFolderDialog 'Save Attachments' $emlSaveDir) 'Save Attachments asks for a folder'
            $emlSaved = WaitFor { $f = Join-Path $emlSaveDir 'file-notes.txt'; if (Test-Path $f) { Get-Content -Raw $f } } 10
            Check ($emlSaved -and $emlSaved.TrimEnd() -eq 'notes that came in the message file') "and saves the file's attachment there ($emlSaved)"
        }
        $compose = WaitCompose { Command $fileWindow $IDM_REPLY }
        Check ($null -ne $compose) 'Reply opens a new message'
        if ($compose) {
            $replySubject = GetText $compose $IDC_SUBJECT
            Check ($replySubject -eq "Re: $emlSubject") "answering the file's message ($replySubject)"
            [void](CloseCompose $compose)
        }
        [void][Native.Win]::PostMessage($fileWindow, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        Check ([bool](WaitFor { -not [Native.Win]::IsWindow($fileWindow) } 10)) 'and the window closes'
    }

    Step 'a message downloaded ahead opens at once'
    # SCENARIO 49b, near the end: everything recent is downloaded from now on, which the steps before do not expect
    # Options' Download messages ahead at the choice of that place: 0 recent messages, 2 only when opened
    function SetDownloadAhead([int]$choice) {
        Command $main $IDM_OPTIONS
        $o = WaitShown 'InboxClassicOptions' 10
        if ($o) {
            OptionsPage $o 2
            [void][Native.Win]::SendMessage([Native.Win]::GetDlgItem($o, $IDC_OPTIONS_DOWNLOAD_AHEAD), $CB_SETCURSEL, [IntPtr]$choice, [IntPtr]::Zero)
            Click $o 1
            [void](WaitFor { -not [Native.Win]::IsWindow($o) } 5)
        }
    }
    $kTestFromStore = 0x53544F52
    SetDownloadAhead 0
    $before = 'Subject: Here before you'
    # in Archive, dated ahead of the others there, so it is the first row
    AddMessage ("From: Kim Example <kim@example.com>`r`nTo: testuser@inboxclassic.test`r`n$before`r`n" +
        "Message-ID: <here-before@example.com>`r`nDate: $([DateTime]::UtcNow.AddMinutes(20).ToString('r'))`r`n`r`nDownloaded before it was opened.`r`n") @() 'Archive'
    Command $main $IDM_SYNC
    [void](WaitFor { Find 'Archive' $before } 30)
    # time for the background to download it: nothing on the screen says when
    Start-Sleep -Seconds 10
    SelectFolder 3
    Start-Sleep -Seconds 2
    SelectRow 0
    Check ([bool](WaitFor { [Native.Win]::SendText($main, $kTestFromStore, '') -eq 11 } 10)) 'a new message downloaded ahead opens from the store, without a download'
    Shot $main 'open-1-from-store'
    SetDownloadAhead 2
    SelectFolder 0

    Step 'the tray'
    Add-Type -Namespace Native -Name Tray -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)] public struct NOTIFYICONIDENTIFIER { public int cbSize; public IntPtr hWnd; public uint uID; public Guid guidItem; }
public struct IconRect { public int Left, Top, Right, Bottom; }
[DllImport("shell32.dll")] public static extern int Shell_NotifyIconGetRect(ref NOTIFYICONIDENTIFIER identifier, out IconRect rect);
public static bool HasIcon(IntPtr window) {
    var id = new NOTIFYICONIDENTIFIER { cbSize = Marshal.SizeOf(typeof(NOTIFYICONIDENTIFIER)), hWnd = window, uID = 1 };
    IconRect rect;
    return Shell_NotifyIconGetRect(ref id, out rect) == 0;
}
'@
    Check ([Native.Tray]::HasIcon($main)) 'the app has its icon in the notification area'
    SelectFolder 0
    $beforeRows = WaitFor { if ((Rows) -ge 1) { Rows } }
    # the close button hides it there, where it goes on checking mail
    [void][Native.Win]::PostMessage($main, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
    Check ([bool](WaitFor { -not [Native.Win]::IsWindowVisible($main) } 10)) 'closing the window hides it in the tray'
    Check (-not $app.HasExited) 'and the app keeps running'
    # new mail while it is hidden: it comes in at once (IDLE), with a notification
    AddMessage "From: Nora Example <nora@example.com>`r`nTo: testuser@inboxclassic.test`r`nSubject: Fresh while hidden`r`nDate: $([DateTime]::UtcNow.AddMinutes(5).ToString('r'))`r`nMessage-ID: <fresh-hidden@example.com>`r`n`r`nJust in.`r`n"
    Start-Sleep -Seconds 6
    $desktop = [Native.Win]::GetDesktopWindow()
    Shot $desktop 'tray-1-notification'
    # an encrypted message: announced by its sender over "Encrypted message", never the Subject outside its encryption
    [void](Notified '')
    AddMessage ([IO.File]::ReadAllText((Join-Path $pgpFiles 'secure-encrypted.eml')))
    Check ([bool](WaitFor { Notified "Alice Example`nEncrypted message" } 30)) 'an encrypted message is announced as Encrypted message, from Alice Example'
    # a click on the icon brings it back, with the new message in the Inbox
    $WM_TRAY = 0x8000 + 60; $NIN_SELECT = 0x0400
    [void][Native.Win]::PostMessage($main, $WM_TRAY, [IntPtr]::Zero, [IntPtr]$NIN_SELECT)
    Check ([bool](WaitFor { [Native.Win]::IsWindowVisible($main) } 10)) 'a click on the icon shows the window again'
    Check ([bool](WaitFor { (Rows) -gt $beforeRows } 10)) "with the new message in the list, which came without a sync ($beforeRows, $(Rows))"
    # the taskbar button counts what is unread in the Inbox
    Start-Sleep -Seconds 1
    Shot $desktop 'tray-2-taskbar'
    # the count as an overlay on the taskbar button: what the app set, through its test hook (TrayBadge, plus 10)
    $badge = WaitFor { $b = [Native.Win]::SendText($main, 0x42414447, '') - 10; if ($b -gt 0) { $b } } 10
    Check ($null -ne $badge) "the taskbar button shows the unread count as an overlay ($([Native.Win]::SendText($main, 0x42414447, '') - 10))"
    $taskbar = [Native.Win]::FindWindow('Shell_TrayWnd', [NullString]::Value)
    if ($taskbar -ne [IntPtr]::Zero) { Shot $taskbar 'tray-3-badge' }
    $added = Find 'INBOX' ([regex]::Escape('<encrypted@ui-test.example>'))
    if ($added) { [void](Invoke-RestMethod -Method Delete "$rest/INBOX/messages/$($added.uid)") }
    Command $main $IDM_SYNC

    Step 'closing'
    # a message being written is asked about first: Cancel keeps the app and the message, No lets both go
    $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
    SetText $compose $IDC_SUBJECT 'Still writing'
    [void](TypeInEditor $compose 'Not done yet.')
    # File > Exit ends the app (the close button only hides it)
    Command $main $IDM_EXIT
    $ask = BoxOf $compose 10
    Check ($null -ne $ask) 'closing the app asks about a message with changes'
    if ($ask) {
        Shot $ask 'write-12-close-app'
        Click $ask 2
        Start-Sleep -Seconds 1
        Check ([Native.Win]::IsWindow($main) -and [Native.Win]::IsWindow($compose)) 'Cancel keeps the app and the message open'
        Command $main $IDM_EXIT
        $ask = BoxOf $compose 10
        if ($ask) { Click $ask 7 }
    }
    Check ($app.WaitForExit(15000)) 'No closes the message without saving, and the app'

    # ---- the other languages ----

    # the app started again with this store; the main window once it shows its folders
    function StartAgain([string[]]$more) {
        # one that did not close (its failure is reported) would take the new start over
        if (-not $script:app.HasExited) { $script:app.Kill(); [void]$script:app.WaitForExit(5000) }
        $script:started += $script:app
        $script:app = Start-Process -FilePath $Exe -ArgumentList ($arguments + $more) -PassThru
        $window = WaitFor {
            # the window of the new process, not of one still closing
            $w = [Native.Win]::FindWindow('InboxClassicMain', [NullString]::Value)
            $owner = [uint32]0
            if ($w -ne [IntPtr]::Zero) { [void][Native.Win]::GetWindowThreadProcessId($w, [ref]$owner) }
            if ($w -ne [IntPtr]::Zero -and $owner -eq $script:app.Id -and [Native.Win]::IsWindowVisible($w)) { $w }
        } 30
        if ($window) {
            $t = [Native.Win]::GetDlgItem($window, $IDC_TREE)
            [void](WaitFor { if (@(TreeTexts $t).Count -gt 2) { $true } } 30)
            # the app starts with the row it was closed on (the core's test checks that); the steps after a new start
            # begin from the first row, All Inboxes, as a first start does
            $root = [Native.Win]::SendMessage($t, $TVM_GETNEXTITEM, [IntPtr]0, [IntPtr]::Zero)
            [void][Native.Win]::SendMessage($t, $TVM_SELECTITEM, [IntPtr]9, $root)
            Start-Sleep -Seconds 2
        }
        $window
    }
    # the app ended with File > Exit, as cleanup between the languages (the closing step above is the check of Exit):
    # the windows a failed step left open are said and closed first, so the next start does not open them again; when
    # the app still does not end, it is a check only when nothing was left open
    function Quit([IntPtr]$window, [string]$what) {
        $left = @(AppWindows | Where-Object { $_ -ne $window })
        if ($left.Count) {
            Write-Host "   (windows left open before File > Exit ($what): $(@($left | ForEach-Object { Describe $_ }) -join '; '))"
            CloseStrays "before File > Exit ($what)" -Writing
        }
        Command $window $IDM_EXIT
        if ($script:app.WaitForExit(15000)) { return }
        $still = @(AppWindows | ForEach-Object { Describe $_ }) -join '; '
        if ($left.Count) {
            Write-Host "   (File > Exit did not end the app ($what) after windows were left open; still open: $still)"
        } else {
            Check $false "File > Exit ends the app ($what; still open: $still)"
        }
    }
    # the message with a photo and an invoice in the language of this start, for the review: opened as a message file
    # in a window of its own (`$prefix-previews`; this start has no passwords, and its sign-in prompt stays, as the
    # steps after expect), with Options' Reading page when `$options` (`$prefix-previews-options`)
    function PreviewsInLanguage([IntPtr]$window, [string]$prefix, [bool]$options) {
        [void][Native.Win]::SendText($window, 2, (Join-Path $previewFiles 'photo-and-pdf.eml'))
        $opened = WaitShown 'InboxClassicMessage' 20
        if (-not $opened) { Check $false "the message file opens ($prefix)"; return }
        Check ($null -ne (PreviewsShown 4 3 $false 'window:')) "the photo and the invoice show after the text ($prefix, $(PreviewsState 'window:'))"
        Start-Sleep -Milliseconds 500
        Shot $opened "$prefix-previews"
        # closed with its close box (Esc posted to it is not taken, and it would be left open)
        [void][Native.Win]::PostMessage($opened, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
        [void](WaitFor { -not [Native.Win]::IsWindow($opened) } 10)
        if ($options) {
            Command $window $IDM_OPTIONS
            $o = WaitShown 'InboxClassicOptions' 10
            if ($o) {
                OptionsPage $o 1
                Shot $o "$prefix-previews-options"
                Click $o 2
                [void](WaitFor { -not [Native.Win]::IsWindow($o) } 10)
            }
        }
    }
    # the toolbar of the main window and the words of its buttons
    function ToolbarText([IntPtr]$window, [int]$id) {
        foreach ($bar in [Native.Win]::FindDescendants($window, 'ToolbarWindow32')) {
            $text = [Native.Win]::RemoteText($bar, 0x044B, [IntPtr]$id)
            if ($text) { return $text }
        }
        ''
    }
    # every static and button of $window: its words not left in English (a word of the pseudo-language starts with
    # "["), and, unless $wordsOnly, not cut off; with $cutOnly only that they are not cut off (a language of its own)
    function CheckPseudo([IntPtr]$window, [string]$what, [bool]$wordsOnly = $false, [bool]$cutOnly = $false) {
        $english = @(); $cut = @()
        foreach ($class in 'Static', 'Button') {
            foreach ($control in [Native.Win]::FindDescendants($window, $class)) {
                if (-not [Native.Win]::IsWindowVisible($control)) { continue }
                $text = WindowText $control
                if ([string]::IsNullOrWhiteSpace($text)) { continue }
                if (-not $text.TrimStart().StartsWith('[')) { $english += $text }
                $style = [Native.Win]::GetWindowLong($control, -16)
                $kind = $style -band 0x1F
                # owner drawn (a picture, a link) and group boxes draw their words their own way
                $drawn = ($class -eq 'Button' -and (($kind -band 0xF) -in @(7, 11))) -or ($class -eq 'Static' -and $kind -eq 13)
                if ($wordsOnly -or $drawn) { continue }
                $isButton = $class -eq 'Button'
                $hasBox = ($kind -band 0xF) -in @(2, 3, 5, 6)
                # BS_MULTILINE: Options' check boxes wrap their words; SS_EDITCONTROL: its notes break a long word
                $wraps = $isButton -and ($style -band 0x2000) -ne 0
                $edit = -not $isButton -and ($style -band 0x2000) -ne 0
                if (-not [Native.Win]::Fits($control, $text, $isButton, $hasBox, $wraps, $edit)) { $cut += $text }
            }
        }
        if (-not $cutOnly) { Check ($english.Count -eq 0) "${what}: no word left in English ($($english -join ' | '))" }
        if (-not $wordsOnly) { Check ($cut.Count -eq 0) "${what}: nothing cut off ($($cut -join ' | '))" }
    }

    # a message to ten recipients with Encrypt on, and Recipients' Keys from Send, in the language in use: the toolbar's,
    # the line's and the window's longer words, the Keys row with more recipients than fit (shots `$prefix-compose-keys`
    # and `$prefix-recipient-keys`, for the review; with `$pseudo` nothing left in English or cut off)
    function ComposeKeysShots([IntPtr]$window, [string]$prefix, [bool]$pseudo) {
        $c = WaitCompose { Command $window $IDM_NEW_MAIL }
        if (-not $c) { Check $false "a compose window opens ($prefix)"; return }
        SetText $c $IDC_TO ('Alice Example <alice@example.org>, Dave <dave@example.com>, Bob Example <bob@example.net>, ' +
            'erin@example.com, frank@example.com, grace@example.com, heidi@example.com, ivan@example.com, judy@example.com, ' +
            'mallory@example.org')
        SetText $c $IDC_SUBJECT 'Ten recipients'
        Command $c 176
        # the account it goes from has no key of its own here: Encrypt offers to make one (Cancel the default), and
        # once it is made, turns on
        $question = WaitShown 'InboxClassicAsk' 5
        if ($question) {
            if ($pseudo) { CheckPseudo $question 'the question of a missing key' }
            Check (([Native.Win]::GetWindowLong([Native.Win]::GetDlgItem($question, 2), -16) -band 0xF) -eq 1) "the question's safe answer is the default ($prefix)"
            Shot $c "$prefix-make-key" $question
            Click $question 1
            # Make a Key opens New Key; a key that can not be used here (this run's passwords are in memory only, and
            # the app started again) opens Encryption Keys, where New Key makes one, and Encrypt is clicked again
            $keysWindow = WaitShown 'InboxClassicKeys' 5
            if ($keysWindow) { Click $keysWindow 871 }
            $made = WaitShown 'InboxClassicNewKey' 10
            if ($made) {
                $for = [Native.Win]::GetDlgItem($made, 880)
                for ($i = 0; $i -lt [int][Native.Win]::SendMessage($for, $CB_GETCOUNT, [IntPtr]::Zero, [IntPtr]::Zero); $i++) {
                    $label = New-Object System.Text.StringBuilder 256
                    [void][Native.Win]::SendMessage($for, $CB_GETLBTEXT, [IntPtr]$i, $label)
                    if ($label.ToString() -match 'alice@example\.com') { [void][Native.Win]::SendMessage($for, $CB_SETCURSEL, [IntPtr]$i, [IntPtr]::Zero) }
                }
                Click $made 1
                [void](WaitFor { -not [Native.Win]::IsWindow($made) } 30)
                $later = WaitShown 'InboxClassicAsk' 10
                if ($later) { Click $later 2; [void](WaitFor { -not [Native.Win]::IsWindow($later) } 5) }
            }
            if ($keysWindow) {
                Click $keysWindow 878
                [void](WaitFor { -not [Native.Win]::IsWindow($keysWindow) } 10)
                Command $c 176
            }
            Check ([bool](WaitFor { Visible $c 353 } 10)) "Encrypt is on once the key is made ($prefix)"
        }
        [void](WaitFor { -not ((GetText $c 353) -match '\.\.\.') -and (Visible $c 353) } 20)
        Start-Sleep -Seconds 1
        if ($pseudo) { CheckPseudo $c 'the compose window with Encrypt on' }
        Shot $c "$prefix-compose-keys"
        Command $c $IDC_SEND
        $k = WaitShown 'InboxClassicRecipientKeys' 10
        Check ($null -ne $k) "Send opens Recipients' Keys ($prefix)"
        if ($k) {
            if ($pseudo) { CheckPseudo $k "Recipients' Keys" }
            Shot $c "$prefix-recipient-keys" $k
            Click $k 2
            [void](WaitFor { -not [Native.Win]::IsWindow($k) } 5)
        }
        Check (CloseCompose $c) "the message to ten recipients closes without saving ($prefix)"
    }

    # the AI agent's draft of the agent step, opened from the top row `$draftsRow` of the tree, All Drafts or Drafts (the
    # folders have the language's names; the app started again has no passwords, so it is the copy kept from that
    # step): the line that says so in the language in use (shot `$prefix-agent-draft`; with `$pseudo` not left in
    # English)
    function AgentDraftShots([IntPtr]$main, [int]$draftsRow, [string]$prefix, [bool]$pseudo) {
        $tree = [Native.Win]::GetDlgItem($main, $IDC_TREE)
        $list = [Native.Win]::GetDlgItem($main, $IDC_LIST)
        $drafts = @(ChildRows ([IntPtr]::Zero))[$draftsRow]
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, $drafts)
        # one draft on the server; ImapKit's users share one mailbox, so with the account signed in with the sign-in app
        # it is listed once for each account, each row naming its own
        $onServer = @(Messages 'Drafts' | Where-Object { (RawText $_) -match 'Subject: Agenda for Friday' }).Count
        $row = WaitFor { $r = @(SubjectRows 'Agenda for Friday'); if ($r.Count -ge 1) { "$($r[0])" } } 20
        $rows = @(SubjectRows 'Agenda for Friday')
        $places = @($rows | ForEach-Object { [Native.Win]::RemoteListText($list, $_, $COL_FOLDER) })
        Check ($null -ne $row -and $onServer -eq 1 -and @($places | Sort-Object -Unique).Count -eq $rows.Count) "the agent's draft is in Drafts, once for each account ($prefix; $(Bare $drafts): $($onServer) on the server, rows $($rows -join ', ') in $($places -join ', '))"
        # the copy of the account the agent step used: only it was downloaded then, and the app has no passwords now
        for ($i = 0; $i -lt $rows.Count; $i++) {
            if ($places[$i] -eq 'inboxclassic.test') { $row = "$($rows[$i])" }
        }
        if ($null -ne $row) {
            SelectRow ([int]$row)
            $c = WaitCompose { Key $list $VK_RETURN }
            Check ($null -ne $c) "it opens ($prefix)"
            if ($c) {
                Check ((Visible $c 354) -and (GetText $c 354) -match 'My AI agent') "the compose window says an agent wrote it (${prefix}: $(GetText $c 354))"
                if ($pseudo) { CheckPseudo $c 'the compose window of an agent''s draft' }
                Start-Sleep -Milliseconds 800
                Shot $c "$prefix-agent-draft"
                Check (CloseCompose $c) "the agent's draft closes without saving ($prefix)"
            }
        }
        [void][Native.Win]::SendMessage($tree, $TVM_SELECTITEM, [IntPtr]9, @(ChildRows ([IntPtr]::Zero))[0])
        # AI Agents: what the program may do, in the language's longer words, shown whole (shot `$prefix-agents`)
        Command $main $IDM_AI_AGENTS
        $agents = WaitShown 'InboxClassicAgents' 10
        if ($agents) {
            $hosts = [Native.Win]::GetDlgItem($agents, 631)
            $access = [Native.Win]::RemoteListText($hosts, 0, 1)
            $hostFont = [System.Drawing.Font]::FromHfont([Native.Win]::SendMessage($hosts, 0x0031, [IntPtr]::Zero, [IntPtr]::Zero))
            $needed = [System.Windows.Forms.TextRenderer]::MeasureText($access, $hostFont).Width
            $accessShown = [int][Native.Win]::SendMessage($hosts, 0x101D, [IntPtr]1, [IntPtr]::Zero)
            Check ($accessShown -ge $needed + 6 -and -not ([Native.Win]::GetWindowLong($hosts, -16) -band 0x00100000)) "AI Agents shows what the program may do whole (${prefix}: $access, $accessShown for $needed)"
            # the log written in English shown in the language in use: its rows are put into words each time
            $log = [Native.Win]::GetDlgItem($agents, 634)
            $rows = @(0..((ListCount $log) - 1) | ForEach-Object { [Native.Win]::RemoteListText($log, $_, 2) })
            $english = @($rows | Where-Object { $_ -match '^(Read \d|Saved the draft|Sent |Marked read|Flagged |Watched |You did not)' })
            $inLanguage = if ($pseudo) { @($rows | Where-Object { $_.StartsWith('[') }).Count -eq $rows.Count } else { @($rows -match 'gelesen').Count -ge 1 -and @($rows -match '^Entwurf ').Count -eq 1 }
            Check ($rows.Count -ge 6 -and $english.Count -eq 0 -and $inLanguage) "the log's rows are in the language in use (${prefix}: $($rows -join '; '))"
            if ($pseudo) { CheckPseudo $agents 'AI Agents' $true }
            Shot $agents "$prefix-agents"
            # Undo Since in the language's longer words, whole (shot `$prefix-undo-since`), closed without taking back
            Key $hosts $VK_HOME
            Start-Sleep -Milliseconds 300
            Click $agents 640
            $since = WaitShown 'InboxClassicAgentUndoSince' 10
            Check ($null -ne $since) "Undo Since opens ($prefix)"
            if ($since) {
                if ($pseudo) {
                    CheckPseudo $since 'Undo Since'
                } else {
                    $cut = @(foreach ($class in 'Static', 'Button') { [Native.Win]::FindDescendants($since, $class) | Where-Object { [Native.Win]::IsWindowVisible($_) } |
                        Where-Object { $t = WindowText $_; $t -and -not $(if ($class -eq 'Static') { [Native.Win]::FitsOwnFont($_, $t) } else { [Native.Win]::Fits($_, $t, $true, $false) }) } |
                        ForEach-Object { WindowText $_ } })
                    Check ($cut.Count -eq 0) "Undo Since: nothing cut off ($prefix`: $($cut -join ' | '))"
                }
                Shot $since "$prefix-undo-since"
                [void][Native.Win]::PostMessage($since, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
                [void](WaitFor { -not [Native.Win]::IsWindow($since) } 10)
            }
            if ($pseudo) {
                # Clear empties the log, what agents did and what they read (what they sent still counts against the
                # limit of an hour, pe-store's a_cleared_log_still_counts)
                Click $agents 636
                # the question Clear asks first, a message box of the window (GW_ENABLEDPOPUP)
                $sure = WaitFor { $w = [Native.Win]::GetWindow($agents, 6); if ($w -ne [IntPtr]::Zero -and $w -ne $agents) { $w } } 10
                Check ($null -ne $sure) "Clear asks first ($prefix)"
                if ($sure) { Click $sure 6 }
                Check ([bool](WaitFor { (ListCount $log) -eq 0 } 10)) "Clear empties the log ($prefix)"
                Check ((ListCount ([Native.Win]::GetDlgItem($agents, 638))) -eq 0 -and -not [Native.Win]::IsWindowEnabled([Native.Win]::GetDlgItem($agents, 636))) 'and the reads under it, with nothing more to clear'
                # the limit counts an agent's sends in the store's log, the cleared ones with them
                $count = Join-Path $Out 'count-sends.cjs'
                Set-Content -Path $count -Encoding UTF8 -Value ("const { DatabaseSync } = require('node:sqlite');`n" +
                    "const store = new DatabaseSync(process.argv[2], { readOnly: true });`n" +
                    "console.log(store.prepare(`"SELECT COUNT(*) AS n FROM agent_log WHERE what = 'send' AND hidden = 1`").get().n);")
                $sends = (& node --no-warnings $count $store | Select-Object -Last 1)
                # the message sent and the answer to the invitation
                Check ("$sends".Trim() -eq '2') "the sends cleared still count against the agent's limit ($sends)"
            }
            [void][Native.Win]::PostMessage($agents, $WM_CLOSE, [IntPtr]::Zero, [IntPtr]::Zero)
            [void](WaitFor { -not [Native.Win]::IsWindow($agents) } 10)
        }
        TerminalQuestion 'OpenConsole' $(if ($pseudo) { 'agents-10c-terminal-pseudo' } else { 'agents-10b-terminal-german' }) 2 $pseudo
    }

    Step 'in German'
    # the language chosen in Options above, read at start
    $de = Catalog 'de'
    $main = StartAgain @()
    Check ($null -ne $main) 'the app starts again in the language chosen'
    if ($main) {
        $menus = [Native.Win]::MenuLabels([Native.Win]::GetMenu($main))
        $wanted = @('menu-file', 'menu-edit', 'menu-view', 'menu-tools', 'menu-message', 'menu-help' | ForEach-Object { $de[$_] })
        Check (($menus -join ',') -eq ($wanted -join ',')) "the menus are German ($($menus -join ', '))"
        $tools = [Native.Win]::MenuLabels([Native.Win]::GetSubMenu([Native.Win]::GetMenu($main), 3))
        Check ($tools[-1] -eq $de['cmd-options']) "Tools ends with $($de['cmd-options'])"
        Check ((ToolbarText $main $IDM_NEW_MAIL) -eq $de['ui-tb-create-mail']) "the toolbar is German ($(ToolbarText $main $IDM_NEW_MAIL))"
        $folders = @(TreeTexts ([Native.Win]::GetDlgItem($main, $IDC_TREE)))
        # with two accounts the Inboxes are named as their accounts under All Inboxes: Sent Items, or All Sent with
        # two accounts, is looked for
        Check (@($folders | Where-Object { $_ -like "$($de['folder-sent'])*" -or $_ -like "$($de['ui-all-sent'])*" }).Count -gt 0) "the folders are German ($($folders -join ', '))"
        $status = [Native.Win]::FindDescendants($main, 'msctls_statusbar32') | Select-Object -First 1
        Write-Host "   status bar: $(StatusPart $status 0) | $(StatusPart $status 1)"
        Shot $main 'lang-1-german'
        PreviewsInLanguage $main 'lang-de' $true
        # the sign-in buttons say it in German, and the form is as wide as they are
        Command $main $IDM_NEW_ACCOUNT
        $form = WaitShown 'InboxClassicAccountStart' 10
        Check ($null -ne $form) 'Add Mail Account opens in German'
        if ($form) {
            Start-Sleep -Milliseconds 500
            Shot $form 'lang-1b-german-form'
            Click $form 2
        }
        Start-Sleep -Milliseconds 500
        # the setup windows in German, the longest words of the catalogs: nothing cut off
        Command $main $IDM_EXPORT_SETUP
        $export = WaitShown 'InboxClassicSetupExport' 10
        Check ($export -and (WindowText $export) -eq $de['ui-setup-export-title']) "Export Settings and Accounts opens in German ($(if ($export) { WindowText $export }))"
        if ($export) {
            SetCheck $export $IDC_SETUP_USE_PASSPHRASE $true
            SetText $export $IDC_SETUP_PASSPHRASE 'kurz'
            [void](WaitFor { Visible $export $IDC_SETUP_PROBLEM } 5)
            Shot $export 'setup-de-export'
            Click $export 2
            [void](WaitFor { -not [Native.Win]::IsWindow($export) } 5)
        }
        Command $main $IDM_IMPORT_SETUP
        if (AnswerFileDialog $de['ui-setup-import-title'] $setupFile $null) {
            $ask = WaitShown 'InboxClassicPassphrase' 30
            if ($ask) {
                SetText $ask $IDC_KEY_PASSPHRASE 'correct horse battery'
                Click $ask 1
            }
            $import = WaitShown 'InboxClassicSetupImport' 30
            Check ($null -ne $import) 'and Import Settings and Accounts'
            if ($import) {
                Shot $import 'setup-de-import'
                Click $import 2
                [void](WaitFor { -not [Native.Win]::IsWindow($import) } 5)
            }
        } else {
            Check $false 'Import Settings and Accounts asks for a file in German'
        }
        ComposeKeysShots $main 'lang-de' $false
        # All Drafts (two accounts) or Drafts (one) by its German name among the top rows of the tree
        $tree = [Native.Win]::GetDlgItem($main, $IDC_TREE)
        $tops = @(ChildRows ([IntPtr]::Zero) | ForEach-Object { Bare $_ })
        $script:draftsRow = [Array]::IndexOf($tops, $de['ui-all-drafts'])
        if ($script:draftsRow -lt 0) { $script:draftsRow = [Array]::IndexOf($tops, $de['folder-drafts']) }
        Check ($script:draftsRow -ge 0) "the tree has $($de['ui-all-drafts']) or $($de['folder-drafts']) ($($tops -join ', '))"
        if ($script:draftsRow -ge 0) { AgentDraftShots $main $script:draftsRow 'lang-de' $false }
        Quit $main 'German'
    }
    Remove-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue

    Step 'in the pseudo-language'
    $main = StartAgain @('--language', 'qps')
    Check ($null -ne $main) 'the app starts in the pseudo-language'
    if ($main) {
        $menus = [Native.Win]::MenuLabels([Native.Win]::GetMenu($main))
        $bar = [Native.Win]::GetMenu($main)
        $items = @()
        for ($i = 0; $i -lt $menus.Count; $i++) { $items += [Native.Win]::MenuLabels([Native.Win]::GetSubMenu($bar, $i)) }
        $english = @(($menus + $items) | Where-Object { $_ -and -not $_.StartsWith('[') })
        Check ($english.Count -eq 0) "no menu item is left in English ($($english -join ' | '))"
        $buttons = @($IDM_NEW_MAIL, $IDM_REPLY, $IDM_REPLY_ALL, $IDM_FORWARD, $IDM_PRINT, $IDM_DELETE, $IDM_SYNC | ForEach-Object { ToolbarText $main $_ })
        Check (@($buttons | Where-Object { -not $_.StartsWith('[') }).Count -eq 0) "no toolbar button is left in English ($($buttons -join ' | '))"
        # the longer words take room from the Find box down to its least width, and a button that would still run
        # under it is hidden (its command is in the menus)
        $findLeft = 0; $box = New-Object Native.Win+RECT
        [void][Native.Win]::GetWindowRect([Native.Win]::GetDlgItem($main, 205), [ref]$box); $findLeft = $box.Left
        $under = @()
        foreach ($bar in [Native.Win]::FindDescendants($main, 'ToolbarWindow32')) {
            foreach ($id in $IDM_NEW_MAIL, $IDM_REPLY, $IDM_REPLY_ALL, $IDM_FORWARD, $IDM_PRINT, $IDM_DELETE, 127, $IDM_SYNC, $IDM_MARK_READ, $IDM_MARK_UNREAD) {
                $r = [Native.Win]::RemoteRect($bar, 0x0433, [IntPtr]$id, 0)
                if ($r.Right -gt $r.Left -and $r.Right -gt $findLeft -and $r.Left -lt $box.Right -and $r.Top -lt $box.Bottom -and $r.Bottom -gt $box.Top) { $under += $id }
            }
        }
        Check ($under.Count -eq 0) "no toolbar button runs under the Find box ($($under -join ', '))"
        # the buttons hidden for want of room are in the menu of the chevron after the others
        $IDC_TOOLBAR_MORE = 233
        $chevron = [Native.Win]::GetDlgItem($main, $IDC_TOOLBAR_MORE)
        Check ($chevron -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($chevron)) 'the chevron is shown after the buttons that fit'
        if ($chevron -ne [IntPtr]::Zero -and [Native.Win]::IsWindowVisible($chevron)) {
            Click $main $IDC_TOOLBAR_MORE
            $more = WaitWindow '#32768' $null 10
            $hidden = if ($more) { @([Native.Win]::MenuLabels([Native.Win]::SendMessage($more, 0x01E1, [IntPtr]::Zero, [IntPtr]::Zero)) | Where-Object { $_ }) } else { @() }
            Check ($hidden.Count -gt 0 -and @($hidden | Where-Object { -not $_.StartsWith('[') }).Count -eq 0) "its menu has the hidden buttons ($($hidden -join ' | '))"
            if ($more) {
                Shot $main 'lang-2b-pseudo-more' $more
                Key $more $VK_ESCAPE
                [void](WaitFor { -not [Native.Win]::IsWindow($more) } 5)
            }
        }
        $folders = @(TreeTexts ([Native.Win]::GetDlgItem($main, $IDC_TREE)))
        Check (@($folders | Where-Object { $_.StartsWith('[') }).Count -ge 3) "the special folders and All Inboxes are pseudo ($($folders -join ', '))"
        CheckPseudo $main 'the main window' $true
        Shot $main 'lang-2-pseudo-main'

        $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
        if ($compose) {
            CheckPseudo $compose 'the compose window'
            Check (CloseCompose $compose) 'the new message closes (pseudo-language)'
        }

        ComposeKeysShots $main 'lang-pseudo' $true
        if ($script:draftsRow -ge 0) { AgentDraftShots $main $script:draftsRow 'lang-pseudo' $true }

        Command $main $IDM_OPTIONS
        $options = WaitShown 'InboxClassicOptions'
        if ($options) {
            CheckPseudo $options 'Options, General'
            Shot $options 'lang-4-pseudo-options'
            OptionsPage $options 1
            CheckPseudo $options 'Options, Reading'
            Shot $options 'lang-4b-pseudo-options-reading'
            OptionsPage $options 2
            CheckPseudo $options 'Options, Downloading'
            Shot $options 'lang-4c-pseudo-options-downloading'
            OptionsPage $options 3
            CheckPseudo $options 'Options, Sync'
            Shot $options 'lang-4d-pseudo-options-sync'
            # Set Up Sync's first step, its longer words (app.h: IDC_OPTIONS_SYNC_SET_UP)
            Click $options 963
            $setUp = WaitShown 'InboxClassicSyncSetUp' 10
            if ($setUp) {
                CheckPseudo $setUp 'Set Up Sync'
                Shot $setUp 'lang-4e-pseudo-sync-setup'
                Click $setUp 2
                [void](WaitFor { -not [Native.Win]::IsWindow($setUp) } 5)
            }
            Click $options 2
        }
        [void](WaitFor { -not [Native.Win]::IsWindow($options) } 10)
        PreviewsInLanguage $main 'lang-pseudo' $false

        # the key windows' longer words: Encryption Keys (with the two own keys of its step) and New Key
        Command $main 172
        $keys = WaitShown 'InboxClassicKeys'
        if ($keys) {
            CheckPseudo $keys 'Encryption Keys'
            Shot $keys 'lang-5-pseudo-keys'
            Click $keys 871
            $newKey = WaitShown 'InboxClassicNewKey'
            if ($newKey) {
                CheckPseudo $newKey 'New Key'
                Shot $newKey 'lang-6-pseudo-new-key'
                Click $newKey 2
                [void](WaitFor { -not [Native.Win]::IsWindow($newKey) } 5)
            }
            Click $keys 878
            [void](WaitFor { -not [Native.Win]::IsWindow($keys) } 5)
        }

        Command $main $IDM_NEW_ACCOUNT
        $form = WaitShown 'InboxClassicAccountStart' 10
        Check ($null -ne $form) 'Add Mail Account opens'
        if ($form) {
            CheckPseudo $form 'the account form'
            Shot $form 'lang-3-pseudo-form'
            Click $form 2
            # Exit while the form is still open is not taken: wait for it to be gone, not a guess of how long that takes
            [void](WaitFor { if (-not [Native.Win]::IsWindow($form)) { $true } } 10)
        }
        Quit $main 'pseudo-language'
    }

    # the languages of wave 2 on this English Windows, the case the window font is for: Japanese, Chinese and Korean
    # in the face Windows itself uses for them, Indonesian and Vietnamese in the default one; the main window, a new
    # message, Add Mail Account and Options in each, nothing cut off (tour-<code>-<n>-<view>)
    Step 'the languages of wave 2'
    $faces = [ordered]@{ 'ja' = 'Yu Gothic UI'; 'zh-Hans' = 'Microsoft YaHei UI'; 'zh-Hant' = 'Microsoft JhengHei UI'; 'ko' = 'Malgun Gothic'; 'id' = ''; 'vi' = '' }
    foreach ($code in $faces.Keys) {
        $main = StartAgain @('--language', $code)
        Check ($null -ne $main) "the app starts in $code"
        if (-not $main) { continue }
        $tree = [Native.Win]::GetDlgItem($main, $IDC_TREE)
        $face = ([System.Drawing.Font]::FromHfont([Native.Win]::SendMessage($tree, 0x0031, [IntPtr]::Zero, [IntPtr]::Zero))).Name
        if ($faces[$code]) {
            Check ($face -eq $faces[$code]) "${code}: the windows' words in $($faces[$code]) ($face)"
        } else {
            Check (@($faces.Values) -notcontains $face) "${code}: the windows' words in the default font ($face)"
        }
        # the sign-in prompt of a start without passwords (its words are in the language too) shot, then cancelled, so
        # the main window's shot shows the window
        $prompt = WaitShown 'InboxClassicForm' 5
        if ($prompt) {
            Shot $prompt "tour-$code-1b-sign-in"
            Click $prompt 2
            [void](WaitFor { -not [Native.Win]::IsWindow($prompt) } 5)
        }
        # the question to sign in again in the browser (this start's account that signs in so): a message box, its
        # buttons in the language too and not in Windows' own
        $words = Catalog $code
        $box = WaitFor { [Native.Win]::TopWindowsOf((AppIds), '#32770') | Where-Object { [Native.Win]::GetDlgItem($_, 6) -ne [IntPtr]::Zero } | Select-Object -First 1 } 5
        if ($box) {
            $yes = WindowText ([Native.Win]::GetDlgItem($box, 6))
            $no = WindowText ([Native.Win]::GetDlgItem($box, 7))
            Check ($yes -eq $words['ui-yes'] -and $no -eq $words['ui-no']) "${code}: a message box's buttons in the language ($yes, $no)"
            Click $box 7
            [void](WaitFor { -not [Native.Win]::IsWindow($box) } 5)
        }
        Shot $main "tour-$code-1-main"
        $compose = WaitCompose { Command $main $IDM_NEW_MAIL }
        if ($compose) {
            CheckPseudo $compose "${code}, the compose window" $false $true
            Shot $compose "tour-$code-2-compose"
            Check (CloseCompose $compose) "the new message closes ($code)"
        }
        Command $main $IDM_NEW_ACCOUNT
        $form = WaitShown 'InboxClassicAccountStart' 10
        if ($form) {
            Start-Sleep -Milliseconds 500
            CheckPseudo $form "${code}, Add Mail Account" $false $true
            Shot $form "tour-$code-3-account"
            Click $form 2
            [void](WaitFor { if (-not [Native.Win]::IsWindow($form)) { $true } } 10)
        }
        Command $main $IDM_OPTIONS
        $options = WaitShown 'InboxClassicOptions'
        if ($options) {
            $pages = @('4-options', '4b-options-reading', '4c-options-downloading')
            for ($page = 0; $page -lt $pages.Count; $page++) {
                if ($page) { OptionsPage $options $page }
                CheckPseudo $options "${code}, Options $($pages[$page])" $false $true
                Shot $options "tour-$code-$($pages[$page])"
            }
            Click $options 2
            [void](WaitFor { -not [Native.Win]::IsWindow($options) } 10)
        }
        Quit $main $code
    }
} catch {
    Harness "unexpected error: $_ at line $($_.InvocationInfo.ScriptLineNumber)"
} finally {
    # this run's app, and any earlier one of it that did not close (a dialog left open by a failed step)
    foreach ($process in @($app) + $started) {
        if ($process -and -not $process.HasExited) { $process.Kill() }
    }
    if ($null -eq $savedLanguage) {
        Remove-ItemProperty -Path $preferencesKey -Name Language -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name Language -Value $savedLanguage
    }
    if ($null -eq $savedGrouping) {
        Remove-ItemProperty -Path $preferencesKey -Name GroupByConversation -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name GroupByConversation -Value $savedGrouping -Type DWord
    }
    if ($null -eq $savedClosedRows) {
        Remove-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name ClosedFolderRows -Value $savedClosedRows
    }
    if ($null -eq $savedCodes) {
        Remove-ItemProperty -Path $preferencesKey -Name CodesInNotifications -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name CodesInNotifications -Value $savedCodes -Type DWord
    }
    if ($null -eq $savedHideRead) {
        Remove-ItemProperty -Path $preferencesKey -Name HideReadMessages -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name HideReadMessages -Value $savedHideRead -Type DWord
    }
    if ($null -eq $savedFolderList) {
        Remove-ItemProperty -Path $preferencesKey -Name FolderList -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $preferencesKey -Name FolderList -Value $savedFolderList -Type DWord
    }
    foreach ($name in $savedLayout.Keys) {
        if ($null -eq $savedLayout[$name]) {
            Remove-ItemProperty -Path $preferencesKey -Name $name -ErrorAction SilentlyContinue
        } else {
            Set-ItemProperty -Path $preferencesKey -Name $name -Value $savedLayout[$name] -Type DWord
        }
    }
    $harness.StandardInput.Close()
    if (-not $harness.WaitForExit(5000)) { $harness.Kill() }
}

TimingReport
$result = if ($failures.Count) { "FAILED: $($failures -join '; ')" } else { 'passed' }
Write-Host $result
Stop-Transcript | Out-Null
Set-Content -Path (Join-Path $Out 'result.txt') -Value $result
if ($failures.Count) { exit 1 }
