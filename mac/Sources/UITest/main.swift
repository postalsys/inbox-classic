// The UI end-to-end test of the Mac app: runs the app in this process and drives its windows (UITest.swift)
import InboxClassicKit

MainActor.assumeIsolated {
    runUITest()
}
