//
//  RegisterViewController.swift
//  YouDescribe-iOS
//
//  Created by Rupal Khilari on 2/5/17.
//  Copyright © 2017 SFSU. All rights reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtRepeatPassword: UITextField!
    @IBOutlet weak var txtEmail: UITextField!

    let dvxApi = DxvApi()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // TODO: Remove warning
    
    @IBAction func loginAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onRegisterAction(_ sender: Any) {
        
        // First make sure the password and the repeated password are the same.
        if txtPassword.text != txtRepeatPassword.text {
            self.showIncorrectPasswordMessage()
        }
        else {
            let request = dvxApi.prepareForAddUser(["AppId": "ydesc",
                                                    "LoginName": txtUsername.text!,
                                                    "Password": txtPassword.text!,
                                                    "Email": txtEmail.text!])
            let session = URLSession.shared
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) in
                var result = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                if let httpResponse = response as? HTTPURLResponse
                {
                    if httpResponse.statusCode == 200 {
                        // TODO: We are not sure what is returned.
                        if result!.length < 6 {
                            // We received the token
                            //self.loginSession = result!
                            DispatchQueue.main.async(execute: self.registerDone)
                        }
                        else {
                            DispatchQueue.main.async {
                                self.showIncorrectRegisterMessage(message: result as! String)
                            }
                        }
                    }
                    else {
                        DispatchQueue.main.async {
                            self.showIncorrectRegisterMessage(message: result as! String)
                        }
                    }
                }
            })
            task.resume()
        }
        
    }

    func registerDone() {
        print("Finished registering")
    }

    func showIncorrectPasswordMessage() {
        let alertController = UIAlertController(title: "Password mismatch", message: "The passwords entered do not match.", preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showRegisteredMessage() {
        let alertController = UIAlertController(title: "Registration complete", message: "You have registered as \(txtUsername.text!). Make sure you click on the activation link sent to your email address", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            // move to the login screen.
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)

    }

    func showIncorrectRegisterMessage(message: String) {
        let alertController = UIAlertController(title: "Failed to register", message: message, preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action:UIAlertAction) in
            
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
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
