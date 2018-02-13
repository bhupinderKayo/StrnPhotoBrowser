//
//  StrnCacheable.swift
//  StrnPhotoBrowser
//
//

import UIKit.UIImage

public protocol StrnCacheable {}
public protocol StrnImageCacheable: StrnCacheable {
    func imageForKey(_ key: String) -> UIImage?
    func setImage(_ image: UIImage, forKey key: String)
    func removeImageForKey(_ key: String)
}

public protocol StrnRequestResponseCacheable: StrnCacheable {
    func cachedResponseForRequest(_ request: URLRequest) -> CachedURLResponse?
    func storeCachedResponse(_ cachedResponse: CachedURLResponse, forRequest request: URLRequest)
}
