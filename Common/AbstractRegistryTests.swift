//
//  Copyright © 2018 Gnosis. All rights reserved.
//

import XCTest
@testable import Common

class AbstractRegistryTests: XCTestCase {

    func test_put_linksService() {
        let instance = MyClass()
        ApplicationServiceRegistry.put(service: instance, for: MyProtocol.self)
        XCTAssertTrue(ApplicationServiceRegistry.service(for: MyProtocol.self) === instance)
    }

}

private protocol MyProtocol: class {}
private class MyClass: MyProtocol {}
private class OtherClass {}
