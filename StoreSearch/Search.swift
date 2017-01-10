//
//  Search.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 10/01/2017.
//  Copyright © 2017 Chaofan Zhang. All rights reserved.
//

import UIKit

typealias SearchComplete = (Bool) -> ()

class Search {
    
    let BASE_URL_ITUNES = "https://itunes.apple.com/search?term=%@&limit=200&entity=%@";
    
    enum Category: Int {
        case all = 0
        case music = 1
        case software = 2
        case ebooks = 3
        
        var entityName: String {
            switch self {
            case .all: return ""
            case .music: return "musicTrack"
            case .software: return "software"
            case .ebooks: return "ebook"
            }
        }
    }
    
    enum State {
        case notSearchedYet
        case loading
        case noResults
        case results([SearchResult])
    }
    
    // Search
    private(set) var state: State = .notSearchedYet
    var dataTask: URLSessionDataTask?

    
    func iTunesUrl(searchText: String, category: Category) -> URL {
        let escapedSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = String(format: BASE_URL_ITUNES, escapedSearchText, category.entityName)
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
    
    func doSearch(searchText: String, category: Category, completion: @escaping SearchComplete) {

        dataTask?.cancel()
        print("after cancel, dataTask=\(dataTask)")
        state = .loading
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        dataTask = URLSession.shared.dataTask(with: iTunesUrl(searchText: searchText, category: category), completionHandler: {
            data, response, error in
            
            var success = false
            if let error = error as? NSError, error.code == -999 {
                return // search was cancelled
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print(SearchViewController.TAG, "Success! \(response)")
                if let data = data, let jsonObject = self.parse(jsonData: data) {
                    
                    print(SearchViewController.TAG, "jsonObject= \(jsonObject)")
                    var searchResults = self.parse(dictionary: jsonObject)
                    searchResults.sort(by: <)
                    

                    if searchResults.isEmpty {
                        self.state = .noResults
                    } else {
                        self.state = .results(searchResults)
                    }
                    success = true
                }
            } else {
                print(SearchViewController.TAG, "Failure! \(response)")
            }
            
            if !success {
                self.state = .notSearchedYet
            }
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                completion(success)
            }
            
        })
        dataTask?.resume()
        
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
