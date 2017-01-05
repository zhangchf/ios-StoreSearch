//
//  SearchResult.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 30/12/2016.
//  Copyright © 2016 Chaofan Zhang. All rights reserved.
//

import Foundation

class SearchResult {
    var name = ""
    var artistName = ""
    var artworkSmallUrl = ""
    var artworkLargeUrl = ""
    var storeUrl = ""
    var kind = ""
    var currency = ""
    var price = 0.0
    var genre = ""
    
    static func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
    
    func kindForDisplay() -> String {
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
