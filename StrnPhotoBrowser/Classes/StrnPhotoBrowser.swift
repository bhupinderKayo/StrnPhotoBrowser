//
//  StrnPhotoBrowser.swift
//  StrnViewExample
//
//

import UIKit

public let StrnPHOTO_LOADING_DID_END_NOTIFICATION = "photoLoadingDidEndNotification"

// MARK: - StrnPhotoBrowser
open class StrnPhotoBrowser: UIViewController {
    
    let pageIndexTagOffset: Int = 1000
    
    fileprivate var _topView: UIView!
    
    fileprivate var closeButton: StrnCloseButton!
    fileprivate var deleteButton: StrnDeleteButton!
    fileprivate var toolbar: StrnToolbar!
    
    // actions
    fileprivate var activityViewController: UIActivityViewController!
    open var activityItemProvider: UIActivityItemProvider? = nil
    fileprivate var panGesture: UIPanGestureRecognizer!
    
    // tool for controls
    fileprivate var applicationWindow: UIWindow!
    fileprivate lazy var pagingScrollView: StrnPagingScrollView = StrnPagingScrollView(frame: self.view.frame, browser: self)
    var backgroundView: UIView!
    
    var initialPageIndex: Int = 0
    var currentPageIndex: Int = 0
    
    var titleText = ""
    
    // for status check property
    fileprivate var isEndAnimationByToolBar: Bool = true
    fileprivate var isViewActive: Bool = false
    fileprivate var isPerformingLayout: Bool = false
    
    // pangesture property
    fileprivate var firstX: CGFloat = 0.0
    fileprivate var firstY: CGFloat = 0.0
    
    // timer
    fileprivate var controlVisibilityTimer: Timer!
    
    // delegate
    fileprivate let animator = StrnAnimator()
    open weak var delegate: StrnPhotoBrowserDelegate?
    
    // photos
    var photos: [StrnPhotoProtocol] = [StrnPhotoProtocol]()
    var numberOfPhotos: Int {
        return photos.count
    }
    
    // statusbar initial state
    private var statusbarHidden: Bool = UIApplication.shared.isStatusBarHidden
    
    // MARK - Initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nil, bundle: nil)
        setup()
    }
    
    public convenience init(photos: [StrnPhotoProtocol], _titleText: String) {
        self.init(nibName: nil, bundle: nil)
        let pictures = photos.flatMap { $0 }
        for photo in pictures {
            photo.checkCache()
            self.photos.append(photo)
        }
        titleText = _titleText
    }
    
    public convenience init(originImage: UIImage, photos: [StrnPhotoProtocol], animatedFromView: UIView) {
        self.init(nibName: nil, bundle: nil)
        animator.senderOriginImage = originImage
        animator.senderViewForAnimation = animatedFromView
        
        let pictures = photos.flatMap { $0 }
        for photo in pictures {
            photo.checkCache()
            self.photos.append(photo)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func setup() {
        if let window = UIApplication.shared.delegate?.window {
            applicationWindow = window
        }else if let window = UIApplication.shared.keyWindow {
            applicationWindow = window
        }else {
            return
        }
        
        modalPresentationCapturesStatusBarAppearance = true
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleStrnPhotoLoadingDidEndNotification(_:)), name: NSNotification.Name(rawValue: StrnPHOTO_LOADING_DID_END_NOTIFICATION), object: nil)
    }
    
    // MARK: - override
    
    //
    // MARK:- Hide statusbar
    override open var prefersStatusBarHidden: Bool {
        return true
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        configureAppearance()
        configureCloseButton()
        configureDeleteButton()
        configureToolbar()
        
        animator.willPresent(self)
    }
    
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        reloadData()
        
        var i = 0
        for photo: StrnPhotoProtocol in photos {
            photo.index = i
            i = i + 1
        }
    }
    
    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        isPerformingLayout = true
        
        //        closeButton.updateFrame()
        deleteButton.updateFrame()
        pagingScrollView.updateFrame(view.bounds, currentPageIndex: currentPageIndex)
        
        toolbar.frame = frameForToolbarAtOrientation()
        
        // where did start
        delegate?.didShowPhotoAtIndex?(currentPageIndex)
        
        isPerformingLayout = false
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        isViewActive = true
    }
    
    // MARK: - Notification
    open func handleStrnPhotoLoadingDidEndNotification(_ notification: Notification) {
        guard let photo = notification.object as? StrnPhotoProtocol else {
            return
        }
        
        DispatchQueue.main.async(execute: {
            guard let page = self.pagingScrollView.pageDisplayingAtPhoto(photo), let photo = page.photo else {
                return
            }
            
            if photo.underlyingImage != nil {
                page.displayImage(complete: true)
                self.loadAdjacentPhotosIfNecessary(photo)
            } else {
                page.displayImageFailure()
            }
        })
    }
    
    open func loadAdjacentPhotosIfNecessary(_ photo: StrnPhotoProtocol) {
        pagingScrollView.loadAdjacentPhotosIfNecessary(photo, currentPageIndex: currentPageIndex)
    }
    
    // MARK: - initialize / setup
    open func reloadData() {
        performLayout()
        view.setNeedsLayout()
    }
    
    open func performLayout() {
        isPerformingLayout = true
        
        toolbar.updateToolbar(currentPageIndex)
        
        // reset local cache
        pagingScrollView.reload()
        
        // reframe
        pagingScrollView.updateContentOffset(currentPageIndex)
        pagingScrollView.tilePages()
        
        delegate?.didShowPhotoAtIndex?(currentPageIndex)
        
        isPerformingLayout = false
    }
    
    open func prepareForClosePhotoBrowser() {
        cancelControlHiding()
        applicationWindow.removeGestureRecognizer(panGesture)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }
    
    open func dismissPhotoBrowser(animated: Bool, completion: ((Void) -> Void)? = nil) {
        prepareForClosePhotoBrowser()
        
        if !animated {
            modalTransitionStyle = .crossDissolve
        }
        
        dismiss(animated: !animated) {
            completion?()
            self.delegate?.didDismissAtPageIndex?(self.currentPageIndex)
        }
    }
    
    open func determineAndClose() {
        delegate?.willDismissAtPageIndex?(currentPageIndex)
        animator.willDismiss(self)
    }
}

