import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!", "message": "Testing!"])
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }

    app.get("people", ":personID") { req async throws -> PersonDTO in
        guard let personID = req.parameters.get("personID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Error, invalid ID")
        }

        guard let person = try await Person.find(personID, on: req.db).map(\.personDTO) else {
            throw Abort(.notFound, reason: "Person not found")
        }

        return person
    }


    try app.register(collection: MovieController())
}
