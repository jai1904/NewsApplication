
import Foundation
import UIKit

class NewsItemController: UITableViewController, UISearchBarDelegate {
    let titles = ["Business", "Technology", "Entertainment", "General", "Health","Science", "Sports"]
    @IBOutlet weak var searchBar: UISearchBar!
    override func viewDidLoad() {
        print("The view did load")
        super.viewDidLoad()
        searchBar.delegate = self
        searchBar.placeholder = "Search For News e.g.,Tom Hanks"
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "NewsItems", sender: "category="+titles[indexPath.row])
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.titles.count
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Top Headlines"
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "NewsItemCell", for: indexPath) as? NewsItemCell else {
            fatalError("Article cell not found")
        }
        let newsTitle = titles[indexPath.row]
        cell.newsItem.text = newsTitle
        return cell
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
extension NewsItemController {
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
