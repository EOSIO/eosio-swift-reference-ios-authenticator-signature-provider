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

    public init() { }

}
