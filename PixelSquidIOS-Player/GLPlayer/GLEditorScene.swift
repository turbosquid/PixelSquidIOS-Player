//
//  GLEditorScene.swift
//  PixelSquidIOS-Player
//
//  Created by Cory Fabre on 1/12/16.
//  Copyright © 2016 TurboSquid, Inc. All rights reserved.
//

import Foundation
import GLKit

let TertiaryColorRGB = (red: CGFloat(52.0/255.0), green: CGFloat(52.0/255.0), blue: CGFloat(52.0/255.0))
let ToolbarHeight : CGFloat = 0

// MARK: EditorViewControllerDelegate protocol
protocol EditorViewControllerDelegate: class {
  func removeContent(content: Spinner)
  func sceneContentCountChanged()
  func sceneContentChanged()
}

enum ZLocation: String {
  case Front = "to front", Back = "to back", Up = "up", Down = "down"
  static let allValues = [Front, Back, Up, Down]
}

// MARK:
class GLEditorScene: GLKView, GLKViewControllerDelegate {
  weak var editorViewControllerDelegate: EditorViewControllerDelegate?

  typealias BeforeRenderFunc = () -> Void

  private let minZoomSize: CGFloat = 50
  private var beforeRenderFuncs = [BeforeRenderFunc]()

  private var simpleProgram: GLSimpleProgram!
  private var spinnerProgram: GLSpinnerProgram!
  private var hitTestProgram: GLHitTestProgram!
  private var blurProgram: GLBlurProgram!
  private var background: ContentSprite?
  private var watermark: ContentSprite?
  private var loadingAnimation: PixelSquidLoadingAnimation?
  var currentContent: Spinner?
  var backgroundSelectionMode = true
  private var spinners: [Spinner] = []
  private var disableTouches = false
  private var backgroundColorRGB = TertiaryColorRGB
  private var nativeScale: CGFloat = 1
  private var photoSize = CGSizeZero

  private var rotationGestureRecognizer: UIRotationGestureRecognizer!
  private var pinchGestureRecognizer: UIPinchGestureRecognizer!
  private var doubleTouchPanGestureRecognizer: UIPanGestureRecognizer!
  private var singleTouchPanGestureRecognizer: UIPanGestureRecognizer!
  private var singleTapGestureRecognizer: UITapGestureRecognizer!

  private var displayDirty = false
  private var snapshotting = false
  private var screenshotViewport = CGRectZero
  private var screenshotTexture: GLTexture?

  private var viewportRect = CGRectZero

  var zooming = false {
    didSet {
      zoomFrame = viewFrame
      calcView()
    }
  }

  var zoomFrame = CGRectZero {
    didSet {
      calcView()
    }
  }

  var viewFrame: CGRect = CGRectZero {
    didSet {
      calcView()
    }
  }

  var watermarkHidden: Bool {
    get {
      return watermark?.hidden ?? true
    }
    set {
      if watermarkHidden != newValue {
        watermark?.hidden = newValue
        displayDirty = true
      }
    }
  }

  var sceneContentCount: Int {
    return spinners.count
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    let context = EAGLContext(API: .OpenGLES2)
    if context == nil {
      print("Failed to create ES context")
    }

    EAGLContext.setCurrentContext(context)

    self.context = context

    opaque = true

    // Configure renderbuffers created by the view
    drawableColorFormat = .RGBA8888
    drawableDepthFormat = .FormatNone
    drawableStencilFormat = .FormatNone
    drawableMultisample = .MultisampleNone

    setupGL()

    let orthoSize = CGSizeMake(frame.width, frame.height)

    simpleProgram = GLSimpleProgram(orthoSize: orthoSize, restoreRenderState: restoreRenderState)
    spinnerProgram = GLSpinnerProgram(orthoSize: orthoSize, restoreRenderState: restoreRenderState)
    hitTestProgram = GLHitTestProgram(orthoSize: orthoSize, restoreRenderState: restoreRenderState)
    blurProgram = GLBlurProgram(orthoSize: orthoSize, restoreRenderState: restoreRenderState)

    viewFrame = CGRect(origin: CGPointZero, size: frame.size)

    multipleTouchEnabled = true

    loadingAnimation = PixelSquidLoadingAnimation()

    singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(GLEditorScene.singleTapGestureHandler(_:)))
    singleTapGestureRecognizer.numberOfTapsRequired = 1
    singleTapGestureRecognizer.delaysTouchesBegan = false
    singleTapGestureRecognizer.cancelsTouchesInView = true
    addGestureRecognizer(singleTapGestureRecognizer)
    
    rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(GLEditorScene.rotationGestureHandler(_:)))
    rotationGestureRecognizer.delaysTouchesBegan = false
    rotationGestureRecognizer.cancelsTouchesInView = true
    addGestureRecognizer(rotationGestureRecognizer)
    rotationGestureRecognizer.delegate = self
    
    pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(GLEditorScene.pinchGestureHandler(_:)))
    addGestureRecognizer(pinchGestureRecognizer)
    pinchGestureRecognizer.delegate = self
    
    doubleTouchPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(GLEditorScene.doubleTouchPanGestureHandler(_:)))
    doubleTouchPanGestureRecognizer.minimumNumberOfTouches = 2
    doubleTouchPanGestureRecognizer.maximumNumberOfTouches = 2
    doubleTouchPanGestureRecognizer.cancelsTouchesInView = true
    addGestureRecognizer(doubleTouchPanGestureRecognizer)

    singleTouchPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(GLEditorScene.singleTouchPanGestureHandler(_:)))
    singleTouchPanGestureRecognizer.minimumNumberOfTouches = 1
    singleTouchPanGestureRecognizer.maximumNumberOfTouches = 1
    addGestureRecognizer(singleTouchPanGestureRecognizer)
  }
  
  
  // MARK: - GLKit & GL Methods
  func glkViewController(controller: GLKViewController, willPause pause: Bool) {
    if pause == false {
      // Redraw when resuming from pause
      redraw()
    }
  }
  
  func glkViewControllerUpdate(controller: GLKViewController) {
    for spinner in spinners {
      spinner.updateAnimation(controller.timeSinceLastUpdate)
    }
  }
  
  private func drawScene() {
    let (red, green, blue) = backgroundColorRGB
    glColorMask(GLTrue, GLTrue, GLTrue, GLTrue)
    glClearColor(Float(red), Float(green), Float(blue), 1.0)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
    
    background?.render()
    
    if !backgroundSelectionMode {
      for (index, spinner) in spinners.enumerate() {
        spinner.zDepth = Float(index)
        spinner.render(snapshotting)
      }
    }
    
    watermark?.render()
  }
  
  private func callBeforeRenderFuncs() {
    for beforeRender in beforeRenderFuncs {
      beforeRender()
    }
    
    beforeRenderFuncs = []
  }
  
  func restoreRenderState() {
    if snapshotting {
      GLOffscreenBuffer.bind()
      if let screenshotTexture = screenshotTexture {
        GLOffscreenBuffer.attachTexture(screenshotTexture)
      }
      glViewport(GLint(screenshotViewport.minX), GLint(screenshotViewport.minY), GLint(screenshotViewport.width), GLint(screenshotViewport.height))
    }
    else {
      bindDrawable()
      setupViewport()
    }
  }
  
  override func drawRect(rect: CGRect) {
    if displayDirty {
      setupViewport()
      
      drawScene()
      callBeforeRenderFuncs()
      
      displayDirty = false
    }
  }
  
  private func setupViewport() {
    var x: GLsizei, y: GLsizei, width: GLsizei, height: GLsizei

    nativeScale = UIScreen.mainScreen().nativeScale
    if let background = background {
      x = GLsizei((frame.size.width - background.size.width) / 2 * nativeScale)
      y = GLsizei((frame.size.height - background.size.height) / 2 * nativeScale)
      width = GLsizei(background.size.width * nativeScale)
      height = GLsizei(background.size.height * nativeScale)
    } else {
      x = GLsizei(frame.origin.x * nativeScale)
      y = GLsizei(frame.origin.y * nativeScale)
      width = GLsizei(frame.size.width * nativeScale)
      height = GLsizei(frame.size.height * nativeScale)
    }

    viewportRect = CGRectMake(CGFloat(x), CGFloat(y), CGFloat(width), CGFloat(height))
    
    glViewport(x, y, width, height)
  }
  
  private func setupGL() {
    setupViewport()
    
    glEnable(GLenum(GL_BLEND))
  }

  // MARK: - Touch Methods
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if touches.count > 1 {
      return
    }

    if let spinner = currentContent {
      if spinner.isLockedForEditing {
        singleTouchPanGestureRecognizer.enabled = false

        if let touch = touches.first {
          let touchLocation = touch.locationInView(self)
          let spinnerTouchLocation = convertPointToSpinner(touchLocation, spinner: spinner)
          let zoomScale = viewFrame.width / zoomFrame.width
          let viewScale = frame.width / viewFrame.width
          let drawScale: CGFloat = viewScale * zoomScale
          spinner.maskDrawStart(spinnerTouchLocation, atScale: drawScale)
        }
      }
    }
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if touches.count > 1 {
      return
    }

    if let spinner = currentContent {
      if spinner.isLockedForEditing {
        if let touch = touches.first {
          let touchLocation = touch.locationInView(self)
          let spinnerTouchLocation = convertPointToSpinner(touchLocation, spinner: spinner)

          spinner.maskDrawTo(spinnerTouchLocation)
        }
      }
    }
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let spinner = currentContent {
      if spinner.isLockedForEditing {
        if let touch = touches.first where touches.count <= 1 {
          let touchLocation = touch.locationInView(self)
          let spinnerTouchLocation = convertPointToSpinner(touchLocation, spinner: spinner)
          spinner.maskDrawTo(spinnerTouchLocation)
        }
      }

      singleTouchPanGestureRecognizer.enabled = true
      spinner.clearLastTouchLocation()
    }
  }
  
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let spinner = currentContent {
      if spinner.isLockedForEditing {
        spinner.discardLastBrushStroke()
      }
    }
  }
  
  // MARK: - Spinner Interaction

  func enableContentEditorMode() {
    zooming = true
    if let spinner = currentContent {
      spinner.isLockedForEditing = true
    }
  }

  func moveContentZPosition(spinner: Spinner, location: ZLocation) {
    if let index = (spinners.indexOf { $0 === spinner }) {
      switch(location) {
      case .Front:
        spinners.removeAtIndex(index)
        spinners.append(spinner)
      case .Back:
        spinners.removeAtIndex(index)
        spinners.insert(spinner, atIndex: 0)
      case .Up:
        guard index < spinners.count - 1 else {
          return
        }
        spinners.removeAtIndex(index)
        spinners.insert(spinner, atIndex: index + 1)
      case .Down:
        guard index > 0 else {
          return
        }
        spinners.removeAtIndex(index)
        spinners.insert(spinner, atIndex: index - 1)
      }
      displayDirty = true
    }
  }

  func selectNextContent() {
    if spinners.count == 0 { return }
    
    if let spinner = currentContent where spinners.count > 1 {
      for (index, value) in spinners.enumerate() {
        if spinner === value {
          spinner.deselect()
          let newIndex = (index + 1) % spinners.count
          let newSpinner = spinners[newIndex]
          newSpinner.select()
          currentContent = newSpinner
          return
        }
      }
    }
    
    currentContent = spinners.first
    currentContent?.select()
  }

  func removeContent(content: Spinner) {
    content.deselect()
    spinners = spinners.filter { $0 !== content }

    if currentContent === content {
      currentContent = spinners.last
      currentContent?.select()
    }
    
    editorViewControllerDelegate?.sceneContentCountChanged()
    displayDirty = true
  }

  func removeAllContent() {
    spinners = []
    editorViewControllerDelegate?.sceneContentCountChanged()
    displayDirty = true
  }
  
  // MARK: - Image Output

  func toImage() -> UIImage? {
    let previousViewFrame = viewFrame

    snapshotting = true
    let image = flattenedImage()
    snapshotting = false

    viewFrame = previousViewFrame
    
    return image
  }

  private func flattenedImage() -> UIImage? {
    let width = Int(photoSize.width)
    let height = Int(photoSize.height)
    let dataSize = width * height * 4
    var imageData = Array<GLubyte>(count: dataSize, repeatedValue: 0)

    GLOffscreenBuffer.bind()
    screenshotTexture = GLTexture(format: GL_RGBA, size: CGSizeMake(CGFloat(width), CGFloat(height)))
    if let screenshotTexture = screenshotTexture {
      GLOffscreenBuffer.attachTexture(screenshotTexture)
    }
    screenshotViewport = CGRectMake(0, 0, CGFloat(width), CGFloat(height))
    glViewport(0, 0, GLsizei(width), GLsizei(height))

    let originalProjectionMatrix = sceneProjectionMatrix
    let minDepth: Float = -256
    let maxDepth: Float = 256
    let orthoSize = CGSizeMake(frame.width, frame.height)
    sceneProjectionMatrix = GLKMatrix4MakeOrtho(0, Float(orthoSize.width), 0, Float(orthoSize.height), minDepth, maxDepth)

    glClearColor(0.0, 0.0, 0.0, 0.0)
    glClear(GLbitfield(GL_COLOR_BUFFER_BIT))

    drawScene()

    sceneProjectionMatrix = originalProjectionMatrix

    glReadPixels(0, 0, GLsizei(width), GLsizei(height), GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &imageData)

    let colorspace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
    let bitsPerComponent = 8
    let numComponents = 4
    let bitsPerPixel = bitsPerComponent * numComponents
    let bytesPerPixel = bitsPerComponent * numComponents / 8
    let bytesPerRow = bytesPerPixel * width

    let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &imageData, length: dataSize))

    let cgImageMaybe = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorspace, bitmapInfo, providerRef, nil, false, .RenderingIntentDefault)

    screenshotTexture = nil

    restoreRenderState()

    guard let cgImage = cgImageMaybe else { return nil }

    return UIImage(CGImage: cgImage)
  }
  
  // MARK: - Background Image

  func bypassBackgroundImage() {
    loadBackgroundImage(named: "BluePixel")
  }

  func loadBackgroundImage(named name: String, selectionMode: Bool = false, forceFullFrame: Bool = false) {
    if let uiImage = UIImage(named: name) {
      loadBackgroundImage(uiImage: uiImage, selectionMode: selectionMode, forceFullFrame: forceFullFrame)
    }
  }

  func loadBackgroundImage(image image: CGImage, selectionMode: Bool = false, forceFullFrame: Bool = false) {
    backgroundSelectionMode = selectionMode
    background = ContentSprite(image: image, program: simpleProgram)
    guard let background = background else { return }

    photoSize = background.size

    if forceFullFrame {
      viewFrame = CGRect(origin: CGPointZero, size: CGSize(width: frame.size.width, height: frame.size.height))
      background.size = frame.size
      background.position = CGPointMake(frame.size.width / 2, frame.size.height / 2)
    } else {
      var frameToBackgroundRatio = frame.size.width / background.size.width
      
      if background.size.height * frameToBackgroundRatio >= frame.size.height {
        frameToBackgroundRatio = frame.size.height / background.size.height
        background.size.height = frame.size.height
        background.size.width *= frameToBackgroundRatio
        viewFrame = CGRect(origin: CGPoint(x: frame.size.width / 2 - background.size.width / 2, y: viewFrame.origin.y) , size: background.size)
        background.position = CGPointMake(frame.size.width / 2, viewFrame.size.height / 2)
      } else {
        background.size.width = frame.size.width
        background.size.height *= frameToBackgroundRatio
        viewFrame = CGRect(origin: CGPointZero, size: background.size)
        background.position = CGPointMake(viewFrame.size.width / 2, viewFrame.size.height / 2)
      }
    }

    background.zDepth = -100
    
    addWatermark()
    zooming = false
    zoomFrame = CGRectZero
    displayDirty = true
  }

  func loadBackgroundImage(uiImage uiImage: UIImage, selectionMode: Bool = false, forceFullFrame: Bool = false) {
    if let image = uiImage.CGImage {
      loadBackgroundImage(image: image, selectionMode: selectionMode, forceFullFrame: forceFullFrame)
    }
  }
  
  // MARK: - Animations

  func showLoadingAnimation() {
    loadingAnimation?.addToScene(self)
  }

  func hideLoadingAnimation() {
    loadingAnimation?.removeFromScene(false)
  }

  /**
  Clears the entire scene contents for memory management purposes
  **/
  func clearScene() {
    currentContent = nil
    spinners = []
    background = nil
    watermark = nil
    loadingAnimation?.removeFromScene(true)
    loadingAnimation = nil
    zooming = false
  }

  // MARK: - Erase & effects methods
  
  /**
  Updates the specified effect value
  **/
  func updateEffect(name: String, value: NSNumber) {
    if let spinner = currentContent {
      spinner.updateEffect(named: name, value: value)
    }
  }

  /**
  Resets the current effects to the last saved state
  **/
  func undoEffects() {
    if let spinner = currentContent {
      spinner.undoEffects()
    }
  }

  /** 
  Saves the current effects
  **/
  func saveEffects(effects: [SpinnerEffect]) {
    if let spinner = currentContent {
      spinner.effects = effects
    }
  }
  
  func discardLastBrushStroke() {
    currentContent?.discardLastBrushStroke()
  }

  func discardBrushStrokes() {
    currentContent?.discardBrushStrokes()
  }

  func saveBrushStrokes() {
    currentContent?.saveBrushStrokes()
  }

  func updateBrushType(type: MaskBrushType) {
    currentContent?.updateBrushType(type)
  }

  func updateBrushSize(radius: CGFloat) {
    currentContent?.updateBrushSize(radius)
  }
  
  // MARK: - Spinner Loading
  private func spinnerLoaded(spinner: Spinner) {
    if let current = currentContent {
      current.deselect()
    }
    currentContent = spinner
    spinner.select()
    displayDirty = true
    hideLoadingAnimation()
    editorViewControllerDelegate?.sceneContentCountChanged()
  }

  typealias addSpinnerCompletionHandler = (error: NSError?, spinner: Spinner) -> Void

  func addSpinner(url url: NSURL, complete: addSpinnerCompletionHandler? = nil) -> Spinner? {
    showLoadingAnimation()

    let image = GLKSpinnerImage(program: spinnerProgram)
    image.hitTestProgram = hitTestProgram
    image.simpleProgram = simpleProgram
    image.blurProgram = blurProgram

    let spinner = Spinner(parentFrame: viewFrame, image: image)
    spinner.sceneDelegate = self
    spinners.append(spinner)
    spinner.load(videoUrl: url) { [weak self] (success, error) in
      self?.spinnerLoaded(spinner)
      complete?(error: error, spinner: spinner)
    }
    return spinner
  }

  typealias SpinnerCompleteFunc = (spinner: Spinner?) -> Void
  func addSpinner(asset asset: PixelSquidAsset, complete: addSpinnerCompletionHandler? = nil) -> Spinner? {
    if let url = asset.localVideoUrl {
      let spinner = addSpinner(url: url) { error, spinner in
        complete?(error: error, spinner: spinner)
      }
      return spinner
    }
    return nil
  }

  func addSpinner(file file: String, complete: addSpinnerCompletionHandler? = nil) -> Spinner? {
    if let url = NSBundle.mainBundle().URLForResource(file, withExtension: "mp4") {
      return addSpinner(url: url, complete: complete)
    }

    return nil
  }
  
  // MARK: - Gestures
  func singleTapGestureHandler(recognizer: UIPanGestureRecognizer) {
    if recognizer.state == .Ended {
      let touchLocation = recognizer.locationInView(recognizer.view)
      spinnerAtPoint(touchLocation) { [weak self] selectedContent in
        if let selectedContent = selectedContent {
          self?.selectContent(selectedContent)
        }
      }
    }
  }
  
  func singleTouchPanGestureHandler(recognizer: UIPanGestureRecognizer) {
    if !zooming {
      if let currentContent = currentContent {
        switch recognizer.state {
        case .Changed:
          currentContent.spin(recognizer.translationInView(self))
          editorViewControllerDelegate?.sceneContentChanged()
        default:
          break // ignore other states
        }
      }
    }
    recognizer.setTranslation(CGPointZero, inView: self)
  }

  func doubleTouchPanGestureHandler(recognizer: UIPanGestureRecognizer) {
    if zooming {
      let zoomScale = viewFrame.width / zoomFrame.width
      let translation = recognizer.translationInView(self)
      let transform = CGAffineTransformMakeTranslation(-translation.x / zoomScale, -translation.y / zoomScale)
      let newZoomFrame = CGRectApplyAffineTransform(zoomFrame, transform)
      zoomFrame = constrainZoomFrame(newZoomFrame, originalZoomFrame: zoomFrame)
    }
    else {
      let viewScale: CGFloat = viewFrame.width / frame.width
      let translationPoint = recognizer.translationInView(self)
      let scaledPoint = CGPointMake(translationPoint.x * viewScale, translationPoint.y * viewScale)
      currentContent?.drag(scaledPoint)
      editorViewControllerDelegate?.sceneContentChanged()
    }
    
    recognizer.setTranslation(CGPointZero, inView: self)
  }
  
  func rotationGestureHandler(recognizer: UIRotationGestureRecognizer) {
    if !zooming {
      if let currentContent = currentContent {
        currentContent.rotation += recognizer.rotation
        editorViewControllerDelegate?.sceneContentChanged()
      }
    }
    
    if recognizer.state != UIGestureRecognizerState.Ended {
      recognizer.rotation = 0.0
    }
  }
  
  func pinchGestureHandler(recognizer: UIPinchGestureRecognizer) {
    if recognizer.state != UIGestureRecognizerState.Ended {
      if zooming {
        let scale = 1 / recognizer.scale

        let currentZoomScale = zoomFrame.width / viewFrame.width
        
        let hRatio = viewFrame.height / frame.size.height
        let wRatio = viewFrame.width / frame.size.width

        let locationInView = recognizer.locationInView(self)

        let zoomX = zoomFrame.minX + (locationInView.x * currentZoomScale * wRatio)
        let zoomY = zoomFrame.minY + (locationInView.y * currentZoomScale * hRatio)

        var transform = CGAffineTransformMakeTranslation(zoomX, zoomY)
        transform = CGAffineTransformScale(transform, scale, scale)
        transform = CGAffineTransformTranslate(transform, -zoomX, -zoomY)

        let newZoomFrame = CGRectApplyAffineTransform(zoomFrame, transform)

        zoomFrame = constrainZoomFrame(newZoomFrame, originalZoomFrame: zoomFrame)

        recognizer.scale = 1.0
      } else {
        if let currentContent = currentContent {
          if recognizer.state == UIGestureRecognizerState.Began {
            recognizer.scale = CGFloat(currentContent.scale)
          }
          currentContent.scale = recognizer.scale
          editorViewControllerDelegate?.sceneContentChanged()
        }
      }
    }
  }
  
  // MARK: - Private Methods
  private func beforeNextRender(forceRedraw forceRedraw: Bool, beforeRender: BeforeRenderFunc) {
    if forceRedraw {
      displayDirty = true
    }
    beforeRenderFuncs.append(beforeRender)
  }
  
  private func findSpinnerUsingFramebufferAlpha(point: CGPoint) -> Spinner? {
    let x = GLsizei(point.x * nativeScale)
    let y = GLsizei((frame.height - point.y) * nativeScale)
    var rgba = Array<GLubyte>(count: 4, repeatedValue: 0)
    
    glReadPixels(x, y, 1, 1, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), &rgba)
    
    // glReadPixels causes a buffer swap so we have to redraw
    redraw()
    
    let index = Int(rgba[3])
    return spinners.indices ~= index ? spinners[index] : nil
  }
  
  private func constrainZoomFrame(newZoomFrame: CGRect, originalZoomFrame: CGRect) -> CGRect {
    var offset = CGPointZero
    let minSize = min(newZoomFrame.height, newZoomFrame.width)
    let scale = minSize / min(viewFrame.height, viewFrame.width)

    // viewFrame.maxY = vf.origin.y + vf.height, but vf.origin.y is always 0.
    // Therefore a more accurate value must be calculated using the frame height
    // and viewFrame heights, plus offsets (like the ToolbarHeight for the slider).
    var adjustedMaxY = viewFrame.maxY
    if viewFrame.height > frame.size.height - 2 * ToolbarHeight {
      adjustedMaxY += ((scale / 2) * (viewFrame.height - frame.size.height + 2 * ToolbarHeight))
    }
    
    var calibratedNewZoomFrame = newZoomFrame

    if newZoomFrame.width > viewFrame.width || newZoomFrame.height > viewFrame.height {
      calibratedNewZoomFrame = originalZoomFrame
    }
    else if minSize < minZoomSize {
      calibratedNewZoomFrame = originalZoomFrame
    }

    if calibratedNewZoomFrame.minX < viewFrame.minX {
      offset.x = viewFrame.minX - calibratedNewZoomFrame.minX
    }
    else if calibratedNewZoomFrame.maxX > viewFrame.maxX {
      offset.x = viewFrame.maxX - calibratedNewZoomFrame.maxX
    }

    if calibratedNewZoomFrame.minY < viewFrame.minY {
      offset.y = viewFrame.minY - calibratedNewZoomFrame.minY
    }
    else if calibratedNewZoomFrame.maxY > adjustedMaxY {
      offset.y = adjustedMaxY - calibratedNewZoomFrame.maxY
    }

    return CGRectOffset(calibratedNewZoomFrame, offset.x, offset.y)
  }
  
  private func getZoomedViewFrame() -> CGRect {
    if zooming {
      return zoomFrame
    }
    else {
      return viewFrame
    }
  }
  
  private var sceneProjectionMatrix: GLKMatrix4? {
    set {
      simpleProgram.projectionMatrix = newValue
      spinnerProgram.projectionMatrix = newValue
      hitTestProgram.projectionMatrix = newValue
    }
    get {
      return simpleProgram.projectionMatrix
    }
  }
  
  private func calcView() {
    let zoomedViewFrame = getZoomedViewFrame()
    simpleProgram.viewFrame = zoomedViewFrame
    spinnerProgram.viewFrame = zoomedViewFrame
    hitTestProgram.viewFrame = zoomedViewFrame
    displayDirty = true
  }
  
  private func spinnerAtPoint(point: CGPoint, complete: ((Spinner?) -> Void)) {
    beforeNextRender(forceRedraw: true) { [weak self] in
      complete(self?.findSpinnerUsingFramebufferAlpha(point))
    }
  }
  
  private func selectContent(selectedContent: Spinner) {
    if currentContent != nil {
      if currentContent!.isLockedForEditing && currentContent === selectedContent {
        return
      }
    }
    
    if selectedContent !== currentContent {
      currentContent?.deselect()
      currentContent = selectedContent
    }
    currentContent?.select()
  }
  
  private func addWatermark() {
    let uiImage = UIImage(named: "ps_logo_light")
    if let image = uiImage?.CGImage {
      let watermark = ContentSprite(image: image, program: simpleProgram)
      let padding: CGFloat = 10
      let widthScale: CGFloat = 0.25
      let ratio = watermark.size.height / watermark.size.width
      let scaledWidth = viewFrame.size.width * widthScale
      watermark.size = CGSizeMake(scaledWidth, scaledWidth * ratio)
      let x = viewFrame.size.width - (watermark.size.width / 2) - padding
      let y = viewFrame.size.height - (watermark.size.height / 2) - padding
      watermark.position = CGPointMake(x, y)
      watermark.premultipliedTexture = true
      watermark.alpha = 0.3
      self.watermark = watermark
    }
  }
  
  private func convertPointToSpinner(point: CGPoint, spinner: Spinner) -> CGPoint {
    let viewRect = CGRectMake(viewportRect.minX / nativeScale, viewportRect.minY / nativeScale, viewportRect.width / nativeScale, viewportRect.height / nativeScale)
    return spinner.translatePoint(point, viewRect: viewRect)
  }

}

// MARK: - UIGestureRecognizerDelegate
extension GLEditorScene: UIGestureRecognizerDelegate {
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {

    let spinning = [gestureRecognizer, otherGestureRecognizer].contains(singleTouchPanGestureRecognizer)
    return zooming || !spinning
  }
}

// MARK: - SpinnerSceneDelegate
extension GLEditorScene: SpinnerSceneDelegate {
  func removeContentFromScene(content: Spinner) {
    editorViewControllerDelegate?.removeContent(content)
  }
  
  func disableInteractions() {
    disableTouches = true
  }
  
  func enableInteractions() {
    disableTouches = false
  }

  func redraw() {
    displayDirty = true
  }
}