//
//  NoctuaSDKTests.swift
//  NoctuaSDKTests
//
//  Created by SDK Dev on 31/07/24.
//

import XCTest
@testable import NoctuaSDK

final class NoctuaSDKTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInitAdjustService() throws {
        let jsonAdjustConfig = """
            {
                appToken: "kg7l0jhuem80",
                "environment": "sandbox",
                "eventMap": {
                    "Purchase": "qye2vk",
                    "TestSendEvent": "qye2vk"
                }
            }
            """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let adjustServiceConfig = try decoder.decode(AdjustServiceConfig.self, from: Data(jsonAdjustConfig.utf8))
        
        let adjustService = AdjustService(config: adjustServiceConfig)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
