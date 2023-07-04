
import Foundation
import SafariServices

class NewsWebViewController: UIViewController, SFSafariViewControllerDelegate {
    var newsWebURL: URL!

    override func viewDidLoad() {
        super.viewDidLoad()
        let vc = SFSafariViewController(url: newsWebURL)
        vc.delegate = self
        present(vc, animated: true)
    }
}
