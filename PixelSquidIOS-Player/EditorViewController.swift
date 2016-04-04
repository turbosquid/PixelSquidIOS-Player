//
//  EditorViewController.swift
//  PixelSquidIOS-Player
//
//  Created by Mark Kurt on 4/2/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import UIKit

class EditorViewController: UIViewController {
  var scene: GLEditorScene!
  var animation: PixelSquidLoadingAnimation!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    let frame = view.frame;

    let glEditorViewController = GLEditorViewController(frame: frame)
    glEditorViewController.preferredFramesPerSecond = 30
    addChildViewController(glEditorViewController)
    view.addSubview(glEditorViewController.view)
    
    scene = glEditorViewController.view as! GLEditorScene
    scene.backgroundSelectionMode = false
    scene.loadBackgroundImage(named: "unsplash")
    scene.frame = frame
    scene.editorViewControllerDelegate = self
    glEditorViewController.delegate = scene
    
    scene.addSpinner(file: "730336166141761442") {
      spinner in
      print("spinner added to scene")
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

extension EditorViewController: EditorViewControllerDelegate {
  func removeContent(content: Spinner) {
    print("called when content is removed from the scene")
  }
  
  func sceneContentCountChanged() {
    print("called when the number of content items displayed in the scene has changed")
  }
  
  func sceneContentChanged() {
    print("called when the scene content has changed - rotated, translated, etc")
  }
}
