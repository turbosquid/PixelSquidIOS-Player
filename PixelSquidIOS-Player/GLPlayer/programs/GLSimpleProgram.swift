//
//  GLBackgroundProgram.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/6/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

class GLSimpleProgram: GLContentProgram {
  override var vertexShaderFile: String { get { return "simple.vsh" } }
  override var fragmentShaderFile: String { get { return "simple.fsh" } }
}