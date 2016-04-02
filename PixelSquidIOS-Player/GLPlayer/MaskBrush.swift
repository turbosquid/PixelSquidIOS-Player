//
//  MaskBrush.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/21/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

enum MaskBrushType {
  case Erase, Unerase
}

class MaskBrush {
  static let eraseColor = UIColor.blackColor().CGColor
  static let uneraseColor = UIColor.whiteColor().CGColor
  static var defaultTexture: GLTexture!

  var currentLineSize: CGFloat = 20.0
  var spinnerScale: CGFloat = 1.0

  var brushType: MaskBrushType {
    get {
      return brushColor === MaskBrush.eraseColor ? .Erase : .Unerase
    }

    set {
      brushColor = newValue == .Erase ? MaskBrush.eraseColor : MaskBrush.uneraseColor
    }
  }

  var textureId: GLuint {
    if let maskTexture = maskTexture {
      return maskTexture.id
    }
    else {
      return MaskBrush.defaultTexture.id
    }
  }

  private var brushColor = eraseColor
  private var previousTouchLocation: CGPoint?
  private var backgroundScale: CGFloat = 1.0
  private var size = CGSizeZero

  private var maskTexture: GLTexture?

  private var maskImage: CGImage?
  private var undoMaskImage: CGImage?
  private var lastStrokeMaskImage: CGImage?

  init(size: CGSize) {
    self.size = size
    createDefault()
  }

  private func createDefault() {
    if MaskBrush.defaultTexture == nil {
      let image = createBlankImage()
      MaskBrush.defaultTexture = GLTexture(image: image!)
    }
  }

  func drawStart(location: CGPoint, atScale: CGFloat) {
    initializeMask()

    previousTouchLocation = location
    backgroundScale = atScale
  }
  
  func drawStop() {
    previousTouchLocation = nil
  }

  func saveMaskChanges() {
    undoMaskImage = nil
    lastStrokeMaskImage = nil
  }

  func discardLastStroke() {
    guard let lastStrokeMaskImage = lastStrokeMaskImage else { return }

    self.maskImage = lastStrokeMaskImage
    self.lastStrokeMaskImage = nil

    guard let maskTexture = maskTexture else { return }
    guard let maskImage = maskImage else { return }

    maskTexture.load(maskImage)
  }

  func discardMaskChanges() {
    guard let undoMaskImage = undoMaskImage else { return }

    self.maskImage = undoMaskImage
    self.undoMaskImage = nil

    guard let maskTexture = maskTexture else { return }
    guard let maskImage = maskImage else { return }

    maskTexture.load(maskImage)
  }

  func drawTo(location: CGPoint) {
    if let previousTouchLocation = previousTouchLocation {
      // record touches as strokes on maskImage
      UIGraphicsBeginImageContext(size)
      let currentContext = UIGraphicsGetCurrentContext()
      
      if let currentMaskImage = maskImage {
        let frame = CGRectMake(0, 0, size.width, size.height)

        CGContextTranslateCTM(currentContext, 0, size.height)
        CGContextScaleCTM(currentContext, 1.0, -1.0)

        CGContextDrawImage(currentContext, frame, currentMaskImage)

        CGContextScaleCTM(currentContext, 1.0, -1.0)
        CGContextTranslateCTM(currentContext, 0, -size.height)
      }

      CGContextSetLineJoin(currentContext, .Round)
      CGContextSetLineCap(currentContext, .Round)
      CGContextSetLineWidth(currentContext, currentLineSize / (spinnerScale * backgroundScale))
      CGContextSetFillColorWithColor(currentContext, brushColor)
      CGContextSetStrokeColorWithColor(currentContext, brushColor)

      let path = CGPathCreateMutable()
      CGPathMoveToPoint(path, nil, previousTouchLocation.x, previousTouchLocation.y)
      CGPathAddLineToPoint(path, nil, location.x, location.y)
      CGContextAddPath(currentContext, path)
      CGContextStrokePath(currentContext)

      maskImage = CGBitmapContextCreateImage(currentContext)
      UIGraphicsEndImageContext()

      if let maskTexture = maskTexture, let maskImage = maskImage {
        maskTexture.load(maskImage)
      }
    }

    previousTouchLocation = location
  }

  private func initializeMask() {
    if maskImage == nil {
      maskImage = createBlankImage()
    }

    if maskTexture == nil {
      if let maskImage = maskImage {
        maskTexture = GLTexture(image: maskImage)
      }
    }

    if undoMaskImage == nil {
      // TODO: Switch to using glCopyTexImage2D
      undoMaskImage = maskImage
    }
    
    lastStrokeMaskImage = maskImage
  }

  private func createBlankImage() -> CGImage? {
    let colorspace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
    let width = Int(size.width)
    let height = Int(size.height)
    let bitsPerComponent = 8
    let numComponents = 4
    let bitsPerPixel = bitsPerComponent * numComponents
    let bytesPerPixel = bitsPerComponent * numComponents / 8
    let bytesPerRow = bytesPerPixel * width

    let whitePixel: UInt32 = 0xFFFFFFFF
    var pixelData = Array<UInt32>(count: width * height, repeatedValue: whitePixel)
    let length = pixelData.count * bytesPerPixel
    let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &pixelData, length: length))

    return CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, providerRef, nil, false, .RenderingIntentDefault)
  }
}