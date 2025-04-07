import Vapor

/// Create a response that renders and returns HTML if the request accept is HTML, otherwise just returns JSON
/// - Parameters:
///   - request: HTTP Request
///   - value: Content
///   - template: Leaf template to render
/// - Throws: Renderer or Encoding errors
/// - Returns: Appropriate Accept type response
func jsonOrHTML<T: Content>(request: Request, templateName: String, value: T) async throws -> Response {
    var response = Response(status: .ok)
    if request.headers.accept.contains(where: { $0.mediaType == .html }) {
        let view: View = try await request.view.render(templateName, value)
        response.headers.contentType = .html
        response.body = .init(buffer: view.data)
    } else {
        try response.content.encode(value)
        response.headers.contentType = .json
    }
    return response
}
