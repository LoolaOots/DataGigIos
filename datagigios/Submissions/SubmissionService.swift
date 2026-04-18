// datagigios/Submissions/SubmissionService.swift
import Foundation
import UIKit
import Observation

enum SubmissionError: LocalizedError {
    case uploadUrlFailed
    case csvUploadFailed
    case confirmFailed

    var errorDescription: String? {
        switch self {
        case .uploadUrlFailed:
            return "Unable to start upload. Please try again later."
        case .csvUploadFailed:
            return "Upload failed. Please try again."
        case .confirmFailed:
            return "Data uploaded but could not confirm. Please contact support."
        }
    }
}

@Observable
@MainActor
final class SubmissionService {
    private let apiClient = APIClient.shared

    // Dedicated session for Supabase Storage PUT — 120s timeout for large CSV uploads
    private let uploadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        return URLSession(configuration: config)
    }()

    private static let deviceType = "generic_ios"

    var isSubmitting = false
    var submittingSessionId: UUID? = nil
    var submittedSessionIds: Set<UUID> = []

    func submit(session: GigRecordingSession, assignmentCode: String, accessToken: String) async throws {
        isSubmitting = true
        submittingSessionId = session.id
        defer {
            isSubmitting = false
            submittingSessionId = nil
        }

        // Step 1: get signed URL
        // session.labelId is the gigLabelId for API calls
        let uploadUrlResponse: UploadUrlResponse
        do {
            uploadUrlResponse = try await apiClient.getUploadUrl(
                assignmentCode: assignmentCode,
                gigLabelId: session.labelId,
                deviceType: Self.deviceType,
                accessToken: accessToken
            )
        } catch {
            print("[SubmissionService] Step 1 failed: \(error)")
            throw SubmissionError.uploadUrlFailed
        }

        // Step 2: export CSV and PUT directly to Supabase Storage
        // Uses a dedicated URLSession with a 120-second timeout; URLSession.shared has no timeout override.
        let csvData = SensorDataExporter.export(session: session)
        do {
            guard let signedURL = URL(string: uploadUrlResponse.signedUrl) else {
                throw SubmissionError.csvUploadFailed
            }
            var putRequest = URLRequest(url: signedURL)
            putRequest.httpMethod = "PUT"
            putRequest.setValue("text/csv", forHTTPHeaderField: "Content-Type")
            let (_, response) = try await uploadSession.upload(for: putRequest, from: csvData)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw SubmissionError.csvUploadFailed
            }
        } catch {
            print("[SubmissionService] Step 2 failed: \(error)")
            throw SubmissionError.csvUploadFailed
        }

        // Step 3: confirm with backend
        // session.intendedDurationSeconds is the duration field (no `duration` property exists)
        let device = UIDevice.current
        let metadata = DeviceMetadata(
            model: device.model,
            osVersion: device.systemVersion
        )
        do {
            _ = try await apiClient.confirmSubmission(
                applicationId: uploadUrlResponse.applicationId,
                gigLabelId: session.labelId,
                assignmentCode: assignmentCode,
                storagePath: uploadUrlResponse.storagePath,
                fileSizeBytes: csvData.count,
                durationSeconds: session.intendedDurationSeconds,
                deviceType: Self.deviceType,
                deviceMetadata: metadata,
                accessToken: accessToken
            )
        } catch {
            print("[SubmissionService] Step 3 failed: \(error)")
            throw SubmissionError.confirmFailed
        }

        submittedSessionIds.insert(session.id)
    }
}
