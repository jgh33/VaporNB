
import Vapor
import Authentication

struct LoginUserController: RouteCollection {
    func boot(router: Router) throws {
        router.get("api", "tokens", use: getAllTokens)
        
        let sginUpRoutes = router.grouped("api", "sginup")
        sginUpRoutes.post(LoginUser.self, use: sginUpHandler)
        
        let loginRoutes = router.grouped("api", "login")
        loginRoutes.post(LoginUser.self, use: loginHandler)
        
        let shortRoutes = router.grouped("api", "short")
        shortRoutes.post(Token.self, use: getShortTokenHandler)
        
        let longRoutes = router.grouped("api", "long")
        longRoutes.post(Token.self, use: getLongTokenHandler)
    }
    
    
//    func getPhoneNumberCode(_ req: Request) throws -> Future<String> {
//        // 发短信给手机号
//    }
//
//    func authenticationPhoneNumberCode(_ req: Request) throws -> Future<String> {
//        // 验证短信手机号
//    }
    
    func sginUpHandler(_ req: Request, loginUser:LoginUser) throws -> Future<HTTPStatus> {
        // 1,验证账号密码格式（账号不能纯数字，密码必须大小写结合，大于等于6位）
        
        // 2,验证账号是否已存在
        let searchTerm = loginUser.username
        return LoginUser.query(on: req).group(.or) { or in
            or.filter(\.username == searchTerm)
            or.filter(\.phone == searchTerm)
            }
            .first().flatMap(to: HTTPStatus.self) { user in
                guard user == nil else {
                    throw Abort(.badRequest)
                }
                return loginUser.save(on: req).transform(to: HTTPStatus.ok)
            }
      
    }
    
    func loginHandler(_ req: Request, loginUser: LoginUser) throws -> Future<Token> {
        // 1,通过账号名搜索用户
        let searchTerm = loginUser.username
        return LoginUser.query(on: req).group(.or) { or in
            or.filter(\.username == searchTerm)
            or.filter(\.phone == searchTerm)
            }
            .first().flatMap(to: Token.self) { user in
                guard let user = user else {
                    throw Abort(.badRequest)
                }
                // 2,验证密码
                guard loginUser.password == user.password else {
                    throw Abort(.badRequest)
                }
                // 3,更新长短Token并保存
                return try user.token.query(on: req).first().flatMap(to: Token.self){ token in
                    if let token = token {
                        return try token.makeNewAllTokens().save(on: req)
                    }
                    
                    let newToken = try Token(userID: user.requireID())
                    return  try newToken.makeNewAllTokens().save(on: req)
                    
                }
            
                
            }
        

       
    }
    
    
    struct ShortToken: Content {
        var shortTokenString: String
        var shortTokenExpiryTime: TimeInterval
    }
    func getShortTokenHandler(_ req: Request, token:Token) throws -> Future<ShortToken> {

        // 验证longToken
        let longToken = token.longTokenString
        return Token.query(on: req).filter(\.userID == token.userID ).filter(\.longTokenString == longToken)
            .first().flatMap(to: ShortToken.self) { tokenTep in
                guard let tokenTep = tokenTep else {
                    throw Abort(.badRequest)
                }
                // kan
                guard tokenTep.longTokenExpiryTime > Date().timeIntervalSince1970  else {
                    throw Abort(.badRequest)
                }
                // 生成短Token并保存
                try tokenTep.makeNewShortToken()
                return tokenTep.save(on: req).map(to: ShortToken.self) { token -> ShortToken in
                    return ShortToken(shortTokenString: token.shortTokenString, shortTokenExpiryTime: token.shortTokenExpiryTime)
                }
        }
        
        

    }
    
    func getLongTokenHandler(_ req: Request, token:Token) throws -> Future<Token> {
        // 验证longToken
        let longToken = token.longTokenString
        return Token.query(on: req).filter(\.userID == token.userID ).filter(\.longTokenString == longToken)
            .first().flatMap(to: Token.self) { tokenTep in
                guard let tokenTep = tokenTep else {
                    throw Abort(.badRequest)
                }
                // kan
                guard tokenTep.longTokenExpiryTime > Date().timeIntervalSince1970  else {
                    throw Abort(.badRequest)
                }
                
                // 生成Tokens并保存
                try tokenTep.makeNewAllTokens()
                return tokenTep.save(on: req)
        }
        
    }
    
//    测试
    func getAllTokens(_ req: Request) -> Future<[Token]> {
        return Token.query(on: req).all()
    }
    
   
}
