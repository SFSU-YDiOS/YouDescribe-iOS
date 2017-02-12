//
//  VideoItemTableViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/26/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

class VideoItemTableViewController: UITableViewController, UISearchBarDelegate, VideoItemTableViewCellDelegate {

    let dvxApi = DxvApi()
    var allMovies: [AnyObject] = []
    var allAuthors: [AnyObject] = []
    var authorMap: [String:String] = [:]
    var tableSize: Int = 25
    lazy var searchBar = UISearchBar()


    @IBOutlet weak var searchBarHeader: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.allMovies = dvxApi.getMovies([:])
        self.allMovies.reverse()
        self.allAuthors = dvxApi.getUsers([:])
        self.authorMap = getAuthorMap()
        print(self.authorMap)
        self.createSearchBar1()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func sortMovies() {
        // sorting the movies based on the date/time
        self.allMovies.sort{ (($0["movieCreated"] as! NSString) as! Int) > (($1["movieCreated"] as! NSString) as! Int) }
    }

    func getAuthorMap() -> [String:String] {
        if (self.allAuthors.count > 0) {
            for author in self.allAuthors {
                self.authorMap[author["userId"] as! String] = author["userHandle"] as? String
            }
        }
        return self.authorMap
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func createSearchBar() {
        // Add in the search bar
        searchBar.placeholder = "Search"
        searchBar.showsSearchResultsButton = true
        searchBarHeader.addSubview(searchBar)
        searchBar.delegate = self
    }
    func createSearchBar1() {
        // Add in the search bar
        searchBar.placeholder = "Search"
        searchBar.showsSearchResultsButton = true
        searchBar.sizeToFit()
        searchBar.text = ""
        searchBarHeader.addSubview(searchBar)
        searchBar.delegate = self
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        performSegue(withIdentifier: "DisplaySearchResultsSegue", sender: nil)
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return tableSize
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "VideoItemTableViewCell"

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! VideoItemTableViewCell
        cell.delegate = self
        // Populating the items
        let videoItem: AnyObject  = self.allMovies[indexPath.row]
        cell.nameLabel.text = videoItem["movieName"] as? String
        var mediaId = ""
        mediaId = videoItem["movieMediaId"] as! String
        cell.descriptionLabel.text = "Media ID: " + mediaId
        cell.mediaId = mediaId
        let movieAuthor = videoItem["movieAuthor"] as? String
        if (movieAuthor != nil && self.authorMap[movieAuthor!] != nil) {
            cell.describerLabel.text = "by " + self.authorMap[movieAuthor!]!
        }
        else {
            cell.describerLabel.text = "No description"
        }
        var thumbnailUrl: URL? = URL(string: "http://img.youtube.com/vi/\(mediaId)/1.jpg")

        if thumbnailUrl == nil {
            thumbnailUrl = URL(string: "https://i.stack.imgur.com/WFy1e.jpg")
        } else {
            var data:NSData? =  NSData(contentsOf: thumbnailUrl!)
            if data == nil {
                data = NSData(contentsOf: URL(string: "https://i.stack.imgur.com/WFy1e.jpg")!)
            }
            else {
                cell.thumbnailView.image = UIImage(data: data as! Data)
            }
        }

        return cell
    }
 
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // make sure the content scrolls dynamically.
        // load 15 more records when the bottom is reached.
        let tableViewHeight = tableView.frame.size.height
        let tableViewContentSizeHeight = tableView.contentSize.height
        let tableViewOffset = tableView.contentOffset.y
        if tableViewOffset + tableViewHeight == tableViewContentSizeHeight {
            if tableSize + 15 <= self.allMovies.count {
                tableSize += 15
                print(tableSize)
                tableView.reloadData()
            }
            else {
                tableSize = self.allMovies.count
                print(tableSize)
                tableView.reloadData()
            }
        }
    }
    
    
    func showItemMenu(mediaId: String) {
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
                self.performSegue(withIdentifier: "CreateDescriptionSegue", sender: nil)
        })
        
        let viewAuthorsVideosAction = UIAlertAction(title: "View videos described by author", style: .default, handler: {
            (alert: UIAlertAction) -> Void in
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


    func showCellDetailMenu(mediaId: String) {
        print("The media ID from the cell is \(mediaId)")
        self.showItemMenu(mediaId: mediaId)
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowVideoDetail" {
            let videoDetailViewController = segue.destination as! ViewController
            let selectedRow = self.tableView.indexPathForSelectedRow
            let row : AnyObject? = self.allMovies[(selectedRow?.row)!]
            videoDetailViewController.movieID = row?["movieMediaId"] as? String
            videoDetailViewController.currentMovieTitle = row?["movieName"] as? String
            videoDetailViewController.displayAuthor = self.authorMap[(row?["movieAuthor"] as? String)!]
        } else if segue.identifier == "DisplaySearchResultsSegue" {
            let searchResultsViewController = segue.destination as! SearchResultsViewController
            searchResultsViewController.searchString = searchBar.text!
            searchResultsViewController.allMovies = allMovies
            searchResultsViewController.authorMap = authorMap
        } else if segue.identifier == "CreateDescriptionSegue" {
            let createDescriptionViewController = segue.destination as! CreateDescriptionViewController
        }
    }
    
}