// MARK: - Public Function For Customizing Buttons

public extension StrnPhotoBrowser {
    func updateCloseButton(_ image: UIImage, size: CGSize? = nil) {
        if closeButton == nil {
            configureCloseButton()
        }
        closeButton.setImage(image, for: UIControlState())
        
        //if let size = size {
            //            closeButton.setFrameSize(size)
        //}
    }
    
    func updateDeleteButton(_ image: UIImage, size: CGSize? = nil) {
        if deleteButton == nil {
            configureDeleteButton()
        }
        deleteButton.setImage(image, for: UIControlState())
        
        if let size = size {
            deleteButton.setFrameSize(size)
        }
    }
}

// MARK: - Public Function For Browser Control

public extension StrnPhotoBrowser {
    func initializePageIndex(_ index: Int) {
        var i = index
        if index >= numberOfPhotos {
            i = numberOfPhotos - 1
        }
        
        initialPageIndex = i
        currentPageIndex = i
        
        if isViewLoaded {
            jumpToPageAtIndex(index)
            if !isViewActive {
                pagingScrollView.tilePages()
            }
        }
    }
    
    func jumpToPageAtIndex(_ index: Int) {
        if index < numberOfPhotos {
            if !isEndAnimationByToolBar {
                return
            }
            isEndAnimationByToolBar = false
            toolbar.updateToolbar(currentPageIndex)
            
            let pageFrame = frameForPageAtIndex(index)
            pagingScrollView.animate(pageFrame)
        }
        hideControlsAfterDelay()
    }
    
    func photoAtIndex(_ index: Int) -> StrnPhotoProtocol {
        return photos[index]
    }
    
    func gotoPreviousPage() {
        jumpToPageAtIndex(currentPageIndex - 1)
    }
    
    func gotoNextPage() {
        jumpToPageAtIndex(currentPageIndex + 1)
    }
    
    func cancelControlHiding() {
        if controlVisibilityTimer != nil {
            controlVisibilityTimer.invalidate()
            controlVisibilityTimer = nil
        }
    }
    
