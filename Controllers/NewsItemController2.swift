
import Foundation
import UIKit
import SafariServices
import SKCountryPicker

class NewsItemController2: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, SFSafariViewControllerDelegate {
    
    
    let datePicker = DatePickerDialog()
    

    let titles = ["Business", "Technology", "Entertainment", "General", "Health", "Science", "Sports"]
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tbl_newsFeed: UITableView!
    @IBOutlet weak var collection_category: UICollectionView!
    
    
    // news list
    private var articleListViewModel: ArticleListViewModel!
    public var newsURL: String = String()
    public var newsDt: String = String()
    private var activityIndicator = UIActivityIndicatorView(style: .medium)
    private var page = 0
    private var endAlertShown = false
    
    

    override func viewDidLoad() {
        self.page = 1
        super.viewDidLoad()
        print("The view did load")
        super.viewDidLoad()
        self.tbl_newsFeed.delegate = self
        self.tbl_newsFeed.dataSource = self
        
        self.collection_category.delegate = self
        self.collection_category.dataSource = self
        
        searchBar.delegate = self
        searchBar.placeholder = "Search For News e.g.,science"
        
        /*
         DispatchQueue.main.async {
             self.tbl_newsFeed.reloadData()
         }
         */
        
        // news list
        newsURL = "Today"
        newsDt = "&from=\(getCurrentShortDate())"
        setupView()
        setupActivityIndicator()
        tbl_newsFeed.rowHeight = UITableView.automaticDimension
        
        self.title = "News India"
        
    }
    
     func getCurrentShortDate() -> String {
         let todaysDate = Date()
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = "yyyy-MM-dd"
         let DateInFormat = dateFormatter.string(from: todaysDate)
        return DateInFormat
    }
    
    @IBAction func onCountryClick(_ sender: Any) {
        
        presentCountryPickerScene(withSelectionControlEnabled: true)

    }
    
    
    
    
    
    @IBAction func onDateItemClick(_ sender: Any) {
        
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
                formatter.dateFormat = "yyyy-MM-dd"
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
                    self.tbl_newsFeed.reloadData()
                } else {
                    self.showAlert(with: "Couldn't Fetch Articles", message: "Please try again", action: "Ok")
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCategoryCell", for: indexPath) as? NewsCategoryCell else {
            fatalError("Article cell not found")
        }
        let newsTitle = titles[indexPath.row]
        cell.iv_category.layer.cornerRadius = 15
        
        //   let titles = ["Business", "Technology", "Entertainment", "General", "Health","Science", "Sports"]
        
        if newsTitle == "Business" {
            cell.iv_category.image = UIImage(named: "buisiness")
        }else if newsTitle == "Technology" {
            cell.iv_category.image = UIImage(named: "technology")
        }else if newsTitle == "Entertainment" {
            cell.iv_category.image = UIImage(named: "entertainment")
        }else if newsTitle == "General" {
            cell.iv_category.image = UIImage(named: "general")
        }else if newsTitle == "Health" {
            cell.iv_category.image = UIImage(named: "heath")
        }else if newsTitle == "Science" {
            cell.iv_category.image = UIImage(named: "science")
        }else if newsTitle == "Sports" {
            cell.iv_category.image = UIImage(named: "sport")
        }
        
    
        
       // cell.imageContainerView.backgroundColor = UIColor(hexString: category.colorString, alpha: 0.25)
        //cell.imageContainerView.backgroundColor = UIColor(hexString: "#ffffff")
        cell.lbl_category.text = newsTitle
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "NewsItems", sender: "category="+titles[indexPath.row])
    }
    
    
     func numberOfSections(in tableView: UITableView) -> Int {
        return self.articleListViewModel == nil ? 0: self.articleListViewModel.noOfSections
    }
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.articleListViewModel.numberOfRowsInSection(section)
    }
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
                     cell.newImage.image = UIImage(data: data!)
                 }
             }
         }
        
        return cell
    }
     func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
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
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Top Headlines"
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
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            if titles.contains(searchText) {
                performSegue(withIdentifier: "NewsItems", sender: "category="+searchText)
            } else {
                performSegue(withIdentifier: "NewsItems", sender: "q="+searchText)
            }
        } else {
            print("Search text is null")
        }
    }
}
// MARK: - Segue methods
extension NewsItemController2 {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("segue object: \(String(describing: segue))")
        print("sender: \(String(describing: sender))")
        if let destinationVC = segue.destination as? NewsListenerController {
            if let item = sender as? String  {
                destinationVC.newsURL = item
            }
        }
    }
}



// MARK: - Dynamically append news items
extension NewsItemController2 {
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
                    self.tbl_newsFeed.beginUpdates()
                    self.tbl_newsFeed.insertRows(at: indexPaths, with: .automatic)
                    self.tbl_newsFeed.endUpdates()
                }
            } else {
                print("No data for page: \(self.page)")
            }
        }
    }
}

// MARK: - Custom Alerts
extension NewsItemController2 {
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


/// MARK: - Private Methods
private extension NewsItemController2 {
    
    /// Dynamically presents country picker scene with an option of including `Selection Control`.
    ///
    /// By default, invoking this function without defining `selectionControlEnabled` parameter. Its set to `True`
    /// unless otherwise and the `Selection Control` will be included into the list view.
    ///
    /// - Parameter selectionControlEnabled: Section Control State. By default its set to `True` unless otherwise.
    
    func presentCountryPickerScene(withSelectionControlEnabled selectionControlEnabled: Bool = true) {
        switch selectionControlEnabled {
        case true:
            // Present country picker with `Section Control` enabled
            CountryPickerWithSectionViewController.presentController(on: self, configuration: { countryController in
                countryController.configuration.flagStyle = .circular
                countryController.configuration.isCountryFlagHidden = false
                countryController.configuration.isCountryDialHidden = true
                countryController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]

            }) { [weak self] country in
                
                guard let self = self else { return }
               // self.countryImageView.isHidden = false
               // self.countryImageView.image = country.flag
                UserDefaults.standard.set("code", forKey: country.countryCode)
                self.title = "News \(country.countryName)"
                self.page = 0
                self.setupView()
                //self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
            }
            
        case false:
            // Present country picker without `Section Control` enabled
            CountryPickerController.presentController(on: self, configuration: { countryController in
                countryController.configuration.flagStyle = .corner
                countryController.configuration.isCountryFlagHidden = false
                countryController.configuration.isCountryDialHidden = true
                countryController.favoriteCountriesLocaleIdentifiers = ["IN", "US"]

            }) { [weak self] country in
                
                guard let self = self else { return }
                UserDefaults.standard.set("code", forKey: country.countryCode)
                self.title = "News \(country.countryName)"
                self.page = 0
                self.setupView()
               // self.countryImageView.isHidden = false
               // self.countryImageView.image = country.flag
               // self.countryCodeButton.setTitle(country.dialingCode, for: .normal)
            }
        }
    }
}
