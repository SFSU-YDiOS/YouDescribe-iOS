//
//  SearchResultsViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 11/27/16.
//  Copyright © 2016 SFSU. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func matchPattern(patStr:String)->Bool {
        var isMatch:Bool = false
        do {
            let regex = try NSRegularExpression(pattern: patStr, options: [.caseInsensitive])
            let result = regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, characters.count))
            
            if (result != nil)
            {
                isMatch = true
            }
        }
        catch {
            isMatch = false
        }
        return isMatch
    }
}


protocol SearchResultsViewControllerDelegate {
    func readAndUpdateFilteredClips(newFilteredClips: [AnyObject])
}

class SearchResultsViewController: UIViewController, UISearchBarDelegate {


    @IBOutlet weak var searchResultsContainer: UIView!
    @IBOutlet weak var searchHeader: UIView!
    var searchString: String = ""
    var allMovies : [AnyObject] = []
    var allMoviesSearch : [AnyObject] = []
    var authorMap: [String:String] = [:]
    var filteredMovies: [AnyObject] = []
    lazy var searchBar = UISearchBar()
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.createSearchBar()
        self.navigationItem.title = "Search Results"

        // Setup notifications for the activity indicator
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ActivityInProgressNotification"), object: nil, queue: nil) { notification in
            self.activityIndicator.startAnimating()
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ActivityCompletedNotification"), object: nil, queue: nil) { notification in
            self.activityIndicator.stopAnimating()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createSearchBar() {
        // Add in the search bar
        searchBar.placeholder = "Search"
        searchBar.sizeToFit()
        searchBar.text = searchString
        searchBar.showsScopeBar = true
        searchBar.scopeButtonTitles = ["All", "Described"]
        searchHeader.addSubview(searchBar)
        searchBar.delegate = self
    }

    func performSearch() {
        print(searchString)
        self.filteredMovies = []
        for movieClip in self.allMoviesSearch {
            if (movieClip.allKeys.contains(where: {$0 as! String == "movieName" }) && (movieClip["movieName"] as! String).matchPattern(patStr: searchString) == true)
            {
                self.filteredMovies.append(movieClip)
                print(movieClip["movieName"]!!)
            }
            else if (movieClip.allKeys.contains(where: {$0 as! String == "userHandle" }) && (movieClip["userHandle"] as! String).matchPattern(patStr: searchString) == true) {
                self.filteredMovies.append(movieClip)
                print(movieClip["userHandle"]!!)
            }
            else if (movieClip.allKeys.contains(where: {$0 as! String == "movieMediaId" }) && (movieClip["movieMediaId"] as! String).matchPattern(patStr: searchString) == true) {
                self.filteredMovies.append(movieClip)
                print(movieClip["movieMediaId"]!!)
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using 

        if segue.identifier == "EmbeddedSearchResultSegue" {
            let resultTableViewController = segue.destination as! SearchResultsTableViewController
            self.performSearch()
            resultTableViewController.filteredMovies = self.filteredMovies
            resultTableViewController.youDescribeMovies = self.filteredMovies
            resultTableViewController.displayMovies = self.filteredMovies
            resultTableViewController.authorMap = self.authorMap
            resultTableViewController.searchString = self.searchString
            resultTableViewController.allMoviesSearch = self.allMoviesSearch
            resultTableViewController.allMovies = self.allMovies
        }
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        NotificationCenter.default.post(name: NSNotification.Name("SearchFilterNotification"), object: selectedScope)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // TODO: Refresh the search
        self.searchString = self.searchBar.text!
        self.performSearch()
        var searchObject: [AnyObject] = []
        searchObject = self.filteredMovies
        var searchItem:[String:String] = [:]
        searchItem["searchString"] = self.searchString
        searchObject.append(searchItem as AnyObject)
        NotificationCenter.default.post(name: NSNotification.Name("SearchAgainNotification"), object: searchObject)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async {
            self.searchBar.sizeToFit()
        }
    }
}
