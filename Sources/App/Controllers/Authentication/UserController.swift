import Vapor
import Fluent

struct ProfilePage: LeafPage {
    var file: String { "profile" }
    
    var meta: PageMetadata {
        let title: String
        let description: String
        if let user = user {
            title = "Logged in as \(user.name)."
            description = "Profile page for \(user.name)."
        } else {
            title = "Not Logged In"
            description = "Not Logged In"
        }
        return .init(title: title, description: description, user: user)
    }
    
    var user: User? = nil
}
struct UserController: RouteCollection, @unchecked Sendable {
    let sessionProtected: RoutesBuilder
    
    func boot(routes: any RoutesBuilder) throws {
        sessionProtected.get("profile", use: renderProfilePage)
        sessionProtected.get("logout", use: performLogout)
    }
    
    @Sendable
    func renderProfilePage(_ req: Request) async throws -> Response {
        let user = try await req.auth.get(Token.self)?.$user.get(on: req.db)

        return try await ProfilePage(user: user)
            .render(with: req)
    }

    @Sendable
    func performLogout(_ req: Request) async throws -> Response {
        req.auth.logout(User.self)
        req.session.destroy()
        
        var redirect = "/"
        if let referrerString = req.headers["Referer"].first,
                let referrerURL = URL(string: referrerString) {
            redirect = referrerURL.path()
        }
        return req.redirect(to: redirect)
    }
}
