import Foundation
import Alamofire

// FileManager extensions for documents and cache directories
extension FileManager {
    class func documentsDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as [String]
        return paths[0]
    }
    
    class func cachesDir() -> String {
        var paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true) as [String]
        return paths[0]
    }
}

// Thread-safe counter for counting the the number of asynchronous audio downloads completed
class AtomicCounter {
    
    private var mutex = pthread_mutex_t()
    private var counter: UInt = 0
    
    init() {
        pthread_mutex_init(&mutex, nil)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    func getCounter() -> UInt {
        return counter
    }

    func incrementAndGet() -> UInt {
        pthread_mutex_lock(&mutex)
        defer {
            pthread_mutex_unlock(&mutex)
        }
        counter += 1
        return counter
    }
}

protocol DownloadAudioDelegate {
    func readDownloadUrls(urls: [URL])
    func readTotalDownloaded(count: Int)
    func registerNewDownload(url: URL, success: Int)
}

class DownloadAudio: NSObject, URLSessionDownloadDelegate {

    var downloadTask: URLSessionDownloadTask!
    var backgroundSession: Foundation.URLSession!
    var downloadUrlMap: [String:Any] = [:]

    let dvxApi = DxvApi()
    var downloadFileUrls: [URL] = []
    let mycounter = AtomicCounter()
    var delegate:DownloadAudioDelegate
    var downloadState: Int = 0

    init(delegate:DownloadAudioDelegate) {
        self.delegate = delegate
        super.init()
        let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
        backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
    }

    var Timestamp: String {
        return "\(NSDate().timeIntervalSince1970 * 1000)"
    }
    
    func getDownloadUrl(metadata: AnyObject) -> URL {
        let clipName: String = ((metadata["clipFilename"]!! as AnyObject).description.replacingOccurrences(of: ".wav", with: ".mp3"))
        var documentsURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        documentsURL.appendPathComponent("YouDescribe/" + clipName)
        return documentsURL
    }

    public func doSimpleDownload() {
        let url = URL(string: "http://dvxtest.ski.org:8080/dvx2Api/clip?AppId=ydesc&ClipId=2110&Movie=1087")!
        downloadTask = backgroundSession.downloadTask(with: url)
        downloadTask.resume()
    }
    func getDownloadFileDestination(metadata: AnyObject) -> DownloadRequest.DownloadFileDestination {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = self.getDownloadUrl(metadata: metadata)
            return (destinationURL:documentsURL, options:[.removePreviousFile, .createIntermediateDirectories])
        }
        return destination
    }

    /*
     NOTE: This is currently not being used in favor of synchonous downloading.
     */
    func prepareAllClipCache(clips: [AnyObject]) {
        // Asynchronously prepare the cache
        var myDownloadUrls: [URL] = []

        // Perform a download only if it is not already in progress
        if self.downloadState != 2 {
            for clip in clips {
                let audioUrl:String = dvxApi.getAudioClipUrl(
                    ["ClipId": (clip["clipId"]!! as AnyObject).description,
                     "Movie":(clip["movieFk"]!! as AnyObject).description])
                myDownloadUrls.append(self.getDownloadUrl(metadata: clip)) // Should download the clips in order
                self.downloadState = 2
                //doDownload(URL(string: audioUrl)!, metadata: clip)
                // doDownload(URL(string: "http://www.sample-videos.com/audio/mp3/wave.mp3")!, metadata: clip)

            }
            self.delegate.readDownloadUrls(urls: myDownloadUrls)
            self.downloadFileUrls = myDownloadUrls
        }
    }

    func prepareClipCache(clips: [AnyObject], index: Int) -> String {
        // Download the current clip if not already downloaded
        if index < clips.count {
            let clip = clips[index]
            //let clip = clips[0]
            let audioUrl:String = dvxApi.getAudioClipUrl(
                ["ClipId": (clip["clipId"]!! as AnyObject).description,
                 "Movie":(clip["movieFk"]!! as AnyObject).description])
            //print("Sleeping..")
            //sleep(4)
            doDownload(URL(string: audioUrl)!, metadata: clip)
            //doDownload(URL(string: "http://www.sample-videos.com/audio/mp3/wave.mp3")!, metadata: clip)
            //doDownload(URL(string: "http://dvxtest.ski.org:8080/dvx2Api/clip?AppId=ydesc&ClipId=2580&Movie=1059")!, metadata: clip)

            //doDownloadURLSession(URL(string: "http://dvxtest.ski.org:8080/dvx2Api/clip?AppId=ydesc&ClipId=2110&Movie=1087")!, metadata: clip)
            print(audioUrl)
            return audioUrl
        }
        return ""
    }
    
