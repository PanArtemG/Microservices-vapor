import Vapor
import Crypto

struct UsersController: RouteCollection {
  func boot(router: Router) throws {
    let usersGroup = router.grouped("users")
    usersGroup.get(use: getAllHandler)
    usersGroup.get(User.parameter, use: getHandler)
    usersGroup.post(User.self, use: createHandler)
  }

  func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
    return User.query(on: req).decode(data: User.Public.self).all()
  }

  func getHandler(_ req: Request) throws -> Future<User.Public> {
    return try req.parameters.next(User.self).convertToPublic()
  }

  func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
    user.password = try BCrypt.hash(user.password)
    return user.save(on: req).convertToPublic()
  }
}
