import Fluent
import struct Foundation.UUID

final class ProductionCompany: Model, @unchecked Sendable {
    static let schema = "production_companies"
    
    @ID(custom: "id", generatedBy: .user)
    var id: Int?
    
    @Field(key: "logo_path")
    var logoPath: String?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "origin_country")
    var originCountry: String
    
    init() {}
    init(dto: ProductionCompanyDTO) {
        self.id = dto.id
        self.logoPath = dto.logoPath
        self.name = dto.name
        self.originCountry = dto.originCountry
    }
    
    var toDTO: ProductionCompanyDTO {
        .init(id: id ?? 0, logoPath: logoPath, name: name, originCountry: originCountry)
    }
}

final class ProductionCountry: Model, @unchecked Sendable {
    static let schema = "production_countries"
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "iso_3166_1")
    var iso3166_1: String?
    
    @Field(key: "name")
    var name: String
    
    init() {}
    init(dto: ProductionCountryDTO) {
        self.iso3166_1 = dto.iso31661
        self.name = dto.name
    }
    
    var toDTO: ProductionCountryDTO { .init(iso31661: iso3166_1, name: name) }
}

// Pivot

final class MovieProductionCompany: Model, @unchecked Sendable {
    static let schema = "movie_production_company"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "movie_id")
    var movie: Movie
    
    @Parent(key: "production_company_id")
    var productionCompany: ProductionCompany
}

final class MovieProductionCountry: Model, @unchecked Sendable {
    static let schema = "movie_production_country"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "movie_id")
    var movie: Movie
    
    @Parent(key: "production_country_id")
    var productionCountry: ProductionCountry
}
