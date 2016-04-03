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
      
      print("Spinner Added")
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
    

  /*
  // MARK: - Navigation

  // In a storyboard-based application, you will often want to do a little preparation before navigation
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
  }
  */
}

extension EditorViewController: EditorViewControllerDelegate {
  func removeContent(content: Spinner) {
    print("called when content is removed")
  }
  
  func sceneContentCountChanged() {
    print("called when the number of content items displayed has changed")
  }
  
  func sceneContentChanged() {
    print("called when the scene content has changed - rotated, translated, etc.")
  }
}
