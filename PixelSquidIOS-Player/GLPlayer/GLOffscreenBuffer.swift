//
//  GLOffscreenBuffer.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 2/10/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

class GLOffscreenBuffer {
  var framebufferIndex: GLuint = 0
  static var instance: GLOffscreenBuffer?

  init() {
    glGenFramebuffers(1, &framebufferIndex)
  }

  deinit {
    glDeleteFramebuffers(1, &framebufferIndex)
  }

  static func getInstance() -> GLOffscreenBuffer {
    if let instance = GLOffscreenBuffer.instance {
      return instance
    }

    let instance = GLOffscreenBuffer()
    GLOffscreenBuffer.instance = instance
    return instance
  }

  static func bind() {
    getInstance().bind()
  }

  static func attachTexture(texture: GLTexture) {
    getInstance().attachTexture(texture)
  }

  func bind() {
    glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebufferIndex)
  }

  func attachTexture(texture: GLTexture) {
    glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), texture.id, 0)
  }
}