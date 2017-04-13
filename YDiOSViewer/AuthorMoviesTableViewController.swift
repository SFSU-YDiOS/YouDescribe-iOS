//
//  AuthorMoviesTableTableViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/25/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class AuthorMoviesTableViewController: UITableViewController, AuthorMoviesTableViewCellDelegate {

    var allMoviesSearch: [AnyObject] = []
    var filteredMovies: [AnyObject] = []
    var preferredAuthor: String = ""
    var isUserLoggedIn: Bool = false

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
        
        // Set, if user is logged in
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil {
            self.isUserLoggedIn = true
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
        
        
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "AuthorMoviesTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! AuthorMoviesTableViewCell

        // Configure the cell...
        let videoItem: AnyObject  = self.filteredMovies[indexPath.row]
        cell.lblMovieName.text = videoItem["movieName"] as? String
        cell.lblAuthorName.text = videoItem["userHandle"] as? String
        cell.author = cell.lblAuthorName.text!
        let mediaId:String = (videoItem["movieMediaId"] as? String)!
        cell.mediaId = mediaId
        cell.delegate = self
        var thumbnailUrl: URL? = URL(string: "http://img.youtube.com/vi/\(mediaId)/1.jpg")
        if thumbnailUrl == nil {
            thumbnailUrl = URL(string: "https://i.stack.imgur.com/WFy1e.jpg")
        }
        var data:NSData? =  NSData(contentsOf: thumbnailUrl!)
        if data == nil {
            data = NSData(contentsOf: URL(string: "https://i.stack.imgur.com/WFy1e.jpg")!)
        }
        cell.thumbnailView.image = UIImage(data: data as! Data)

        // Setup for accessibility
        if self.isUserLoggedIn {
            let moreAction = UIAccessibilityExtendedAction(name: "More Actions", target: self, selector: #selector(AuthorMoviesTableViewController.onMoreActions(_:)))
            moreAction.mediaId = mediaId
            cell.accessibilityCustomActions = [moreAction]
        }
        else {
            cell.btnMenu.isHidden = true
        }
        return cell
    }

    @objc private func onMoreActions(_ sender: UIAccessibilityExtendedAction) -> Bool {
        self.showItemMenu(mediaId: sender.mediaId, author: self.preferredAuthor)
        return true
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
                    self.performSegue(withIdentifier: "ShowCreateDescriptionSegue", sender: nil)
            })
            optionMenu.addAction(createDescriptionAction)
        }
        optionMenu.addAction(cancelAction)
        self.present(optionMenu, animated: true, completion: nil)
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
}
