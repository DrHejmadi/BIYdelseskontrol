import Foundation

actor OllamaService {
    static let shared = OllamaService()

    private let baseURL = "http://localhost:11434"

    enum OllamaError: Error, LocalizedError {
        case notRunning
        case modelNotFound(String)
        case requestFailed(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .notRunning: return "Ollama koerer ikke. Start Ollama og proev igen."
            case .modelNotFound(let m): return "Model '\(m)' ikke fundet. Koer: ollama pull \(m)"
            case .requestFailed(let msg): return "LLM-fejl: \(msg)"
            case .invalidResponse: return "Ugyldigt svar fra LLM"
            }
        }
    }

    struct GenerateRequest: Encodable {
        let model: String
        let prompt: String
        let system: String
        let stream: Bool
        let options: Options?

        struct Options: Encodable {
            let temperature: Double
            let num_predict: Int
        }
    }

    struct GenerateResponse: Decodable {
        let response: String
        let done: Bool
    }

    struct ModelList: Decodable {
        let models: [ModelInfo]
        struct ModelInfo: Decodable {
            let name: String
        }
    }

    func isRunning() async -> Bool {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func availableModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/tags") else { throw OllamaError.notRunning }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw OllamaError.notRunning }
        let list = try JSONDecoder().decode(ModelList.self, from: data)
        return list.models.map { $0.name }
    }

    func generate(model: String, system: String, prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/generate") else { throw OllamaError.notRunning }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let body = GenerateRequest(
            model: model,
            prompt: prompt,
            system: system,
            stream: false,
            options: .init(temperature: 0.1, num_predict: 500)
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, httpResp) = try await URLSession.shared.data(for: request)
        guard let statusCode = (httpResp as? HTTPURLResponse)?.statusCode else {
            throw OllamaError.notRunning
        }

        if statusCode == 404 { throw OllamaError.modelNotFound(model) }
        guard statusCode == 200 else {
            throw OllamaError.requestFailed("HTTP \(statusCode)")
        }

        let result = try JSONDecoder().decode(GenerateResponse.self, from: data)
        return result.response
    }
}
