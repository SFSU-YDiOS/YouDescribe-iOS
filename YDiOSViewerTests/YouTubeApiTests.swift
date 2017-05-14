//
//  YouTubeApi.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 5/6/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import XCTest

@testable import YouDescribe_iOS

class YouTubeApiTests: XCTestCase {
    
    var youTubeApi: YouTubeApi!
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        youTubeApi = YouTubeApi()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetContentDetails() {
        youTubeApi.getContentDetails(mediaId: "k-Z8xxygd2", finished: {
            (result) in
            XCTAssertEqual(result["duration"], "RTERT")
        })
    }
    
    func testGetInfo() {
        youTubeApi.getInfo(mediaId: "k-Z8xxygd2", finished: {
            (result) in
            
        })
    }
    
    func testGetDuration() {
        youTubeApi.getContentDetails(mediaId: "k-Z8xxygd2", finished: {
            (result) in
            let formattedDuration:String = self.youTubeApi.getYoutubeFormattedDuration(result["duration"]!)
            XCTAssert(formattedDuration == "00:00")
        })
    }
    
}
