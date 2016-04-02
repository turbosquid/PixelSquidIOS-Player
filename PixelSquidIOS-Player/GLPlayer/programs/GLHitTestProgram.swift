//
//  GLHitTestProgram.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/15/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation

class GLHitTestProgram: GLContentProgram {
  override var vertexShaderFile: String { get { return "hitTest.vsh" } }
  override var fragmentShaderFile: String { get { return "hitTest.fsh" } }
}