import Vapor

struct AcronymsController: RouteCollection {
  let userServiceURL = "http://localhost:8081"
  let acronymsServiceURL = "http://localhost:8082"

  func boot(router: Router) throws {
    let acronymsGroup = router.grouped("api", "acronyms")
    
    acronymsGroup.get(use: getAllHandler)
    acronymsGroup.get(Int.parameter, use: getHandler)
    
    }
    
    func getAllHandler(_ req: Request) throws -> Future<Response> {
      return try req.client().get("\(acronymsServiceURL)/")
    }

    // 2
    func getHandler(_ req: Request) throws -> Future<Response> {
      let id = try req.parameters.next(Int.self)
      return try req.client().get("\(acronymsServiceURL)/\(id)")
    }
}

struct CreateAcronymData: Content {
  let short: String
  let long: String
}
