//
//  SpinnerEffect.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/20/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

struct SpinnerEffect {
  var name: String!
  var displayName: String!
  var minimumValue: CGFloat = 0.0
  var maximumValue: CGFloat = 0.0
  var value: CGFloat = 0.0
  var startingValue: CGFloat = 0.0
  var invert = false
  
  var convertedValue: CGFloat {
    get {
      if invert {
        return (maximumValue - value) + minimumValue
      }
      else {
        return value
      }
    }
    set(newValue) {
      if invert {
        value = (maximumValue - newValue) + minimumValue
      }
      else {
        value = newValue
      }
    }
  }
}

let DefaultSpinnerEffects: [SpinnerEffect] = [
  // warmth, tint, lightness, vibrance
  SpinnerEffect(name: "Temperature", displayName: "Warmth", minimumValue: 2700, maximumValue: 10300, value: 6500, startingValue: 6500, invert: true),
  SpinnerEffect(name: "Hue", displayName: "Tint", minimumValue: 0.5, maximumValue: 1.5, value: 1.0, startingValue: 1.0, invert: false),
  SpinnerEffect(name: "Gamma", displayName: "Lightness", minimumValue: 0.0, maximumValue: 2.0, value: 1.0, startingValue: 1.0, invert: false),
  SpinnerEffect(name: "Vibrance", displayName: "Vibrance", minimumValue: 0.0, maximumValue: 2.0, value: 1.0, startingValue: 1.0, invert: false),
  SpinnerEffect(name: "Opacity", displayName: "Opacity", minimumValue: 0.0, maximumValue: 1.0, value: 1.0, startingValue: 1.0, invert: false),
  SpinnerEffect(name: "BlurRadius", displayName: "Blur", minimumValue: 0.0, maximumValue: CGFloat(SpinnerSprite.maxBlurRadius), value: 0.0, startingValue: 0.0, invert: false)
]
