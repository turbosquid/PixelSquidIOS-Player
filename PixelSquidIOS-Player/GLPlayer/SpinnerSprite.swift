//
//  SpinnerSprite.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/20/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

class SpinnerSprite: ContentSprite {
  var hitTestProgram: GLHitTestProgram?
  var simpleProgram: GLSimpleProgram?
  var blurProgram: GLBlurProgram?
  var effects = [String: NSNumber]()
  var maskBrush: MaskBrush!
  var originalTexture: GLTexture?

  static let maxBlurRadius: Float = 8 + 36 // Maximum of 2 iterations (3 passes)

  private var flattened = false
  private var renderedBlurRadius: Float = 0.0

  override var size: CGSize {
    didSet {
      maskBrush.spinnerScale = size.height / textureSize.height
    }
  }

  var blurRadius: Float {
    return min(effects["BlurRadius"]?.floatValue ?? 0.0, SpinnerSprite.maxBlurRadius)
  }

  override init(image: CGImage, program: GLContentProgram) {
    super.init(image: image, program: program)
    let maskSize = CGSize(width: textureSize.width / 2.0, height: textureSize.height)
    maskBrush = MaskBrush(size: maskSize)
  }

  override internal func afterLoad() {
    renderedBlurRadius = 0.0
    originalTexture = texture
    updateBlur()
  }

  private func updateBlur() {
    if renderedBlurRadius != blurRadius {
      texture = originalTexture
      texture = renderBlurPass()
      renderedBlurRadius = blurRadius
    }
  }

  func flatten() {
    if !flattened {
      texture = renderToTexture()
      originalTexture = nil
      flattened = true
    }
  }

  private func renderBlurPass() -> GLTexture? {
    guard let texture = texture else { return nil }
    guard let blurProgram = blurProgram else { return nil }

    guard blurRadius != 0.0 else { return texture }

    let blurScale: Float = 1.0

    let hDirection = GLKVector2(v: (blurScale / Float(textureSize.width), 0.0))
    let vDirection = GLKVector2(v: (0.0, blurScale / Float(textureSize.height)))
    let quadVertexCount: GLsizei = 4

    GLOffscreenBuffer.bind()

    glColorMask(GLTrue, GLTrue, GLTrue, GLTrue)
    glDisable(GLenum(GL_BLEND))

    glViewport(0, 0, GLsizei(textureSize.width), GLsizei(textureSize.height))

    loadPositionQuad()

    blurProgram.use()
    blurProgram.projectionMatrix = GLKMatrix4MakeOrtho(0, Float(textureSize.width), 0, Float(textureSize.height), -256, 256)
    blurProgram.modelViewMatrix = GLKMatrix4MakeScale(Float(textureSize.width), Float(textureSize.height), 1)

    var blurredTexture = texture

    let blurredFirstPassTexture = GLTexture(format: GL_RGBA, size: textureSize)
    let blurredSecondPassTexture = GLTexture(format: GL_RGBA, size: textureSize)

    var remainingRadius = Int(blurRadius)
    var maxStepRadius = 8
    while remainingRadius > 0 {
      if remainingRadius > maxStepRadius {
        blurProgram.setUniform("u_radius", floatValue: Float(maxStepRadius))
        remainingRadius -= maxStepRadius
        maxStepRadius *= 8
      }
      else {
        blurProgram.setUniform("u_radius", floatValue: Float(remainingRadius))
        remainingRadius = 0
      }

      // horizontal pass
      GLOffscreenBuffer.attachTexture(blurredFirstPassTexture)
      blurProgram.textureName = blurredTexture.id
      blurProgram.setUniform("u_direction", floatVector2Value: hDirection)
      glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, quadVertexCount)

      // vertical pass
      GLOffscreenBuffer.attachTexture(blurredSecondPassTexture)
      blurProgram.textureName = blurredFirstPassTexture.id
      blurProgram.setUniform("u_direction", floatVector2Value: vDirection)
      glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, quadVertexCount)

