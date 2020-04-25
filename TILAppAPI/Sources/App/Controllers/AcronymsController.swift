import Vapor

struct AcronymsController: RouteCollection {
    let acronymsServiceURL: String
    let userServiceURL: String
    
    init(
        acronymsServiceHostname: String,
        userServiceHostname: String) {
        acronymsServiceURL = "http://\(acronymsServiceHostname):8082"
        userServiceURL = "http://\(userServiceHostname):8081"
    }
    func boot(router: Router) throws {
        let acronymsGroup = router.grouped("api", "acronyms")
        
        acronymsGroup.get(use: getAllHandler)
        acronymsGroup.get(Int.parameter, use: getHandler)
        acronymsGroup.post(use: createHandler)
        acronymsGroup.put(Int.parameter, use: updateHandler)
        acronymsGroup.delete(Int.parameter, use: deleteHandler)
        acronymsGroup.get(Int.parameter, "user", use: getUserHandler)
        
    }
    
    func getAllHandler(_ req: Request) throws -> Future<Response> {
        return try req.client().get("\(acronymsServiceURL)/")
    }
    
    // 2
    func getHandler(_ req: Request) throws -> Future<Response> {
        let id = try req.parameters.next(Int.self)
        return try req.client().get("\(acronymsServiceURL)/\(id)")
    }
    
    func createHandler(_ req: Request) throws -> Future<Response> {
        // 1
        return try req.client().post("\(acronymsServiceURL)/") {
            createRequest in
            // 2
            guard let authHeader = req.http.headers[.authorization].first else {
                throw Abort(.unauthorized)
            }
            // 3
            createRequest.http.headers.add(name: .authorization, value: authHeader)
            // 4
            try createRequest.content.encode(req.content.syncDecode(CreateAcronymData.self))
        }
    }
    
    func updateHandler(_ req: Request) throws -> Future<Response> {
        // 1
        let acronymID = try req.parameters.next(Int.self)
        // 2
        return try req.client()
            .put("\(acronymsServiceURL)/\(acronymID)") { updateRequest in
                // 3
                guard let authHeader =
                    req.http.headers[.authorization].first else {
                        throw Abort(.unauthorized)
                }
                // 4
                updateRequest.http.headers.add(name: .authorization, value: authHeader)
                // 5
                try updateRequest.content.encode(req.content.syncDecode(CreateAcronymData.self))
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<Response> {
        // 6
        let acronymID = try req.parameters.next(Int.self)
        // 7
        return try req.client()
            .delete("\(acronymsServiceURL)/\(acronymID)") { deleteRequest in
                // 8
                guard let authHeader = req.http.headers[.authorization].first else {
                    throw Abort(.unauthorized)
                }
                // 9
                deleteRequest.http.headers.add(name: .authorization, value: authHeader)
        }
    }
    
    func getUserHandler(_ req: Request) throws -> Future<Response> {
        // 1
        let acronymID = try req.parameters.next(Int.self)
        // 2
        return try req
            .client()
            .get("\(acronymsServiceURL)/\(acronymID)")
            .flatMap(to: Response.self) { response in
                // 3
                let acronym =
                    try response.content.syncDecode(Acronym.self)
                // 4
                return try req
                    .client()
                    .get("\(self.userServiceURL)/users/\(acronym.userID)")
        }
    }
}

struct CreateAcronymData: Content {
    let short: String
    let long: String
}
