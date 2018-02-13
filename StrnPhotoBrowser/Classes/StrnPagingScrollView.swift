//
//  StrnPagingScrollView.swift
//  StrnPhotoBrowser
//
//

import Foundation

class StrnPagingScrollView: UIScrollView {
    let pageIndexTagOffset: Int = 1000
    let sideMargin: CGFloat = 10
    fileprivate var visiblePages = [StrnZoomingScrollView]()
    fileprivate var recycledPages = [StrnZoomingScrollView]()
    
    fileprivate weak var browser: StrnPhotoBrowser?
    var numberOfPhotos: Int {
        return browser?.photos.count ?? 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        isPagingEnabled = true
        showsHorizontalScrollIndicator = true
        showsVerticalScrollIndicator = true
    }
    
    convenience init(frame: CGRect, browser: StrnPhotoBrowser) {
        self.init(frame: frame)
        self.browser = browser
        
        updateFrame(bounds, currentPageIndex: browser.currentPageIndex)
    }
    
    func reload() {
        visiblePages.forEach({$0.removeFromSuperview()})
        visiblePages.removeAll()
        recycledPages.removeAll()
    }
    
    func loadAdjacentPhotosIfNecessary(_ photo: StrnPhotoProtocol, currentPageIndex: Int) {
        guard let browser = browser, let page = pageDisplayingAtPhoto(photo) else {
            return
        }
        let pageIndex = (page.tag - pageIndexTagOffset)
        if currentPageIndex == pageIndex {
            // Previous
            if pageIndex > 0 {
                let previousPhoto = browser.photos[pageIndex - 1]
                if previousPhoto.underlyingImage == nil {
                    previousPhoto.loadUnderlyingImageAndNotify()
                }
            }
            // Next
            if pageIndex < numberOfPhotos - 1 {
                let nextPhoto = browser.photos[pageIndex + 1]
                if nextPhoto.underlyingImage == nil {
                    nextPhoto.loadUnderlyingImageAndNotify()
                }
            }
        }
    }
    
    func deleteImage() {
        // index equals 0 because when we slide between photos delete button is hidden and user cannot to touch on delete button. And visible pages number equals 0
        if numberOfPhotos > 0 {
            visiblePages[0].captionView?.removeFromSuperview()
        }
    }
    
    func animate(_ frame: CGRect) {
        setContentOffset(CGPoint(x: frame.origin.x - sideMargin, y: 0), animated: true)
    }
    
    func updateFrame(_ bounds: CGRect, currentPageIndex: Int) {
        var frame = bounds
        frame.origin.x -= sideMargin
        frame.size.width += (2 * sideMargin)
        
        self.frame = frame
        
        if visiblePages.count > 0 {
            for page in visiblePages {
                let pageIndex = page.tag - pageIndexTagOffset
                page.frame = frameForPageAtIndex(pageIndex)
                page.setMaxMinZoomScalesForCurrentBounds()
                if page.captionView != nil {
                    page.captionView.frame = frameForCaptionView(page.captionView, index: pageIndex)
                }
            }
        }
        
        updateContentSize()
        updateContentOffset(currentPageIndex)
    }
    
    func updateContentSize() {
        contentSize = CGSize(width: bounds.size.width * CGFloat(numberOfPhotos), height: bounds.size.height)
    }
    
    func updateContentOffset(_ index: Int) {
        let pageWidth = bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        contentOffset = CGPoint(x: newOffset, y: 0)
    }
    
