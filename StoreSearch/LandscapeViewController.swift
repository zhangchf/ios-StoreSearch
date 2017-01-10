//
//  LandscapeViewController.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 06/01/2017.
//  Copyright © 2017 Chaofan Zhang. All rights reserved.
//

import UIKit

class LandscapeViewController: UIViewController {
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    
    var search: Search!
    private var firstTime = true
    
    var downloadTasks = [URLSessionDownloadTask]()
    
    deinit {
        print("deinit \(self)")
        for downloadTask in downloadTasks {
            downloadTask.cancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.removeConstraints(view.constraints)
        view.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.removeConstraints(scrollView.constraints)
        scrollView.translatesAutoresizingMaskIntoConstraints = true
        
        pageControl.removeConstraints(pageControl.constraints)
        pageControl.translatesAutoresizingMaskIntoConstraints = true
        
        scrollView.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "LandscapeBackground"))
        pageControl.numberOfPages = 0
    }

    override func viewWillLayoutSubviews() {
        scrollView.frame = view.bounds
        pageControl.frame = CGRect(x: 0, y: view.frame.height - pageControl.frame.height, width: view.frame.width, height: pageControl.frame.height)
        
        if firstTime {
            firstTime = false
            switch search.state {
            case .notSearchedYet, .loading, .noResults:
                break
            case .results(let list):
                tileButtons(list)
            }
        }
    }
    
    private func tileButtons(_ searchResults: [SearchResult]) {
        var columnsPerPage = 5
        var rowsPerPage = 3
        var itemWidth: CGFloat = 96
        var itemHeight: CGFloat = 88
        var marginX: CGFloat = 0
        var marginY: CGFloat = 20
        
        let scrollViewWidth = scrollView.bounds.size.width
        
        switch scrollViewWidth {
        case 568:
            columnsPerPage = 6
            itemWidth = 94
            marginX = 2
        case 667:
            columnsPerPage = 7
            itemWidth = 95
            itemHeight = 98
            marginX = 1
            marginY = 29
        case 736:
            columnsPerPage = 8
            rowsPerPage = 4
            itemWidth = 92
        default:
            break
        }
        
        let buttonWidth: CGFloat = 82
        let buttonHeight: CGFloat = 82
        let paddingHorz = (itemWidth - buttonWidth)/2
        let paddingVert = (itemHeight - buttonHeight)/2
        
        // create buttons
        var row = 0
        var col = 0
        var x = marginX
        for (_, searchResult) in searchResults.enumerated() {
            let button = UIButton(type: .custom)
            button.setBackgroundImage(#imageLiteral(resourceName: "LandscapeButton"), for: .normal)
            let downloadTask = downloadImage(with: searchResult.artworkSmallUrl, andPlaceOn: button)
            if let downloadTask = downloadTask {
                downloadTasks.append(downloadTask)
            }
            
            
            button.frame = CGRect(
                x: x + paddingHorz,
                y: marginY + CGFloat(row)*itemHeight + paddingVert,
                width: buttonWidth, height: buttonHeight)
            
            scrollView.addSubview(button)
            
            row += 1
            if row == rowsPerPage {
                row = 0; col += 1; x += itemWidth
                
                if col == columnsPerPage {
                    col = 0; x += marginX * 2
                }
            }
            
//            col += 1
//            if col == columnsPerPage {
//                row += 1; col = 0
//                if row == rowsPerPage {
//                    pageNum += 1; row = 0; x += marginX * 2 + CGFloat(columnsPerPage) * itemWidth
//                }
//            }
            
        }
        
        let buttonsPerPage = columnsPerPage * rowsPerPage
        let numPages = 1 + (searchResults.count - 1) / buttonsPerPage
        scrollView.contentSize = CGSize(width: CGFloat(numPages)*scrollViewWidth, height: scrollView.bounds.height)
        print("Number of pages: \(numPages)")
        
        pageControl.numberOfPages = numPages
        pageControl.currentPage = 0
    }
    
    func downloadImage(with imgUrlStr: String, andPlaceOn button: UIButton) -> URLSessionDownloadTask? {
        if let url = URL(string: imgUrlStr) {
            let downloadTask = URLSession.shared.downloadTask(with: url, completionHandler: {
                [weak button] fileUrl, response, error in
                if error == nil, let fileUrl = fileUrl, let data = try? Data(contentsOf: fileUrl), let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let button = button {
                            button.setImage(image, for: .normal)
                        }
                    }
                }
            })
            downloadTask.resume()
            return downloadTask
        }
        return nil
    }
    
    @IBAction func pageChanged(_ sender: UIPageControl) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.scrollView.contentOffset = CGPoint(x: self.scrollView.bounds.width * CGFloat(sender.currentPage), y: 0)
        }, completion: nil)
    }
}

extension LandscapeViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let width = scrollView.bounds.width
        let currentPage = Int((scrollView.contentOffset.x + width/2)/width)
        pageControl.currentPage = currentPage
    }
}
