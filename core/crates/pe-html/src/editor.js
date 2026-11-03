// The editor of the compose window. The only script Inbox Classic runs: the page allows it by a nonce, nothing else
// can run (the CSP has no other script source; the quoted message was sanitized in Rust and waits in an inert
// template until it is put into the text). The host calls window.pe; the page answers with plain strings over
// postMessage, which the host never parses beyond their prefix:
//   "html:<the body>"   the HTML of what was written, after pe.send(); the quote still folded, for the core to add
//   "split:<written>\u001f<quote>"  the quote unfolded into the text: what was written, then the quote as the user
//                       left it (trimmed, written in), each on its own; the core adds that quote
//   "full:<the body>"   the quote unfolded and then deleted: the body is all there is
//   "state:<flags>"     one 0 or 1 per command of STATE, for the format bar
//   "dirty"             the first change (since pe.clean(), after a save), so closing can ask before throwing it away
//   "drop"              files dropped on the page, as File objects beside the message: the host reads them (through
//                       the core, as Insert Picture does) and inserts the pictures where the cursor now is
(() => {
    'use strict';
    // the order of the flags of "state:", which kStateButtons in app/src/compose.cpp follows
    const STATE = ['bold', 'italic', 'underline', 'insertOrderedList', 'insertUnorderedList', 'justifyLeft', 'justifyCenter', 'justifyRight'];
    const body = document.getElementById('body');
    // a message to the host, with the File objects of `files` beside it when given
    const post = (message, files) => {
        const webview = window.chrome && window.chrome.webview;
        if (webview && files) {
            webview.postMessageWithAdditionalObjects(message, files);
        } else if (webview) {
            webview.postMessage(message);
        }
    };
    // the cursor at `range`, or at the end of the text without one
    const placeCursor = range => {
        if (!range) {
            range = document.createRange();
            range.selectNodeContents(body);
            range.collapse(false);
        }
        const selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
    };

    // <b>, <i>, <font> rather than spans with styles: what other mail programs show the same way
    document.execCommand('styleWithCSS', false, false);
    document.execCommand('defaultParagraphSeparator', false, 'div');

    let last = '';
    const report = () => {
        const flags = STATE.map(command => (document.queryCommandState(command) ? '1' : '0')).join('');
        if (flags !== last) {
            last = flags;
            post('state:' + flags);
        }
    };
    document.addEventListener('selectionchange', report);

    let dirty = false;
    body.addEventListener('input', () => {
        if (!dirty) {
            dirty = true;
            post('dirty');
        }
    });

    // the quoted message: folded behind "..." in a reply, in the text from the start in a forward. Unfolded it is
    // part of the text, to read, trim, select and copy like the rest; it does not fold again.
    const quote = document.getElementById('quote');
    const fold = document.getElementById('fold');
    const more = document.getElementById('more');
    let unfolded = false;
    const unfold = () => {
        if (!quote || unfolded) {
            return;
        }
        unfolded = true;
        const block = document.createElement('div');
        block.className = 'quoted';
        block.appendChild(document.importNode(quote.content, true));
        body.appendChild(document.createElement('div')).appendChild(document.createElement('br'));
        body.appendChild(block);
        fold.hidden = true;
    };
    if (quote) {
        more.addEventListener('click', () => {
            unfold();
            body.focus();
        });
        if (quote.dataset.folded !== '1') {
            unfold();
        }
    }
    // Select All takes the quote too: unfolded first, then everything selected
    document.addEventListener('keydown', event => {
        if ((event.ctrlKey || event.metaKey) && !event.altKey && event.key.toLowerCase() === 'a') {
            event.preventDefault();
            unfold();
            body.focus();
            const range = document.createRange();
            range.selectNodeContents(body);
            const selection = window.getSelection();
            selection.removeAllRanges();
            selection.addRange(range);
        }
    });

    window.pe = {
        // a formatting command of the format bar: bold, fontName, foreColor, insertImage, ...
        exec(command, value) {
            body.focus();
            document.execCommand(command, false, value === undefined ? null : value);
            report();
        },
        // a link around the selection, or the address itself as the link when nothing is selected
        link(url) {
            body.focus();
            const selection = window.getSelection();
            if (selection && !selection.isCollapsed) {
                document.execCommand('createLink', false, url);
            } else {
                const a = document.createElement('a');
                a.href = url;
                a.textContent = url;
                document.execCommand('insertHTML', false, a.outerHTML);
            }
        },
        send() {
            if (!unfolded) {
                post('html:' + body.innerHTML);
                return;
            }
            const block = body.querySelector(':scope > div.quoted');
            if (!block) {
                post('full:' + body.innerHTML);
                return;
            }
            // what was written apart from the quote, which the core then judges and sends on its own
            const written = body.cloneNode(true);
            written.querySelector(':scope > div.quoted').remove();
            post('split:' + written.innerHTML + '\u001f' + block.innerHTML);
        },
        // saved: the next change is a change again
        clean() {
            dirty = false;
        },
        focus() {
            body.focus();
        }
    };

    // files dragged in from Explorer: the cursor goes where they were dropped and the files go to the host. The page
    // reads no file; without this the browser would try to open the file and nothing would happen
    const carriesFiles = event => event.dataTransfer && Array.from(event.dataTransfer.types).includes('Files');
    for (const type of ['dragenter', 'dragover']) {
        document.addEventListener(type, event => {
            if (carriesFiles(event)) {
                event.preventDefault();
                event.dataTransfer.dropEffect = 'copy';
            }
        });
    }
    document.addEventListener('drop', event => {
        if (!carriesFiles(event)) {
            return;
        }
        event.preventDefault();
        body.focus();
        const range = document.caretRangeFromPoint(event.clientX, event.clientY);
        placeCursor(range && body.contains(range.startContainer) ? range : null);
        post('drop', event.dataTransfer.files);
    });

    // a click in the empty space below the text puts the cursor at its end, as in a text box
    document.addEventListener('mousedown', event => {
        if (event.target === document.documentElement || event.target === document.body) {
            event.preventDefault();
            body.focus();
            placeCursor(null);
        }
    });
    // the page is at least the window's height, so that space is the page's
    document.body.style.minHeight = '100vh';

    // the cursor where the user writes
    body.focus();
    report();
})();
