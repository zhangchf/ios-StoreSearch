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
        
        
        search.doSearch(searchText: searchBar.text!, entity: entityName, completion: {
            success in
            if !success {
                self.showNetworkError()
            }
            self.tableView.reloadData()
        })
        
        tableView.reloadData()
    }

    
    func showNetworkError() {
        let alertController = UIAlertController(title: "Whoops...", message: "There was an error reading from iTuens Store. Please try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.SEGUE_ID_SHOW_DETAIL, let selectedIndexPath = sender as? IndexPath {
            let detailViewController = segue.destination as! DetailViewController
            detailViewController.searchResult = search.searchResults[selectedIndexPath.row]
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
        if search.isLoading {
            return 1
        } else if !search.hasSearched {
            return 0
        } else if search.searchResults.count == 0 {
            return 1
        } else {
            return search.searchResults.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if search.isLoading {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.loadingCell, for: indexPath)
            let activityIndicator = cell.viewWithTag(TAG_LOADING_CELL_ACTIVITY_INDICATOR) as! UIActivityIndicatorView
            activityIndicator.startAnimating()
            return cell
        } else if search.searchResults.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.nothingFoundCell, for: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCellIdentifiers.searchResultCell, for: indexPath) as! SearchResultCell

            let searchResult = search.searchResults[indexPath.row]
            cell.configure(searchResult: searchResult)
            
            return cell
        }
    }
        
}

extension SearchViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if search.searchResults.count == 0 || search.isLoading {
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
            }, completion: {
                _ in
                controller.view.removeFromSuperview()
                controller.removeFromParentViewController()
                self.landscapeViewController = nil
            })
        }
    }
}

