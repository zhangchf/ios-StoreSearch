//
//  DetailViewController.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 05/01/2017.
//  Copyright © 2017 Chaofan Zhang. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    
    var searchResult: SearchResult!
    
    var imgDownloadTask: URLSessionDownloadTask?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    deinit {
        print("deinit \(self)")
        imgDownloadTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
        popupView.layer.cornerRadius = 10
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(close))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
        
        if searchResult != nil {
            fillData(searchResult: searchResult)
        }
    }
    
    func fillData(searchResult: SearchResult) {
        // image
        artworkImageView.image = UIImage(named: "Placeholder")
        if let url = URL(string: searchResult.artworkLargeUrl) {
            imgDownloadTask = artworkImageView.loadImage(imgUrl: url)
        }
        
        nameLabel.text = searchResult.name
        artistNameLabel.text = searchResult.artistName.isEmpty ? "Unknown" : searchResult.artistName
        kindLabel.text = searchResult.kindForDisplay()
        genreLabel.text = searchResult.genre
        
        // Price
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = searchResult.currency
        let priceText: String
        if searchResult.price == 0.0 {
            priceText = "Free"
        } else if let text = formatter.string(from: searchResult.price as NSNumber) {
            priceText = text
        } else {
            priceText = ""
        }
        priceButton.setTitle(priceText, for: .normal)
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openInStore() {
        if let url = URL(string: searchResult.storeUrl) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

}

extension DetailViewController: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DimmingPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

extension DetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view === self.view  // only handle taps outside of the popup view.
    }
}

