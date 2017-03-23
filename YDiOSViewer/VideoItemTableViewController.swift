//
//  VideoItemTableViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/26/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import UIKit

class VideoItemTableViewController: UITableViewController, UISearchBarDelegate, VideoItemTableViewCellDelegate, UINavigationControllerDelegate {

    let dvxApi = DvxApi()
    var allMovies: [AnyObject] = []
    var allMoviesSearch: [AnyObject] = []
    var allAuthors: [AnyObject] = []
    var authorMap: [String:String] = [:]
    var tableSize: Int = 25
    var currentItem: String = "" // TODO: Figure out how to perform segue with argument
    var currentAuthor: String = ""
    var currentUser: String = ""
    var startEditMode: Bool = false
    lazy var searchBar = UISearchBar()

    @IBOutlet weak var searchBarHeader: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.allMovies = dvxApi.getMovies([:])
        //self.allMovies.reverse()
        self.allAuthors = dvxApi.getUsers([:])
        //self.allMoviesSearch = dvxApi.getMoviesSearchTable([:])
        self.authorMap = getAuthorMap()
        self.createSearchBar()
        self.navigationController?.delegate = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Update the cache if required
        if let allMoviesSearchCache = GlobalCache.cache.object(forKey: "allMoviesSearch") {
            print("Using the old cache")
            self.allMoviesSearch = allMoviesSearchCache as! [AnyObject]
        } else {
            self.allMoviesSearch = dvxApi.getMoviesSearchTable([:])
            print("Resetting the cache")
            GlobalCache.cache.setObject(self.allMoviesSearch as AnyObject, forKey: "allMoviesSearch")
        }
        
