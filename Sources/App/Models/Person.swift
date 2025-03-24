import Fluent
import struct Foundation.UUID

final class Person: Model, @unchecked Sendable {
    static let schema = "people"
    
    @ID(custom: "id", generatedBy: .user)
    var id: Int?
    
    @Field(key: "adult")
    var adult: Bool
    
    @Field(key: "gender")
    var gender: Int
    
    @Field(key: "known_for_department")
    var knownForDepartment: String
    
    @Field(key: "name")
    var name: String?
    
    @Field(key: "original_name")
    var originalName: String
    
    @Field(key: "popularity")
    var popularity: Double
    
    @Field(key: "profile_path")
    var profilePath: String?
    
    init() {}
    init(id: Int,
         adult: Bool,
         gender: Int,
         knownForDepartment: String,
         name: String?,
         originalName: String,
         popularity: Double,
         profilePath: String? = nil) {
        
        self.id = id
        self.adult = adult
        self.gender = gender
        self.knownForDepartment = knownForDepartment
        self.name = name
        self.originalName = originalName
        self.popularity = popularity
        self.profilePath = profilePath
    }
}
