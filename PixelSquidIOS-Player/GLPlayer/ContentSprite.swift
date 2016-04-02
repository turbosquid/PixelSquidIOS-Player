//
//  ContentSprite.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/5/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

class ContentSprite {
  internal var program: GLContentProgram
  internal var texture: GLTexture?
  private var textureQuad = SpriteQuad(size: CGSizeMake(1, 1))
  private var cachedModelMatrix: GLKMatrix4?
  var hidden = false
  var premultipliedTexture = true
  var alpha: Float = 1.0

  internal var modelMatrix: GLKMatrix4 {
    if let matrix = cachedModelMatrix {
      return matrix
    }
    else {
      let matrix = calcModelMatrix()
      cachedModelMatrix = matrix
      return matrix
    }
  }

  var textureSize: CGSize {
    return texture?.size ?? CGSizeZero
  }

  var animatedScale: Double = 1 {
    didSet {
      if animatedScale != oldValue {
        refreshModelMatrix()
      }
    }
  }

  var zDepth: Float = 0.0 {
    didSet {
      if zDepth != oldValue {
        refreshModelMatrix()
      }
    }
  }

  var position = CGPointZero {
    didSet {
      if position != oldValue {
        refreshModelMatrix()
      }
    }
  }

  var size = CGSizeZero {
    didSet {
      if size != oldValue {
        refreshModelMatrix()
      }
    }
  }

  var rotation: Float = 0.0 {
    didSet {
      if rotation != oldValue {
        refreshModelMatrix()
      }
    }
  }

  init(image: CGImage, program: GLContentProgram) {
    self.program = program
    let texture = GLTexture(image: image)
    size = texture.size
    self.texture = texture
  }

  convenience init(path: String, program: GLContentProgram) {
    let data = NSData(contentsOfFile: path)
    let uiImage = UIImage(data: data!)
    self.init(image: uiImage!.CGImage!, program: program)
  }

  convenience init(name: String, program: GLContentProgram) {
    let path = NSBundle.mainBundle().pathForResource(name, ofType: nil)!
    self.init(path: path, program: program)
  }

  func load(image: CGImage) {
    if let texture = texture {
      texture.load(image)
    }
    else {
      texture = GLTexture(image: image)
    }
    afterLoad()
  }

  internal func afterLoad() {
    // overrideable in derived
  }

  func translatePoint(point: CGPoint, viewRect: CGRect, normalized: Bool = false) -> CGPoint? {
    guard let projectionMatrix = program.projectionMatrix else { return nil }

    let offsetPoint = CGPointMake(point.x, viewRect.height - point.y)
    var viewportArray: Array<Int32> = [Int32(viewRect.minX), Int32(viewRect.height - viewRect.maxY), Int32(viewRect.width), Int32(viewRect.height)]
    let windowPoint = GLKVector3(v: (Float(offsetPoint.x), Float(offsetPoint.y), 0))
    let modelViewMatrix = GLKMatrix4Multiply(program.viewMatrix, modelMatrix)
    let glkPoint = GLKMathUnproject(windowPoint, modelViewMatrix, projectionMatrix, &viewportArray, nil)
    let texturePoint = CGPointMake(CGFloat(glkPoint.x), CGFloat(glkPoint.y))

    if normalized {
      return texturePoint
    }
    else {
      let scaledPoint = CGPointMake(texturePoint.x * textureSize.width / 2.0, texturePoint.y * textureSize.height)
      return scaledPoint
    }
  }

  internal func setProgramParameters(program: GLContentProgram) {
    program.textureName = texture?.id
    program.alpha = alpha
    program.modelViewMatrix = GLKMatrix4Multiply(program.viewMatrix, modelMatrix)
  }

  internal func renderProgram(program: GLContentProgram) {
    program.use()
    setProgramParameters(program)
    let quadVertexCount: GLsizei = 4
    glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, quadVertexCount)
  }

  private func renderVisibleSprite() {
    glColorMask(GLTrue, GLTrue, GLTrue, GLFalse)

    glEnable(GLenum(GL_BLEND))
    if premultipliedTexture {
      glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
    }
    else {
      glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
    }

    renderVisibleProgram()
  }

  internal func renderVisibleProgram() {
    renderProgram(program)
  }

  internal func loadPositionQuad() {
    glEnableVertexAttribArray(program.positionIndex)

    withUnsafePointer(&textureQuad.bottomLeft) { pointer in
      glVertexAttribPointer(program.positionIndex, 2, GLenum(GL_FLOAT), GLFalse,
        GLsizei(sizeof(GLKVector2)), pointer)
    }
  }

  internal func unloadPositionQuad() {
    glDisableVertexAttribArray(program.positionIndex)
  }

  // Overridable in derived class
  internal func renderQuad(snapshotting: Bool) {
    renderVisibleSprite()
  }

  // Overridable in derived class
  internal func prepareRender(snapshotting: Bool = false) {
  }

  // Overridable in derived class
  internal func cleanupRender(snapshotting: Bool = false) {
  }

  func render(snapshotting: Bool = false) {
    if hidden { return }

    prepareRender(snapshotting)

    loadPositionQuad()

    renderQuad(snapshotting)

    unloadPositionQuad()

    cleanupRender(snapshotting)
  }

  private func calcModelMatrix() -> GLKMatrix4 {
    let x = Float(position.x)
    let y = Float(position.y)
    let width = Float(size.width) * Float(animatedScale)
    let height = Float(size.height) * Float(animatedScale)
    let rotationMatrix = GLKMatrix4MakeRotation(rotation, 0, 0, 1)

    var matrix = GLKMatrix4Identity
    matrix = GLKMatrix4Translate(matrix, x, y, -zDepth)
    matrix = GLKMatrix4Multiply(matrix, rotationMatrix)
    matrix = GLKMatrix4Scale(matrix, width, height, 1)
    matrix = GLKMatrix4Translate(matrix, -0.5, -0.5, 0)
    return matrix
  }

  private func refreshModelMatrix() {
    cachedModelMatrix = nil
  }

}
