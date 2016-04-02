//
//  PixelSquidAsset.swift
//  PixelSquidIOS-Player
//
//  Created by Mark Kurt on 3/23/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import UIKit

class PixelSquidAsset {
  var assetId: String
  var bundleName: String
  var bundleDisplayName: String
  var lastAccessed: NSDate?
  var name: String
  var date: NSDate
  var galleryImage200Url: String?
  var galleryImage400Url: String?
  var localVideoUrl: NSURL?
  
  init(assetId: String, bundleName: String, bundleDisplayName: String, lastAccessed: NSDate?, name: String, date: NSDate, localVideoUrl: NSURL) {
    self.assetId = assetId
    self.bundleName = bundleName
    self.bundleDisplayName = bundleDisplayName
    self.lastAccessed = lastAccessed
    self.name = name
    self.date = date
    self.localVideoUrl = localVideoUrl
  }
}
