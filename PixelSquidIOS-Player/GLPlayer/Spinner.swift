//
//  Spinner.swift
//  PixelSquidIOS-Player
//
//  Created by Mark Kurt on 12/30/15.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import UIKit
import GLKit

// Based on the iPad 3rd gen width (1024 pts) and a 50% increase in size
let ScreenScaleFactor: CGFloat = 1.5 * UIScreen.mainScreen().bounds.width / 1024.0

protocol SpinnerImage {
  var position: CGPoint {get set}
  var scale: CGFloat {get set}
  var rotation: CGFloat {get set}
  var animatedScale: Double {get set}
  var zDepth: Float {get set}

  func load(cgImage: CGImage)
  func draw(snapshotting: Bool)
  func updateEffect(named name: String, value: NSNumber)
  func discardLastBrushStroke()
  func discardBrushStrokes()
  func saveBrushStrokes()
  func updateBrushType(type: MaskBrushType)
  func updateBrushSize(radius: CGFloat)
  func clearLastTouchLocation()
  func maskDrawStart(location: CGPoint, atScale: CGFloat)
  func maskDrawStop()
  func maskDrawTo(location: CGPoint)
  func translatePoint(point: CGPoint, viewRect: CGRect) -> CGPoint
  func flatten()
  func expand()
}

class GLKSpinnerImage: SpinnerImage {
  var zDepth: Float = 0 {
    didSet {
      sprite?.zDepth = zDepth
    }
  }

  var rotation: CGFloat = 0 {
    didSet {
      sprite?.rotation = Float(rotation)
    }
  }
  
  var position: CGPoint = CGPointZero {
    didSet {
      sprite?.position = position
    }
  }

  var scale: CGFloat = 1.0 {
    didSet {
      calculateSize()
    }
  }

  var animatedScale: Double = 1 {
    didSet {
      sprite?.animatedScale = animatedScale
    }
  }

  var program: GLSpinnerProgram
  var hitTestProgram: GLHitTestProgram?
  var simpleProgram: GLSimpleProgram?
  var blurProgram: GLBlurProgram?
  var sprite: SpinnerSprite?

  init(program: GLSpinnerProgram) {
    self.program = program
  }

  private func calculateSize() {
    if let sprite = sprite {
      let resolution = sprite.textureSize.height * scale * ScreenScaleFactor
      sprite.size = CGSizeMake(resolution, resolution)
    }
  }
  
  func load(cgImage: CGImage) {
    // TODO: Just add a load func to ContentSprite and move this protocol to the sprite

    if let sprite = sprite {
      sprite.load(cgImage)
    }
    else {
      let sprite = SpinnerSprite(image: cgImage, program: program)
      self.sprite = sprite
      sprite.hitTestProgram = hitTestProgram
      sprite.simpleProgram = simpleProgram
      sprite.blurProgram = blurProgram
      sprite.position = position
      calculateSize()
    }
  }
  
  func draw(snapshotting: Bool) {
    sprite?.render(snapshotting)
  }

  func updateEffect(named name: String, value: NSNumber) {
    sprite?.effects[name] = value
  }
  
  func discardLastBrushStroke() {
    sprite?.maskBrush.discardLastStroke()
  }

  func discardBrushStrokes() {
    sprite?.maskBrush.discardMaskChanges()
  }

  func saveBrushStrokes() {
    sprite?.maskBrush.saveMaskChanges()
  }

  func updateBrushType(type: MaskBrushType) {
    sprite?.maskBrush.brushType = type
  }

  func updateBrushSize(radius: CGFloat) {
    sprite?.maskBrush.currentLineSize = radius
  }

  func clearLastTouchLocation() {
    sprite?.maskBrush.drawStop()
  }

  func maskDrawStart(location: CGPoint, atScale: CGFloat) {
    sprite?.maskBrush.drawStart(location, atScale: atScale)
  }

  func maskDrawStop() {
    sprite?.maskBrush.drawStop()
  }

