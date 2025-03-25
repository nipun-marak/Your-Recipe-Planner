import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)
    case rateLimitExceeded
    case unauthorized
    case unknown
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://api.spoonacular.com"
    private let apiKey = "97eaa*************************"
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
        
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    private func createURL(endpoint: String, queryItems: [URLQueryItem] = []) -> URL? {
        var components = URLComponents(string: baseURL + endpoint)
        
        // Add API key
        var allQueryItems = queryItems
        allQueryItems.append(URLQueryItem(name: "apiKey", value: apiKey))
        
        components?.queryItems = allQueryItems
        return components?.url
    }
    
    func fetch<T: Decodable>(_ type: T.Type, endpoint: String, queryItems: [URLQueryItem] = []) -> AnyPublisher<T, APIError> {
        guard let url = createURL(endpoint: endpoint, queryItems: queryItems) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200..<300:
                    return data
                case 401:
                    throw APIError.unauthorized
                case 429:
                    throw APIError.rateLimitExceeded
                case 400..<500:
                    throw APIError.serverError(httpResponse.statusCode)
                default:
                    throw APIError.unknown
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                }
                return APIError.networkError(error)
            }
            .flatMap { data -> AnyPublisher<T, APIError> in
                Just(data)
                    .decode(type: T.self, decoder: self.decoder)
                    .mapError { error in
                        APIError.decodingError(error)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Recipe APIs
    
    func searchRecipes(query: String, cuisine: String? = nil, diet: String? = nil, 
                      intolerances: String? = nil, maxReadyTime: Int? = nil, 
                      number: Int = 20, offset: Int = 0) -> AnyPublisher<SearchResults, APIError> {
        
        var queryItems = [URLQueryItem(name: "query", value: query)]
        
        if let cuisine = cuisine {
            queryItems.append(URLQueryItem(name: "cuisine", value: cuisine))
        }
        
        if let diet = diet {
            queryItems.append(URLQueryItem(name: "diet", value: diet))
        }
        
        if let intolerances = intolerances {
            queryItems.append(URLQueryItem(name: "intolerances", value: intolerances))
        }
        
        if let maxReadyTime = maxReadyTime {
            queryItems.append(URLQueryItem(name: "maxReadyTime", value: String(maxReadyTime)))
        }
        
        queryItems.append(URLQueryItem(name: "number", value: String(number)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        
        return fetch(SearchResults.self, endpoint: "/recipes/complexSearch", queryItems: queryItems)
    }
    
    func getRecipeInformation(id: Int) -> AnyPublisher<APIRecipe, APIError> {
        return fetch(APIRecipe.self, endpoint: "/recipes/\(id)/information", queryItems: [])
    }
    
    func getRandomRecipes(number: Int = 10, tags: [String]? = nil) -> AnyPublisher<RecipeResponse, APIError> {
        var queryItems = [URLQueryItem(name: "number", value: String(number))]
        
        if let tags = tags, !tags.isEmpty {
            queryItems.append(URLQueryItem(name: "tags", value: tags.joined(separator: ",")))
        }
        
        return fetch(RecipeResponse.self, endpoint: "/recipes/random", queryItems: queryItems)
    }
}

// MARK: - Additional Response Types

struct SearchResults: Codable {
    let results: [APIRecipe]
    let offset: Int
    let number: Int
    let totalResults: Int
} 
