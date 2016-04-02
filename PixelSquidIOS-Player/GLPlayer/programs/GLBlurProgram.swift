//
//  GLBlurProgram.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 2/11/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

class GLBlurProgram: GLContentProgram {
  override var vertexShaderFile: String { get { return "gaussianBlur.vsh" } }
  override var fragmentShaderFile: String { get { return "gaussianBlur.fsh" } }
}