  func maskDrawTo(location: CGPoint) {
    sprite?.maskBrush.drawTo(location)
  }

  func translatePoint(point: CGPoint, viewRect: CGRect) -> CGPoint {
    return sprite?.translatePoint(point, viewRect: viewRect) ?? point
  }

  func flatten() {
    sprite?.flatten()
  }

  func expand() {
    sprite?.expand()
  }
}

protocol SpinnerSceneDelegate: class {
  func removeContentFromScene(content: Spinner)
  func disableInteractions()
  func enableInteractions()
  func redraw()
  func restoreRenderState()
}

class Spinner {
  private static let PixelsPerLongitude = 10.0
  private static let PixelsPerLatitude = 10.0
  private static let MaximumContentScale: CGFloat = 5.0
  private static let MinimumContentScale: CGFloat = 0.05
  private var parentFrame: CGRect = CGRectZero
  private let decoder: MovieDecoder!
  private var dragOffset: CGPoint = CGPoint(x: Spinner.PixelsPerLongitude / 2.0, y: Spinner.PixelsPerLatitude / 2.0)
  private var bounceTimeOffset: NSTimeInterval?
  private var startBouncing = false

  var effects: [SpinnerEffect]?
  var image: SpinnerImage
  var isLockedForEditing = false

  static let bounceDuration: NSTimeInterval = 0.2
  static let bounceMultiplier: Double = 0.1

  weak var sceneDelegate: SpinnerSceneDelegate?

  var zDepth: Float = 0 {
    didSet {
      image.zDepth = zDepth
    }
  }
  
  var position: CGPoint = CGPointZero {
    didSet {
      image.position = position
      sceneDelegate?.redraw()
    }
  }
  
  var scale: CGFloat = 0.5 {
    didSet {
      scale = max(min(scale, Spinner.MaximumContentScale), Spinner.MinimumContentScale)
      image.scale = scale
      sceneDelegate?.redraw()
    }
  }
  
  var rotation: CGFloat = 0 {
    didSet {
      rotation = rotation % CGFloat(M_PI * 2)
      image.rotation = rotation
      sceneDelegate?.redraw()
    }
  }
  
  init(parentFrame: CGRect, image: SpinnerImage) {
    self.image = image
    self.parentFrame = parentFrame
    decoder = MovieDecoder()
    initializeParameters()
  }

  private func initializeParameters() {
    position = CGPointMake(parentFrame.width / 2.0, parentFrame.height / 2.0)
    scale = 0.5
  }

  private func bounce() {
    startBouncing = true
    sceneDelegate?.redraw()
  }

  typealias CompletionFunc = (success: Bool, error: NSError?) -> Void
  
  func load(videoUrl videoUrl: NSURL, completion: CompletionFunc) {
    // TODO: We are double loading the frame on select
    decoder.load(videoUrl) { [weak self] success, error, frameImage in
      self?.decoder.deactivate()
      
      if !success {
        completion(success: success, error: error)
        return
      }
      
      self?.image.load(frameImage!)
      self?.resetEffects()

      completion(success: success, error: error)
    }
  }

  func load(videoUrlPath videoUrlPath: String, completion: CompletionFunc) {
    load(videoUrl: NSURL(fileURLWithPath: videoUrlPath), completion: completion)
  }

  func drag(offset: CGPoint) {
    position = CGPointMake(position.x + offset.x, position.y + offset.y)
  }
  
