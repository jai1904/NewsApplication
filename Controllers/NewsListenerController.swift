
import Foundation
import UIKit
import SafariServices

class NewsListenerController: UITableViewController, SFSafariViewControllerDelegate {
    
    
    let datePicker = DatePickerDialog()
    private var articleListViewModel: ArticleListViewModel!
    public var newsURL: String = String()
    public var newsDt: String = String()
    public var category: String = String()
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    private var page = 0
    private var endAlertShown = false
    override func viewDidLoad() {
        self.page = 1
        super.viewDidLoad()
        setupView()
        setupActivityIndicator()
        tableView.rowHeight = UITableView.automaticDimension
        
        let heading = newsURL.split(separator: "=")
        if heading.count > 1 {
            self.title = String(heading[1])
        }
        
    }
    
    
    @IBAction func onDateClick(_ sender: Any) {
        
        datePickerTapped()
    }
    
    func datePickerTapped() {
        let currentDate = Date()
        var dateComponents = DateComponents()
        dateComponents.month = -3
        let threeMonthAgo = Calendar.current.date(byAdding: dateComponents, to: currentDate)

        datePicker.show("DatePickerDialog",
                        doneButtonTitle: "Done",
                        cancelButtonTitle: "Cancel",
                        minimumDate: threeMonthAgo,
                        maximumDate: currentDate,
                        datePickerMode: .date) { (date) in
            if let dt = date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd"
                self.newsDt = "&from=\(formatter.string(from: dt))"
                self.page = 0
                self.setupView()
            }
        }
    }
    
    
    private func setupView() {
        var dataFetched = false
        print("Setting up view")
        self.navigationController?.navigationBar.prefersLargeTitles = true
        activityIndicator.startAnimating()
        print("Fetching Webservice articles")
        WebService().getArticles(for: newsURL+newsDt, with: page) { articles, totalResults in
//        WebService().getArticles(for: newsURL, with: page) { articles, totalResults in
            if let articles = articles {
                dataFetched = true
                self.page = self.page + 1
                self.articleListViewModel = ArticleListViewModel(articles, totalArticles: totalResults)
            } else {
                print("No data")
            }
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                if dataFetched {
                    self.tableView.reloadData()
                } else {
                    self.showAlert(with: "Couldn't Fetch Articles", message: "Please try again", action: "Ok")
                }
            }
        }
    }
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.articleListViewModel == nil ? 0: self.articleListViewModel.noOfSections
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articleListViewModel.numberOfRowsInSection(section)
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleTableCell", for: indexPath) as? ArticleTableCell else {
            fatalError("Article cell not found")
        }
        let articleAtCell = self.articleListViewModel.articleAtIndex(indexPath.row)
        cell.titleLabel.text = articleAtCell.title
        cell.descriptionLabel.text = articleAtCell.description
        
        
        if articleAtCell.urlToImage != nil {
            let url = URL(string: (articleAtCell.urlToImage!))

            DispatchQueue.global().async {
                let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    guard let data = data else {
//                        cell.newImage.image = UIImage(data: nil)
                        return
                    }
//                    cell.newImage.image = UIImage(data: data!)
                    cell.newImage.image = UIImage(data: data)
                }
            }
        }
        
        return cell
    }
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let endScrolling = scrollView.contentOffset.y + scrollView.frame.size.height;
        if (endScrolling >= scrollView.contentSize.height && (page-1)*20 < self.articleListViewModel.totalNoOfArticles())
        {
            print("Requesting for new articles")
            fetchAdditionalNewsArticles()
        }
        if (page-1)*20 > self.articleListViewModel.totalNoOfArticles() && !endAlertShown {
            self.showAlert(with: "You are upto date", message: "", action: "Ok")
            endAlertShown = true
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let articleAtCell = self.articleListViewModel.articleAtIndex(indexPath.row)
        let urlString = articleAtCell.articleURL
        if let url = URL(string: urlString) {
            let sfConfiguration = SFSafariViewController.Configuration()
            sfConfiguration.entersReaderIfAvailable = true
            let articleWebView = SFSafariViewController(url: url, configuration: sfConfiguration)
            articleWebView.delegate = self
            present(articleWebView, animated: true)
        } else {
            print("Error in forming URL")
        }
    }
    func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        let verticalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
        activityIndicator.hidesWhenStopped = true
    }
}
// MARK: -
extension NewsListenerController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("segue object: \(String(describing: segue))")
        print("sender: \(String(describing: sender))")
        if let destinationVC = segue.destination as? NewsWebViewController {
            if let item = sender as? URL  {
                destinationVC.newsWebURL = item
            }
        }
    }
}
// MARK: - Dynamically append news items
extension NewsListenerController {
    func fetchAdditionalNewsArticles() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
        print("Fetching addtional news articles: \(self.page)")
        WebService().getArticles(for: self.newsURL, with: self.page) { articles, totalResults in
            if let newArticles = articles {
                self.page = self.page + 1
                let intialCount = self.articleListViewModel.numberOfRowsInSection(0)
                self.articleListViewModel.add(newArticles: newArticles)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    let finalCount = self.articleListViewModel.numberOfRowsInSection(0)
                    let indexPaths = (intialCount ..< finalCount).map {
                        IndexPath(row: $0, section: 0)
                    }
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: indexPaths, with: .automatic)
                    self.tableView.endUpdates()
                }
            } else {
                print("No data for page: \(self.page)")
            }
        }
    }
}
// MARK: - Custom Alerts
extension NewsListenerController {
    func showAlert(with title: String, message: String, action: String) {
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: action, style: .default) {
            (UIAlertAction) -> Void in
        }
        alert.addAction(alertAction)
        self.present(alert, animated: true)
        {
            () -> Void in
        }
    }
}
