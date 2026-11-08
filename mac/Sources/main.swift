// HSC Essay Engine - macOS wrapper
// Version 1.1.0
// A native window around index.html. Progress is mirrored into UserDefaults
// so it survives restarts and updates. On launch (and from the menu) it checks
// GitHub for a newer index.html and installs it into Application Support.

import Cocoa
import WebKit

let appVersion = "1.1.0"
let storeKey = "hsc-essay-engine-v1"   // must match KEY in index.html
let updateURL = URL(string: "https://raw.githubusercontent.com/Brandonshev/hsc-essay-engine/main/web/index.html")!

// MARK: - Content versioning

func pageVersion(_ html: String) -> String? {
    guard let r = html.range(of: #"var VERSION = "([0-9.]+)""#, options: .regularExpression) else { return nil }
    let m = String(html[r])
    return m.components(separatedBy: "\"").dropFirst().first
}

func isNewer(_ a: String, than b: String) -> Bool {
    let x = a.split(separator: ".").map { Int($0) ?? 0 }
    let y = b.split(separator: ".").map { Int($0) ?? 0 }
    for i in 0..<max(x.count, y.count) {
        let p = i < x.count ? x[i] : 0, q = i < y.count ? y[i] : 0
        if p != q { return p > q }
    }
    return false
}

var supportDir: URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    let dir = base.appendingPathComponent("HSCEssayEngine", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}
var downloadedPage: URL { supportDir.appendingPathComponent("index.html") }

/// The newest page available locally: the downloaded update if it beats the bundled copy.
func currentPage() -> (url: URL, version: String)? {
    guard let bundled = Bundle.main.url(forResource: "index", withExtension: "html") else { return nil }
    let bv = (try? String(contentsOf: bundled, encoding: .utf8)).flatMap(pageVersion) ?? "0"
    if let dl = try? String(contentsOf: downloadedPage, encoding: .utf8), let dv = pageVersion(dl), isNewer(dv, than: bv) {
        return (downloadedPage, dv)
    }
    return (bundled, bv)
}

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

        loadCurrentPage()
        NSApp.activate(ignoringOtherApps: true)
        checkForUpdates(userInitiated: false)
    }

    func loadCurrentPage() {
        if let page = currentPage() {
            window.subtitle = "app v\(appVersion) · content v\(page.version)"
            webView.loadFileURL(page.url, allowingReadAccessTo: page.url.deletingLastPathComponent())
        } else {
            webView.loadHTMLString("<h2 style='font-family:sans-serif'>index.html is missing from the app bundle. Rebuild with build.sh.</h2>", baseURL: nil)
        }
    }

    // MARK: - Updates

    @objc func checkForUpdatesMenu(_ sender: Any?) { checkForUpdates(userInitiated: true) }

    func checkForUpdates(userInitiated: Bool) {
        var req = URLRequest(url: updateURL)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 15
        URLSession.shared.dataTask(with: req) { data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            let html = data.flatMap { String(data: $0, encoding: .utf8) }
            DispatchQueue.main.async {
                guard error == nil, status == 200, let html = html, let remote = pageVersion(html) else {
                    if userInitiated {
                        self.info("Couldn't check for updates",
                                  status == 404 ? "GitHub returned 404. The hsc-essay-engine repo needs to be public for updates to download." :
                                  "Check your internet connection and try again.")
                    }
                    return
                }
                let local = currentPage()?.version ?? "0"
                if isNewer(remote, than: local) {
                    do { try html.write(to: downloadedPage, atomically: true, encoding: .utf8) }
                    catch { if userInitiated { self.info("Update failed", error.localizedDescription) }; return }
                    let a = NSAlert()
                    a.messageText = "Update installed: v\(remote)"
                    a.informativeText = "You had v\(local). Your progress is kept."
                    a.addButton(withTitle: "Reload now")
                    a.addButton(withTitle: "Later")
                    if a.runModal() == .alertFirstButtonReturn { self.loadCurrentPage() }
                } else if userInitiated {
                    self.info("You're up to date", "Content v\(local) is the latest.")
                }
            }
        }.resume()
    }

    func info(_ title: String, _ text: String) {
        let a = NSAlert(); a.messageText = title; a.informativeText = text; a.runModal()
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
        let upd = appMenu.addItem(withTitle: "Check for Updates…", action: #selector(checkForUpdatesMenu(_:)), keyEquivalent: "u")
        upd.target = self
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
