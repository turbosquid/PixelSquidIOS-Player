//
//  SpriteQuad.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/20/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

struct SpriteQuad {
  var bottomLeft: GLKVector2
  var bottomRight: GLKVector2
  var topLeft: GLKVector2
  var topRight: GLKVector2


  var size: GLKVector2 {
    get {
      return GLKVector2Make(topRight.x - topLeft.x, topLeft.y - bottomLeft.y)
    }
  }

  init(size: CGSize) {
    self.init(rect: CGRect(origin: CGPointZero, size: size))
  }

  init(rect: CGRect) {
    bottomLeft  = GLKVector2Make(Float(rect.minX), Float(rect.minY))
    bottomRight = GLKVector2Make(Float(rect.maxX), Float(rect.minY))
    topLeft     = GLKVector2Make(Float(rect.minX), Float(rect.maxY))
    topRight    = GLKVector2Make(Float(rect.maxX), Float(rect.maxY))
  }
}