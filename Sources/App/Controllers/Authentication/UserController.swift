import Vapor
import Fluent

struct ProfilePage: LeafPage {
    var file: String { "profile" }
    
    var meta: PageMetadata
    init(user: User?=nil) {
        let title: String
        let description: String
        if let user = user {
            title = "Logged in as \(user.name)."
            description = "Profile page for \(user.name)."
        } else {
            title = "Not Logged In"
            description = "Not Logged In"
        }
        meta = .init(title: title, description: description, user: user)
    }
}

struct UserController: RouteCollection, @unchecked Sendable {
    let sessionProtected: RoutesBuilder
    
    func boot(routes: any RoutesBuilder) throws {
        sessionProtected.get("profile", use: renderProfilePage)
        sessionProtected.get("logout", use: performLogout)
    }
    
    @Sendable
    func renderProfilePage(_ req: Request) async throws -> Response {
        if let user = try await req.auth.get(Token.self)?.$user.get(on: req.db) {
            return try await ProfilePage(user: user)
                .render(with: req)
        }
        return req.redirect(to: "/login")
    }

    @Sendable
    func performLogout(_ req: Request) async throws -> Response {
        req.auth.logout(User.self)
        req.session.destroy()
        
        var redirect = "/"
        if let referrerString = req.headers["Referer"].first,
                let referrerURL = URL(string: referrerString),
                !["/login","/profile","/logout"].contains(referrerURL.path()) {
            redirect = referrerURL.path()
        }
        return req.redirect(to: redirect)
    }
}
