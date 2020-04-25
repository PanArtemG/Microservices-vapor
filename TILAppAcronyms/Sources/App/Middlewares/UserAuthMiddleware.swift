import Vapor


final class UserAuthMiddleware: Middleware {
    
  func respond(to request: Request, chainingTo next: Responder) throws -> Future<Response> {
      
    guard let token = request.http.headers.bearerAuthorization else {
          throw Abort(.unauthorized)
        }
    
      return try request
        .client()
        .post("http://localhost:8081/auth/authenticate") { authRequest in
            
          try authRequest.content.encode(AuthenticateData(token: token.token))
          }.flatMap(to: Response.self) { response in
            
            guard response.http.status == .ok else {
              if response.http.status == .unauthorized {
                throw Abort(.unauthorized)
              } else {
                throw Abort(.internalServerError)
              }
            }
            
            let user = try response.content.syncDecode(User.self)
            try request.authenticate(user)
            return try next.respond(to: request)
          }
    }
}

struct AuthenticateData: Content {
  let token: String
}
