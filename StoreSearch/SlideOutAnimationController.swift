//
//  SlideOutAnimationController.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 06/01/2017.
//  Copyright © 2017 Chaofan Zhang. All rights reserved.
//

import UIKit

class SlideOutAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            return
        }
        let containerView = transitionContext.containerView
        let animations = {
            fromView.center.y -= containerView.bounds.size.height
            fromView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: animations)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: animations, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }
}
