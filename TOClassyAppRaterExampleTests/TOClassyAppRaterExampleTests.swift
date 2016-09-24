//
//  TOClassyAppRaterExampleTests.swift
//  TOClassyAppRaterExampleTests
//
//  Created by Peter Hunt on 23/09/2016.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

import XCTest

class TOClassyAppRaterExampleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
   
   
   
   func testCheckForUpdates() {
      //let networkExpectation = expectation(description: "Wait for url to load.")
      
      TOClassyAppRaterSwift.appId = "493845493"
      TOClassyAppRaterSwift.checkForUpdates()
      print(TOClassyAppRaterSwift.localizedUsersRatedString)
      
      
      //waitForExpectations(timeout: 5, handler: nil)
   }
}
