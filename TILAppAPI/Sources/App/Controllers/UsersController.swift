import Vapor

struct UsersController: RouteCollection {
  let userServiceURL = "http://localhost:8081"
  let acronymsServiceURL = "http://localhost:8082"

  func boot(router: Router) throws {
    let routeGroup = router.grouped("api", "users")
    
    routeGroup.get(use: getAllHandler)
    routeGroup.get(UUID.parameter, use: getHandler)
    routeGroup.post(use: createHandler)
  }
    
    func getAllHandler(_ req: Request) throws -> Future<Response> {
      return try req.client().get("\(userServiceURL)/users")
    }

    // 2
    func getHandler(_ req: Request) throws -> Future<Response> {
      let id = try req.parameters.next(UUID.self)
      return try req.client().get("\(userServiceURL)/users/\(id)")
    }

    // 3
    func createHandler(_ req: Request) throws -> Future<Response> {
      return try req.client().post("\(userServiceURL)/users") { createRequest in
        // 4
        try createRequest.content.encode(
          req.content.syncDecode(CreateUserData.self))
      }
    }
}

struct CreateUserData: Content {
  let name: String
  let username: String
  let password: String
}
