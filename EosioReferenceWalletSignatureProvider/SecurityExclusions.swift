//
//  SecurityExclusions.swift
//  EosioReferenceWalletSignatureProvider
//
//  Created by Ben Martell on 2/5/19.
//  Copyright (c) 2018-2019 block.one
//

import Foundation

public struct SecurityExclusions: Codable {

    //If true, the authenticator may skip adding assert actions to the transaction
    public var addAssertToTransactions = false

    //If true, the authenticator may skip chain manifest and app metadata integrity checks
    public var appMetadataIntegrity = false

    //If true, the authenticator may not enforce the same-origin policy
    public var domainMatch = false

    //If true, the authenticator may allow signing of non-manifest-whitelisted actions
    public var whitelistedActions = false

    //If true, the authenticator may skip app-, action-, and/or chain-icon integrity checks
    public var iconIntegrity = false

    //If true, the authenticator may allow for parsing of non-compliant Ricardian contracts
    public var relaxedContractParsing = false

    public init() { }

}
