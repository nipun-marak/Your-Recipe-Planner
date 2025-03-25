import Foundation
import Combine

class CacheService {
    static let shared = CacheService()
    
    private let cache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Configure the memory cache
        cache.countLimit = 100 // Maximum number of objects in memory cache
        
        // Get the directory for persistent cache
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("RecipeCache")
        
        // Create cache directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            } catch {
                print("Error creating cache directory: \(error)")
            }
        }
    }
    
    // Add an item to the cache
    func cache<T: Codable>(object: T, forKey key: String, expiration: TimeInterval = 3600) {
        // Create a cache entry
        let entry = CacheEntry(object: object, expirationDate: Date().addingTimeInterval(expiration))
        
        // Store in memory cache
        cache.setObject(entry, forKey: key as NSString)
        
        // Store on disk
        saveToDisk(entry: entry, forKey: key)
    }
    
    // Get an item from the cache
    func object<T: Codable>(forKey key: String, type: T.Type) -> T? {
        // Try memory cache first
        if let entry = cache.object(forKey: key as NSString), !entry.isExpired {
            return entry.object as? T
        }
        
        // Try disk cache if not in memory
        return loadFromDisk(forKey: key, type: type)
    }
    
    // Get an item from the cache as a publisher
    func objectPublisher<T: Codable>(forKey key: String, type: T.Type) -> AnyPublisher<T?, Never> {
        return Just(object(forKey: key, type: type))
            .eraseToAnyPublisher()
    }
    
    // Remove an item from the cache
    func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
        removeDiskCache(forKey: key)
    }
    
    // Clear all cached items
    func clearCache() {
        cache.removeAllObjects()
        clearDiskCache()
    }
    
    // MARK: - Private methods
    
    private func saveToDisk(entry: CacheEntry, forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL)
        } catch {
            print("Error saving to disk: \(error)")
        }
    }
    
    private func loadFromDisk<T: Codable>(forKey key: String, type: T.Type) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let entry = try JSONDecoder().decode(CacheEntry.self, from: data)
            
            // Check if the cached object has expired
            if entry.isExpired {
                removeDiskCache(forKey: key)
                return nil
            }
            
            // Store in memory cache for faster future access
            cache.setObject(entry, forKey: key as NSString)
            
            return entry.object as? T
        } catch {
            print("Error loading from disk: \(error)")
            return nil
        }
    }
    
    private func removeDiskCache(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            print("Error removing disk cache: \(error)")
        }
    }
    
    private func clearDiskCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("Error clearing disk cache: \(error)")
        }
    }
}

// MARK: - Cache Entry

class CacheEntry: Codable {
    let objectData: Data
    let expirationDate: Date
    
    var object: Any? {
        return try? JSONDecoder().decode(AnyDecodable.self, from: objectData).value
    }
    
    var isExpired: Bool {
        return Date() > expirationDate
    }
    
    init<T: Codable>(object: T, expirationDate: Date) {
        self.objectData = try! JSONEncoder().encode(object)
        self.expirationDate = expirationDate
    }
}

// MARK: - Helper for storing Any Codable type

private struct AnyDecodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyDecodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyDecodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode unknown type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { try AnyDecodable(from: $0 as! Decoder) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { try AnyDecodable(from: $0 as! Decoder) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Cannot encode \(type(of: self.value))")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
} 
