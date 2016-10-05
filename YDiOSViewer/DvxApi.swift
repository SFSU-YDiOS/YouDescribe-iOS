//
//  DvxApi.swift
//  YDiOSViewer
//
//  Created by Rupal Khilari on 9/28/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import Foundation

class DxvApi {
    let defaultAppId = "ydesc"
    let apiBaseUrl = "http://dvxtest.ski.org:8080/dvx2Api/"

    func getConstructedUrl(_ query: String, params:[String: String]) -> String {
        var url:String = apiBaseUrl + query + "?AppId=ydesc"
        // loop through the arguments and create the url parameters.
        var paramString = ""
        var paramArray:[String] = Array()
        for (k, v) in params {
            paramArray.append(k + "=" + (v ))
        }
        paramString = paramArray.joined(separator: "&")
        
        if (paramString != ""){
            url += "&"+paramString
        }
        return url
    }

    func getMovies(_ params:[String: String]) -> Array<AnyObject> {
        let url:String! = getConstructedUrl("movie", params: params)
        return DvxXmlParser().makeRequest(url, separator: "movie")
    }
    
    func getClips(_ params:[String: String]) -> Array<AnyObject> {
        let url:String! = getConstructedUrl("clip/metadata", params: params)
        print("THE URL Is " + url)
        return DvxXmlParser().makeRequest(url, separator: "clip")
    }
    
}
