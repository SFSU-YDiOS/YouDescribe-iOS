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


class SearchResultsViewController: UIViewController {


    @IBOutlet weak var searchResultsContainer: UIView!
    @IBOutlet weak var searchHeader: UIView!
    var searchString: String = ""
    var allMovies : [AnyObject] = []
    var filteredMovies: [AnyObject] = []
    lazy var searchBar = UISearchBar()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.createSearchBar()
        self.navigationItem.title = "Search Results"
        self.performSearch()
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
    }
    
    func performSearch() {
        print(searchString)
        self.filteredMovies = []
        for movieClip in self.allMovies {
            if ((movieClip["movieName"] as! String).matchPattern(patStr: searchString)==true)
            {
                self.filteredMovies.append(movieClip)
                print(movieClip["movieName"])
            }
        }
        let srtvc:SearchResultsTableViewController  =  self.childViewControllers.last as! SearchResultsTableViewController
        srtvc.filteredMovies = self.filteredMovies
        srtvc.loadView()
        //performSegue(withIdentifier: "EmbeddedSearchResultSegue", sender: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using 
        
        //segue.destinationViewController
        // Pass the selected object to the new view controller.
        if segue.identifier == "EmbeddedSearchResultSegue" {
            //let resultTableViewController = segue.destination as! SearchResultsTableViewController
            //resultTableViewController.filteredMovies = self.filteredMovies
        }
    }


}
