
import Vapor
import Authentication

struct LoginUserController: RouteCollection {
    func boot(router: Router) throws {
        router.get("api", "tokens", use: getAllTokens)
        router.get("api", "users", use: getAllLoginUsers)
       
        let s = router.grouped(AuthTokenMiddleware())
        s.post("api", "token", "user", use: getMyLoginUserHandler)
        
        let sginUpRoutes = router.grouped("api", "sginup")
        sginUpRoutes.post(LoginUser.self, use: sginUpHandler)
        
        let loginRoutes = router.grouped("api", "login")
        loginRoutes.post(LoginData.self, use: loginHandler)
        
        let shortRoutes = router.grouped("api", "short")
        shortRoutes.post(LongTokenData.self, use: getShortTokenHandler)
        
        let longRoutes = router.grouped("api", "long")
        longRoutes.post(LongTokenData.self, use: getLongTokenHandler)
    }
    
    
//    func getPhoneNumberCode(_ req: Request) throws -> Future<String> {
//        // 发短信给手机号
//    }
//
//    func authenticationPhoneNumberCode(_ req: Request) throws -> Future<String> {
//        // 验证短信手机号
//    }
    
    
    
    func sginUpHandler(_ req: Request, loginUser:LoginUser) throws -> Future<Response> {
        // 1,验证账号密码格式（账号不能纯数字，密码必须大小写结合，大于等于6位）
        
        // 2,验证账号是否已存在
        let searchTerm = loginUser.username
        return LoginUser.query(on: req).group(.or) { or in
            or.filter(\.username == searchTerm)
            or.filter(\.phone == searchTerm)
            }
            .first().flatMap { user in
                guard user == nil else {
                    return try ResponseJSON<Empty>(status: .userExist).encode(for: req)
                }
                return loginUser.save(on: req).flatMap{ _ in
                    return try ResponseJSON<Empty>(status: .ok, message: "注册成功").encode(for: req)
                }
            }
      
    }
    
    
    func loginHandler(_ req: Request, loginData: LoginData) throws -> Future<Response> {
        // 1,通过账号名搜索用户
        let searchTerm = loginData.username
        return LoginUser.query(on: req).group(.or) { or in
            or.filter(\.username == searchTerm)
            or.filter(\.phone == searchTerm)
            }
            .first().flatMap { user in
                guard let user = user else {
                    return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
                }
                // 2,验证密码
                guard loginData.password == user.password else {
                    return try ResponseJSON<Empty>(status: .passwordError).encode(for: req)
                }
                // 3,更新长短Token并保存
                return try user.token.query(on: req).first().flatMap { token in
                    if let token = token {
                        return try token.makeNewAllTokens().save(on: req).flatMap{ token in
                            return try ResponseJSON<Token>(status: .ok, message: "登陆成功", data: token).encode(for: req)
                        }
                        
                    }
                    
                    let newToken = try Token(userID: user.requireID())
                    return try newToken.makeNewAllTokens().save(on: req).flatMap{ token in
                        return try ResponseJSON<Token>(status: .ok, message: "登陆成功", data: token).encode(for: req)
                    }
                }
            }
    }
    

    func getShortTokenHandler(_ req: Request, longTokenData:LongTokenData) throws -> Future<Response> {

        // 验证longToken
        let longToken = longTokenData.longTokenString
        return Token.query(on: req).filter(\.userID == longTokenData.userID ).filter(\.longTokenString == longToken)
            .first().flatMap { tokenTep in
                guard let tokenTep = tokenTep else {
                    return try ResponseJSON<Empty>(status: .longToken).encode(for: req)
                }
                // kan
                guard tokenTep.longTokenExpiryTime > Date().timeIntervalSince1970  else {
                    return try ResponseJSON<Empty>(status: .longToken).encode(for: req)
                }
                // 生成短Token并保存
                return try tokenTep.makeNewShortToken().save(on: req).flatMap { token in
                    let shortToken = ShortToken(userID:token.userID, shortTokenString: token.shortTokenString, shortTokenExpiryTime: token.shortTokenExpiryTime)
                    return try ResponseJSON<ShortToken>(status: .ok, message: "更换短token成功", data: shortToken).encode(for: req)
                }
        }
    }
    
    
    
    func getLongTokenHandler(_ req: Request, longTokenData: LongTokenData) throws -> Future<Response> {
        // 验证longToken
        let longToken = longTokenData.longTokenString
        return Token.query(on: req).filter(\.userID == longTokenData.userID ).filter(\.longTokenString == longToken)
            .first().flatMap { tokenTep in
                guard let tokenTep = tokenTep else {
                    
                    return try ResponseJSON<Token>(status: .longToken).encode(for: req)
                }
                // kan
                guard tokenTep.longTokenExpiryTime > Date().timeIntervalSince1970  else {
                    return try ResponseJSON<Token>(status: .longToken).encode(for: req)
                }
                // 生成Tokens并保存
                return try tokenTep.makeNewAllTokens().save(on: req).flatMap{ token in
                    return try ResponseJSON<Token>(status: .ok, message: "更换长token成功", data: token).encode(for: req)
                }
                
        }
    }

    
    
//    测试
    func getAllTokens(_ req: Request) -> Future<[Token]> {
        return Token.query(on: req).all()
    }
    
    func getAllLoginUsers(_ req: Request) -> Future<[LoginUser]> {
        return LoginUser.query(on: req).all()
    }
    
    
    func getMyLoginUserHandler(_ req: Request) throws -> Future<LoginUser> {
        return try req.content.decode(ShortTokenData.self).flatMap{ shortTokenData in
            return Token.query(on: req).filter(\.userID == shortTokenData.userID).first().flatMap(to: LoginUser.self) { token in
                return token!.loginUser.get(on: req)
            }
        }
        
    }
 
}
