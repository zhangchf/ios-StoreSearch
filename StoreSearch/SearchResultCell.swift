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
        let artistNameStr = searchResult.artistName.isEmpty ? "Unknown" : String(format: "%@ (%@)", searchResult.artistName, kindForDisplay(searchResult.kind))
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
