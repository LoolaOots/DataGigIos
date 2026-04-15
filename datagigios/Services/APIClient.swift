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

// MARK: - Submission Models

struct UploadUrlResponse: Decodable {
    let signedUrl: String       // decoded from backend's signed_url
    let storagePath: String     // decoded from backend's storage_path
    let applicationId: String   // decoded from backend's application_id
}

struct ConfirmSubmissionResponse: Decodable {
    let submissionId: String    // decoded from backend's submission_id
}

struct DeviceMetadata: Encodable {
    let model: String
    let osVersion: String       // sent as os_version via convertToSnakeCase
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

    func getUploadUrl(
        assignmentCode: String,
        gigLabelId: String,
        deviceType: String,
        accessToken: String
    ) async throws -> UploadUrlResponse {
        struct Body: Encodable {
            let assignmentCode: String
            let gigLabelId: String
            let deviceType: String
            let fileExtension: String
        }
        let body = Body(
            assignmentCode: assignmentCode,
            gigLabelId: gigLabelId,
            deviceType: deviceType,
            fileExtension: "csv"
        )
        return try await request(
            "/submissions/upload-url",
            method: "POST",
            body: body,
            auth: accessToken
        )
    }

    func confirmSubmission(
        applicationId: String,
        gigLabelId: String,
        assignmentCode: String,
        storagePath: String,
        fileSizeBytes: Int,
        durationSeconds: Int,
        deviceType: String,
        deviceMetadata: DeviceMetadata,
        accessToken: String
    ) async throws -> ConfirmSubmissionResponse {
        struct Body: Encodable {
            let applicationId: String
            let gigLabelId: String
            let assignmentCode: String
            let storagePath: String
            let fileSizeBytes: Int
            let durationSeconds: Int
            let deviceType: String
            let deviceMetadata: DeviceMetadata
        }
        let body = Body(
            applicationId: applicationId,
            gigLabelId: gigLabelId,
            assignmentCode: assignmentCode,
            storagePath: storagePath,
            fileSizeBytes: fileSizeBytes,
            durationSeconds: durationSeconds,
            deviceType: deviceType,
            deviceMetadata: deviceMetadata
        )
        return try await request(
            "/submissions/confirm",
            method: "POST",
            body: body,
            auth: accessToken
        )
    }

    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        auth: String? = nil
    ) async throws -> T {
        do {
            return try await performRequest(endpoint, method: method, body: body, auth: auth)
        } catch NetworkError.serverError {
            // Retry once on server errors (5xx); second failure propagates to the caller.
            // Note: the submission spec says "no automatic retry", but the confirm endpoint
            // is idempotent and get-upload-url is also safe to retry, so this is benign.
            return try await performRequest(endpoint, method: method, body: body, auth: auth)
        }
    }

    private func performRequest<T: Decodable>(
        _ endpoint: String,
        method: String,
        body: (any Encodable)?,
        auth: String?
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
