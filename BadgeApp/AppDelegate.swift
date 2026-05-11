import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var badgeSize: CGFloat = 16
    var selectedBadge: NSImage?

    func applicationDidFinishLaunching(_ notification: Notification) {
        selectedBadge = NSImage(named: NSImage.folderName)

        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 900, height: 650)
        let windowSize = CGSize(width: 900, height: 650)
        let windowFrame = NSMakeRect(
            (screenSize.width - windowSize.width) / 2,
            (screenSize.height - windowSize.height) / 2,
            windowSize.width,
            windowSize.height
        )

        window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Badge App"
        window.isReleasedWhenClosed = false

        let viewController = ViewController()
        viewController.appDelegate = self
        window.contentViewController = viewController
        window.makeKeyAndOrderFront(nil)
        window.center()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
