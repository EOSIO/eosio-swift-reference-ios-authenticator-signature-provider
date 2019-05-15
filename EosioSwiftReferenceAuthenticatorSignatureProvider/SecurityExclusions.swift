//
//  SecurityExclusions.swift
//  EosioReferenceAuthenticatorSignatureProvider
//
//  Created by Ben Martell on 2/5/19.
//  Copyright (c) 2017-2019 block.one and its contributors. All rights reserved.
//

import Foundation

/// Struct to define what security exclusions that the developer is willing to relax for testing.
/// - Note: Exclusions relax the built in security of the system and are not recommended for production use.
public struct SecurityExclusions: Codable {

    /// If true, the authenticator may skip adding assert actions to the transaction.
    public var addAssertToTransactions = false

    /// If true, the authenticator may skip chain manifest and app metadata integrity checks.
    public var appMetadataIntegrity = false

    /// If true, the authenticator may not enforce the same-origin policy.
    public var domainMatch = false

    /// If true, the authenticator may allow signing of non-manifest-whitelisted actions.
    public var whitelistedActions = false

    /// If true, the authenticator may skip app-, action-, and/or chain-icon integrity checks.
    public var iconIntegrity = false

    /// If true, the authenticator may allow for parsing of non-compliant Ricardian contracts.
    public var relaxedContractParsing = false

    enum CodingKeys: String, CodingKey {
        case addAssertToTransactions
        case appMetadataIntegrity
        case domainMatch
        case whitelistedActions
        case iconIntegrity
        case relaxedContractParsing
    }

    public init() { }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        addAssertToTransactions = try container.decodeIfPresent(Bool.self, forKey: .addAssertToTransactions) ?? false
        appMetadataIntegrity = try container.decodeIfPresent(Bool.self, forKey: .appMetadataIntegrity) ?? false
        domainMatch = try container.decodeIfPresent(Bool.self, forKey: .domainMatch) ?? false
        whitelistedActions = try container.decodeIfPresent(Bool.self, forKey: .whitelistedActions) ?? false
        iconIntegrity = try container.decodeIfPresent(Bool.self, forKey: .iconIntegrity) ?? false
        relaxedContractParsing = try container.decodeIfPresent(Bool.self, forKey: .relaxedContractParsing) ?? false
    }

}
