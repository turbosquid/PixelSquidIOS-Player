//
//  GLExtras.swift
//  PixelSquidIOS-Player
//
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.

import Foundation
import GLKit

let GLFalse = GLboolean(GL_FALSE)
let GLTrue = GLboolean(GL_TRUE)

func glAssertNoError() {
  let error = glGetError()
  assert(error != GLenum(GL_INVALID_ENUM))
  assert(error != GLenum(GL_INVALID_VALUE))
  assert(error != GLenum(GL_INVALID_OPERATION))
  assert(error != GLenum(GL_INVALID_FRAMEBUFFER_OPERATION))
  assert(error != GLenum(GL_OUT_OF_MEMORY))
  assert(error != GLenum(GL_STACK_UNDERFLOW))
  assert(error != GLenum(GL_STACK_OVERFLOW))

  assert(error == GLenum(GL_NO_ERROR))
}