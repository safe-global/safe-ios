// THIS FILE IS GENERATED. DO NOT MODIFY BY HAND.

import Foundation
import Solidity

public enum GnosisSafeProxyFactory_v1_3_0 {
    public struct calculateCreateProxyWithNonceAddress: SolContractFunction, SolKeyPathTuple {
        public var _singleton: Sol.Address
        public var initializer: Sol.Bytes
        public var saltNonce: Sol.UInt256
        
        public static var keyPaths: [AnyKeyPath] = [
            \Self._singleton,
             \Self.initializer,
             \Self.saltNonce
        ]
        
        public init(_singleton : Sol.Address, initializer : Sol.Bytes, saltNonce : Sol.UInt256) {
            self._singleton = _singleton
            self.initializer = initializer
            self.saltNonce = saltNonce
        }
        
        public init() {
            self.init(_singleton: .init(), initializer: .init(), saltNonce: .init())
        }
        
        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var proxy: Sol.Address
            
            public static var keyPaths: [AnyKeyPath] = [
                \Self.proxy
            ]
            
            public init(proxy : Sol.Address) {
                self.proxy = proxy
            }
            
            public init() {
                self.init(proxy: .init())
            }
        }
    }
    
    public struct createProxy: SolContractFunction, SolKeyPathTuple {
        public var singleton: Sol.Address
        public var data: Sol.Bytes
        
        public static var keyPaths: [AnyKeyPath] = [
            \Self.singleton,
             \Self.data
        ]
        
        public init(singleton : Sol.Address, data : Sol.Bytes) {
            self.singleton = singleton
            self.data = data
        }
        
        public init() {
            self.init(singleton: .init(), data: .init())
        }
        
        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var proxy: Sol.Address
            
            public static var keyPaths: [AnyKeyPath] = [
                \Self.proxy
            ]
            
            public init(proxy : Sol.Address) {
                self.proxy = proxy
            }
            
            public init() {
                self.init(proxy: .init())
            }
        }
    }
    
    public struct createProxyWithCallback: SolContractFunction, SolKeyPathTuple {
        public var _singleton: Sol.Address
        public var initializer: Sol.Bytes
        public var saltNonce: Sol.UInt256
        public var callback: Sol.Address
        
        public static var keyPaths: [AnyKeyPath] = [
            \Self._singleton,
             \Self.initializer,
             \Self.saltNonce,
             \Self.callback
        ]
        
        public init(_singleton : Sol.Address, initializer : Sol.Bytes, saltNonce : Sol.UInt256, callback : Sol.Address) {
            self._singleton = _singleton
            self.initializer = initializer
            self.saltNonce = saltNonce
            self.callback = callback
        }
        
        public init() {
            self.init(_singleton: .init(), initializer: .init(), saltNonce: .init(), callback: .init())
        }
        
        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var proxy: Sol.Address
            
            public static var keyPaths: [AnyKeyPath] = [
                \Self.proxy
            ]
            
            public init(proxy : Sol.Address) {
                self.proxy = proxy
            }
            
            public init() {
                self.init(proxy: .init())
            }
        }
    }
    
    public struct createProxyWithNonce: SolContractFunction, SolKeyPathTuple {
        public var _singleton: Sol.Address
        public var initializer: Sol.Bytes
        public var saltNonce: Sol.UInt256
        
        public static var keyPaths: [AnyKeyPath] = [
            \Self._singleton,
             \Self.initializer,
             \Self.saltNonce
        ]
        
        public init(_singleton : Sol.Address, initializer : Sol.Bytes, saltNonce : Sol.UInt256) {
            self._singleton = _singleton
            self.initializer = initializer
            self.saltNonce = saltNonce
        }
        
        public init() {
            self.init(_singleton: .init(), initializer: .init(), saltNonce: .init())
        }
        
        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var proxy: Sol.Address
            
            public static var keyPaths: [AnyKeyPath] = [
                \Self.proxy
            ]
            
            public init(proxy : Sol.Address) {
                self.proxy = proxy
            }
            
            public init() {
                self.init(proxy: .init())
            }
        }
    }
    
    public struct proxyCreationCode: SolContractFunction, SolKeyPathTuple {
        
        
        public static var keyPaths: [AnyKeyPath] = [
            
        ]
        
        
        
        public init() {
            
        }
        
        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bytes
            
            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]
            
            public init(_arg0 : Sol.Bytes) {
                self._arg0 = _arg0
            }
            
            public init() {
                self.init(_arg0: .init())
            }
        }
    }
    
    public struct proxyRuntimeCode: SolContractFunction, SolKeyPathTuple {
        
        
        public static var keyPaths: [AnyKeyPath] = [
            
        ]
        
        
        
        public init() {
            
        }
        
        public struct Returns: SolEncodableTuple, SolKeyPathTuple {
            public var _arg0: Sol.Bytes
            
            public static var keyPaths: [AnyKeyPath] = [
                \Self._arg0
            ]
            
            public init(_arg0 : Sol.Bytes) {
                self._arg0 = _arg0
            }
            
            public init() {
                self.init(_arg0: .init())
            }
        }
    }
}
