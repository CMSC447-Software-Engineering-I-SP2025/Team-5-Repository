import Fluent
import Vapor

struct MovieDTO: Content {
    var id: UUID?
    var title: String?
    
    func toModel() -> Movie {
        let model = Movie()
        
        model.id = self.id
        if let title = self.title {
            model.title = title
        }
        return model
    }
}
