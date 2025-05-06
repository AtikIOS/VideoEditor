//
//  ActivityIndicatorManager.swift
//  VideoEditing
//
//  Created by Atik Hasan on 4/10/25.
//

import UIKit
import NVActivityIndicatorView

class ActivityIndicatorManager {

    static let shared = ActivityIndicatorManager()
    
    private var containerView: UIView?
    private var activityIndicator: NVActivityIndicatorView?

    private init() {}

    func showLoader(on view: UIView, type: NVActivityIndicatorType = .pacman, color: UIColor = .white) {
        guard containerView == nil else { return }

        // Main overlay view
        let container = UIView(frame: view.bounds)
        container.backgroundColor = UIColor.black.withAlphaComponent(1.0)
        container.isUserInteractionEnabled = true 

        // Indicator
        let indicatorSize: CGFloat = 60
        let indicatorFrame = CGRect(
            x: (view.bounds.width - indicatorSize)/2,
            y: (view.bounds.height - indicatorSize)/2,
            width: indicatorSize,
            height: indicatorSize
        )
        
        let indicator = NVActivityIndicatorView(frame: indicatorFrame, type: type, color: color, padding: 0)
        container.addSubview(indicator)
        view.addSubview(container)

        view.bringSubviewToFront(container)

        indicator.startAnimating()
        
        containerView = container
        activityIndicator = indicator
    }



    func hideLoader() {
        activityIndicator?.stopAnimating()
        containerView?.removeFromSuperview()
        activityIndicator = nil
        containerView = nil
    }
}
