import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
  let usersHostname: String
  let acronymsHostname: String

  // 1
  if let users = Environment.get("USERS_HOSTNAME") {
    usersHostname = users
  } else {
    usersHostname = "localhost"
  }

  // 2
  if let acronyms = Environment.get("ACRONYMS_HOSTNAME") {
    acronymsHostname = acronyms
  } else {
    acronymsHostname = "localhost"
  }

  // 3
  try router.register(collection: UsersController(
                        userServiceHostname: usersHostname,
                        acronymsServiceHostname: acronymsHostname))
  try router.register(collection: AcronymsController(
                        acronymsServiceHostname: acronymsHostname,
                        userServiceHostname: usersHostname))
}
