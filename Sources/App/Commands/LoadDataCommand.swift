import Vapor
import ZIPFoundation
import Foundation

struct LoadDataCommand: AsyncCommand {
    struct Signature: CommandSignature { }
   
    @Argument(name: "dump_file")
    var dumpFile: String
    
    var help: String {
        "Load Data from dump file"
    }
    
    func run(using context: CommandContext, signature: Signature) async throws {
        context.console.print("Loading Data")
        
        // Load zip
        context.console.print("Unzipping...")
        let fileManager = FileManager()
        let currentWorkingPath = fileManager.currentDirectoryPath
        let sourceURL = URL(fileURLWithPath: currentWorkingPath)
            .appending(path:"tmdb_dump_2025-03-12.zip")
        
        var destinationURL = URL(fileURLWithPath: currentWorkingPath)
        
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: sourceURL, to: destinationURL)
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
        }
        
        // Open file
        let extractedPath = URL(fileURLWithPath: currentWorkingPath).appending(path:"tmdb_dump_2025-03-12.json")
        let fileData = try Data(contentsOf: extractedPath)
        
        // Remove file
        try fileManager.removeItem(at: extractedPath)
        
        
        // parse
        var decoder = JSONDecoder()
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
        
        // decode
        let parsedData = try decoder.decode([String: MovieDTO].self, from: fileData)
        
        for (key, movie) in parsedData {
            context.console.print(key)
            _ = try await Movie.createOrUpdate(on: context.application.db,
                                               from: movie)
        }
    }
}

