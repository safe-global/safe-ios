//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// `AbstractRegistry` is the base class for service registries, implementing a simple dependency injection mechanism.
///
/// Each registry class is a singleton that stores mapping from protocols or class types to objects - instances that
/// implement that protocol or are that class or subclass.
///
/// The registry provides implementations of two basic methods:
/// `AbstractRegistry.put(service:for:)` and `AbstractRegistry.service(for:)`.
/// Usually, you implement your own registry by adding getters that return specific type or protocol instance
/// using `AbstractRegistry.service(for:)` method under the hood. For example:
///
///     class MyRegistry: AbstractRegistry {
///         static var myService: MyService {
///             return service(for: MyService.self)
///         }
///     }
///
/// Note, that before using services of the registry you must provide implementations by calling
/// `AbstractRegistry.put(service:for:)` method. You can put either mock services, for example,
/// in test cases, or real implementations - in AppDelegate.
///
/// Either way, your modules using the protocols can be independent of the implementations, providing
/// you a plain dependency injection mechanism.
open class AbstractRegistry {

    private static var instance = AbstractRegistry()
    private var services = [String: Any]()

    /// Stores the implementation of `type` service in memory.
    ///
    /// You can later get the stored service with `service(...)` method.
    ///
    /// - Parameters:
    ///   - service: The instance implementing `type` protocol or class
    ///   - type: The class or protocol to store in registry.
    public class func put<T>(service: T, for type: T.Type) {
        instance.put(service: service, for: type)
    }

    /// Returns stored service of type `type`. Crashes if implementation for the service was not found.
    ///
    /// - Parameter type: Protocol or class registered before
    /// - Returns: instance in the registry.
    public class func service<T>(for type: T.Type) -> T {
        return instance.service(for: type)
    }

}

// MARK: - Instance Methods

private extension AbstractRegistry {

    func put<T>(service: T, for type: T.Type) {
        services[key(type)] = service
    }

    func service<T>(for type: T.Type) -> T {
        return services[key(type)]! as! T
    }

    func key(_ type: Any.Type) -> String {
        return String(describing: type)
    }

}