    func hideControlsAfterDelay() {
        // reset
        cancelControlHiding()
        // start
        controlVisibilityTimer = Timer.scheduledTimer(timeInterval: 4.0, target: self, selector: #selector(StrnPhotoBrowser.hideControls(_:)), userInfo: nil, repeats: false)
    }
    
    func hideControls() {
        setControlsHidden(true, animated: true, permanent: false)
        //        setControlsHidden(false, animated: true, permanent: false)
    }
    
    func hideControls(_ timer: Timer) {
        hideControls()
        delegate?.controlsVisibilityToggled?(hidden: true)
    }
    
    func toggleControls() {
        let hidden = !areControlsHidden()
        setControlsHidden(hidden, animated: true, permanent: false)
        //        setControlsHidden(false, animated: true, permanent: false)
        delegate?.controlsVisibilityToggled?(hidden: areControlsHidden())
    }
    
    func areControlsHidden() -> Bool {
        //        return false
        return toolbar.alpha == 0.0
    }
    
    func popupShare(includeCaption: Bool = true) {
        let photo = photos[currentPageIndex]
        guard let underlyingImage = photo.underlyingImage else {
            return
        }
        
        var activityItems: [AnyObject] = [underlyingImage]
        if photo.caption != nil && includeCaption {
            if let shareExtraCaption = StrnPhotoBrowserOptions.shareExtraCaption {
                let caption = photo.caption + shareExtraCaption
                activityItems.append(caption as AnyObject)
            } else {
                activityItems.append(photo.caption as AnyObject)
            }
        }
        
        if let activityItemProvider = activityItemProvider {
            activityItems.append(activityItemProvider)
        }
        
        activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = {
            (activity, success, items, error) in
            self.hideControlsAfterDelay()
            self.activityViewController = nil
        }
        if UI_USER_INTERFACE_IDIOM() == .phone {
            present(activityViewController, animated: true, completion: nil)
        } else {
            activityViewController.modalPresentationStyle = .popover
            let popover: UIPopoverPresentationController! = activityViewController.popoverPresentationController
            popover.barButtonItem = toolbar.toolActionButton
            present(activityViewController, animated: true, completion: nil)
        }
    }
    
    func getCurrentPageIndex() -> Int {
        return currentPageIndex
    }
}


// MARK: - Internal Function

internal extension StrnPhotoBrowser {
    func showButtons() {
        if StrnPhotoBrowserOptions.displayCloseButton {
            closeButton.alpha = 1
            //            closeButton.frame = closeButton.showFrame
            closeButton.frame = CGRect(x: 0, y: 0, width: ((self.view.frame.size.height) * 0.0824), height: ((self.view.frame.size.height) * 0.0824))
            _topView.alpha = 1
            _topView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: ((self.view.frame.size.height) * 0.0824))
        }
        if StrnPhotoBrowserOptions.displayDeleteButton {
            deleteButton.alpha = 1
            deleteButton.frame = deleteButton.showFrame
        }
    }
    
    func pageDisplayedAtIndex(_ index: Int) -> StrnZoomingScrollView? {
        return pagingScrollView.pageDisplayedAtIndex(index)
    }
    
    func getImageFromView(_ sender: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(sender.frame.size, true, 0.0)
        sender.layer.render(in: UIGraphicsGetCurrentContext()!)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
}

// MARK: - Internal Function For Frame Calc

internal extension StrnPhotoBrowser {
    func frameForToolbarAtOrientation() -> CGRect {
        let currentOrientation = UIApplication.shared.statusBarOrientation
        var height: CGFloat = navigationController?.navigationBar.frame.size.height ?? 44
        if UIInterfaceOrientationIsLandscape(currentOrientation) {
            height = 32
        }
        return CGRect(x: 0, y: view.bounds.size.height - height, width: view.bounds.size.width, height: height)
    }
    
    func frameForToolbarHideAtOrientation() -> CGRect {
        let currentOrientation = UIApplication.shared.statusBarOrientation
        var height: CGFloat = navigationController?.navigationBar.frame.size.height ?? 44
        if UIInterfaceOrientationIsLandscape(currentOrientation) {
            height = 32
        }
        return CGRect(x: 0, y: view.bounds.size.height + height, width: view.bounds.size.width, height: height)
    }
    
    func frameForPageAtIndex(_ index: Int) -> CGRect {
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= (2 * 10)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + 10
        return pageFrame
    }
}

// MARK: - Internal Function For Button Pressed, UIGesture Control

internal extension StrnPhotoBrowser {
    func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
        guard let zoomingScrollView: StrnZoomingScrollView = pagingScrollView.pageDisplayedAtIndex(currentPageIndex) else {
            return
        }
        
        backgroundView.isHidden = true
        
