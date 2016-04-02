//
//  GLSpinnerProgram.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/6/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

class GLSpinnerProgram: GLContentProgram {
  override var vertexShaderFile: String { get { return "spinner.vsh" } }
  override var fragmentShaderFile: String { get { return "spinner.fsh" } }
}