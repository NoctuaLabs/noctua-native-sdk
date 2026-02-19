import Foundation

enum InitError: Error {
    case invalidArgument(String)
}

enum ConfigurationError: Error {
    case fileNotFound
    case invalidFormat
    case missingKey(String)
    case unknown(Error)
}

enum AdjustServiceError: Error {
    case adjustNotFound
    case invalidConfig(String)
}

enum FirebaseServiceError: Error {
    case firebaseNotFound
    case invalidConfig(String)
}

enum FacebookServiceError: Error {
    case facebookNotFound
    case invalidConfig(String)
}
