//
//  EosioReferenceAuthenticatorSignatureProvider.swift
//
//  Created by Todd Bowden on 9/30/18.
//  Copyright (c) 2017-2019 block.one and its contributors. All rights reserved.
//

import Foundation
import UIKit
import EosioSwift

/// Signature provider for EOSIO SDK for Swift that provides selective disclosure and transaction signing using the
/// EOSIO Reference iOS Authenticator App.  Conforms to `EosioSignatureProviderProtocol`.
///
/// Requirements for developers.
/// + Add manifest.json file.
/// + Add URL scheme or Universal Link.
/// + Add URL scheme to whitelist.
public class EosioReferenceAuthenticatorSignatureProvider: EosioSignatureProviderProtocol {

    /// Singleton instance of the `EosioReferenceAuthenticatorSignatureProvider`.
    public static let shared = EosioReferenceAuthenticatorSignatureProvider()

    /// Map of the current completion closures for transaction signatures, keyed by the incoming payload ID.
    static var transactionSignatureCompletions = [String: ((EosioTransactionSignatureResponse) -> Void)]()

    /// Map of the current completion closures for selective disclosure requests, keyed by the incoming payload ID.
    static var selectiveDisclosureCompletions = [String: ((SelectiveDisclosureResponse) -> Void)]()

    /// Handle an incoming request from a Universal Link.
    ///
    /// - Parameter userActivity: Current application state as `NSUserActivity`.
    public static func handleIncoming(userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        handleIncoming(url: url)
    }

    /// Handle an incoming request from a custom URL scheme.
    ///
    /// - Parameter url: The URL passed in from the system handler that the app has registered.
    public static func handleIncoming(url: URL) {
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        guard let queryItems = urlComponents.queryItems else { return }
        guard let payloadHex = queryItems.dictionary["response"] else { return }
        guard let payload = try? ResponsePayload(hex: payloadHex) else { return }

        handleIncomingSelectiveDisclosure(payload: payload)
        handleIncomingTransactionSignature(payload: payload)
    }

    /// If true the incoming request requires biometric authentication to be processed.
    public var requireBiometric = false

    /// The return URL of the request.
    public var returnUrl = ""

    /// The call back URL of the request.
    public var callbackUrl: String?

    /// The declared domain of the request.
    public var declaredDomain: String?

    /// The application manifest of the request.
    public var manifest: String?

    /// Security checks or rules to relax during processing of the current request.
	public var securityExclusions: SecurityExclusions?

    /// The incoming request structure to handle.
    public struct Request: Codable {
        /// If set, the incoming request is a transaction signature request.
        public var transactionSignature: TransactionSignatureRequest?
        /// If set, the incoming request is a selective disclosure request.
        public var selectiveDisclosure: SelectiveDisclosureRequest?
    }

    /// Request Payload native struct.
    /// - seealso: https://github.com/EOSIO/eosio-auth-transport-protocol-specification
    public struct RequestPayload: Codable {
        /// The payload ID.  Should be instance unique.
        public var id = UUID().uuidString
        /// The payload declared domain for domain matching checks.
        public var declaredDomain: String?
        /// The payload return URL.
        public var returnUrl = ""
        /// The payload call back URL.
        public var callbackUrl: String?
        /// The payload response key.
        public var responseKey: String?
        /// If true, the request requires biometric authentication.
        public var requireBiometric: Bool?
        /// The actual request to be processed.
        public var request = Request()
        /// Security checks or rules to relax during the processing of this request.
        public var securityExclusions: SecurityExclusions?

        /// The current request in Hex format.
        public var toHex: String? {
            return try? toJsonData().hex
        }

        public init() { }

        /// Initialize a request payload from a hexadecimal `String` representation.
        ///
        /// - Parameter hex: Hexadecimal `String` representation of a `RequestPayload`.
        public init(hex: String) throws {
            guard let data = Data(hexString: hex) else {
                throw EosioError(.signatureProviderError, reason: "Invalid request hex string")
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            self = try decoder.decode(RequestPayload.self, from: data)
        }
    }

    /// Returned response structure for processed request.
    public struct Response: Codable {
        /// If set, the returned response is a transaction signature response.
        public var transactionSignature: TransactionSignatureResponse?
        /// If set, the returned response is a selective disclosure response.
        public var selectiveDisclosure: SelectiveDisclosureResponse?
    }

    /// Response Payload native struct.
    /// - seealso: https://github.com/EOSIO/eosio-auth-transport-protocol-specification
    public struct ResponsePayload: Codable {
        /// The response payload ID.  Copied from the incoming request.
        public var id = ""
        /// The device ID that processed the request.
        public var deviceId = ""
        /// The actual response to be returned.
        public var response = Response()

        /// The current response, in Hex format.
        public var toHex: String? {
            return try? toJsonData().hex
        }

        public init() { }

        /// Initialize a response payload from a hexadecimal `String` representation.
        ///
        /// - Parameter hex: Hexadecimal `String` representation of a `ResponsePayload`.
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
            self.response.transactionSignature = TransactionSignatureResponse(eosioTransactionSignatureResponse: transactionSignatureResponse)
        }

    }

}
