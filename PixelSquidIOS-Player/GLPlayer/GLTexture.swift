//
//  GLTexture.swift
//  PixelSquidIOS-Player
//
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.

import Foundation
import GLKit

class GLTexture {
  private(set) var id: GLuint = GL_INVALID_INDEX
  private(set) var size: CGSize = CGSizeZero

  init(image: CGImage) {
    id = generateTexture()
    load(image)
  }

  init(format: GLint, size: CGSize) {
    id = generateTexture()
    self.size = size
    glTexImage2D(GLenum(GL_TEXTURE_2D), 0, format, GLint(size.width), GLint(size.height), 0, GLenum(format), GLenum(GL_UNSIGNED_BYTE), nil)
  }

  deinit {
    destroyTexture()
  }

  func load(image: CGImage?) {
    if let image = image {
      if id == GL_INVALID_INDEX {
        id = generateTexture()
      }

      let width = CGFloat(CGImageGetWidth(image))
      let height = CGFloat(CGImageGetHeight(image))
      size = CGSizeMake(width, height)

      glBindTexture(GLenum(GL_TEXTURE_2D), id)
      let imageBuffer = imageData(image)

      imageBuffer.withUnsafeBufferPointer { pointer in
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLint(size.width), GLint(size.height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), pointer.baseAddress)
      }
    }
    else {
      destroyTexture()
    }
  }
  
  private func generateTexture() -> GLuint {
    var texture = GL_INVALID_INDEX

    glGenTextures(1, &texture)
    glBindTexture(GLenum(GL_TEXTURE_2D), texture)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
    glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)

    return texture
  }

  private func imageData(image: CGImage) -> Array<GLubyte> {
    let width = Int(size.width)
    let height = Int(size.height)
    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width;
    let bitsPerComponent = 8
    let bitmapInfo = CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue
    var textureData = Array<GLubyte>(count: width * height * bytesPerPixel, repeatedValue: 0)
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    textureData.withUnsafeMutableBufferPointer { pointer in
      let context = CGBitmapContextCreate(pointer.baseAddress, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
      CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image)
    }

    return textureData
  }


  private func destroyTexture() {
    glDeleteTextures(1, [id])
    id = GL_INVALID_INDEX
    size = CGSizeZero
  }
}