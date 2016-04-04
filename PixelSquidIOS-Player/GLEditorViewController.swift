//
//  GameViewController.swift
//  PixelSquidIOS-Player
//
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.

import GLKit
import OpenGLES


class GLEditorViewController: GLKViewController {
  private var initialFrame = CGRectZero
  
  init(frame: CGRect) {
    super.init(nibName: nil, bundle: nil)
    initialFrame = frame
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func loadView() {
    self.view = GLEditorScene(frame: initialFrame)
  }
}