        let viewHeight: CGFloat = zoomingScrollView.frame.size.height
        let viewHalfHeight: CGFloat = viewHeight/2
        var translatedPoint: CGPoint = sender.translation(in: self.view)
        
        // gesture began
        if sender.state == .began {
            firstX = zoomingScrollView.center.x
            firstY = zoomingScrollView.center.y
            
            hideControls()
            setNeedsStatusBarAppearanceUpdate()
        }
        
        translatedPoint = CGPoint(x: firstX, y: firstY + translatedPoint.y)
        zoomingScrollView.center = translatedPoint
        
        let minOffset: CGFloat = viewHalfHeight / 4
        let offset: CGFloat = 1 - (zoomingScrollView.center.y > viewHalfHeight
            ? zoomingScrollView.center.y - viewHalfHeight
            : -(zoomingScrollView.center.y - viewHalfHeight)) / viewHalfHeight
        
        view.backgroundColor = UIColor.black.withAlphaComponent(max(0.7, offset))
        
        // gesture end
        if sender.state == .ended {
            
            if zoomingScrollView.center.y > viewHalfHeight + minOffset
                || zoomingScrollView.center.y < viewHalfHeight - minOffset {
                
                backgroundView.backgroundColor = view.backgroundColor
                determineAndClose()
                
            } else {
                // Continue Showing View
                setNeedsStatusBarAppearanceUpdate()
                
                let velocityY: CGFloat = CGFloat(0.35) * sender.velocity(in: self.view).y
                let finalX: CGFloat = firstX
                let finalY: CGFloat = viewHalfHeight
                
                let animationDuration: Double = Double(abs(velocityY) * 0.0002 + 0.2)
                
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(animationDuration)
                UIView.setAnimationCurve(UIViewAnimationCurve.easeIn)
                view.backgroundColor = UIColor.black
                zoomingScrollView.center = CGPoint(x: finalX, y: finalY)
                UIView.commitAnimations()
            }
        }
    }
    
    func deleteButtonPressed(_ sender: UIButton) {
        delegate?.removePhoto?(self, index: currentPageIndex) { [weak self] in
            self?.deleteImage()
        }
    }
    
    func closeButtonPressed(_ sender: UIButton) {
        determineAndClose()
    }
    
    func actionButtonPressed(ignoreAndShare: Bool) {
        delegate?.willShowActionSheet?(currentPageIndex)
        
        guard numberOfPhotos > 0 else {
            return
        }
        
        if let titles = StrnPhotoBrowserOptions.actionButtonTitles {
            let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            }))
            for idx in titles.indices {
                actionSheetController.addAction(UIAlertAction(title: titles[idx], style: .default, handler: { (action) -> Void in
                    self.delegate?.didDismissActionSheetWithButtonIndex?(idx, photoIndex: self.currentPageIndex)
                }))
            }
            
            if UI_USER_INTERFACE_IDIOM() == .phone {
                present(actionSheetController, animated: true, completion: nil)
            } else {
                actionSheetController.modalPresentationStyle = .popover
                
                if let popoverController = actionSheetController.popoverPresentationController {
                    popoverController.sourceView = self.view
                    popoverController.barButtonItem = toolbar.toolActionButton
                }
                
                present(actionSheetController, animated: true, completion: { () -> Void in
                })
            }
            
        } else {
            popupShare()
        }
    }
}

