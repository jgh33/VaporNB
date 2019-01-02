import FluentPostgreSQL
import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first
    try services.register(FluentPostgreSQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    // Configure a postgreSQL database
    var username = ""
    var password = ""
    #if os(Linux)
    username = "ubuntu"
    password = "123321"
    #else
    username = "jgh"
    password = "123"
    #endif
    let postgresqlConfig = PostgreSQLDatabaseConfig(
        hostname: "127.0.0.1",
        port: 5432,
        username: username,
        database: "vapornb",
        password: password
    )
    services.register(postgresqlConfig)


    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: LoginUser.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    services.register(migrations)

}