  func spin(spinOffset: CGPoint) {
    let rotateTransform = CGAffineTransformMakeRotation(-rotation)
    let updatedSpinOffset = CGPointApplyAffineTransform(spinOffset, rotateTransform)
    
    dragOffset.x -= updatedSpinOffset.x
    
    let longitudeIncrement = dragOffset.x / CGFloat(Spinner.PixelsPerLongitude)
    dragOffset.x = dragOffset.x % CGFloat(Spinner.PixelsPerLongitude)
    let longitude = decoder.longitude + Int(longitudeIncrement)
    
    dragOffset.y -= updatedSpinOffset.y
    
    let latitudeIncrement = dragOffset.y / CGFloat(Spinner.PixelsPerLatitude)
    dragOffset.y = dragOffset.y % CGFloat(Spinner.PixelsPerLatitude)
    let latitude = decoder.latitude + Int(latitudeIncrement)
    
    if decoder.rotate(latitude, longitude: longitude) {
      loadCurrentFrame()
    }
  }

  private func loadCurrentFrame(completion: CompletionFunc? = nil) {
    decoder.getCurrentImage() { [weak self] success, error, cgImage in
      if let cgImage = cgImage {
        self?.image.load(cgImage)
        self?.sceneDelegate?.redraw()
      }
      completion?(success: success, error: error)
    }
  }

  func updateBounceAnimation(timeSinceLastUpdate: NSTimeInterval) {
    if startBouncing {
      startBouncing = false
      bounceTimeOffset = 0
    }
    else if let bounceTimeOffset = bounceTimeOffset {
      self.bounceTimeOffset = bounceTimeOffset + timeSinceLastUpdate
    }

    if let bounceTimeOffset = bounceTimeOffset {
      if bounceTimeOffset < Spinner.bounceDuration {
        let bounceAddition = sin((bounceTimeOffset / Spinner.bounceDuration) * M_PI) * Spinner.bounceMultiplier
        image.animatedScale = 1 + bounceAddition
      }
      else {
        image.animatedScale = 1
        self.bounceTimeOffset = nil
      }
      sceneDelegate?.redraw()
    }
  }

  func updateAnimation(timeSinceLastUpdate: NSTimeInterval) {
    updateBounceAnimation(timeSinceLastUpdate)
  }
  
  func render(snapshotting: Bool) -> Bool {
    image.draw(snapshotting)

    return true
  }

  func deselect() {
    image.flatten()
  }

  func select() {
    image.expand()
    loadCurrentFrame() { [weak self] success, error in
      self?.bounce()
    }
  }

  func clearLastTouchLocation() {
    image.clearLastTouchLocation()
  }

  private func setEffects(effects: [SpinnerEffect]) {
    for filter in effects {
      updateEffect(named: filter.name, value: filter.value)
    }
    sceneDelegate?.redraw()
  }

  private func resetEffects() {
    if let effects = effects {
      setEffects(effects)
    }
    else {
      setEffects(DefaultSpinnerEffects)
    }
  }

  func undoEffects() {
    resetEffects()
  }

  func updateEffect(named name: String, value: NSNumber) {
    image.updateEffect(named: name, value: value)
    sceneDelegate?.redraw()
  }

  func maskDrawStart(location: CGPoint, atScale: CGFloat) {
    image.maskDrawStart(location, atScale: atScale)
    sceneDelegate?.redraw()
  }

  func maskDrawStop() {
    image.maskDrawStop()
    sceneDelegate?.redraw()
  }

  func maskDrawTo(location: CGPoint) {
    image.maskDrawTo(location)
    sceneDelegate?.redraw()
  }
  
  func discardLastBrushStroke() {
    image.discardLastBrushStroke()
    sceneDelegate?.redraw()
  }

  func discardBrushStrokes() {
    image.discardBrushStrokes()
    isLockedForEditing = false
    sceneDelegate?.redraw()
  }

  func saveBrushStrokes() {
    image.saveBrushStrokes()
    isLockedForEditing = false
    sceneDelegate?.redraw()
  }

  func updateBrushType(type: MaskBrushType) {
    image.updateBrushType(type)
  }

  func updateBrushSize(radius: CGFloat) {
    image.updateBrushSize(radius)
  }

  func translatePoint(point: CGPoint, viewRect: CGRect) -> CGPoint {
    return image.translatePoint(point, viewRect: viewRect)
  }
}
