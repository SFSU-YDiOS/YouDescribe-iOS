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
    var authorMap: [String:String] = [:]
    var filteredMovies: [AnyObject] = []
    lazy var searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createSearchBar()
        self.navigationItem.title = "Search Results"
        //self.performSearch()
        // call the segue
        
        // Do any additional setup after loading the view.
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
        for movieClip in self.allMovies {
            if ((movieClip["movieName"] as! String).matchPattern(patStr: searchString)==true)
            {
                self.filteredMovies.append(movieClip)
                print(movieClip["movieName"]!!)
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
        }
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        NotificationCenter.default.post(name: NSNotification.Name("SearchFilterNotification"), object: selectedScope)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // TODO: Refresh the search
        print("Searched from the local search")
    }
}
