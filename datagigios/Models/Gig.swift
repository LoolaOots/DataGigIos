//
//  Gig.swift
//  datagigios
//

import Foundation

// MARK: - Gig (list item)

struct Gig: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String
    let activityType: String
    let status: String
    let totalSlots: Int
    let filledSlots: Int
    let applicationDeadline: Date?
    let dataDeadline: Date?
    let companyName: String
    let minRateCents: Int
    let maxRateCents: Int
    let deviceTypes: [String]
}

// MARK: - GigDetail (single gig with labels)

struct GigDetail: Decodable, Identifiable {
    let id: String
    let title: String
    let description: String
    let activityType: String
    let status: String
    let totalSlots: Int
    let filledSlots: Int
    let applicationDeadline: Date?
    let dataDeadline: Date?
    let companyName: String
    let minRateCents: Int
    let maxRateCents: Int
    let deviceTypes: [String]
    let labels: [GigLabel]
}

// MARK: - GigLabel

struct GigLabel: Decodable, Identifiable {
    let id: String
    let labelName: String
    let description: String?
    let durationSeconds: Int
    let rateCents: Int
    let quantityNeeded: Int
    let quantityFulfilled: Int
}
