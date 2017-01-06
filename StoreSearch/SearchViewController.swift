//
//  SearchViewController.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 29/12/2016.
//  Copyright © 2016 Chaofan Zhang. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    static let TAG = "SearchViewController: "
    
    let BASE_URL_ITUNES = "https://itunes.apple.com/search?term=%@&limit=200&entity=%@";
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    let TAG_LOADING_CELL_ACTIVITY_INDICATOR = 100
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    // Search
    var searchResults: [SearchResult] = []
    var hasSearched = false
    var isLoading = false
    var dataTask: URLSessionDataTask?
    
    // LandscapeViewController
    var landscapeViewController: LandscapeViewController?
    
    deinit {
        print("deinit \(self)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
    
        let cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        let nothingFoundNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(nothingFoundNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        let loadingCellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(loadingCellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        searchBar.becomeFirstResponder()
        
        registerNotification()
        
        // For test purpose
        searchBar.text = "Stephen King"
        performSearch()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        performSearch()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SEGUE_ID_SHOW_DETAIL, let selectedIndexPath = sender as? IndexPath {
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.searchResult = searchResults[selectedIndexPath.row]
        }
    }
    
    func refresh() {
        tableView.reloadData()
    }
    
    
    func registerNotification() {
        NotificationCenter.default.addObserver(forName: Notification.Name.UIContentSizeCategoryDidChange, object: nil, queue: OperationQueue.main, using: {_ in
            print("UIContentSizeCategoryDidChange Notification")
            self.refresh()
        })
    }
}

extension SearchViewController: UISearchBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch()
    }

    func performSearch() {
        print("search text: '\(searchBar.text!)'")
        if searchBar.text!.isEmpty {
            return
        }
        searchBar.resignFirstResponder()
        
        let entityName: String
        switch segmentedControl.selectedSegmentIndex {
        case 1:
            entityName = "musicTrack"
        case 2:
            entityName = "software"
        case 3:
            entityName = "ebook"
        default:
            entityName = ""
        }

        
        doSearch(searchText: searchBar.text!, entity: entityName)
    }
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            let activityIndicator = cell.viewWithTag(TAG_LOADING_CELL_ACTIVITY_INDICATOR) as! UIActivityIndicatorView
            activityIndicator.startAnimating()
            return cell
        } else if searchResults.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell

            let searchResult = searchResults[indexPath.row]
            cell.configure(searchResult: searchResult)
            
            return cell
        }
    }
        
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: Constants.SEGUE_ID_SHOW_DETAIL, sender: indexPath)
    }
    
}

// web request
extension SearchViewController {
    
    func iTunesUrl(searchText: String, entity: String) -> URL {
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = String(format: BASE_URL_ITUNES, escapedSearchText, entity)
        let url = URL(string: urlString)
        
        print(SearchViewController.TAG, "Search URL: \(url)")
        return url!
    }
    
    func parse(jsonData: Data) -> [String: Any]? {
        do {
            return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        } catch {
            print(SearchViewController.TAG, "parse json error: \(error)")
            return nil
        }
    }
    
    func doSearch(searchText: String, entity: String) {
        hasSearched = true
        searchResults = []
        
        dataTask?.cancel()
        print("after cancel, dataTask=\(dataTask)")
        isLoading = true
        tableView.reloadData()
        
        dataTask = URLSession.shared.dataTask(with: iTunesUrl(searchText: searchText, entity: entity), completionHandler: {
            data, response, error in
            
            if let error = error as? NSError, error.code == -999 {
                return // search was cancelled
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print(SearchViewController.TAG, "Success! \(response)")
                if let data = data, let jsonObject = self.parse(jsonData: data) {
                    
                    print(SearchViewController.TAG, "jsonObject= \(jsonObject)")
                    self.searchResults = self.parse(dictionary: jsonObject)
                    self.searchResults.sort(by: <)
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.tableView.reloadData()
                    }
                    return
                }
            } else {
                print(SearchViewController.TAG, "Failure! \(response)")
            }
            
            DispatchQueue.main.async {
                self.hasSearched = false
                self.isLoading = false
                self.tableView.reloadData()
                self.showNetworkError()
            }
        })
        dataTask?.resume()
        
    }
    
    func showNetworkError() {
        let alertController = UIAlertController(title: "Whoops...", message: "There was an error reading from iTuens Store. Please try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func parse(dictionary: [String: Any]) -> [SearchResult] {
        guard let resultsArray = dictionary["results"] as? [Any] else {
            print(SearchViewController.TAG, "expected results array")
            return []
        }
        
        var searchResults = [SearchResult]()
        
        for resultDict in resultsArray {
            if let resultDict = resultDict as? [String: Any] {
                var searchResult: SearchResult?
                if let wrapperType = resultDict["wrapperType"] as? String {
                    switch wrapperType {
                    case "track":
                        searchResult = parse(track: resultDict)
                    case "audiobook":
                        searchResult = parse(audiobook: resultDict)
                        case "software":
                        searchResult = parse(software: resultDict)
                    default:
                        break
                    }
                } else if let kind = resultDict["kind"] as? String, kind == "ebook" {
                    searchResult = parse(ebook: resultDict)
                }
                if let searchResult = searchResult {
                    searchResults.append(searchResult)
                }
            }
        }
        
        return searchResults
    }
    
    func parse(track dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
        searchResult.storeUrl = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parse(audiobook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
        searchResult.storeUrl = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["collectionPrice"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parse(software dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
        searchResult.storeUrl = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        if let genre = dictionary["primaryGenreName"] as? String {
            searchResult.genre = genre
        }
        return searchResult
    }
    
    func parse(ebook dictionary: [String: Any]) -> SearchResult {
        let searchResult = SearchResult()
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkSmallUrl = dictionary["artworkUrl60"] as! String
        searchResult.artworkLargeUrl = dictionary["artworkUrl100"] as! String
        searchResult.storeUrl = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        if let price = dictionary["price"] as? Double {
            searchResult.price = price
        }
        if let genres: Any = dictionary["genres"] {
            searchResult.genre = (genres as! [String]).joined(separator: ", ")
        }
        return searchResult
    }
}

// MARK: - LandscapeViewController
extension SearchViewController {
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        switch newCollection.verticalSizeClass {
        case .compact:
            print("rotate to landscape")
            showLandscape(with:coordinator)
        case .regular, .unspecified:
            print("rotate to portrait")
            hideLandscape(with: coordinator)
        }
    }
    
    func showLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        guard landscapeViewController == nil else {
            return
        }
        landscapeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.STORYBOARD_ID_LANDSCAPE_VIEW_CONTROLLER) as? LandscapeViewController
        if let controller = landscapeViewController {
            controller.view.frame = view.bounds
            view.addSubview(controller.view)
            addChildViewController(controller)
            controller.didMove(toParentViewController: self)
        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeViewController {
            controller.willMove(toParentViewController: self)
            controller.view.removeFromSuperview()
            controller.removeFromParentViewController()
            landscapeViewController = nil
        }
    }
}

