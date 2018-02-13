//
//  StrnCache.swift
//  StrnPhotoBrowser
//
//

import UIKit

open class StrnCache {
    open static let sharedCache = StrnCache()
    open var imageCache: StrnCacheable

    init() {
        self.imageCache = StrnDefaultImageCache()
    }

    open func imageForKey(_ key: String) -> UIImage? {
        guard let cache = imageCache as? StrnImageCacheable else {
            return nil
        }
        
        return cache.imageForKey(key)
    }

    open func setImage(_ image: UIImage, forKey key: String) {
        guard let cache = imageCache as? StrnImageCacheable else {
            return
        }
        
        cache.setImage(image, forKey: key)
    }

    open func removeImageForKey(_ key: String) {
        guard let cache = imageCache as? StrnImageCacheable else {
            return
        }
        
        cache.removeImageForKey(key)
    }

    open func imageForRequest(_ request: URLRequest) -> UIImage? {
        guard let cache = imageCache as? StrnRequestResponseCacheable else {
            return nil
        }
        
        if let response = cache.cachedResponseForRequest(request) {
            return UIImage(data: response.data)
        }
        return nil
    }

    open func setImageData(_ data: Data, response: URLResponse, request: URLRequest) {
        guard let cache = imageCache as? StrnRequestResponseCacheable else {
            return
        }
        let cachedResponse = CachedURLResponse(response: response, data: data)
        cache.storeCachedResponse(cachedResponse, forRequest: request)
    }
}

class StrnDefaultImageCache: StrnImageCacheable {
    var cache: NSCache<AnyObject, AnyObject>

    init() {
        cache = NSCache()
    }

    func imageForKey(_ key: String) -> UIImage? {
        return cache.object(forKey: key as AnyObject) as? UIImage
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as AnyObject)
    }

    func removeImageForKey(_ key: String) {
        cache.removeObject(forKey: key as AnyObject)
    }
}
