//
//  SearchViewController.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 29/12/2016.
//  Copyright © 2016 Chaofan Zhang. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    let TAG = "SearchViewController: "
    
    let BASE_URL_ITUNES = "https://itunes.apple.com/search?term=%@";
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    let TAG_LOADING_CELL_ACTIVITY_INDICATOR = 100
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Search
    var searchResults: [SearchResult] = []
    var hasSearched = false
    var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
    
        let cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        let nothingFoundNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.register(nothingFoundNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        let loadingCellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.register(loadingCellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        searchBar.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension SearchViewController: UISearchBarDelegate {
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("search text: '\(searchBar.text!)'")
        
        if searchBar.text!.isEmpty {
            return
        }
        
        searchBar.resignFirstResponder()
        
        doSearch(searchText: searchBar.text!)
        
//        if searchBar.text!.lowercased() != "justin bieber" {
//            for i in 0...2 {
//                let searchResult = SearchResult()
//                searchResult.name = String(format: "Fake result %d", i)
//                searchResult.artistName = searchBar.text!
//                searchResults.append(searchResult)
//            }
//        }
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

            let data = searchResults[indexPath.row]
            cell.nameLabel.text = data.name
            let artistNameStr = data.artistName.isEmpty ? "Unknown" : String(format: "%@ (%@)", data.artistName, kindForDisplay(data.kind))
            cell.artistNameLabel.text = artistNameStr
            
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
    }
    
}

// web request
extension SearchViewController {
    
    func iTunesUrl(searchText: String) -> URL {
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = String(format: BASE_URL_ITUNES, escapedSearchText)
        let url = URL(string: urlString)
        
        print(TAG, "Search URL: \(url)")
        return url!
    }
    
    func performWebRequest(url: URL) -> String? {
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            print(TAG, "performWebRequest error: \(error)")
            return nil
        }
    }
    
    func parse(jsonStr: String) -> [String: Any]? {
        guard let jsonData = jsonStr.data(using: .utf8, allowLossyConversion: false) else {
            return nil
        }
        
        do {
            return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        } catch {
            print(TAG, "parse json error: \(error)")
            return nil
        }
    }
    
    func doSearch(searchText: String) {
        hasSearched = true
        searchResults = []
        isLoading = true
        tableView.reloadData()
        
        DispatchQueue.global().async {
            
            if let jsonResult = self.performWebRequest(url: self.iTunesUrl(searchText: searchText)),
                let jsonObject = self.parse(jsonStr: jsonResult) {
                print(self.TAG, "jsonObject= \(jsonObject)")
                self.searchResults = self.parse(dictionary: jsonObject)
                self.searchResults.sort(by: <)
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.tableView.reloadData()
                }
                return
            }
            
            DispatchQueue.main.async {
                self.showNetworkError()
            }
        }
    }
    
    func showNetworkError() {
        let alertController = UIAlertController(title: "Whoops...", message: "There was an error reading from iTuens Store. Please try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func parse(dictionary: [String: Any]) -> [SearchResult] {
        guard let resultsArray = dictionary["results"] as? [Any] else {
            print(TAG, "expected results array")
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
    
    
    func kindForDisplay(_ kind: String) -> String {
        switch kind {
            case "album": return "Album"
            case "audiobook": return "Audio Book"
            case "book": return "Book"
            case "ebook": return "E-Book"
            case "feature-movie": return "Movie"
            case "music-video": return "Music Video"
            case "podcast": return "Podcast"
            case "software": return "App"
            case "song": return "Song"
            case "tv-episode": return "TV Episode"
            default: return kind
        }
    }
}

