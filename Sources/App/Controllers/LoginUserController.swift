
import Vapor
import Authentication
import Crypto

struct LoginUserController: RouteCollection {
    func boot(router: Router) throws {
        // MARK: --测试用aip
        router.get("api", "tokens", use: getAllTokens)
        router.get("api", "users", use: getAllLoginUsers)
        let s = router.grouped(AuthTokenMiddleware())
        s.post("api", "token", "user", use: getMyLoginUserHandler)
        
        let userRouter = router.grouped("api", "user")
        userRouter.post(LoginUser.self, at:"register", use: registerHandler)
        userRouter.post(LoginData.self,at: "login", use: loginHandler)
//        userRouter.post(UsernameAndPhoneData.self, at: "verify_username_and_phone", use: <#T##(Request) throws -> ResponseEncodable#>)
        
        let tokenRouter = router.grouped("api", "token")
        tokenRouter.post(LongTokenData.self, at: "short", use: getShortTokenHandler)
        tokenRouter.post(LongTokenData.self, at: "long", use: getLongTokenHandler)
    }
    
    
//    func getPhoneNumberCode(_ req: Request) throws -> Future<String> {
//        // 发短信给手机号
//    }
//
//    func authenticationPhoneNumberCode(_ req: Request) throws -> Future<String> {
//        // 验证短信手机号
//    }
    // 验证用户名和手机账号是否被注册过
    func auth(_ req: Request, userAndPhone:UsernameAndPhoneData) throws -> Future<Response> {
        return LoginUser.query(on: req).group(.or) { or in
            or.filter(\.username == userAndPhone.username)
            or.filter(\.phone == userAndPhone.phone)
            }
            .first().flatMap { user in
                guard user == nil else {
                    if user!.username == userAndPhone.username {
                        return try ResponseJSON<Empty>(status: .userExist).encode(for: req)
                    }else if user!.phone == userAndPhone.phone {
                        return try ResponseJSON<Empty>(status: .phoneRegistered).encode(for: req)
                    }
                    return try ResponseJSON<Empty>(status: .error).encode(for: req)
                }
                //发送短信
                
                
                return try ResponseJSON<Empty>(status: .ok, message: "用户名和手机均为被使用").encode(for: req)
                
        }
    }
    
    func registerHandler(_ req: Request, loginUser:LoginUser) throws -> Future<Response> {
        // 1,验证账号密码格式（账号不能纯数字，密码必须大小写结合，大于等于6位）
        
        // 2,验证账号是否已存在
        return LoginUser.query(on: req).group(.or) { or in
            or.filter(\.username == loginUser.username)
            or.filter(\.phone == loginUser.phone)
            }
            .first().flatMap { user in
                guard user == nil else {
                    if user!.username == loginUser.username {
                        return try ResponseJSON<Empty>(status: .userExist).encode(for: req)
                    }else if user!.phone == loginUser.phone {
                        return try ResponseJSON<Empty>(status: .phoneRegistered).encode(for: req)
                    }
                    return try ResponseJSON<Empty>(status: .error).encode(for: req)
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
                let now1 = Date()
                let now2 = now1.addingTimeInterval(-60)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMddHHmm"
                let key1 = dateFormatter.string(from: now1)
                let key2 = dateFormatter.string(from: now2)
                print(key1, key2)
                let password1 = try HMAC.SHA1.authenticate(user.password, key: key1).hexEncodedString()
                let password2 = try HMAC.SHA1.authenticate(user.password, key: key2).hexEncodedString()

                // 2,验证密码
                guard loginData.password == password1 || loginData.password == password2 else {
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

    func getPhoneCode(_ req: Request) throws -> Future<Response> {
        let code = "vapor"
        return try ResponseJSON<String >(status: .ok, data: code).encode(for: req)
    }
    
    func getLoginUserKeyHandler(_ req: Request, phoneData: PhoneData) throws -> Future<Response> {
        //验证设备（短信验证）
        let code = "vapor"
        guard phoneData.code == code else {
            return try ResponseJSON<Empty>(status: .codeError).encode(for: req)
        }
        return LoginUser.query(on: req).filter(\.username == phoneData.username).filter(\.phone == phoneData.phone).first().flatMap { user in
            guard let user = user else {
                return try ResponseJSON<Empty>(status: .error).encode(for: req)
            }
            return try ResponseJSON<String>(status: .ok, message: "获取key成功", data: user.key).encode(for: req)
            
        }
    }
  
    
    //MARK: --发送短信验证码,模拟测试用
    //1，注册
    //2，认证设备
    //3，找回密码
    
    func sendMessage(phoneNumber: String) -> String {
        return "vapor"
    }
    
    
    
    
    
//MARK: --    测试
    func getAllTokens(_ req: Request) -> Future<Response> {
        return Token.query(on: req).all().flatMap{ tokens in
            return try ResponseJSON<[Token]>(status: .ok, data: tokens).encode(for: req)
        }
    }
    
    func getAllLoginUsers(_ req: Request) -> Future<Response> {
        return LoginUser.query(on: req).all().flatMap{ loginUsers in
            return try ResponseJSON<[LoginUser]>(status: .ok, data: loginUsers).encode(for: req)
        }
    }
    
    
    func getMyLoginUserHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(ShortTokenData.self).flatMap{ shortTokenData in
            return Token.query(on: req).filter(\.userID == shortTokenData.userID).first().flatMap { token in
                return token!.loginUser.get(on: req).flatMap { loginUser in
                    return try ResponseJSON<LoginUser>(status: .ok, data: loginUser).encode(for: req)
                }
            }
        }
        
    }
 
}
