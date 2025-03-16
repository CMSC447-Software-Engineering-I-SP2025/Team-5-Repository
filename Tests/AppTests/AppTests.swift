@testable import App
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct AppTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()   
            try await test(app)
            try await app.autoRevert()   
        }
        catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Test Hello World Route")
    func helloWorld() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "hello", afterResponse: { res async in
                #expect(res.status == .ok)
                #expect(res.body.string == "Hello, world!")
            })
        }
    }
    
    @Test("Getting all the Movies")
    func getAllMovies() async throws {
        try await withApp { app in
            let sampleMovies = [Movie(title: "sample1"), Movie(title: "sample2")]
            try await sampleMovies.create(on: app.db)
            
            try await app.testing().test(.GET, "movies", afterResponse: { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode([MovieDTO].self) == sampleMovies.map { $0.toDTO()} )
            })
        }
    }
    
    @Test("Creating a Movie")
    func createMovie() async throws {
        let newDTO = MovieDTO(id: nil, title: "test")
        
        try await withApp { app in
            try await app.testing().test(.POST, "movies", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let models = try await Movie.query(on: app.db).all()
                #expect(models.map({ $0.toDTO().title }) == [newDTO.title])
            })
        }
    }
    
    @Test("Deleting a Movie")
    func deleteMovie() async throws {
        let testMovies = [Movie(title: "test1"), Movie(title: "test2")]
        
        try await withApp { app in
            try await testMovies.create(on: app.db)
            
            try await app.testing().test(.DELETE, "movies/\(testMovies[0].requireID())", afterResponse: { res async throws in
                #expect(res.status == .noContent)
                let model = try await Movie.find(testMovies[0].id, on: app.db)
                #expect(model == nil)
            })
        }
    }
}

extension MovieDTO: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}
