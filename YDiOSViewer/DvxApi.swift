import Foundation

class DvxApi {
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

    func getPostRequest(urlString: String, params: [String: String]) -> NSMutableURLRequest {

        let url:URL = URL(string: urlString)!
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        
        // Create the parameter body
        var paramString = ""
        for (key, value) in params {
            paramString = paramString + key + "=" + value + "&"
        }
        request.httpBody = paramString.data(using: String.Encoding.utf8)
        return request
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
        return url
    }

    func getUsers(_ params:[String: String]) -> Array<AnyObject> {
        let url:String! = getConstructedUrl("user", params: params)
        return DvxXmlParser().makeRequest(url, separator: "user")
    }

    func addUser(_ params:[String: String]) {
        let url:String! = getConstructedUrl("user", params: params)
    }

    func prepareForLogin(_ params: [String: String]) -> NSMutableURLRequest {
        return self.getPostRequest(urlString: apiBaseUrl + "login", params: params)
    }

    func prepareForAddUser(_ params: [String: String]) -> NSMutableURLRequest {
        return self.getPostRequest(urlString: apiBaseUrl + "user", params: params)
    }

    func getMoviesSearchTable(_ params: [String: String]) -> Array<AnyObject> {
        let url:String! = getConstructedUrl("searchTable", params: params)
        return DvxXmlParser().makeRequest(url, separator: "searchTable")
    }

    func getMovieIdFromMediaId(allMovies: Array<AnyObject>, mediaId: String) -> String {
        for movie in allMovies {
            if movie["movieMediaId"]  as! String == mediaId {
                return movie["movieId"] as! String
            }
        }
        return "" // No movie is found
    }
}
