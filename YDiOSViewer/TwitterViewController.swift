//
//  TwitterViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 4/23/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class TwitterViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate = self
        // Do any additional setup after loading the view.
        if let url = URL(string: "https://twitter.com/search?q=%23YDRequest%20Requesting%20description") {
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.bordered, target: self, action: Selector(("back:")))
        self.navigationItem.leftBarButtonItem = newBackButton;
        //webView.allowsLinkPreview = false
    }

    func back(sender: UIBarButtonItem) {
        if(webView.canGoBack) {
            webView.goBack()
        } else {
            self.navigationController?.popViewController(animated:true)
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        activity.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        activity.stopAnimating()
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
