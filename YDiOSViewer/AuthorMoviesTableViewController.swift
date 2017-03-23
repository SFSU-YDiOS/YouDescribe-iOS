//
//  AuthorMoviesTableTableViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/25/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class AuthorMoviesTableViewController: UITableViewController {

    var allMoviesSearch: [AnyObject] = []
    var filteredMovies: [AnyObject] = []
    var preferredAuthor: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // filter the movies based on the required author
        self.filteredMovies = []
        for movie in self.allMoviesSearch {
            if movie["userHandle"] as! String == self.preferredAuthor {
                self.filteredMovies.append(movie)
            }
        }

        // Remove the extra empty cells of the table
        tableView.tableFooterView = UIView(frame: .zero)

        // Change the navigation controller title
        self.title = "Videos described by \(self.preferredAuthor)"

        // Remove the back button title.
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
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
        
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "AuthorMoviesTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AuthorMoviesTableViewCell

        // Configure the cell...
        let videoItem: AnyObject  = self.filteredMovies[indexPath.row]
        cell.lblMovieName.text = videoItem["movieName"] as? String
        cell.lblAuthorName.text = videoItem["userHandle"] as? String
        let mediaId:String = (videoItem["movieMediaId"] as? String)!
        var thumbnailUrl: URL? = URL(string: "http://img.youtube.com/vi/\(mediaId)/1.jpg")
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowAuthorVideoDetailSegue" {
            let videoDetailViewController = segue.destination as! ViewController
            let selectedRow = self.tableView.indexPathForSelectedRow
            let row : AnyObject? = self.filteredMovies[(selectedRow?.row)!]
            videoDetailViewController.movieID = row?["movieMediaId"] as? String
            videoDetailViewController.currentMovieTitle = row?["movieName"] as? String
            if (row?["userHandle"] as? String != nil) {
                videoDetailViewController.displayAuthor = row?["userHandle"] as? String!
            }
            else {
                videoDetailViewController.displayAuthor = "None"
            }
        }
    }

    // Mark - Accessibility
    override func accessibilityPerformMagicTap() -> Bool {
        self.performSegue(withIdentifier: "ShowAuthorVideoDetailSegue", sender: nil)
        return true
    }
}
