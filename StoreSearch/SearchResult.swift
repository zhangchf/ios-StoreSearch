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
}
