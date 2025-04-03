import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!", "message": "Testing!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    app.get("people", ":id") { req async throws -> PersonDTO in
        guard let personID = req.parameters.get("id", as: Int.self) else {
            throw Abort(.badRequest, reason: "Error, Invalid ID")
        }

        guard let person = try await Person.find(personID, on: req.db) else {
            throw Abort(.notFound, reason: "Person not found")
        }

        return PersonDTO(from: person)
    }

    try app.register(collection: MovieController())
}
