//
//  GLContentProgram.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/7/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation

import Foundation
import GLKit

class GLContentProgram: GLProgram {
  var projectionMatrix: GLKMatrix4?
  var viewMatrix = GLKMatrix4Identity
  var viewSize = CGSizeZero
  private let minDepth: GLfloat = -256
  private let maxDepth: GLfloat = 256

  var viewFrame: CGRect = CGRectZero {
    didSet {
      let widthScale = Float(viewSize.width / viewFrame.width)
      let heightScale = Float(viewSize.height / viewFrame.height)
      let xOffset = Float(-viewFrame.minX)
      let yOffset = Float(-viewFrame.minY)

      viewMatrix = GLKMatrix4Identity
      viewMatrix = GLKMatrix4Scale(viewMatrix, widthScale, heightScale, 1)
      viewMatrix = GLKMatrix4Translate(viewMatrix, xOffset, yOffset, 0)
    }
  }

  var textureName: GLuint? {
    didSet {
      if let textureName = textureName {
        if textureUniform != GL_INVALID_VALUE {
          setTexture(textureUniform, textureNumber: 0, textureId: textureName)
        }
      }
    }
  }

  var alpha: GLfloat = 1.0 {
    didSet {
      setUniform("alpha", floatValue: alpha)
    }
  }

  var modelViewMatrix: GLKMatrix4? {
    didSet {
      if let modelViewMatrix = modelViewMatrix {
        var matrix = GLKMatrix4Multiply(projectionMatrix!, modelViewMatrix)
        withUnsafePointer(&matrix.m) {
          glUniformMatrix4fv(matrixUniform, 1, GLboolean(GL_FALSE), UnsafePointer<GLfloat>($0))
        }
      }
    }
  }

  private (set) var positionIndex: GLuint!

  private var matrixUniform: GLint!
  private var textureUniform: GLint!

  var vertexShaderFile: String { get { return "" } }
  var fragmentShaderFile: String { get { return "" } }

  override init(restoreRenderState: () -> Void) {
    super.init(restoreRenderState: restoreRenderState)
    
    if vertexShaderFile.isEmpty || fragmentShaderFile.isEmpty {
      print("vertex or fragment shader file not initialized")
      return
    }
    
    loadShaders(vertexShaderFile, fragmentShaderFile)
    
    link()
    
    positionIndex = attributeIndex("position")

    matrixUniform = uniformIndex("matrix")
    textureUniform = uniformIndex("texture")
  }

  convenience init(orthoSize: CGSize, restoreRenderState: () -> Void) {
    self.init(restoreRenderState: restoreRenderState)

    viewSize = orthoSize
    viewFrame = CGRect(origin: CGPointMake(0, 0), size: viewSize)
    projectionMatrix = GLKMatrix4MakeOrtho(0, Float(orthoSize.width), Float(orthoSize.height), 0, minDepth, maxDepth)
  }
}