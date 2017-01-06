//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by Chaofan Zhang on 05/01/2017.
//  Copyright © 2017 Chaofan Zhang. All rights reserved.
//

import UIKit

class DimmingPresentationController: UIPresentationController {
    
    lazy var dimmingView = GradientView(frame: CGRect.zero)
    
    override var shouldRemovePresentersView: Bool {
        return false
    }
    
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView!.bounds
        containerView!.insertSubview(dimmingView, at: 0)
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            return
        }
        self.dimmingView.alpha = 0
        coordinator.animate(alongsideTransition: {
            _ in
            self.dimmingView.alpha = 1
        }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            return
        }
        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0
        }, completion: nil)
    }

}