        if let allMoviesCache = GlobalCache.cache.object(forKey: "allMovies") {
            self.allMovies = allMoviesCache as! [AnyObject]
        } else {
            self.allMovies = dvxApi.getMovies([:])
            GlobalCache.cache.setObject(self.allMovies as AnyObject, forKey: "allMovies")
        }
    }

    func sortMovies() {
        // sorting the movies based on the date/time
        self.allMovies.sort{ (($0["movieCreated"] as! NSString) as! Int) > (($1["movieCreated"] as! NSString) as! Int) }
    }

    func showDVXError() {
        // Hide the views if no data could be retrieved
        tableView.tableFooterView = UIView(frame: .zero)
        tabBarController?.view = UIView(frame: .zero)
        
        // Display the alert controller and exit once the user confirms
        let alertController = UIAlertController(title: "Error connecting to the server!", message: "Unable to retrieve YouDescribe data from the server. Either your phone may not be connected to the internet or the server may be down. Exiting for now. Please try again later.", preferredStyle: .alert)

        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
            // Close the app here
            exit(0)
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
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
        searchBar.sizeToFit()
        searchBar.searchBarStyle = .default
        searchBar.delegate = self
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.endEditing(true)
        performSegue(withIdentifier: "DisplaySearchResultsSegue", sender: nil)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar.text = ""
        self.searchBar.endEditing(true)
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if self.allMoviesSearch.isEmpty {
            self.showDVXError()
            return 0
        }
        else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.allMoviesSearch.isEmpty {
            return 0
        }
        else {
            return tableSize
        }
        
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "VideoItemTableViewCell"

        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! VideoItemTableViewCell
        cell.delegate = self
        // Populating the items
        if self.allMoviesSearch.isEmpty {
            print ("Failed to connect to DVX")
        }
        else {
            let videoItem: AnyObject  = self.allMoviesSearch[indexPath.row]
            cell.nameLabel.text = videoItem["movieName"] as? String
            var mediaId = ""
            mediaId = videoItem["movieMediaId"] as! String
            cell.descriptionLabel.text = "Media ID: " + mediaId
            cell.mediaId = mediaId
            let clipAuthor = videoItem["userHandle"] as? String
            cell.author = clipAuthor
            if (clipAuthor != nil) {
                cell.describerLabel.text = "by " + clipAuthor!
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
        }
        return cell
    }
 
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.searchBar
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        //return self.searchBarHeader.frame.height
        return self.searchBar.frame.height
    }
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // make sure the content scrolls dynamically.
        // load 15 more records when the bottom is reached.
        let tableViewHeight = tableView.frame.size.height
        let tableViewContentSizeHeight = tableView.contentSize.height
        let tableViewOffset = tableView.contentOffset.y
        if tableViewOffset + tableViewHeight == tableViewContentSizeHeight {
            if tableSize + 15 <= self.allMoviesSearch.count {
                tableSize += 15
                print(tableSize)
                tableView.reloadData()
            }
            else {
                tableSize = self.allMoviesSearch.count
                print(tableSize)
                tableView.reloadData()
            }
        }
    }
    
    
    func showItemMenu(mediaId: String, author: String) {
        let optionMenu = UIAlertController(title: nil, message: "Choose action", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: {
            (alert: UIAlertAction) -> Void in
        })


        let viewAuthorsVideosAction = UIAlertAction(title: "List videos described by \(author)", style: .default, handler: {
            (alert: UIAlertAction) -> Void in
            self.currentAuthor = author
            self.performSegue(withIdentifier: "ShowAuthorMoviesSegue", sender: nil)
        })

        optionMenu.addAction(cancelAction)

        // show only if the user is logged in
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil {
            var descAction:String = "Create"
            var editMode: Bool = false
            if preferences.object(forKey: "username") as! String == author {
                descAction = "Edit"
                editMode = true
            }
            let createDescriptionAction = UIAlertAction(
                title: descAction + " description",
                style: .default,
                handler: {
                    (alert: UIAlertAction) -> Void in
                    self.currentItem = mediaId
                    self.startEditMode = editMode
                    self.performSegue(withIdentifier: "ShowCreateDescriptionSegue", sender: nil)
            })
            optionMenu.addAction(createDescriptionAction)
        }
        optionMenu.addAction(viewAuthorsVideosAction)

        self.present(optionMenu, animated: true, completion: nil)
    }


    func showCellDetailMenu(mediaId: String, author: String) {
        self.showItemMenu(mediaId: mediaId, author: author)
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowVideoDetail" {
            let videoDetailViewController = segue.destination as! ViewController
            let selectedRow = self.tableView.indexPathForSelectedRow
            let row : AnyObject? = self.allMoviesSearch[(selectedRow?.row)!]
            videoDetailViewController.movieID =  row?["movieMediaId"] as? String

            videoDetailViewController.currentMovieTitle = row?["movieName"] as? String
            videoDetailViewController.displayAuthor = row?["userHandle"] as? String
            videoDetailViewController.displayAuthorID = row?["clipAuthor"] as? String
        }
        else if segue.identifier == "DisplaySearchResultsSegue" {
            let searchResultsViewController = segue.destination as! SearchResultsViewController
            searchResultsViewController.searchString = searchBar.text!
            searchResultsViewController.allMovies = allMovies
            searchResultsViewController.allMoviesSearch = allMoviesSearch
            searchResultsViewController.authorMap = authorMap
        }
        else if segue.identifier == "ShowCreateDescriptionSegue" {
            let createDescriptionViewController = segue.destination as! CreateDescriptionViewController
            createDescriptionViewController.mediaId = self.currentItem
            createDescriptionViewController.allMovies = self.allMovies
            createDescriptionViewController.isEditMode = self.startEditMode
        }
        else if segue.identifier == "ShowAuthorMoviesSegue" {
            let authorMoviesViewController = segue.destination as! AuthorMoviesTableViewController
            authorMoviesViewController.allMoviesSearch = self.allMoviesSearch
            authorMoviesViewController.preferredAuthor = self.currentAuthor
        }
    }

    // TODO: Remove if no specific purpose now.
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        print("Rotated")
    }

    // Mark - Accessibility
    override func accessibilityPerformMagicTap() -> Bool {
        self.performSegue(withIdentifier: "ShowVideoDetail", sender: nil)
        return true
    }
    
}
