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
            return "Unable to start upload. Check your connection and try again."
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

    var isSubmitting = false
    var submittedSessionIds: Set<UUID> = []

    func submit(session: GigRecordingSession, accessToken: String) async throws {
        isSubmitting = true
        defer { isSubmitting = false }

        // Step 1: get signed URL
        // session.labelId is the gigLabelId for API calls
        let uploadUrlResponse: UploadUrlResponse
        do {
            uploadUrlResponse = try await apiClient.getUploadUrl(
                assignmentCode: session.assignmentCode,
                gigLabelId: session.labelId,
                deviceType: "generic_ios",
                accessToken: accessToken
            )
        } catch {
            throw SubmissionError.uploadUrlFailed
        }

        // Step 2: export CSV and PUT directly to Supabase Storage
        let csvData = SensorDataExporter.export(session: session)
        do {
            guard let signedURL = URL(string: uploadUrlResponse.signedUrl) else {
                throw SubmissionError.csvUploadFailed
            }
            var putRequest = URLRequest(url: signedURL)
            putRequest.httpMethod = "PUT"
            putRequest.setValue("text/csv", forHTTPHeaderField: "Content-Type")
            let (_, response) = try await URLSession.shared.upload(for: putRequest, from: csvData)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw SubmissionError.csvUploadFailed
            }
        } catch is SubmissionError {
            throw SubmissionError.csvUploadFailed
        } catch {
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
                assignmentCode: session.assignmentCode,
                storagePath: uploadUrlResponse.storagePath,
                fileSizeBytes: csvData.count,
                durationSeconds: session.intendedDurationSeconds,
                deviceType: "generic_ios",
                deviceMetadata: metadata,
                accessToken: accessToken
            )
        } catch {
            throw SubmissionError.confirmFailed
        }

        submittedSessionIds.insert(session.id)
    }
}
