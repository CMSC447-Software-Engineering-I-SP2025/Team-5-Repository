import Vapor

enum AuthenticationError: String, DebuggableError {
    case passwordsDontMatch
    case emailAlreadyExists
    case invalidEmailOrPassword
    case refreshTokenOrUserNotFound
    case refreshTokenHasExpired
    case userNotFound
    case emailTokenHasExpired
    case emailTokenNotFound
    case emailIsNotVerified
    case invalidPasswordToken
    case passwordTokenHasExpired
}

extension AuthenticationError: AbortError {
    var status: HTTPResponseStatus {
        switch self {
        case .passwordsDontMatch,.emailAlreadyExists, .emailTokenHasExpired:
            return .badRequest
            
        case .refreshTokenOrUserNotFound, .userNotFound,
                .emailTokenNotFound, .invalidPasswordToken:
            return .notFound
            
        case .invalidEmailOrPassword, .refreshTokenHasExpired,
                .emailIsNotVerified, .passwordTokenHasExpired:
            return .unauthorized
        }
    }
    
    var reason: String {
        switch self {
        case .passwordsDontMatch: "Passwords did not match"
        case .emailAlreadyExists: "A user with that email already exists"
        case .invalidEmailOrPassword: "Email or password was incorrect"
        case .refreshTokenOrUserNotFound: "User or refresh token was not found"
        case .refreshTokenHasExpired: "Refresh token has expired"
        case .userNotFound: "User was not found"
        case .emailTokenNotFound: "Email token not found"
        case .emailTokenHasExpired: "Email token has expired"
        case .emailIsNotVerified: "Email is not verified"
        case .invalidPasswordToken: "Invalid reset password token"
        case .passwordTokenHasExpired: "Reset password token has expired"
        }
    }
    
    var identifier: String {
        return self.rawValue
    }
}
