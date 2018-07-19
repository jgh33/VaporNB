
import Vapor
import Fluent


struct AuthTokenMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
      let short = try request.content.decode(ShortTokenData.self)
        return short.flatMap(to: Response.self) { shortTokenData in
            return Token.query(on: request)
                .filter(\.userID == shortTokenData.userID)
                .filter(\.shortTokenString == shortTokenData.shortTokenString)
                .filter(\.shortTokenExpiryTime > Date().timeIntervalSince1970)
                .first()
                .flatMap { token in
                    guard token != nil else {
                        return try ResponseJSON<Token>(status: .shortToken).encode(for: request)
                    }
                    return try next.respond(to: request)

            }
        }
        
    }
    
    
}