      blurredTexture = blurredSecondPassTexture
    }

    unloadPositionQuad()

    program.restoreRenderState()

    return blurredTexture
  }

  private func renderToTexture() -> GLTexture {
    GLOffscreenBuffer.bind()

    let flattenedSize = CGSizeMake(textureSize.width / 2.0, textureSize.height)

    let flattenedTexture = GLTexture(format: GL_RGBA, size: flattenedSize)
    GLOffscreenBuffer.attachTexture(flattenedTexture)

    glViewport(0, 0, GLsizei(flattenedSize.width), GLsizei(flattenedSize.height))

    glColorMask(GLTrue, GLTrue, GLTrue, GLTrue)

    glEnable(GLenum(GL_BLEND))
    glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))

    let originalProjectionMatrix = program.projectionMatrix

    program.projectionMatrix = GLKMatrix4MakeOrtho(0, Float(flattenedSize.width), 0, Float(flattenedSize.height), -256, 256)

    loadPositionQuad()

    program.use()
    program.textureName = texture?.id
    program.alpha = alpha
    program.modelViewMatrix = GLKMatrix4MakeScale(Float(flattenedSize.width), Float(flattenedSize.height), 1)
    setSpriteProgramParameters(program)

    glClearColor(0.0, 0.0, 0.0, 0.0)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

    let quadVertexCount: GLsizei = 4
    glDrawArrays(GLenum(GL_TRIANGLE_STRIP), 0, quadVertexCount)

    unloadPositionQuad()

    program.projectionMatrix = originalProjectionMatrix

    program.restoreRenderState()

    return flattenedTexture
  }

  func expand() {
    if flattened {
      texture = nil
      flattened = false
    }
  }

  private func setSpriteProgramParameters(program: GLContentProgram) {
    if !flattened {
      program.setTexture(program.uniformIndex("u_Mask"), textureNumber: 1, textureId: maskBrush.textureId)

      for (name, value) in effects {
        if name == "Temperature" {
          program.setUniform("u_\(name)RGB", floatVector3Value: temperatureToRGB(value.floatValue))
        }
        else if name == "Opacity" {
          program.setUniform("alpha", floatValue: value.floatValue)
        }
        else {
          program.setUniform("u_\(name)", floatValue: value.floatValue)
        }
      }
      program.setUniform("u_flattened", boolValue: false)
    }
    else {
      program.setTexture(program.uniformIndex("u_Mask"), textureNumber: 1, textureId: maskBrush.textureId)
      program.setUniform("u_flattened", boolValue: true)
    }
  }


  override internal func setProgramParameters(program: GLContentProgram) {
    super.setProgramParameters(program)

    setSpriteProgramParameters(program)
  }

  override internal func prepareRender(snapshotting: Bool) {
    updateBlur()
  }

  override internal func renderVisibleProgram() {
    if let simpleProgram = simpleProgram where flattened {
      renderProgram(simpleProgram)
    }
    else {
      super.renderVisibleProgram()
    }
  }

  override internal func renderQuad(snapshotting: Bool) {
    super.renderQuad(snapshotting)

    if snapshotting == false {
      renderHitTestAlpha()
    }
  }

  private func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
  }
  
  private func saturate(value: Float) -> Float {
    return clamp(value, lower: 0.0, upper: 1.0)
  }
  
  private func temperatureToRGB(temperatureInKelvins: Float) -> GLKVector3 {
    var r: Float
    var g: Float
    var b: Float
     
    let temperatureInKelvins = clamp(temperatureInKelvins, lower: 1000.0, upper: 40000.0) / 100.0
    
    if (temperatureInKelvins <= 66.0)
    {
      r = 1.0
      g = saturate(0.39008157876901960784 * log(temperatureInKelvins) - 0.63184144378862745098)
    }
    else
    {
      let t = temperatureInKelvins - 60.0
      r = saturate(1.29293618606274509804 * pow(t, -0.1332047592))
      g = saturate(1.12989086089529411765 * pow(t, -0.0755148492))
    }
    
    if (temperatureInKelvins >= 66.0) {
      b = 1.0
    }
    else if(temperatureInKelvins <= 19.0) {
      b = 0.0
    }
    else {
      b = saturate(0.54320678911019607843 * log(temperatureInKelvins - 10.0) - 1.19625408914)
    }
    
    return GLKVector3(v: (r, g, b))
  }

  private func renderFlattened() {
    if let simpleProgram = simpleProgram {
      renderProgram(simpleProgram)
    }
  }

  private func renderHitTestAlpha() {
    if let hitTestProgram = hitTestProgram {
      glEnable(GLenum(GL_BLEND))
      glBlendFunc(GLenum(GL_ONE), GLenum(GL_ZERO))
      glColorMask(GLFalse, GLFalse, GLFalse, GLTrue)
      renderProgram(hitTestProgram)
    }
  }
}