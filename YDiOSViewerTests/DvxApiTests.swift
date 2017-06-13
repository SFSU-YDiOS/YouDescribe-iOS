//
//  DvxApiTests.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 5/6/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import XCTest

@testable import YouDescribe_iOS

class DvxApiTests: XCTestCase {
    
    var dvxApi: DvxApi!
    override func setUp() {
        super.setUp()
        dvxApi = DvxApi()
    }
    
    override func tearDown() {
        super.tearDown()
        dvxApi = nil
    }
    
    // Tests query to get all movies
    func testGetAllMovies() {
        let results = dvxApi?.getMovies([:])
        XCTAssertGreaterThan(results!.count, 1500, "Did not find more than 1500 movies")
    }

    // Test query to get movie by media ID
    func testGetMoviesByMediaID() {
        let results:Array<AnyObject> = (dvxApi?.getMovies(["MediaId" : "kPsyx1aEFI0"]))!
        XCTAssertEqual(results.count, 1, "Could not find a movie with the given MediaId")
    }
    
    // Tests the number of attributes returned by a movie object
    func testMovieObject() {
        let result:Array<AnyObject> = (dvxApi?.getMovies(["MediaId" : "kPsyx1aEFI0"]))!
        XCTAssertEqual(result[0].count, 7, "Mismatch in the number of attributes in a Movie object")
    }

    // Tests the performance of the query to get all movies.
    func testPerformanceAllMovies() {
        self.measure {
            _ = self.dvxApi?.getMovies([:])
        }
    }
}
