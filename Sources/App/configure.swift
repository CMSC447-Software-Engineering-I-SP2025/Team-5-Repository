import NIOSSL
import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Encoders for custom date formatting
    // Ensure manual conversion to/from camel/snake cases where necessary
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .custom { date, encoder in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        var container = encoder.singleValueContainer()
        let dateString = formatter.string(from: date)
        try container.encode(dateString)
    }
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = formatter.date(from: dateString) {
            return date
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
    }
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    let urldecoder = URLEncodedFormDecoder(configuration: .init(dateDecodingStrategy: .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let date = formatter.date(from: dateString) {
            return date
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
    }))
    ContentConfiguration.global.use(urlDecoder: urldecoder)
    

    let urlEncoder = URLEncodedFormEncoder(configuration: .init(arrayEncoding: .values,
                                                                dateEncodingStrategy: .custom { date, encoder in
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        var container = encoder.singleValueContainer()
        let dateString = formatter.string(from: date)
        try container.encode(dateString)
    }))
    ContentConfiguration.global.use(urlEncoder: urlEncoder)
    
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "movies_user",
        password: Environment.get("DATABASE_PASSWORD") ?? "movies",
        database: Environment.get("DATABASE_NAME") ?? "movies_database",
        tls: .disable)
    ), as: .psql)
    
//    app.logger.logLevel = .debug
    
    app.routes.defaultMaxBodySize = "10mb"
    
    // Migrations
    app.migrations.add(CreateInitialTables())
    app.migrations.add(AuthenticationMigration())
    app.migrations.add(SessionRecord.migration)

    app.asyncCommands.use(LoadDataCommand(), as: "import")
    // Views
    
    app.views.use(.leaf)
    app.leaf.cache.isEnabled = app.environment.isRelease

    app.sessions.use(.fluent)

    // register routes
    try routes(app)
}