    func tilePages() {
        guard let browser = browser else { return }
        
        let firstIndex: Int = getFirstIndex()
        let lastIndex: Int = getLastIndex()
        
        visiblePages
            .filter({ $0.tag - pageIndexTagOffset < firstIndex ||  $0.tag - pageIndexTagOffset > lastIndex })
            .forEach { page in
                recycledPages.append(page)
                page.prepareForReuse()
                page.removeFromSuperview()
        }
        
        let visibleSet: Set<StrnZoomingScrollView> = Set(visiblePages)
        let visibleSetWithoutRecycled: Set<StrnZoomingScrollView> = visibleSet.subtracting(recycledPages)
        visiblePages = Array(visibleSetWithoutRecycled)
        
        while recycledPages.count > 2 {
            recycledPages.removeFirst()
        }
        
        for index: Int in firstIndex...lastIndex {
            if visiblePages.filter({ $0.tag - pageIndexTagOffset == index }).count > 0 {
                continue
            }
            
            let page: StrnZoomingScrollView = StrnZoomingScrollView(frame: frame, browser: browser)
            page.frame = frameForPageAtIndex(index)
            page.tag = index + pageIndexTagOffset
            page.photo = browser.photos[index]
            
            visiblePages.append(page)
            addSubview(page)
            
            // if exists caption, insert
            if let captionView: StrnCaptionView = createCaptionView(index) {
                captionView.frame = frameForCaptionView(captionView, index: index)
                captionView.alpha = 1//browser.areControlsHidden() ? 0 : 1
                captionView.backgroundColor = UIColor(red: 118/255, green: 164/255, blue: 22/255, alpha: 1)
                addSubview(captionView)
                // ref val for control
                page.captionView = captionView
            }
        }
    }
    
    func frameForCaptionView(_ captionView: StrnCaptionView, index: Int) -> CGRect {
        let pageFrame = frameForPageAtIndex(index)
        //        let captionSize = captionView.sizeThatFits(CGSize(width: pageFrame.size.width, height: 0))
        //        let navHeight = browser?.navigationController?.navigationBar.frame.size.height ?? 44
        //        return CGRect(x: pageFrame.origin.x, y: pageFrame.size.height - captionSize.height - navHeight,
        //                      width: pageFrame.size.width, height: captionSize.height)
        return CGRect(x: pageFrame.origin.x, y: ((pageFrame.size.height) * 0.8861), width: pageFrame.size.width, height: ((pageFrame.size.height) * 0.1139))
    }
    
    func pageDisplayedAtIndex(_ index: Int) -> StrnZoomingScrollView? {
        for page in visiblePages {
            if page.tag - pageIndexTagOffset == index {
                return page
            }
        }
        return nil
    }
    
    func pageDisplayingAtPhoto(_ photo: StrnPhotoProtocol) -> StrnZoomingScrollView? {
        for page in visiblePages {
            if page.photo === photo {
                return page
            }
        }
        return nil
    }
    
    func getCaptionViews() -> Set<StrnCaptionView> {
        var captionViews = Set<StrnCaptionView>()
        visiblePages
            .filter({ $0.captionView != nil })
            .forEach {
                captionViews.insert($0.captionView)
        }
        return captionViews
    }
}

private extension StrnPagingScrollView {
    func frameForPageAtIndex(_ index: Int) -> CGRect {
        var pageFrame = bounds
        pageFrame.size.width -= (2 * sideMargin)
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + sideMargin
        return pageFrame
    }
    
    func createCaptionView(_ index: Int) -> StrnCaptionView? {
        guard let photo = browser?.photoAtIndex(index) , photo.caption != nil else {
            return nil
        }
        return StrnCaptionView(photo: photo)
    }
    
    func getFirstIndex() -> Int {
        let firstIndex = Int(floor((bounds.minX + sideMargin * 2) / bounds.width))
        if firstIndex < 0 {
            return 0
        }
        if firstIndex > numberOfPhotos - 1 {
            return numberOfPhotos - 1
        }
        return firstIndex
    }
    
    func getLastIndex() -> Int {
        let lastIndex  = Int(floor((bounds.maxX - sideMargin * 2 - 1) / bounds.width))
        if lastIndex < 0 {
            return 0
        }
        if lastIndex > numberOfPhotos - 1 {
            return numberOfPhotos - 1
        }
        return lastIndex
    }
}





