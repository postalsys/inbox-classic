// The Mac app's entry point: everything else is InboxClassicKit, which the UI end-to-end test runs too
import InboxClassicKit

MainActor.assumeIsolated {
    runApp()
}
