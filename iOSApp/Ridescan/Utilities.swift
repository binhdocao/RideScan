//
//  Utilities.swift
//  Ridescan
//
//  Created by Gage Broberg on 10/10/23.
//

import Foundation
import Models
import SwiftBSON

extension String {
    var isValidEmail: Bool {
          let regularExpressionForEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
          let testEmail = NSPredicate(format:"SELF MATCHES %@", regularExpressionForEmail)
          return testEmail.evaluate(with: self)
    }
       var isValidPhone: Bool {
          let regularExpressionForPhone = "^\\(?\\d{3}\\)?[ -]?\\d{3}[ -]?\\d{4}$"
          let testPhone = NSPredicate(format:"SELF MATCHES %@", regularExpressionForPhone)
          return testPhone.evaluate(with: self)
    }
    var isValidPassword: Bool {
        let regularExpressionForPassword = "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$"
        let testPassword = NSPredicate(format:"SELF MATCHES %@", regularExpressionForPassword)
        return testPassword.evaluate(with: self)
    }
}

extension URLResponse {
    /// Whether this response's HTTP status code indicates success.
    var wasSuccessful: Bool {
        (200...299).contains(self.httpStatusCode)
    }

    /// The HTTP status code returned in this response.
    var httpStatusCode: Int {
        // Ok to force cast since we only use this for responses to HTTP requests.
        // swiftlint:disable:next force_cast
        (self as! HTTPURLResponse).statusCode
    }
}

extension User {
	/// Corresponding URL for this user on the server.
	var resourceURL: URL {
		if let id = self.id {
			// If id is a String, it's assumed to be already in the correct format
			return HTTP.baseURL.appendingPathComponent(id)
		} else {
			// If the `id` is nil, handle accordingly; FIX THIS LATER BINH - NOT DEFAULT
			return HTTP.baseURL.appendingPathComponent("default")
		}
	}
}




/// Errors that can result from HTTP requests.
enum HTTPError: LocalizedError {
    case badResponse(code: Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case let .badResponse(code):
            return "Bad HTTP response with code \(code)"
        case let .decodingError(msg):
            return "Decoding error: \(msg)"
        }
    }
}

enum HTTP {
    /// Base URL where our application is running.
    // Ok to force unwrap since we know this is a valid URL.
    // swiftlint:disable:next force_unwrapping
    
    // Development
    static let baseURL = URL(string: "http://127.0.0.1:8081")!
    
    // Production
//    static let baseURL = URL(string: "https://www.ridescan.app")!

    /// Supported HTTP methods.
    enum Method: String {
        case POST, PATCH, GET, DELETE
    }

    /// Sends a GET request to the provided URL. Decodes the resulting extended JSON data into `dataType` and returns
    /// the result.
    static func get<T: Codable>(url: URL, dataType _: T.Type) async throws -> T {
        let data = try await sendRequest(to: url, body: nil as String?, method: .GET)
        do {
            return try ExtendedJSONDecoder().decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingError("Error decoding type \(T.self) from HTTP response")
        }
    }

    /// Sends a POST request to the provided URL. If `body` is provided it will be encoded to extended JSON and sent
    /// as the body of the request.
    static func post<T: Codable, R: Codable>(url: URL, body: T?) async throws -> R {
        let data = try await self.sendRequest(to: url, body: body, method: .POST)
        let decodedResponse = try JSONDecoder().decode(R.self, from: data)
        return decodedResponse
    }

    /// Sends a PATCH request to the provided URL. If `body` is provided it will be encoded to extended JSON and sent
    /// as the body of the request.
    static func patch<T: Codable>(url: URL, body: T?) async throws {
        try await self.sendRequest(to: url, body: body, method: .PATCH)
    }

    /// Sends a DELETE request to the provided URL.
    static func delete(url: URL) async throws {
        try await self.sendRequest(to: url, body: nil as String?, method: .DELETE)
    }

    /// Sends an HTTP request to the specified URL using the specified HTTP method. If `body` is provided it will be
    /// encoded to extended JSON and used as the body of the request. Returns the resulting data.
    /// Throws an error if the HTTP response code is not a successful one.
    @discardableResult
    private static func sendRequest<T: Codable>(
        to url: URL,
        body: T?,
        method: Method
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let body = body {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try ExtendedJSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard response.wasSuccessful else {
            throw HTTPError.badResponse(code: response.httpStatusCode)
        }
        return data
    }
}
