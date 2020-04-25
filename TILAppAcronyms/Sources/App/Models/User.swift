import Foundation
import Vapor
import Authentication


final class User: Codable {
  let id: UUID
  let name: String
  let username: String

  init(id: UUID, name: String, username: String) {
    self.id = id
    self.name = name
    self.username = username
  }
}

extension User: Content {}
extension User: Authenticatable {}
