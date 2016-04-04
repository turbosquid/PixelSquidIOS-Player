//
//  GLProgram.swift
//  PixelSquidIOS-Player
//
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.

import Foundation
import GLKit

//typealias GLInfoFunction = (GLuint, GLenum, inout GLint) -> Void
typealias GLLogFunction = (GLuint, GLsizei, UnsafeMutablePointer<GLsizei>, UnsafeMutablePointer<GLchar>) -> Void
typealias GLInfoFunction = (GLuint, GLenum, UnsafeMutablePointer<GLint>) -> Void

class GLProgram {
  var program: GLuint = 0
  var vertShader: GLuint = 0
  var fragShader: GLuint = 0
  var uniformNameToIndex = [String: GLint]()
  var attributeNameToIndex = [String: GLuint]()
  var restoreRenderState: () -> Void
  
  init(restoreRenderState: () -> Void) {
    self.restoreRenderState = restoreRenderState
    program = glCreateProgram()
  }
  
  init(vertexShaderFilename: String, fragmentShaderFilename: String, restoreRenderState: () -> Void) {
    self.restoreRenderState = restoreRenderState
    program = glCreateProgram()
    loadShaders(vertexShaderFilename, fragmentShaderFilename)
  }
  
  func loadShaders(vertexShaderFilename: String, _ fragmentShaderFilename: String) {
    let vertShaderPathname = NSBundle.mainBundle().pathForResource(vertexShaderFilename, ofType: nil)
    if !compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname!) {
      NSLog("Failed to compile vertex shader")
      NSLog(vertexShaderLog())
    }
    
    let fragShaderPathname = NSBundle.mainBundle().pathForResource(fragmentShaderFilename, ofType: nil)
    if !compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname!) {
      NSLog("Failed to compile fragment shader")
      NSLog(fragmentShaderLog())
    }
    
    glAttachShader(program, vertShader)
    glAttachShader(program, fragShader)
  }

  func setTexture(textureUniform: GLint, textureNumber: GLint, textureId: GLuint) {
    glActiveTexture(GLenum(GL_TEXTURE0 + textureNumber))
    glBindTexture(GLenum(GL_TEXTURE_2D), textureId)
    glUniform1i(textureUniform, textureNumber)
  }

  func setUniform(uniformName: String, floatVector2Value: GLKVector2) {
    var vector = floatVector2Value
    withUnsafeMutablePointer(&vector) { pointer in
      glUniform2fv(uniformIndex(uniformName), 1, UnsafePointer<GLfloat>(pointer))
    }
  }

  func setUniform(uniformName: String, floatVector3Value: GLKVector3) {
    var vector = floatVector3Value
    withUnsafeMutablePointer(&vector) { pointer in
      glUniform3fv(uniformIndex(uniformName), 1, UnsafePointer<GLfloat>(pointer))
    }
  }

  func setUniform(uniformName: String, boolValue: Bool) {
    glUniform1i(uniformIndex(uniformName), GLint(boolValue ? 1 : 0))
  }

  func setUniform(uniformName: String, floatValue: GLfloat) {
    glUniform1f(uniformIndex(uniformName), floatValue)
  }

  func setUniform(uniformIndex: GLint, floatValue: GLfloat) {
    if uniformIndex != GL_INVALID_VALUE {
      glUniform1f(uniformIndex, floatValue)
    }
  }

  private func compileShader(inout shader: GLuint, type: GLenum, file: String) -> Bool {
    var status: GLint = 0
    
    if let source = try? NSString(contentsOfFile: file, encoding: NSUTF8StringEncoding) {
      var sourceUTF8 = source.UTF8String
      var shaderStringLength = GLint(source.length)
      shader = glCreateShader(type)
      glShaderSource(shader, 1, &sourceUTF8, &shaderStringLength)
      glCompileShader(shader)
      glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
      return status == GL_TRUE
    } else {
      NSLog("Failed to load vertex shader")
      return false
    }
  }
  
  func attributeIndex(attributeName: String) -> GLuint {
    if let index = attributeNameToIndex[attributeName] {
      return index
    }
    else {
      let glName = attributeName.cStringUsingEncoding(NSUTF8StringEncoding)!
      let index = GLuint(glGetAttribLocation(program, glName))
      attributeNameToIndex[attributeName] = index
      return index
    }
  }
  
  func uniformIndex(uniformName: String) -> GLint {
    if let index = uniformNameToIndex[uniformName] {
      return index
    }
    else {
      let glName = uniformName.cStringUsingEncoding(NSUTF8StringEncoding)!
      let index = glGetUniformLocation(program, glName)
      uniformNameToIndex[uniformName] = index
      return index
    }
  }
  
  func link() -> Bool {
    var status: GLint = 0
    
    glLinkProgram(program)
    glValidateProgram(program)
    glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
    
    if vertShader != 0 {
      glDeleteShader(vertShader)
      vertShader = 0
    }
    
    if fragShader != 0 {
      glDeleteShader(fragShader)
      fragShader = 0
    }
    
    if status == GL_FALSE {
      NSLog("Failed to link program")
      NSLog(programLog())
      return false
    }
    
    return true
  }
  
  func use() {
    glUseProgram(program)
  }
  
  func logForOpenGLObject(object: GLuint, infoFunc: GLInfoFunction, logFunc: GLLogFunction) -> String {
    var logLength: GLint = 0
    var charsWritten: GLint = 0
    
    infoFunc(object, GLenum(GL_INFO_LOG_LENGTH), &logLength)
    if logLength < 1 {
      return ""
    }
    
    let logBytes = UnsafeMutablePointer<GLchar>.alloc(Int(logLength))
    logFunc(object, logLength, &charsWritten, logBytes)
    return NSString(bytes: logBytes, length: Int(logLength), encoding: NSUTF8StringEncoding) as! String
  }
  
  func vertexShaderLog() -> String {
    return logForOpenGLObject(vertShader, infoFunc: glGetShaderiv, logFunc: glGetShaderInfoLog)
  }
  
  func fragmentShaderLog() -> String {
    return logForOpenGLObject(fragShader, infoFunc: glGetShaderiv, logFunc: glGetShaderInfoLog)
  }
  
  func programLog() -> String {
    return logForOpenGLObject(program, infoFunc: glGetProgramiv, logFunc: glGetProgramInfoLog)
  }
  
  deinit {
    
    if vertShader != 0 {
      glDeleteShader(vertShader)
      vertShader = 0
    }
    
    if fragShader != 0 {
      glDeleteShader(fragShader)
      fragShader = 0
    }
    
    if program != 0 {
      glDeleteProgram(program)
      program = 0
    }
  }
}