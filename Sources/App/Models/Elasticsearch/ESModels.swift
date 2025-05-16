import Vapor


// Search response
struct Shards: Content {
    let total, successful, skipped, failed: Int
}

struct Hits<T: Content>: Content {
    let total: HitsTotal
    let max_score: Double
    let hits: [Hit<T>]
}

struct HitsTotal: Content {
    let value: Int
    let relation: String
}
struct Hit<T: Content>: Content {
    let _index: String
    let _id: String
    let _score: Double
    let _ignored: [String]?
    let _source: T
}
struct ESResponse<T: Content>: Content {
    let took: Int
    let timed_out: Bool
    let _shards: Shards
    let hits: Hits<T>
}


// Search query

struct ESQueryBody: Content {
    struct Query: Content {
        struct QueryMatch: Content {
            let query: String
            let fields: [String]
            let op: String
            enum CodingKeys: String, CodingKey {
                case query, fields, op = "operator"
            }
        }
        let multi_match: QueryMatch
    }
    let query: Query
    let _source: [String]
    let from, size: Int
}
