//
//  UIImage+DownloadImage.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 05/01/2017.
//  Copyright © 2017 Chaofan Zhang. All rights reserved.
//

import UIKit

extension UIImageView {
    
    
    func loadImage(imgUrl: URL) -> URLSessionDownloadTask {
        
        let downloadTask = URLSession.shared.downloadTask(with: imgUrl, completionHandler: {
            [weak self] url, response, error in
            
            if error == nil, let url = url, let imgData = try? Data(contentsOf: url), let image = UIImage(data:imgData) {
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        strongSelf.image = image
                    }
                }
            }
        })
        downloadTask.resume()
        
        return downloadTask
    }
}
