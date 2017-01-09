//
//  FadeOutAnimationController.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 09/01/2017.
//  Copyright © 2017 Chaofan Zhang. All rights reserved.
//

import UIKit

class FadeOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let fromView = transitionContext.view(forKey: .from) {
            UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
                fromView.alpha = 0
            }, completion: { finished in
                transitionContext.completeTransition(finished)
            })
        }
    }
}
