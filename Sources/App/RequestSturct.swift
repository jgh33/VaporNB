
import Vapor

// 用户登录时的参数结构
struct LoginData:Content {
    var username: String
    var password: String
}


//用户更换token时的参数结构，长短token的更换都是相同的参数
struct LongTokenData: Content {
    var userID: LoginUser.ID
    var longTokenString: String
}

//用户通过短token拿数据时的参数，主要是authMiddleware中间件
struct ShortTokenData: Content {
    var userID: LoginUser.ID
    var shortTokenString: String
}

//用户验证新设备的时候（获取key）时，提交的数据结构
struct GetKeyData: Content {
    var username: String
    var phone: String
    var code: String
}


//用户修改密码时提交的参数
struct ChangePasswordData:Content {
    var code: String
    var password: String
    var username: String
    var phone: String
    var key: String
    
}
