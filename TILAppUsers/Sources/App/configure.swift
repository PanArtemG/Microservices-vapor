import FluentPostgreSQL
import Vapor
import Authentication
import Redis

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())
    
    let port: Int
    if let environmentPort = Environment.get("PORT") {
        port = Int(environmentPort) ?? 8081
    } else {
        port = 8081
    }
    let nioServerConfig = NIOServerConfig.default(port: port)
    services.register(nioServerConfig)
    
    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    // Configure a database
    var databases = DatabasesConfig()
    let databaseConfig: PostgreSQLDatabaseConfig
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let username = Environment.get("DATABASE_USER") ?? "vapor"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    let databaseName = Environment.get("DATABASE_DB") ?? "vapor"
    
    databaseConfig = PostgreSQLDatabaseConfig(
        hostname: hostname,
        username: username,
        database: databaseName,
        password: password)
    
    let postgres = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: postgres, as: .psql)
    
    var redisConfig = RedisClientConfig()
    if let redisHostname = Environment.get("REDIS_HOSTNAME") {
        redisConfig.hostname = redisHostname
    }
    let redis = try RedisDatabase(config: redisConfig)
    databases.add(database: redis, as: .redis)
    
    services.register(databases)
    
    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: DatabaseIdentifier<User.Database>.psql)
    services.register(migrations)
}
