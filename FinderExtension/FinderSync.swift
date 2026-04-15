import Cocoa
import FinderSync

class FinderSync: FIFinderSync {

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // 支持空白处右键和文件夹上右键
        guard menuKind == .contextualMenuForContainer || menuKind == .contextualMenuForItems else {
            return nil
        }

        let menu = NSMenu(title: "")
        let item = NSMenuItem(
            title: "打开 Claude Code",
            action: #selector(openClaudeCode(_:)),
            keyEquivalent: ""
        )
        item.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: nil)
        menu.addItem(item)
        return menu
    }

    @objc func openClaudeCode(_ sender: AnyObject?) {
        var targetPath: String

        // 优先使用选中的文件夹，否则使用当前目录
        if let selectedItems = FIFinderSyncController.default().selectedItemURLs(),
           let firstItem = selectedItems.first {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: firstItem.path, isDirectory: &isDir), isDir.boolValue {
                targetPath = firstItem.path
            } else {
                targetPath = firstItem.deletingLastPathComponent().path
            }
        } else if let target = FIFinderSyncController.default().targetedURL() {
            targetPath = target.path
        } else {
            return
        }

        // 使用 AppleScript 在 iTerm2 新建 tab 并执行 claude
        let script = """
        tell application "iTerm"
            activate
            tell current window
                create tab with default profile
                tell current session
                    write text "cd '\(targetPath.replacingOccurrences(of: "'", with: "'\\''"))' && /Users/mark/.local/bin/claude"
                end tell
            end tell
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                NSLog("AppleScript error: \(error)")
            }
        }
    }
}
