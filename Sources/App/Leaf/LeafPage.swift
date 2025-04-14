import Vapor

protocol LeafPage: Content {
    var file: String { get }
    var meta: PageMetadata { get }
}

extension LeafPage {
    func render(with req: Request) async throws -> Response {
        try await req.view.render(file, self).encodeResponse(for: req)
    }
    
    func render(with req: Request) async throws -> View {
        try await req.view.render(file, self)
    }
}

struct PageMetadata: Content {
    let title: String
    var description: String = ""
    var error: String? = nil
    var user: User? = nil
}

struct Page: LeafPage {
    let file: String
    let meta: PageMetadata
}

struct SomePage<T: Content>: LeafPage {
    let file: String
    let meta: PageMetadata
    let content: T
}

