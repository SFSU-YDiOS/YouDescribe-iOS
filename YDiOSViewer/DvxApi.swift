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

    /*
    func login_now(username:String, password:String)
    {
        let post_data: NSDictionary = NSMutableDictionary()
        
        
        post_data.setValue(username, forKey: "username")
        post_data.setValue(password, forKey: "password")
        
        let url:URL = URL(string: login_url)!
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url)
        request.httpMethod = "POST"
        request.cachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        
        var paramString = ""
        
        
        for (key, value) in post_data
        {
            paramString = paramString + (key as! String) + "=" + (value as! String) + "&"
        }
        
        request.httpBody = paramString.data(using: String.Encoding.utf8)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (
            data, response, error) in
            
            guard let _:Data = data, let _:URLResponse = response  , error == nil else {
                
                return
            }
            
            
            
            let json: Any?
            
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                return
            }
            
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            
            
            if let data_block = server_response["data"] as? NSDictionary
            {
                if let session_data = data_block["session"] as? String
                {
                    self.login_session = session_data
                    
                    let preferences = UserDefaults.standard
                    preferences.set(session_data, forKey: "session")
                    
                    DispatchQueue.main.async(execute: self.LoginDone)
                }
            }
        })
        
        task.resume()
    }
*/
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
}
