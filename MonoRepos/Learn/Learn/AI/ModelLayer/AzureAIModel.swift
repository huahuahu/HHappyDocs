//
//  AzureAIModel.swift
//  Learn
//
//  Created by tigerguo on 2024/11/21.
//

import Foundation
import UIKit

enum AzureAIModel {
  static func summarizeText(_ text: String) async throws -> String {
    let endpoint = "https://web-site-ai-service.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview"

    guard let url = URL(string: endpoint) else {
      throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(AIKey.azureAI, forHTTPHeaderField: "api-key")

    let requestBody: [String: Any] = [
      "messages": [
        [
          "role": "system",
          "content": "Assistant is a large language model trained by OpenAI to help summary text.",
        ],
        // swiftlint:disable:next line_length
        ["role": "user", "content": "Cloud computing has revolutionized the IT industry, providing scalable and cost-efficient solutions for businesses of all sizes. Companies no longer need to invest heavily in on-premises infrastructure; instead, they can rely on cloud service providers like AWS, Microsoft Azure, or Google Cloud. These platforms offer a variety of services, including storage, computing power, and advanced analytics. Moreover, cloud computing supports collaboration by enabling access to shared resources from anywhere with an internet connection. However, concerns about data security, compliance, and vendor lock-in remain significant challenges that organizations need to address."],
        ["role": "assistant", "content": "Cloud computing enables businesses to access scalable IT solutions without investing in on-premises infrastructure, offering services like storage and analytics through providers such as AWS and Azure. While it fosters collaboration, data security and compliance remain key challenges."],
        ["role": "user", "content": text],

      ],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    let (data, response) = try await URLSession.shared.data(for: request)

    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

    guard let httpResponse = response as? HTTPURLResponse else {
      throw NSError(domain: "Invalid response type", code: -1, userInfo: nil)
    }

    guard httpResponse.statusCode == 200 else {
      Log.common.error("Invalid response:, status code is \(httpResponse.statusCode), error is \(json?.debugDescription ?? "")")
      throw NSError(domain: "Invalid response", code: httpResponse.statusCode, userInfo: nil)
    }

    guard let json,
          let choices = json["choices"] as? [[String: Any]],
          let message = choices.first?["message"] as? [String: Any],
          let content = message["content"] as? String
    else {
      throw NSError(domain: "Invalid response format", code: -1, userInfo: nil)
    }

    return content
  }

  static func describeImage(_ image: UIImage) async throws -> String {
    let endpoint = "https://web-site-ai-service.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2024-08-01-preview"

    guard let url = URL(string: endpoint) else {
      throw NSError(domain: "Invalid URL", code: -1, userInfo: nil)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue(AIKey.azureAI, forHTTPHeaderField: "api-key")

    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
      throw NSError(domain: "Invalid image data", code: -1, userInfo: nil)
    }

    let base64Image = imageData.base64EncodedString()
    let requestBody: [String: Any] = [
      "messages": [
        [
          "role": "system",
          "content": "You are a helpful assistant.",
        ],
        [
          "role": "user",
          "content": [
            [
              "type": "text",
              "text": "Describe this picture:",
            ],
            [
              "type": "image_url",
              "image_url": [
                "url": "data:image/jpeg;base64,\(base64Image)",
              ],
            ],
          ],
        ],
      ],
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    let (data, response) = try await URLSession.shared.data(for: request)

    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    guard let httpResponse = response as? HTTPURLResponse else {
      throw NSError(domain: "Invalid response type", code: -1, userInfo: nil)
    }

    guard httpResponse.statusCode == 200 else {
      Log.common.error("Invalid response:, status code is \(httpResponse.statusCode), error is \(json?.debugDescription ?? "")")
      throw NSError(domain: "Invalid response", code: httpResponse.statusCode, userInfo: nil)
    }

    guard httpResponse.statusCode == 200 else {
      Log.common.error("Invalid response:, status code is \(httpResponse.statusCode), error is \(json?.debugDescription ?? "")")
      throw NSError(domain: "Invalid response", code: httpResponse.statusCode, userInfo: nil)
    }

    guard let json,
          let choices = json["choices"] as? [[String: Any]],
          let message = choices.first?["message"] as? [String: Any],
          let content = message["content"] as? String else {
      throw NSError(domain: "Invalid response format", code: -1, userInfo: nil)
    }

    return content
  }
}