    func doDownloadURLSession(_ audioDataUrl: URL, metadata: AnyObject) {
        downloadUrlMap[audioDataUrl.absoluteString] = metadata
        downloadTask = backgroundSession.downloadTask(with: audioDataUrl)
        downloadTask.resume()
    }

    // Attempt to download the clip and return the status code.
    func doDownload(_ audioDataUrl: URL, metadata: AnyObject) {

        let destination = getDownloadFileDestination(metadata: metadata)
        //let myurl:URL = URL(string: "http://dvxtest.ski.org:8080/dvx2Api/clip")!
        //let myparameters: Parameters = ["AppId" : "ydesc", "ClipId":"2580", "Movie":"1059" ]
        
        //let myurl:URL = URL(string: "http://s.w.org/images/core/3.9/JellyRollMorton-BuddyBoldensBlues.mp3")!
        //let myparameters: Parameters = ["play" : "1"]
        // Alamofire.download(myurl, method: .get, parameters: myparameters, encoding: JSONEncoding.default, to: destination)
        let urlRequest = URLRequest(url: audioDataUrl)
        do {
            //var encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: myparameters)
            
            print("THE ENCODED URL IS ")
            
            //print(encodedURLRequest)
            //encodedURLRequest.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 8_3 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) FxiOS/1.0 Mobile/12F69 Safari/600.1.4", forHTTPHeaderField: "User-Agent")
            //encodedURLRequest.setValue("*/*", forHTTPHeaderField: "Accept")
            //encodedURLRequest.setValue("application/zip", forHTTPHeaderField: "Content-Type")
            Alamofire.download(audioDataUrl, to: destination)
            //Alamofire.download(encodedURLRequest, to: destination)
                .downloadProgress { progress in
                    print("Download Progress: \(progress.completedUnitCount)")
                }
                .responseData { response in
                    print(response)
                    print("The destination URL is ")
                    print(response.destinationURL?.path)
                    print(response.debugDescription)
                    print(response.result)
                    self.delegate.readTotalDownloaded(count: Int(self.mycounter.incrementAndGet()))
                    var success = 0
                    if response.response?.statusCode != 200 {
                        success = -1
                    }
                    self.delegate.registerNewDownload(url: response.destinationURL!, success: success)
                    if (Int(self.mycounter.getCounter()) == self.downloadFileUrls.count) {
                        print("Completed all downloads.")
                        self.downloadState = 1 // completed all downloads
                    }
                //print(encodedURLRequest.allHTTPHeaderFields?.count)
            }
            
        } catch _ {
            print("ERROR#@$@#$@#$")
        }
    }
    
    // URL Session classes
    // 1
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL){
        print("Finally got here")
        print(downloadTask.currentRequest?.url?.absoluteString)
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        //let destination = getDownloadFileDestination(metadata: downloadUrlMap[(downloadTask.currentRequest?.url?.absoluteString)!] as AnyObject)
        //print("The destination is ")
        //print(destination)
        //let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath + "/file.pdf")
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath + "/media.mp3")
        print("Document Directory Path")
        print(documentDirectoryPath)
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            //showFileWithPath(destinationURLForFile.path)
            print("Completed")
        }
        else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                print("Completed")
                // show file
                //showFileWithPath(destinationURLForFile.path)
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
    }
    // 2
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64){
        //progressView.setProgress(Float(totalBytesWritten)/Float(totalBytesExpectedToWrite), animated: true)
    }
    
    
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        downloadTask = nil
        //progressView.setProgress(0.0, animated: true)
        if (error != nil) {
            print("ERROR!!!")
            print(error)
        }else{
            print("The task finished transferring data successfully")
        }
    }

}
