import UIKit
import WebKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = WasfatyViewController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

final class WasfatyViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    private let homeURL = URL(string: "https://cp.wasfaty.sa/")!
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private let toolbar = UIToolbar()
    private var progressObservation: NSKeyValueObservation?

    private lazy var webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = self
        view.uiDelegate = self
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.keyboardDismissMode = .interactive
        view.isOpaque = true
        view.backgroundColor = .systemBackground
        return view
    }()

    private lazy var backButton = UIBarButtonItem(
        image: UIImage(systemName: "chevron.backward"),
        style: .plain,
        target: self,
        action: #selector(goBack)
    )

    private lazy var homeButton = UIBarButtonItem(
        image: UIImage(systemName: "house.fill"),
        style: .plain,
        target: self,
        action: #selector(goHome)
    )

    private lazy var reloadButton = UIBarButtonItem(
        barButtonSystemItem: .refresh,
        target: self,
        action: #selector(reloadPage)
    )

    private lazy var safariButton = UIBarButtonItem(
        image: UIImage(systemName: "safari"),
        style: .plain,
        target: self,
        action: #selector(openInSafari)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureLayout()
        configureToolbar()
        observeProgress()
        loadHome()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .default
    }

    private func configureLayout() {
        progressView.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(progressView)
        view.addSubview(webView)
        view.addSubview(toolbar)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureToolbar() {
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [backButton, spacer, homeButton, spacer, reloadButton, spacer, safariButton]
        updateToolbarState()
    }

    private func observeProgress() {
        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.progressView.progress = Float(webView.estimatedProgress)
                self.progressView.isHidden = webView.estimatedProgress >= 1.0
            }
        }
    }

    private func loadHome() {
        var request = URLRequest(url: homeURL)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 60
        webView.load(request)
    }

    private func updateToolbarState() {
        backButton.isEnabled = webView.canGoBack
    }

    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            loadHome()
        }
    }

    @objc private func goHome() {
        loadHome()
    }

    @objc private func reloadPage() {
        if webView.url != nil {
            webView.reload()
        } else {
            loadHome()
        }
    }

    @objc private func openInSafari() {
        let url = webView.url ?? homeURL
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // Keep normal web/SSO redirects inside the app. Non-web schemes are handed to iOS.
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "http" || scheme == "https" || scheme == "about" || scheme == "data" || scheme == "blob" {
            decisionHandler(.allow)
        } else {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
        }
    }

    // Pages that request a new window (target=_blank / window.open) stay usable in the same WebView.
    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateToolbarState()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateToolbarState()
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        updateToolbarState()
        presentFailureIfNeeded(error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        updateToolbarState()
        presentFailureIfNeeded(error)
    }

    private func presentFailureIfNeeded(_ error: Error) {
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
            return
        }
        guard presentedViewController == nil else { return }

        let alert = UIAlertController(
            title: "تعذر فتح وصفتي",
            message: "تحقق من اتصال الإنترنت. إذا كانت البوابة تمنع العرض داخل التطبيق، افتحها في Safari.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "إعادة المحاولة", style: .default) { [weak self] _ in
            self?.reloadPage()
        })
        alert.addAction(UIAlertAction(title: "فتح في Safari", style: .default) { [weak self] _ in
            self?.openInSafari()
        })
        alert.addAction(UIAlertAction(title: "إلغاء", style: .cancel))
        present(alert, animated: true)
    }
}
