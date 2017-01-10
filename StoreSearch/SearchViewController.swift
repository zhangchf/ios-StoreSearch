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
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    let TAG_LOADING_CELL_ACTIVITY_INDICATOR = 100
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    
    // LandscapeViewController
    var landscapeViewController: LandscapeViewController?
    
    // Search function
    let search = Search()
    
    
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
    
    
    func performSearch() {
        print("search text: '\(searchBar.text!)'")
        guard !searchBar.text!.isEmpty, let category = Search.Category(rawValue: segmentedControl.selectedSegmentIndex) else {
            return
        }

        search.doSearch(searchText: searchBar.text!, category: category, completion: {
            success in
            if !success {
                self.showNetworkError()
            }
            self.tableView.reloadData()
            self.landscapeViewController?.searchResultsReceived()
        })
        
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }

    
    func showNetworkError() {
        let alertController = UIAlertController(title: "Whoops...", message: "There was an error reading from iTuens Store. Please try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SEGUE_ID_SHOW_DETAIL, let selectedIndexPath = sender as? IndexPath {
            if case .results(let list) = search.state {
                let detailViewController = segue.destination as! DetailViewController
                detailViewController.searchResult = list[selectedIndexPath.row]
            }
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
}

extension SearchViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch search.state {
        case .notSearchedYet:
            return 0
        case .loading:
            return 1
        case .noResults:
            return 1
        case .results(let list):
            return list.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch search.state {
        case .notSearchedYet:
            fatalError("Should never get here")
        case .loading:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            let activityIndicator = cell.viewWithTag(TAG_LOADING_CELL_ACTIVITY_INDICATOR) as! UIActivityIndicatorView
            activityIndicator.startAnimating()
            return cell
        case .noResults:
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
            return cell
        case .results(let list):
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell
            
            let searchResult = list[indexPath.row]
            cell.configure(searchResult: searchResult)
            
            return cell
        }
    }
        
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        switch search.state {
        case .notSearchedYet, .loading, .noResults:
            return nil
        case .results:
            return indexPath
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: Constants.SEGUE_ID_SHOW_DETAIL, sender: indexPath)
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
            // Init searchResults.
            controller.search = search
            
            controller.view.frame = view.bounds
            view.addSubview(controller.view)
            addChildViewController(controller)
            
            controller.view.alpha = 0
            coordinator.animate(alongsideTransition: {
                _ in
                self.searchBar.resignFirstResponder()
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
                controller.view.alpha = 1
            }, completion: {
                _ in
                controller.didMove(toParentViewController: self)
            })
        }
    }
    
    func hideLandscape(with coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeViewController {
            
            controller.willMove(toParentViewController: self)
            coordinator.animate(alongsideTransition: {
                _ in
                controller.view.alpha = 0
                print("self.presentedViewController: \(self.presentedViewController)")
                print("landscape.presentedViewController: \(controller.presentedViewController)")
                if self.presentedViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                }
            }, completion: {
                _ in
                controller.view.removeFromSuperview()
                controller.removeFromParentViewController()
                self.landscapeViewController = nil
            })
        }
    }
}

