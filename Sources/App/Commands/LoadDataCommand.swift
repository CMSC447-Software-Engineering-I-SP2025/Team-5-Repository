import Vapor
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
            let res = try await runShellCommand("unzip tmdb_dump_2025-03-12.zip")
            context.console.print(res)
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


/// Runs a shell command asynchronously and returns its output as a String.
/// - Parameter command: The shell command to execute.
/// - Returns: The standard output (or combined output in case of an error) from the command.
/// - Throws: An error if the command fails to run or returns a non-zero exit status.
func runShellCommand(_ command: String) async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        let process = Process()
        // Use bash to run the command.
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        // Pipe to capture both standard output and standard error.
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // This closure is called when the process terminates.
        process.terminationHandler = { process in
            // Read the complete output from the pipe.
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            // Check if the command was successful.
            if process.terminationStatus == 0 {
                continuation.resume(returning: output)
            } else {
                let error = NSError(
                    domain: "ShellCommandError",
                    code: Int(process.terminationStatus),
                    userInfo: [NSLocalizedDescriptionKey: output]
                )
                continuation.resume(throwing: error)
            }
        }
        
        // Start the process.
        do {
            try process.run()
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
