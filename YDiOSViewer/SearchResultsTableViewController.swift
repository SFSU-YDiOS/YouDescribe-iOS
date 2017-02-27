//
//  SearchResultsTableViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/27/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit
import SwiftyJSON

class SearchResultsTableViewController: UITableViewController, SearchResultTableViewCellDelegate {

    var searchString: String = ""
    var filteredMovies: [AnyObject] = []
    var youDescribeMovies: [AnyObject] = []
    var displayMovies: [AnyObject] = []
    var authorMap:[String:String] = [:]
    var apiKey = "AIzaSyApPkoF9hjzHB6Wg7cGuOteLLGC3Cpj35s"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.getYouTubeResults()

        // Search from the second screen (using the same logic)
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SearchAgainNotification"), object: nil, queue: nil) { notification in
            var myObject = notification.object as! [AnyObject]
            let lastItem = myObject.removeLast()
            self.filteredMovies = myObject
            self.searchString = lastItem["searchString"] as! String
            self.youDescribeMovies = myObject
            self.displayMovies = myObject
            self.getYouTubeResults()
        }
        
        // setup the notification observer
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SearchFilterNotification"), object: nil, queue: nil) { notification in
            // Cache the filteredMovies before overwriting it.
            
            if notification.object as! Int == 1 {
                self.filteredMovies = self.youDescribeMovies
            }
            else {
                self.filteredMovies = self.displayMovies
            }
            self.tableView.reloadData()
        }
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
        return self.filteredMovies.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultsTableViewCell", for: indexPath) as! SearchResultsTableViewCell

        // Configure the cell...
        /*cell.nameLabel.text = "Hello"
        return cell*/
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "SearchResultsTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! SearchResultsTableViewCell
        
        // Populating the items
        let videoItem: AnyObject  = self.filteredMovies[indexPath.row]
        cell.nameLabel.text = videoItem["movieName"] as? String
        var mediaId = ""
        mediaId = videoItem["movieMediaId"] as! String
        cell.descriptionLabel.text = "Media ID: " + mediaId
        let clipAuthor = videoItem["userHandle"] as? String
        if (clipAuthor != nil) {
            cell.descriptionLabel.text = "by " + clipAuthor!
        }
        else {
            cell.descriptionLabel.text = "No description"
        }
        var thumbnailUrl: URL? = URL(string: "http://img.youtube.com/vi/\(mediaId)/default.jpg")
        
        if thumbnailUrl == nil {
            thumbnailUrl = URL(string: "https://i.stack.imgur.com/WFy1e.jpg")
        }
        var data:NSData? =  NSData(contentsOf: thumbnailUrl!)
        if data == nil {
            data = NSData(contentsOf: URL(string: "https://i.stack.imgur.com/WFy1e.jpg")!)
        }
        
        cell.thumbnailView.image = UIImage(data: data as! Data)


        return cell
    }
    
    func getYouTubeResults() {

        if (self.searchString != "") {
            NotificationCenter.default.post(name: NSNotification.Name("ActivityInProgressNotification"), object: nil)
            let youTubeSearchString = self.searchString.replacingOccurrences(of: " ", with: ",")
            let maxYouTubeResults:Int = 20

            let config = URLSessionConfiguration.default
            let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&fields=items(id,snippet(title,channelTitle,description,publishedAt))&q=\(youTubeSearchString)&type=video&maxResults=\(maxYouTubeResults)&key=\(apiKey)")
            print("\n\nURL\n\n: ",url)
            print("YouTube Items")
            let task = URLSession.shared.dataTask(with: url! as URL) {(data, response, error) in
                let json = JSON(data: data!)
                if let items = json["items"].array{
                    for item in items{
                        print(item)
                        var ytItem:[String:String] = [:]
                        ytItem["isYTResult"] = "1"
                        ytItem["movieDescription"] = item["snippet"]["description"].stringValue
                        ytItem["movieMediaId"] = item["id"]["videoId"].stringValue
                        ytItem["movieName"] = item["snippet"]["title"].stringValue
                        ytItem["movieCreator"] = item["snippet"]["channelTitle"].stringValue
                        ytItem["clipAuthor"] = ""
                        self.filteredMovies.append(ytItem as AnyObject)
                        self.displayMovies.append(ytItem as AnyObject)
                    }
                    print("\n\nSearched list of videos: ",self.filteredMovies)  
                    self.tableView.reloadData()
                    NotificationCenter.default.post(name: NSNotification.Name("ActivityCompletedNotification"), object: nil)
                }
            }
            task.resume()
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowSearchVideoDetailSegue" {
            let videoDetailViewController = segue.destination as! ViewController
            let selectedRow = self.tableView.indexPathForSelectedRow
            let row : AnyObject? = self.filteredMovies[(selectedRow?.row)!]
            videoDetailViewController.movieID = row?["movieMediaId"] as? String
            videoDetailViewController.currentMovieTitle = row?["movieName"] as? String
            if (self.authorMap.index(forKey: (row?["clipAuthor"] as? String)!) != nil) {
                videoDetailViewController.displayAuthor = self.authorMap[(row?["clipAuthor"] as? String)!]
            }
            else {
                videoDetailViewController.displayAuthor = "None"
            }

        }
    }
    
    func showCellDetailMenu(mediaId: String, author: String) {
        self.showItemMenu(mediaId: mediaId, author: author)
    }
    
    func showItemMenu(mediaId: String, author: String) {
        let optionMenu = UIAlertController(title: nil, message: "Choose action", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: {
                (alert: UIAlertAction) -> Void in
        })

        let createDescriptionAction = UIAlertAction(
            title: "Create description",
            style: .default,
            handler: {
                (alert: UIAlertAction) -> Void in
                //self.currentItem = mediaId
                self.performSegue(withIdentifier: "ShowCreateDescriptionSegue", sender: nil)
        })

        let viewAuthorsVideosAction = UIAlertAction(title: "List videos described by \(author)", style: .default, handler: {
            (alert: UIAlertAction) -> Void in
            //self.currentAuthor = author
            self.performSegue(withIdentifier: "ShowAuthorMoviesSegue", sender: nil)
        })
        
        optionMenu.addAction(cancelAction)
        // show only if the user is logged in
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil {
            optionMenu.addAction(createDescriptionAction)
        }
        optionMenu.addAction(viewAuthorsVideosAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
}
