//
//  APIClient.swift
//  datagigios
//

import Foundation

// MARK: - Errors

enum NetworkError: Error, LocalizedError {
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case invalidURL
    case transportError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You are not authorized. Please sign in."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let code):
            return "Server error (HTTP \(code))."
        case .decodingError(let underlying):
            return "Failed to decode response: \(underlying.localizedDescription)"
        case .invalidURL:
            return "Invalid URL."
        case .transportError(let underlying):
            return underlying.localizedDescription
        }
    }
}

// MARK: - Config

enum Config {
    static var backendBaseURL: String {
        // Read from Info.plist (populated from Config.xcconfig via build settings)
        if let value = Bundle.main.infoDictionary?["BACKEND_BASE_URL"] as? String,
           !value.isEmpty {
            return value
        }
        return "http://localhost:8000"
    }
}

// MARK: - APIClient

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        auth: String? = nil
    ) async throws -> T {
        let baseURL = Config.backendBaseURL
        guard let url = URL(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = auth {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.transportError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(0)
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        default:
            throw NetworkError.serverError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
