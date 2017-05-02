//
//  LoginViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/6/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!

    let dvxApi = DvxApi()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAround()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        UITextField.connectFields(fields: [self.txtUserName, self.txtPassword])
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginAction(_ sender: Any) {
        let request = dvxApi.prepareForLogin(["AppId": "ydesc", "UserName": txtUserName.text!, "Password": txtPassword.text!])
        let session = URLSession.shared
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            
            if let httpResponse = response as? HTTPURLResponse
            {
                if httpResponse.statusCode == 200 {
                    var result = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    if result!.length < 6 {
                        // We received the token
                        //self.loginSession = result!
                        let preferences = UserDefaults.standard
                        preferences.set(result!, forKey: "session")
                        preferences.set(self.txtUserName.text, forKey: "username")
                        DispatchQueue.main.async(execute: self.loginDone)
                    }
                    else {
                        DispatchQueue.main.async(execute: self.showIncorrectLoginMessage)
                    }
                }
                else {
                    DispatchQueue.main.async(execute: self.showIncorrectLoginMessage)
                }
            }
        })
        task.resume()
    }
    
    func loginDone() {
        self.showLoggedInMessage()
        self.txtPassword.text = ""
        self.tabBarController?.selectedIndex = 0
        NotificationCenter.default.post(name: NSNotification.Name("LoginNotification"), object: nil)
    }
    
    func showIncorrectLoginMessage() {
        let alertController = UIAlertController(title: "Failed to login", message: "Incorrect login credentials.", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in

        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showLoggedInMessage() {
        let alertController = UIAlertController(title: "Logged in", message: "Logged in as \(txtUserName.text!)", preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        let when = DispatchTime.now() + 3
        DispatchQueue.main.asyncAfter(deadline: when){
            // your code with delay
            alertController.dismiss(animated: true, completion: nil)
            
        }
    }
    
    // TODO: Remove warning
    func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        var userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.scrollView.contentInset = contentInset
    }
    
    func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        self.scrollView.contentInset = contentInset
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
