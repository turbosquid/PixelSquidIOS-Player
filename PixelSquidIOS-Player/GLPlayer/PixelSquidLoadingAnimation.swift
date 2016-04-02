//
//  PixelSquidSpinner.swift
//  PixelSquidIOS-Player
//
//  Created by Mark Kurt on 10/5/15.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import UIKit

class PixelSquidLoadingAnimation {
  let size = CGSizeMake(20, 20)
  
  var activityIndicator: UIActivityIndicatorView?
  
  init() {
    activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
  }
  
  func clean() {
    if activityIndicator != nil {
      activityIndicator = nil
    }
  }
  
  func addToScene(scene: GLEditorScene) {
    if let activityIndicator = activityIndicator {
      let viewSize = scene.bounds.size
      let position = CGPoint(x: viewSize.width / 2.0, y: viewSize.height / 2.0)

      let origin = CGPointMake(position.x - (size.width / 2.0), position.y - (size.height / 2.0))
      let frame = CGRect(origin: origin, size: size)
      activityIndicator.frame = frame
      scene.addSubview(activityIndicator)
      activityIndicator.startAnimating()
    }
  }
  
  func removeFromScene(clean: Bool) {
    if let activityIndicator = activityIndicator {
      activityIndicator.removeFromSuperview()
      activityIndicator.stopAnimating()
    }

    if clean {
      self.clean()
    }
  }
}