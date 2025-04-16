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
            .appending(path:"movie_dump.zip")
        
        var destinationURL = URL(fileURLWithPath: currentWorkingPath)
        
        do {
            let res = try await runShellCommand("unzip movie_dump.zip")
            context.console.print(res)
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
        }
        
        // Open file
        let extractedPath = URL(fileURLWithPath: currentWorkingPath).appending(path:"movie_dump.json")
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
        
        try await parsedData.asyncForEach { key, movie in
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
extension Sequence {
    /// Processes each element asynchronously with a concurrency limit of 8.
    /// - Parameter body: An async throwing closure to process each element.
    /// - Throws: Rethrows any error produced by the async closure.
    func asyncForEach(_ body: @escaping (Element) async throws -> Void) async throws {
        let semaphore = DispatchSemaphore(value: 8)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                // Wait until there's an available "worker" slot.
                semaphore.wait()
                group.addTask {
                    defer { semaphore.signal() }
                    try await body(element)
                }
            }
            // Wait for all tasks to finish.
            for try await _ in group { }
        }
    }
}
