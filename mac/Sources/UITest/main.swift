// The UI end-to-end test of the Mac app: runs the app in this process and drives its windows (UITest.swift). Started
// with --mcp by the test's agent, it is the relay, as the app's own executable is for a real agent: the app knows its
// relay by its executable, so the agent's relay is this one
import InboxClassicKit

MainActor.assumeIsolated {
    if CommandLine.arguments.contains("--mcp") {
        runApp()
    } else {
        runUITest()
    }
}
