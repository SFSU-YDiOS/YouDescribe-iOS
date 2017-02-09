//
//  MainTabBarController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/5/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class MainTabBarController: UITabBarController {


    var loginSession:String = ""
    var loggedInViewControllers : [UIViewController]?
    var loggedOutViewControllers: [UIViewController]?

    override func viewDidLoad() {
        super.viewDidLoad()
        loggedInViewControllers = self.viewControllers
        loggedOutViewControllers = self.viewControllers
        loggedInViewControllers?.remove(at: 1)
        loggedOutViewControllers?.remove(at: 2)
        // setup the notification observers for login and logout
        NotificationCenter.default.addObserver(forName: NSNotification.Name("LogoutNotification"), object: nil, queue: nil) { notification in
            print("Logged out.")
            let preferences = UserDefaults.standard
            if preferences.object(forKey: "session") != nil {
                preferences.removeObject(forKey: "session")
            }
            if preferences.object(forKey: "username") != nil {
                preferences.removeObject(forKey: "username")
            }

            self.setViewControllers(self.loggedOutViewControllers, animated: false)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("LoginNotification"), object: nil, queue: nil) { notification in
            // Cache the filteredMovies before overwriting it.
            print("Logged in.")
            self.setViewControllers(self.loggedInViewControllers, animated: false)
        }
        // Save the token string
        let preferences = UserDefaults.standard
        if preferences.object(forKey: "session") != nil {
            loginSession = preferences.object(forKey: "session") as! String
            // load the account page.
            self.setViewControllers(self.loggedInViewControllers, animated: false)
            // check_session()
        }
        else {
            print("Show the login screen here")
            self.setViewControllers(self.loggedOutViewControllers, animated: false)
            // Show the login screen
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
