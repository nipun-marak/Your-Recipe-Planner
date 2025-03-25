import Foundation
import UIKit
import Combine

class ImageService {
    static let shared = ImageService()
    
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let imageDirectory: URL
    
    private init() {
        // Configure the memory cache
        cache.countLimit = 100 // Maximum number of images in memory
        
        // Get the directory for persistent cache
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        imageDirectory = cachesDirectory.appendingPathComponent("RecipeImages")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: imageDirectory.path) {
            do {
                try fileManager.createDirectory(at: imageDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating image cache directory: \(error)")
            }
        }
    }
    
    // Load image from URL
    func loadImage(from urlString: String?) -> AnyPublisher<UIImage?, Never> {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        // Generate a cache key from the URL
        let cacheKey = NSString(string: urlString)
        
        // Check memory cache first
        if let cachedImage = cache.object(forKey: cacheKey) {
            return Just(cachedImage).eraseToAnyPublisher()
        }
        
        // Check disk cache
        if let diskCachedImage = loadImageFromDisk(key: urlString) {
            // Store in memory cache for future use
            cache.setObject(diskCachedImage, forKey: cacheKey)
            return Just(diskCachedImage).eraseToAnyPublisher()
        }
        
        // Download image if not in cache
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { data, _ -> UIImage? in
                guard let image = UIImage(data: data) else {
                    return nil
                }
                
                // Cache the image
                self.cache.setObject(image, forKey: cacheKey)
                self.saveImageToDisk(image: image, key: urlString)
                
                return image
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
    
    // Clear the image cache
    func clearCache() {
        cache.removeAllObjects()
        clearDiskCache()
    }
    
    // MARK: - Private Methods
    
    private func saveImageToDisk(image: UIImage, key: String) {
        let fileURL = imageDirectory.appendingPathComponent(key.md5Hash)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            try data.write(to: fileURL)
        } catch {
            print("Error saving image to disk: \(error)")
        }
    }
    
    private func loadImageFromDisk(key: String) -> UIImage? {
        let fileURL = imageDirectory.appendingPathComponent(key.md5Hash)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            print("Error loading image from disk: \(error)")
            return nil
        }
    }
    
    private func clearDiskCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: imageDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing disk cache: \(error)")
        }
    }
}

// MARK: - String Extension for MD5 Hashing

extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = data.withUnsafeBytes {
            CC_MD5($0.baseAddress, CC_LONG(data.count), &digest)
        }
        
        var hashString = ""
        for byte in digest {
            hashString += String(format: "%02x", byte)
        }
        
        return hashString
    }
}

// Need to import CommonCrypto at the top of the file
import CommonCrypto 