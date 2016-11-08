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
    func registerNewDownload(url: URL)
}

class DownloadAudio {
    let dvxApi = DxvApi()
    var downloadFileUrls: [URL] = []
    let mycounter = AtomicCounter()
    var delegate:DownloadAudioDelegate
    var downloadState: Int = 0

    init(delegate:DownloadAudioDelegate) {
        self.delegate = delegate
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

    func getDownloadFileDestination(metadata: AnyObject) -> DownloadRequest.DownloadFileDestination {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = self.getDownloadUrl(metadata: metadata)
            return (destinationURL:documentsURL, options:[.removePreviousFile, .createIntermediateDirectories])
        }
        return destination
    }

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
                doDownload(URL(string: audioUrl)!, metadata: clip)
            }
            self.delegate.readDownloadUrls(urls: myDownloadUrls)
            self.downloadFileUrls = myDownloadUrls
        }
    }

    func prepareClipCache(clips: [AnyObject], index: Int) -> String {
        // Download the current clip if not already downloaded
        if index < clips.count {
            let clip = clips[index]
            let audioUrl:String = dvxApi.getAudioClipUrl(
                ["ClipId": (clip["clipId"]!! as AnyObject).description,
                 "Movie":(clip["movieFk"]!! as AnyObject).description])
            doDownload(URL(string: audioUrl)!, metadata: clip)
            print(audioUrl)
            return audioUrl
        }
        return ""
    }
    
    
    func doDownload(_ audioDataUrl: URL, metadata: AnyObject) {

        let destination = getDownloadFileDestination(metadata: metadata)
        print(destination)
        print("The cache directory is ")
        print(FileManager.cachesDir())
        Alamofire.download(audioDataUrl, to: destination)
            .downloadProgress { progress in
                print("Download Progress: \(progress.completedUnitCount)")
            }
            .responseData { response in
                print(response)
                print("The destination URL is ")
                print(response.destinationURL?.path)
                self.delegate.readTotalDownloaded(count: Int(self.mycounter.incrementAndGet()))
                self.delegate.registerNewDownload(url: response.destinationURL!)
                if (Int(self.mycounter.getCounter()) == self.downloadFileUrls.count) {
                    print("Completed all downloads.")
                    self.downloadState = 1 // completed all downloads
                }
        }
    }
}
