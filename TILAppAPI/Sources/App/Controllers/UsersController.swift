import Vapor

struct UsersController: RouteCollection {
    let userServiceURL: String
    let acronymsServiceURL: String
    
    init(
        userServiceHostname: String,
        acronymsServiceHostname: String) {
        userServiceURL = "http://\(userServiceHostname):8081"
        acronymsServiceURL = "http://\(acronymsServiceHostname):8082"
    }
    
    func boot(router: Router) throws {
        let routeGroup = router.grouped("api", "users")
        
        routeGroup.get(use: getAllHandler)
        routeGroup.get(UUID.parameter, use: getHandler)
        routeGroup.post(use: createHandler)
        routeGroup.post("login", use: loginHandler)
        
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
    
    func loginHandler(_ req: Request) throws -> Future<Response> {
        // 1
        return try req.client().post("\(userServiceURL)/auth/login") { loginRequest in
            // 2
            guard let authHeader = req.http.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            // 3
            loginRequest.http.headers.add(name: .authorization,
                                          value: authHeader)
        }
    }
    
    func getAcronyms(_ req: Request) throws -> Future<Response> {
        // 1
        let userID = try req.parameters.next(UUID.self)
        // 2
        return try req.client()
            .get("\(acronymsServiceURL)/user/\(userID)")
    }
}

struct CreateUserData: Content {
    let name: String
    let username: String
    let password: String
}
