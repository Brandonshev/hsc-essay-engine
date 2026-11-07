// HSC Essay Engine — macOS wrapper
// Version 1.0.1
// A native window around the bundled index.html. Progress is mirrored into
// UserDefaults so it survives app restarts and updates.

import Cocoa
import WebKit

let appVersion = "1.0.1"
let storeKey = "hsc-essay-engine-v1"   // must match KEY in index.html

func jsStringLiteral(_ s: String) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: [s]),
          let arr = String(data: data, encoding: .utf8) else { return "\"\"" }
    return String(arr.dropFirst().dropLast())   // strip [ ]
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()

        let saved = UserDefaults.standard.string(forKey: storeKey) ?? ""
        let restoreJS = """
        (function(){
          try { var s = \(jsStringLiteral(saved)); if (s) localStorage.setItem('\(storeKey)', s); } catch(e) {}
          try {
            var orig = Storage.prototype.setItem;
            Storage.prototype.setItem = function(k, v) {
              orig.call(this, k, v);
              if (k === '\(storeKey)') {
                try { window.webkit.messageHandlers.store.postMessage(String(v)); } catch(e) {}
              }
            };
          } catch(e) {}
        })();
        """

        let content = WKUserContentController()
        content.addUserScript(WKUserScript(source: restoreJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        content.add(self, name: "store")

        let config = WKWebViewConfiguration()
        config.userContentController = content
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.allowsMagnification = true

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "HSC Essay Engine"
        window.subtitle = "v\(appVersion)"
        window.minSize = NSSize(width: 420, height: 500)
        window.contentView = webView
        window.center()
        window.setFrameAutosaveName("HSCEssayEngineMain")
        window.makeKeyAndOrderFront(nil)

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.loadHTMLString("<h2 style='font-family:sans-serif'>index.html is missing from the app bundle. Rebuild with build.sh.</h2>", baseURL: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    // Page saved progress -> mirror into UserDefaults
    func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "store", let s = message.body as? String {
            UserDefaults.standard.set(s, forKey: storeKey)
        }
    }

    // Open web links (sources) in the default browser; keep in-page #links inside the app
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, let scheme = url.scheme?.lowercased(),
           (scheme == "http" || scheme == "https"), action.navigationType == .linkActivated {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    @objc func reloadPage(_ sender: Any?) { webView.reload() }
    @objc func zoomIn(_ sender: Any?) { webView.magnification = min(webView.magnification + 0.1, 2.0) }
    @objc func zoomOut(_ sender: Any?) { webView.magnification = max(webView.magnification - 0.1, 0.6) }
    @objc func zoomReset(_ sender: Any?) { webView.magnification = 1.0 }

    func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About HSC Essay Engine", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide HSC Essay Engine", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit HSC Essay Engine", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        // Edit menu is required for copy/paste/undo in the writing box
        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit

        let viewItem = NSMenuItem(); main.addItem(viewItem)
        let view = NSMenu(title: "View")
        for (title, sel, key) in [("Reload", #selector(reloadPage(_:)), "r"),
                                  ("Zoom In", #selector(zoomIn(_:)), "+"),
                                  ("Zoom Out", #selector(zoomOut(_:)), "-"),
                                  ("Actual Size", #selector(zoomReset(_:)), "0")] {
            let item = view.addItem(withTitle: title, action: sel, keyEquivalent: key)
            item.target = self
        }
        viewItem.submenu = view

        let winItem = NSMenuItem(); main.addItem(winItem)
        let win = NSMenu(title: "Window")
        win.addItem(withTitle: "Minimise", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        win.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        winItem.submenu = win
        NSApp.windowsMenu = win

        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
