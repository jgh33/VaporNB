
import Vapor


struct LoginData:Content {
    var username: String
    var password: String
}


struct ShortToken: Content {
    var userID: LoginUser.ID
    var shortTokenString: String
    var shortTokenExpiryTime: TimeInterval
}


struct LongTokenData: Content {
    var userID: LoginUser.ID
    var longTokenString: String
}


struct ShortTokenData: Content {
    var userID: LoginUser.ID
    var shortTokenString: String
}
