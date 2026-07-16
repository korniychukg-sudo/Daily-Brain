import SwiftUI

@main
struct DailyBrainApp: App {
    @State private var brainGateReady: Bool? = nil
    private let brainSourceLink = "https://example.com"
    private let brainCheckDomain = "example"

    @StateObject private var store = BrainStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = brainGateReady {
                    if ready {
                        BrainWebPanel(urlString: brainSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                            .environmentObject(store)
                            .preferredColorScheme(.light)
                    }
                } else {
                    BrainLaunchScreen()
                        .onAppear { checkBrainLink() }
                }
            }
        }
    }

    private func checkBrainLink() {
        guard let url = URL(string: brainSourceLink) else {
            brainGateReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let watcher = BrainRedirectWatcher(checkDomain: brainCheckDomain)
        let session = URLSession(configuration: .default, delegate: watcher, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if watcher.foundCheckDomain {
                    brainGateReady = false; return
                }
                if let finalURL = watcher.resolvedURL?.absoluteString,
                   finalURL.contains(self.brainCheckDomain) {
                    brainGateReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.brainCheckDomain) {
                    brainGateReady = false; return
                }
                if error != nil {
                    brainGateReady = false; return
                }
                brainGateReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if brainGateReady == nil { brainGateReady = false }
        }
    }
}

final class BrainRedirectWatcher: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) { self.checkDomain = checkDomain }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