// MARK: - Private Function
private extension StrnPhotoBrowser {
    func configureAppearance() {
        view.backgroundColor = UIColor.black
        view.clipsToBounds = true
        view.isOpaque = false
        
        backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: StrnMesurement.screenWidth, height: StrnMesurement.screenHeight))
        backgroundView.backgroundColor = UIColor.black
        backgroundView.alpha = 0.0
        applicationWindow.addSubview(backgroundView)
        
        pagingScrollView.delegate = self
        view.addSubview(pagingScrollView)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(StrnPhotoBrowser.panGestureRecognized(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        if !StrnPhotoBrowserOptions.disableVerticalSwipe {
            view.addGestureRecognizer(panGesture)
        }
    }
    
    func configureCloseButton() {
        
        _topView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: ((self.view.frame.size.height) * 0.0824)))
        _topView.backgroundColor = UIColor(red: 118/255, green: 164/255, blue: 22/255, alpha: 1)
        
        let lblTitle = UILabel(frame: _topView.frame)
        lblTitle.frame.size.width = _topView.frame.size.width * 0.664
        lblTitle.center = _topView.center
        lblTitle.text = titleText
        lblTitle.font = StrnPhotoBrowserOptions.titleFont
        lblTitle.adjustsFontSizeToFitWidth = true
        lblTitle.textColor = .white
        lblTitle.textAlignment = .center
        
        _topView.addSubview(lblTitle)
        view.addSubview(_topView)
        
        closeButton = StrnCloseButton(frame: CGRect(x: 0, y: 0, width: ((self.view.frame.size.height) * 0.0824), height: ((self.view.frame.size.height) * 0.0824)))
        closeButton.addTarget(self, action: #selector(closeButtonPressed(_:)), for: .touchUpInside)
        closeButton.isHidden = !StrnPhotoBrowserOptions.displayCloseButton
        _topView.addSubview(closeButton)
    }
    
    func configureDeleteButton() {
        deleteButton = StrnDeleteButton(frame: .zero)
        deleteButton.addTarget(self, action: #selector(deleteButtonPressed(_:)), for: .touchUpInside)
        deleteButton.isHidden = !StrnPhotoBrowserOptions.displayDeleteButton
        view.addSubview(deleteButton)
    }
    
    func configureToolbar() {
        toolbar = StrnToolbar(frame: frameForToolbarAtOrientation(), browser: self)
        view.addSubview(toolbar)
    }
    
    func setControlsHidden(_ hidden: Bool, animated: Bool, permanent: Bool) {
        cancelControlHiding()
        
        //        let captionViews = pagingScrollView.getCaptionViews()
        
        
        UIView.animate(withDuration: 0.35,
                       animations: { () -> Void in
                        let alpha: CGFloat = hidden ? 0.0 : 1.0
                        self.toolbar.alpha = alpha
                        self.toolbar.frame = hidden ? self.frameForToolbarHideAtOrientation() : self.frameForToolbarAtOrientation()
                        
                        /*
                         if StrnPhotoBrowserOptions.displayCloseButton {
                         //                    self.closeButton.alpha = alpha
                         //                    self.closeButton.frame = hidden ? self.closeButton.hideFrame : self.closeButton.showFrame
                         self._topView.alpha = alpha
                         if hidden {
                         self.closeButton.frame.size.height = 0
                         self._topView.frame.size.height = 0
                         } else {
                         self.closeButton.frame = CGRect(x: 0, y: 0, width: ((self.view.frame.size.height) * 0.0824), height: ((self.view.frame.size.height) * 0.0824))
                         self._topView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: ((self.view.frame.size.height) * 0.0824))
                         }
                         }*/
                        if StrnPhotoBrowserOptions.displayDeleteButton {
                            self.deleteButton.alpha = alpha
                            self.deleteButton.frame = hidden ? self.deleteButton.hideFrame : self.deleteButton.showFrame
                        }
                        //                captionViews.forEach { $0.alpha = alpha }
                        //                captionViews.forEach { $0.alpha = 1 }
        },
                       completion: nil)
        
        if !permanent {
            hideControlsAfterDelay()
        }
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func deleteImage() {
        defer {
            reloadData()
        }
        
        if photos.count > 1 {
            pagingScrollView.deleteImage()
            
            photos.remove(at: currentPageIndex)
            if currentPageIndex != 0 {
                gotoPreviousPage()
            }
            toolbar.updateToolbar(currentPageIndex)
            
        } else if photos.count == 1 {
            dismissPhotoBrowser(animated: true)
        }
    }
}

// MARK: -  UIScrollView Delegate

extension StrnPhotoBrowser: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard isViewActive else {
            return
        }
        guard !isPerformingLayout else {
            return
        }
        
        // tile page
        pagingScrollView.tilePages()
        
        // Calculate current page
        let previousCurrentPage = currentPageIndex
        let visibleBounds = pagingScrollView.bounds
        currentPageIndex = min(max(Int(floor(visibleBounds.midX / visibleBounds.width)), 0), numberOfPhotos - 1)
        
        if currentPageIndex != previousCurrentPage {
            delegate?.didShowPhotoAtIndex?(currentPageIndex)
            toolbar.updateToolbar(currentPageIndex)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        hideControlsAfterDelay()
        
        let currentIndex = pagingScrollView.contentOffset.x / pagingScrollView.frame.size.width
        delegate?.didScrollToIndex?(Int(currentIndex))
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isEndAnimationByToolBar = true
    }
}
