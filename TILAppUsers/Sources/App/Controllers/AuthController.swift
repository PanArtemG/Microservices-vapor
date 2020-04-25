import Vapor
import Crypto
import Redis
import Fluent

struct AuthController: RouteCollection {
    func boot(router: Router) throws {
        
        let authGroup = router.grouped("auth")
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = authGroup.grouped(basicAuthMiddleware)
        
        basicAuthGroup.post("login", use: loginHandler)
        
        
        authGroup.post( AuthenticateData.self, at: "authenticate", use: authenticate)
        
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return req.withPooledConnection(to: .redis) { redis in
            redis.jsonSet(token.tokenString, to: token)
                .transform(to: token)
        }
    }
    
    func authenticate(_ req: Request, data: AuthenticateData) throws -> Future<User.Public> {
        return req.withPooledConnection(to: .redis) { redis in
            return redis.jsonGet(data.token, as: Token.self)
                .flatMap(to: User.Public.self) { token in
                    guard let token = token else {
                        throw Abort(.unauthorized)
                    }
                    return User.query(on: req)
                        .filter(\.id == token.userID)
                        .first()
                        .unwrap(or: Abort(.internalServerError))
                        .convertToPublic()
            }
        }
    }
}


struct AuthenticateData: Content {
    let token: String
}
