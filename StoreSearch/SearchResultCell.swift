//
//  SearchResultCell.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 30/12/2016.
//  Copyright © 2016 Chaofan Zhang. All rights reserved.
//

import UIKit

class SearchResultCell: UITableViewCell {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    
    var downloadImageTask: URLSessionDownloadTask?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 0.5)
        selectedBackgroundView = selectedView
    }
    
    func configure(searchResult: SearchResult) {
        nameLabel.text = searchResult.name
        let artistNameStr = searchResult.artistName.isEmpty ? "Unknown" : String(format: "%@ (%@)", searchResult.artistName, searchResult.kindForDisplay())
        artistNameLabel.text = artistNameStr
        
        artworkImageView.image = #imageLiteral(resourceName: "Placeholder")
        if let url = URL(string: searchResult.artworkSmallUrl) {
            downloadImageTask = artworkImageView.loadImage(imgUrl: url)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print("SearchResultCell prepareForReuse")
        downloadImageTask?.cancel()
        downloadImageTask = nil
    }
    
}
