//
//  Application.swift
//  datagigios
//

import Foundation

// MARK: - Application (list item)

struct Application: Decodable, Identifiable {
    let id: String
    let gigId: String
    let gigTitle: String
    let status: String
    let deviceType: String
    let assignmentCode: String?
    let appliedAt: Date
    let noteFromCompany: String?
}

// MARK: - ApplicationDetail (single application with full gig info)

struct ApplicationDetail: Decodable, Identifiable {
    let id: String
    let gigId: String
    let gigTitle: String
    let status: String
    let deviceType: String
    let assignmentCode: String?
    let appliedAt: Date
    let noteFromCompany: String?
    let noteFromUser: String?
    let gigDetail: ApplicationGigDetail
}

// MARK: - ApplicationGigDetail

struct ApplicationGigDetail: Decodable {
    let title: String
    let description: String
    let activityType: String
    let dataDeadline: Date?
    let labels: [ApplicationLabel]
}

// MARK: - ApplicationLabel

struct ApplicationLabel: Decodable, Identifiable {
    let id: String
    let labelName: String
    let durationSeconds: Int
    let rateCents: Int
}

// MARK: - UserProfile

struct UserProfile: Decodable {
    let displayName: String
    let creditsBalanceCents: Int
}
