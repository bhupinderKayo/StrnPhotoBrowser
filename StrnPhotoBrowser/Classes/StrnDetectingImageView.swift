//
//  StrnDetectingImageView.swift
//  StrnPhotoBrowser
//
//

import UIKit

@objc protocol StrnDetectingImageViewDelegate {
    func handleImageViewSingleTap(_ touchPoint: CGPoint)
    func handleImageViewDoubleTap(_ touchPoint: CGPoint)
}

class StrnDetectingImageView: UIImageView {
    weak var delegate: StrnDetectingImageViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        delegate?.handleImageViewDoubleTap(recognizer.location(in: self))
    }
    
    func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
        delegate?.handleImageViewSingleTap(recognizer.location(in: self))
    }
}

private extension StrnDetectingImageView {
    func setup() {
        isUserInteractionEnabled = true
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTap.require(toFail: doubleTap)
        addGestureRecognizer(singleTap)
    }
}
