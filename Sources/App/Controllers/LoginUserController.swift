
import Vapor
import Authentication
import Crypto
import Foundation

struct LoginUserController: RouteCollection {
    func boot(router: Router) throws {
        
        router.get("api", "tokens", use: getAllTokens)
        router.get("api", "users", use: getAllLoginUsers)
        let s = router.grouped(AuthTokenMiddleware())
        s.post("api", "token", "user", use: getMyLoginUserHandler)
        
        
        
        
        router.get("api","get_time_interval", use: getTimeIntervalHandler)
        
        let userRouter = router.grouped("api", "user")
        userRouter.post(LoginUser.self, at:"register", String.parameter, use: registerHandler)
        userRouter.post(LoginData.self,at: "login", use: loginHandler)
        userRouter.get("get_code", String.parameter, use: getCodeHandler)
        userRouter.get("get_phone", String.parameter, use: getUserPhoneHandler)
        userRouter.post(ChangePasswordData.self, at:"change_password", use: changePasswordHandler)
        
        let tokenRouter = router.grouped("api", "token")
        tokenRouter.post(LongTokenData.self, at: "short", use: getShortTokenHandler)
        tokenRouter.post(LongTokenData.self, at: "long", use: getLongTokenHandler)
    }
    
    
//  内部api，发送短信
    func getPhoneNumberCode(_ req: Request, number: String, code: String) throws -> Future<Bool>  {
        // 发短信给手机号
        let promise = req.eventLoop.newPromise(Bool.self)
        
        /// Dispatch some work to happen on a background thread
        DispatchQueue.global().async {
            //发送短信
 //
            let ok = true
            promise.succeed(result: ok)
        }
        return promise.futureResult
        
        
        
    }
    
//MARK: --注册类API
    
// api - https://120.78.148.54/api/user/register/(code)
// 注册用户
    func registerHandler(_ req: Request, loginUser:LoginUser) throws -> Future<Response> {
        //验证码校验
        let code = try req.parameters.next(String.self)
        guard code == "vapor" else {
            return try ResponseJSON<Empty>(status: .codeError).encode(for: req)
        }
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
    
    
    
//MARK: --登录类api
// api - https://120.78.148.54/api/get_time_interval
// 校准时间
    func getTimeIntervalHandler(_ req: Request) throws -> Future<Response> {
        let timeInterval = Date().timeIntervalSince1970
        return try ResponseJSON<TimeInterval>(status: .ok, data:timeInterval).encode(for: req)
    }
    
// api - https://120.78.148.54/api/user/get_phone
// 通过用户名获取用户手机号码
    func getUserPhoneHandler(_ req: Request) throws -> Future<Response> {
        let username = try req.parameters.next(String.self)
        return LoginUser.query(on: req).filter(\.username == username).first().flatMap { user in
            guard let user = user else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            return try ResponseJSON<String>(status: .ok, message:"获取用户电话号码成功", data: user.phone).encode(for: req)

        }
    }

// api - https://120.78.148.54/api/user/get_key
// 验证新设备，获取key
    func getLoginUserKeyHandler(_ req: Request, data: GetKeyData) throws -> Future<Response> {
        //验证设备（短信验证）
        let code = "vapor"
        guard data.code == code else {
            return try ResponseJSON<Empty>(status: .codeError).encode(for: req)
        }
        return LoginUser.query(on: req).filter(\.username == data.username).filter(\.phone == data.phone).first().flatMap { user in
            guard let user = user else {
                return try ResponseJSON<Empty>(status: .error).encode(for: req)
            }
            return try ResponseJSON<String>(status: .ok, message: "获取key成功", data: user.key).encode(for: req)
            
        }
    }
    
// api - https://120.78.148.54/api/user/login
// 登录
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
                let password1 = try HMAC.SHA1.authenticate(user.password, key: key1).base64EncodedString()
                let password2 = try HMAC.SHA1.authenticate(user.password, key: key2).base64EncodedString()

                print("pdata:" + loginData.password)
                print("p+:" + user.password)
                print("p++1:" + password1)
                print("p++2:" + password2)
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
    

// MARK: --更换长短token api
    
// api - https://120.78.148.54/api/token/short
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
                    let shortToken = ShortTokenData(userID:token.userID, shortTokenString: token.shortTokenString)
                    return try ResponseJSON<ShortTokenData>(status: .ok, message: "更换短token成功", data: shortToken).encode(for: req)
                }
        }
    }
    
    
// api - https://120.78.148.54/api/token/long
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


    
//MARK: --修改密码 api
    
// api - https://120.78.148.54/api/user/change_password
    func changePasswordHandler(_ req: Request, data: ChangePasswordData) throws -> Future<Response> {
        //验证手机设备（短信验证）
        let code = "vapor"
        guard data.code == code else {
            return try ResponseJSON<Empty>(status: .codeError).encode(for: req)
        }
        
        return LoginUser.query(on: req).filter(\.username == data.username).filter(\.phone == data.phone).first().flatMap { user in
            guard let user = user else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            user.key = data.key
            user.password = data.password
            user.password = data.password
            return user.save(on: req).flatMap { _ in
                return try ResponseJSON<Empty>(status: .ok, message: "修改密码成功").encode(for: req)
                
            }
        }
    
    }
    
// MARK: -- 获取短信验证码
// api - https://120.78.148.54/api/user/get_code
    // 获取短信验证码
    func getCodeHandler(_ req: Request) throws -> Future<Response> {
        let phone = try req.parameters.next(String.self)
        let code = "vapor"

        //发送短信
        return  try self.getPhoneNumberCode(req, number: phone, code: code).flatMap{ ok in
            if ok {
                return try ResponseJSON<Empty>(status: .ok, message: "已发送短信验证码、、").encode(for: req)
            } else {
                return try ResponseJSON<Empty>(status: .error, message: "发送短信失败").encode(for: req)
            }
            
        }
    }
    
    
    
    
//MARK: --发送短信验证码,模拟测试用
    //1，注册
    //2，认证设备
    //3，找回密码
    
    func sendMessage(phoneNumber: String) -> String {
        return "vapor"
    }
    
    
    
    
    
//MARK: --  测试
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
