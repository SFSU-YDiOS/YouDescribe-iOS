//
//  VideoTableViewController.swift
//  YDiOSViewer
//
//  Created by Madhura Patil on 10/16/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SwiftyJSON

class VideoTableViewController: UITableViewController, YTPlayerViewDelegate, UISearchResultsUpdating {
    
    let dvxApi = DxvApi()
    var allMovies : [AnyObject] = []
    var filteredMovies : [AnyObject] = []
    var youTubeSearchMovies = [String: String]()
    var resultSearchController = UISearchController(searchResultsController: nil)
    var thumbnailUrl: String = ""
    var videoName : AnyObject?
    var apiKey = "AIzaSyAI9H-v1Zyt1bN6W7fSz-Zl0jrfU0UYzho"
    var maxYouTubeResults = 5
    var videoIdYT : String = ""
    var titleYT : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        allMovies = dvxApi.getMovies([:])
        tableView.estimatedRowHeight = CGFloat(allMovies.count)
        
        //print("\n\nestimated row height\n\n")
        //print(tableView.estimatedRowHeight)
        //print("all movies count =")
        //print(allMovies[1]["movieMediaId"])
        //print(allMovies.count)
        
        resultSearchController.searchResultsUpdater = self
        resultSearchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        self.resultSearchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = resultSearchController.searchBar
        self.tableView.reloadData()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.resultSearchController.isActive{
            return self.filteredMovies.count
        }
        else{
            return self.allMovies.count
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoTableCell", for: indexPath) as! VideoTableViewCell
        
        // Configure the cell...
        
        if self.resultSearchController.isActive{
            videoName = filteredMovies[indexPath.row]
        }
        else{
            videoName = allMovies[indexPath.row]
        }
        cell.videoLabel.font =
            UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)
        cell.videoLabel.text = videoName?["movieName"] as? String
        let movieMediaId = videoName?["movieMediaId"] as! String
        
        thumbnailUrl = "http://img.youtube.com/vi/"
        thumbnailUrl = thumbnailUrl.appending(movieMediaId)
        thumbnailUrl = thumbnailUrl.appending("/0.jpg")
        
        var url = URL(string: thumbnailUrl)
        if (url == nil){
            url = URL(string: "https://www.youtube.com/yt/brand/media/image/YouTube-logo-full_color.png")
            var data = NSData(contentsOf:url!)
            if (data != nil) {
                cell.videoThumbnail.image = UIImage(data:data! as Data)
            }
        }
        else{
            var data = NSData(contentsOf:url!)
            if (data != nil) {
                cell.videoThumbnail.image = UIImage(data:data! as Data)
            }
            else{
                url = URL(string: "https://www.youtube.com/yt/brand/media/image/YouTube-logo-full_color.png")
                var data = NSData(contentsOf:url!)
                if (data != nil) {
                    cell.videoThumbnail.image = UIImage(data:data! as Data)
                }
            }
        }
        
        
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "PlaySelectedVideo" {
            let videoViewController = segue.destination
                as! ViewController
            
            let myIndexPath = self.tableView.indexPathForSelectedRow
            let row : AnyObject?
            
            if resultSearchController.isActive && resultSearchController.searchBar.text != "" {
                row = filteredMovies[(myIndexPath?.row)!]
            } else {
                row = allMovies[(myIndexPath?.row)!]
            }
            
            videoViewController.movieID = row?["movieMediaId"] as? String
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func updateSearchResults(for searchController: UISearchController) {
        self.filteredMovies.removeAll(keepingCapacity: false)
        let selfPredicate = NSPredicate(format: "SELF.movieName CONTAINS[c] %@", searchController.searchBar.text!)
        let array = (self.allMovies as NSArray).filtered(using: selfPredicate)
        self.filteredMovies = array as [AnyObject]
        
        //search using YouTube API
        if (self.resultSearchController.searchBar.text != ""){
            let youTubeSearchString = self.resultSearchController.searchBar.text?.replacingOccurrences(of: " ", with: ",")
            let config = URLSessionConfiguration.default
            let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id,snippet(title,channelTitle))&q=\(youTubeSearchString!)&type=video&maxResults=\(maxYouTubeResults)&key=\(apiKey)")
            print("\n\nURL\n\n: ",url)
            let task = URLSession.shared.dataTask(with: url! as URL) {(data, response, error) in
                let json = JSON(data: data!)
                if let items = json["items"].array{
                    for item in items{
                        self.videoIdYT = item["id"]["videoId"].stringValue
                        self.titleYT = item["snippet"]["title"].stringValue
                        self.youTubeSearchMovies["movieMediaId"] = self.videoIdYT
                        self.youTubeSearchMovies["movieName"] = self.titleYT
                        self.filteredMovies.append(self.youTubeSearchMovies as AnyObject)
                    }
                    print("\n\nSearched list of videos: ",self.filteredMovies)
                    self.tableView.reloadData()
                }
            }
            task.resume()
        }
        self.tableView.reloadData()
    }
}
