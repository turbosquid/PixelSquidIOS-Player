//
//  MovieNode.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 11/5/15.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit
import CoreImage

class MovieDecoder {
  private static let ErrorDomain = "MovieDecoder"
  private static let RequiredKeys = ["playable"]
  private var videoUrl: NSURL? = nil
  private var asset: AVURLAsset? = nil
  private var generator: AVAssetImageGenerator? = nil
  private var error: Bool = false
  private var frameRate: Double = 0.0
  private var latitudeCount: Int = 16
  private let longitudeCount: Int = 16
  private var currentLatitude: Int = 5
  private var currentLongitude: Int = 1

  var latitude: Int {
    get {
      return currentLatitude
    }
  }
  
  var longitude: Int {
    get {
      return currentLongitude
    }
  }
  
  typealias completionFunc = (success: Bool, error: NSError?, frameImage: CGImage?) -> Void

  deinit {
    deactivate()
    videoUrl = nil
  }

  func deactivate() {
    generator = nil
    asset = nil
  }

  func rotate(latitude: Int, longitude: Int) -> Bool {
    let newLatitude = max(min(latitude, latitudeCount - 1), 0)

    var newLongitude = longitude % longitudeCount
    if newLongitude < 0 {
      newLongitude += longitudeCount
    }

    if currentLatitude != newLatitude || currentLongitude != newLongitude {
      currentLatitude = newLatitude
      currentLongitude = newLongitude
      return true
    }
    else {
      return false
    }
  }
  
  func getCurrentImage(completion: completionFunc) {
    getCurrentFrameImage() { success, error, frameImage in
      if !success || frameImage == nil {
        completion(success: false, error: error, frameImage: nil)
        return
      }
      
      completion(success: true, error: nil, frameImage: frameImage)
    }
  }

  func getCurrentFrameImage(completion: completionFunc) {
    decodeCurrentFrame() {
      success, error, frameImage in
      completion(success: success, error: error, frameImage: frameImage)
    }
  }

  func load(videoUrl: NSURL, completion: completionFunc) {
    self.videoUrl = videoUrl
    activate(completion)
  }

  func load(videoUrlPath: String, completion: completionFunc) {
    load(NSURL(fileURLWithPath: videoUrlPath), completion: completion)
  }

  func handleLoadedTrack(asset: AVURLAsset, completion: completionFunc) {
    let tracks = asset.tracksWithMediaType(AVMediaTypeVideo)
    let track = tracks[0]
    frameRate = Double(track.nominalFrameRate)
    let frameCount = Int(CMTimeGetSeconds(asset.duration) * frameRate)
    latitudeCount = frameCount / longitudeCount
    
    decodeCurrentFrame(completion)
  }
  
  func activate(completion: completionFunc) {
    if error {
      let completionError = NSError(domain: MovieDecoder.ErrorDomain, code: 1, userInfo: nil)
      completion(success: false, error: completionError, frameImage: nil)
      return
    }

    if let url = videoUrl {
      asset = AVURLAsset(URL: url)
      if let asset = asset {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = kCMTimeZero
        generator.requestedTimeToleranceAfter = kCMTimeZero
        self.generator = generator

        asset.loadValuesAsynchronouslyForKeys(MovieDecoder.RequiredKeys) {
          dispatch_async(dispatch_get_main_queue()) { [weak self] in
            var loadingError: NSError? = nil
            let assetStatus = asset.statusOfValueForKey("playable", error: &loadingError)
            switch (assetStatus) {
              case .Loaded:
                self?.handleLoadedTrack(asset, completion: completion)
                return

              default:
                self?.setErrorState()
                completion(success: false, error: loadingError, frameImage: nil)
                return
            }
          }
        }
      }
    }
  }
  
  private func decodeCurrentFrame(completion: completionFunc) {
    if let asset = asset, generator = generator {
      let frameOffset = currentLatitude * longitudeCount + currentLongitude
      let timeOffset = Double(frameOffset) / frameRate
      let seek = CMTimeMakeWithSeconds(timeOffset, asset.duration.timescale)
      var actualTime = CMTimeMake(0, 0)
      
      do {
        let frameImage = try generator.copyCGImageAtTime(seek, actualTime: &actualTime)
        completion(success: true, error: nil, frameImage: frameImage)
      }
      catch let error as NSError {
        completion(success: false, error: error, frameImage: nil)
        return
      }
    }
    else {
      activate(completion)
    }
  }
  
  private func setErrorState() {
    error = true
  }
}