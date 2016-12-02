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
            paramArray.append(k + "=" + (v))
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
        return DvxXmlParser().makeRequest(url, separator: "clip")
    }

    func getAudioClipUrl(_ params:[String: String]) -> String {
        let url:String = getConstructedUrl("clip", params: params)
        print("Audio url is " + url)
        return url
    }

    func getUsers(_ params:[String: String]) -> Array<AnyObject> {
        let url:String! = getConstructedUrl("user", params: params)
        return DvxXmlParser().makeRequest(url, separator: "user")
    }

}
