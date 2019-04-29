//
//  EosioReferenceWalletSignatureProvider.swift
//
//  Created by Todd Bowden on 9/30/18.
//  Copyright (c) 2018-2019 block.one
//

//  requirements for Devs:
//
//  add manifest.json file
//  add url scheme or universal link
//  add url scheme to whitelist
//

import Foundation
import UIKit
import EosioSwift

public class EosioReferenceWalletSignatureProvider: EosioSignatureProviderProtocol {

    public static let shared = EosioReferenceWalletSignatureProvider()

    static var transactionSignatureCompletions = [String: ((EosioTransactionSignatureResponse) -> Void)]()
    static var selectiveDisclosureCompletions = [String: ((SelectiveDisclosureResponse) -> Void)]()

    public static func handleIncoming(userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        handleIncoming(url: url)
    }

    public static func handleIncoming(url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        guard let queryItems = urlComponents.queryItems else { return }
        guard let payloadHex = queryItems.dictionary["response"] else { return }
        guard let payload = try? ResponsePayload(hex: payloadHex) else { return }

        handleIncomingSelectiveDisclosure(payload: payload)
        handleIncomingTransactionSignature(payload: payload)
    }

    public var requireBiometric = false
    public var returnUrl = ""
    public var callbackUrl: String?
    public var declaredDomain: String?
    public var manifest: String?
	public var securityExclusions: SecurityExclusions?

    public struct Request: Codable {
        public var transactionSignature: EosioTransactionSignatureRequest?
        public var selectiveDisclosure: SelectiveDisclosureRequest?
    }

    // Request Payload native struct
    // Reference: https://github.com/EOSIO/eosio-auth-transport-protocol-specification
    public struct RequestPayload: Codable {
        public var id = UUID().uuidString
        public var declaredDomain: String?
        public var returnUrl = ""
        public var callbackUrl: String?
        public var responseKey: String?
        public var requireBiometric: Bool?
        public var request = Request()
        public var securityExclusions: SecurityExclusions?

        public var toHex: String? {
            return try? toJsonData().hex
        }

        public init() { }

        public init(hex: String) throws {
            guard let data = Data(hexString: hex) else {
                throw EosioError(.signatureProviderError, reason: "Invalid request hex string")
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            self = try decoder.decode(RequestPayload.self, from: data)
        }
    }

    public struct Response: Codable {
        public var transactionSignature: EosioTransactionSignatureResponse?
        public var selectiveDisclosure: SelectiveDisclosureResponse?
    }

    // Response Payload native struct
    // Reference: https://github.com/EOSIO/eosio-auth-transport-protocol-specification
    public struct ResponsePayload: Codable {
        public var id = ""
        public var deviceId = ""
        public var response = Response()

        public var toHex: String? {
            return try? toJsonData().hex
        }

        public init() { }

        public init(hex: String) throws {
            guard let data = Data(hexString: hex) else {
                throw EosioError(.signatureProviderError, reason: "Invalid response hex string")
            }
            print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
            print(String(data: data, encoding: .utf8)!)
            print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            self = try decoder.decode(ResponsePayload.self, from: data)
        }

        public init(id: String, transactionSignatureResponse: EosioTransactionSignatureResponse) {
            self.id = id
            self.response.transactionSignature = transactionSignatureResponse
        }

    }

}
