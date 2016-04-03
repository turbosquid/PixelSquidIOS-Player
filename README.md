# PixelSquidIOS-Player

This repository contains the player code used in our [PixelSquidIOS](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=0ahUKEwjAv5_9z_LLAhWmloMKHfhDCAsQFggcMAA&url=https%3A%2F%2Fitunes.apple.com%2Fus%2Fapp%2Fpixelsquid-add-3d-objects%2Fid1050150541%3Fmt%3D8&usg=AFQjCNEOjBHPtjayq3UbFe5eG5ujrcnaWQ&bvm=bv.118443451,d.amc) along with the default bundled assets.

While it includes the code for the erase brush and various adjustment filters, those are not enabled through the simplified UI included in this project.

## Getting Started
The easiest way to get started is by looking at `EditorViewController.swift` and `GLEditorViewController.swift`.

The `GLEditorViewController` is derived from the GLKViewController and renders the editable screen using GLKit.  The scene consists of a background image, and an array of spinner objects that may have erase masks and/or filters applied.  While the scene is "owned" by the `GLEditorViewController` it is managed by the `EditorViewController`.

The `EditorViewController` is wired into the Storyboard as the initial UIViewController.  If you were using this project as a base for an application the UI elements and logic pertaining to image editing would end up in this class.  The barebones version of this class just loads an Unsplash background image and then places a single spinner in the scene.


```
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    let frame = view.frame;

    //the frame passed to the GLEditorViewController may be reduced by UI elements in your editor (like toolbars, buttons, etc)
    let glEditorViewController = GLEditorViewController(frame: frame)
    glEditorViewController.preferredFramesPerSecond = 30
    addChildViewController(glEditorViewController)
    view.addSubview(glEditorViewController.view)
    
    //retrieve the scene from the GLEditorViewController
    scene = glEditorViewController.view as! GLEditorScene

    //when backgroundSelectionMode is true, the render loop is paused (this is when you have the camera view or camera roll visible)
    scene.backgroundSelectionMode = false

    //we are loading an image from the asset catalog, but this could be from a camera roll
    scene.loadBackgroundImage(named: "unsplash")
    scene.frame = frame

    //set the scene delegate to receive messages when items are removed or rotated
    scene.editorViewControllerDelegate = self
    glEditorViewController.delegate = scene
    
    //load a spinner
    scene.addSpinner(file: "730336166141761442") {
      spinner in
      
      print("Spinner Added")
    }
  }
```

## Additional Content
The content included in this project is only for testing purposes, you may not use the content in a free or paid app without a signed license agreement.  You can contact [support](mailto:support@pixelsquid.com) to begin the process.  Please include a bit about how you plan to use our content in your app.

With a signed license agreement, most of the content available on [PixelSquid](https://www.pixelsquid.com) can be made available in app.

## Contributing
If you are interested in contributing by either building additional features or fixing bugs, please fork this repository and submit a pull request against our master branch.  We welcome all submissions.  If you want to submit a bug or feature request, please do so through [issues](https://github.com/turbosquid/PixelSquidIOS-Player/issues).


