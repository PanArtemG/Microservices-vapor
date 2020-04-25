import Vapor
import Fluent

struct AcronymsController: RouteCollection {
  func boot(router: Router) throws {
    router.get(use: getAllHandler)
    router.get(Acronym.parameter, use: getHandler)
    router.get("user", UUID.parameter, use: getUsersAcronyms)
    
    let authHostname: String
    // 1
    if let host = Environment.get("AUTH_HOSTNAME") {
      authHostname = host
    } else {
      authHostname = "localhost"
    }
    // 2
    let authGroup = router.grouped(UserAuthMiddleware(authHostname: authHostname))
    authGroup.post(use: createHandler)
    authGroup.delete(Acronym.parameter, use: deleteHandler)
    authGroup.put(Acronym.parameter, use: updateHandler)
  }
  
  func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
    return Acronym.query(on: req).all()
  }
  
  func getHandler(_ req: Request) throws -> Future<Acronym> {
    return try req.parameters.next(Acronym.self)
  }
  
  func createHandler(_ req: Request) throws -> Future<Acronym> {
    let data = try req.content.syncDecode(AcronymData.self)
    let user = try req.requireAuthenticated(User.self)
    let acronym = Acronym(short: data.short, long: data.long, userID: user.id)
    return acronym.save(on: req)
  }
  
  func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
    return try req.parameters.next(Acronym.self).delete(on: req).transform(to: .noContent)
  }
  
  func updateHandler(_ req: Request) throws -> Future<Acronym> {
    return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(AcronymData.self)) { acronym, updateData in
      acronym.short = updateData.short
      acronym.long = updateData.long
      let user = try req.requireAuthenticated(User.self)
      acronym.userID = user.id
      return acronym.save(on: req)
    }
  }
  
  func getUsersAcronyms(_ req: Request) throws -> Future<[Acronym]> {
    let userID = try req.parameters.next(UUID.self)
    return Acronym.query(on: req).filter(\.userID == userID).all()
  }
}

struct AcronymData: Content {
  let short: String
  let long: String
}
