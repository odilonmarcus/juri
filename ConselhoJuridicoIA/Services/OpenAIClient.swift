import Foundation

struct OpenAIClient {
    struct ResponseEnvelope: Decodable {
        struct OutputItem: Decodable {
            struct ContentItem: Decodable {
                let type: String?
                let text: String?
            }

            let type: String?
            let content: [ContentItem]?
        }

        struct APIError: Decodable {
            let message: String?
        }

        let output: [OutputItem]?
        let error: APIError?
    }

    func generate(
        apiKey: String,
        model: String,
        system: String,
        prompt: String,
        maxOutputTokens: Int
    ) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw AIClientError.missingCredential("OpenAI")
        }

        guard let url = URL(string: "https://api.openai.com/v1/responses") else {
            throw AIClientError.invalidResponse("OpenAI")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 180
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": model,
            "instructions": system,
            "input": prompt,
            "max_output_tokens": maxOutputTokens,
            "store": false
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIClientError.invalidResponse("OpenAI")
        }

        guard (200..<300).contains(http.statusCode) else {
            let fallback = String(data: data, encoding: .utf8) ?? "Erro HTTP \(http.statusCode)"
            let message = extractErrorMessage(from: data) ?? fallback
            throw AIClientError.provider("OpenAI", message)
        }

        let decoded = try JSONDecoder().decode(ResponseEnvelope.self, from: data)

        var texts: [String] = []
        if let outputItems = decoded.output {
            for outputItem in outputItems {
                guard let contentItems = outputItem.content else {
                    continue
                }

                for contentItem in contentItems {
                    let isTextItem = contentItem.type == nil || contentItem.type == "output_text"
                    if isTextItem, let text = contentItem.text {
                        texts.append(text)
                    }
                }
            }
        }

        let joinedText = texts.joined(separator: "\n")
        let result = joinedText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        guard !result.isEmpty else {
            if let message = decoded.error?.message {
                throw AIClientError.provider("OpenAI", message)
            }
            throw AIClientError.emptyResponse("OpenAI")
        }

        return result
    }

    private func extractErrorMessage(from data: Data) -> String? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: data),
            let json = jsonObject as? [String: Any],
            let error = json["error"] as? [String: Any],
            let message = error["message"] as? String
        else {
            return nil
        }

        return message
    }
}

enum AIClientError: LocalizedError {
    case missingCredential(String)
    case invalidResponse(String)
    case provider(String, String)
    case emptyResponse(String)

    var errorDescription: String? {
        switch self {
        case .missingCredential(let provider):
            return "Configure a chave da \(provider) em Ajustes."
        case .invalidResponse(let provider):
            return "Resposta invalida recebida da \(provider)."
        case .provider(let provider, let message):
            return "\(provider): \(message)"
        case .emptyResponse(let provider):
            return "A \(provider) retornou uma resposta vazia."
        }
    }
}
