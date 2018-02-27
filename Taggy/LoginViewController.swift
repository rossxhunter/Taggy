//
//  LoginViewController.swift
//  Taggy
//
//  Created by Ross Hunter on 08/08/2016.
//  Copyright © 2016 Ross Hunter. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseDatabase
import FirebaseAuth

var ref = FIRDatabase.database().reference()
var token = ""

class LoginViewController: UIViewController, UITextFieldDelegate {

    var logInPressed = false
    var signUpPressed = false
    var keyboardShown = false
    var keyboardHidden = false
    var keyboardAlreadyShown = false
    var keyboardFrame : CGRect!
    var signUpValid = true
    var logInValid = true
    var deviceCount = 0
    var loadingView : UIView!
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    @IBOutlet weak var taggyTitleLabel: UILabel!
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var emailLogInTextField: UITextField!
    @IBOutlet weak var passwordLogInTextField: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func logInButtonPressed(_ sender: AnyObject) {
        if logInPressed == false {
            emailLogInTextField.clearsOnBeginEditing = true
            passwordLogInTextField.clearsOnBeginEditing = true
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                self.logInButton.frame.origin.y = (self.view.frame.height/4)*3
                self.signUpButton.frame.origin.y = self.view.frame.height
                self.logInEnterLeave(-1)
                }, completion: { finished in
                    if UserDefaults.standard.string(forKey: "emailLogIn") != nil {
                        self.emailLogInTextField.text = UserDefaults.standard.string(forKey: "emailLogIn")
                    }
                    if UserDefaults.standard.string(forKey: "passwordLogIn") != nil {
                        self.passwordLogInTextField.text = UserDefaults.standard.string(forKey: "passwordLogIn")
                    }
                    self.logInPressed = true
                    self.cancelButton.frame.origin.y = (self.view.frame.height/4)*3 + self.logInButton.frame.height+15
                    self.cancelButton.isHidden = false
            })
            
        }
        else {
            logInValid = true
            checkForEmptyField(emailLogInTextField, correction: "Please enter email", boolToChange: &logInValid)
            checkForEmptyField(passwordLogInTextField, correction: "Please enter password", boolToChange: &logInValid)
            if logInValid {
                self.showActivityIndicator()
                FIRAuth.auth()?.signIn(withEmail: emailLogInTextField.text!, password: passwordLogInTextField.text!) { (user, error) in
                    if error != nil {
                        if error?.code == FIRAuthErrorCode.errorCodeInvalidEmail.rawValue {
                            self.emailLogInTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                            self.emailLogInTextField.text = "Invalid email"
                        }
                        else if error?.code == FIRAuthErrorCode.errorCodeUserNotFound.rawValue {
                            self.emailLogInTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                            self.emailLogInTextField.text = "Account does not exist"
                        }
                        else if error?.code == FIRAuthErrorCode.errorCodeWrongPassword.rawValue {
                            self.passwordLogInTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                            self.passwordLogInTextField.isSecureTextEntry = false
                            self.passwordLogInTextField.text = "Incorrect password"
                        }
                        self.hideActivityIndicator()
                        return
                    }
                    else {
                        UserDefaults.standard.set(self.emailLogInTextField.text, forKey: "emailLogIn")
                        UserDefaults.standard.set(self.passwordLogInTextField.text, forKey: "passwordLogIn")
                        let currentUserDetailsRef = ref.child("users").child(user!.uid).child("userDetails")
                        currentUserDetailsRef.observeSingleEvent(of: .value, with: { snapshot in
                            currentUser = User(userId: user!.uid, firstName: snapshot.value!["firstname"] as! String, lastName: snapshot.value!["lastname"] as! String, email: user!.email!, taggies: [[],[]], messages: [])
                            let devicesRef = ref.child("users").child(currentUser.userId).child("devices")
                            token = String(FIRInstanceID.instanceID().token()!)
                            devicesRef.child(token).setValue("loggedin")
                            if waitToLoad {
                                let time = DispatchTime(DispatchTime.now()) + Double(3 * Int64(NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
                                DispatchQueue.main.asyncAfter(deadline: time) {
                                    self.performSegue(withIdentifier: "loginToHome", sender: self)
                                    self.cancelButtonPressed(self)
                                    self.hideActivityIndicator()
                                    waitToLoad = false
                                    print("india")
                                }
                            }
                            else {
                                self.performSegue(withIdentifier: "loginToHome", sender: self)
                                self.cancelButtonPressed(self)
                                self.hideActivityIndicator()
                            }
                        })
                    
                }
            }}
        }
    }
    func getNumberOfDevices() {
        let currentUserRef = ref.child("users").child(currentUser.userId)
        currentUserRef.observeSingleEvent(of: .value, with: { snapshot in
            self.deviceCount = Int(snapshot.childSnapshot(forPath: "devices").childrenCount)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "searchForDevice"), object: self)
        })
    }
    
    func getKeyboardShownValues() {
        if self.keyboardShown == true {
            self.keyboardAlreadyShown = true
        }
        else {
            self.keyboardAlreadyShown = false
        }
    }
    
    @IBAction func emailLogInTextFieldPressed(_ sender: UITextField) {
        if emailLogInTextField.textColor == UIColor.black {
            emailLogInTextField.clearsOnBeginEditing = false
        }
        getKeyboardShownValues()
        isError(emailLogInTextField)
    }
    @IBAction func passwordLogInTextFieldPressed(_ sender: UITextField) {
        getKeyboardShownValues()
        isError(passwordLogInTextField)
        passwordLogInTextField.isSecureTextEntry = true
    }
    
    func checkForEmptyField(_ textField : UITextField, correction: String, boolToChange: inout Bool) {
        if textField.text == "" || textField.text == correction {
            textField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
            if textField.isSecureTextEntry == true {
                textField.isSecureTextEntry = false
            }
            textField.text = correction
            boolToChange = false
        }
    }
    
    @IBOutlet weak var firstNameSignUpTextField: UITextField!
    @IBOutlet weak var lastNameSignUpTextField: UITextField!
    @IBOutlet weak var emailSignUpTextField: UITextField!
    @IBOutlet weak var passwordSignUpTextField: UITextField!
    @IBOutlet weak var confirmPasswordSignUpTextField: UITextField!
    @IBAction func signUpButtonPressed(_ sender: AnyObject) {
        if signUpPressed == false {
            firstNameSignUpTextField.clearsOnBeginEditing = true
            lastNameSignUpTextField.clearsOnBeginEditing = true
            emailSignUpTextField.clearsOnBeginEditing = true
            passwordSignUpTextField.clearsOnBeginEditing = true
            confirmPasswordSignUpTextField.clearsOnBeginEditing = true
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                self.logInButton.frame.origin.y = 0 - self.logInButton.frame.height
                self.signUpEnterLeave(-1)
                }, completion: { finished in
                    self.signUpPressed = true
                    self.cancelButton.frame.origin.y = (self.view.frame.height/4)*3 + self.logInButton.frame.height+15
                    self.cancelButton.isHidden = false
            })
        }
        else {
            signUpValid = true
            checkForEmptyField(firstNameSignUpTextField, correction: "Please enter first name", boolToChange: &signUpValid)
            checkForEmptyField(lastNameSignUpTextField, correction: "Please enter last name", boolToChange: &signUpValid)
            checkForEmptyField(emailSignUpTextField, correction: "Please enter email", boolToChange: &signUpValid)
            checkForEmptyField(passwordSignUpTextField, correction: "Please enter password", boolToChange: &signUpValid)
            checkForEmptyField(confirmPasswordSignUpTextField, correction: "Please re-enter password", boolToChange: &signUpValid)
            if signUpValid {
                if self.passwordSignUpTextField.text != self.confirmPasswordSignUpTextField.text {
                    self.passwordSignUpTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                    self.passwordSignUpTextField.isSecureTextEntry = false
                    self.passwordSignUpTextField.text = "Passwords do not match"
                    self.confirmPasswordSignUpTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                    self.confirmPasswordSignUpTextField.isSecureTextEntry = false
                    self.confirmPasswordSignUpTextField.text = "Passwords do not match"
                    signUpValid = false
                }
            }
            if signUpValid {
                self.showActivityIndicator()
                FIRAuth.auth()?.createUser(withEmail: emailSignUpTextField.text!, password: passwordSignUpTextField.text!) { (user, error) in
                    if error != nil {
                        if error!.code == FIRAuthErrorCode.errorCodeInvalidEmail.rawValue {
                            self.emailSignUpTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                            self.emailSignUpTextField.text = "Invalid email"
                        }
                        if error!.code == FIRAuthErrorCode.errorCodeEmailAlreadyInUse.rawValue {
                            self.emailSignUpTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                            self.emailSignUpTextField.text = "Email already in use"
                        }
                        if error!.code == FIRAuthErrorCode.errorCodeWeakPassword.rawValue {
                            self.passwordSignUpTextField.textColor = UIColor(red: 230.0/255.0, green: 25.0/255.0, blue: 56.0/255.0, alpha: 1)
                            self.passwordSignUpTextField.isSecureTextEntry = false
                            self.passwordSignUpTextField.text = "Password is not strong enough"
                            self.confirmPasswordSignUpTextField.text = ""
                        }
                        self.hideActivityIndicator()
                        return
                    }
                    else {
                        UserDefaults.standard.set(self.emailSignUpTextField.text, forKey: "emailLogIn")
                        UserDefaults.standard.set(self.passwordSignUpTextField.text, forKey: "passwordLogIn")
                        currentUser = User(userId: (user?.uid)!, firstName: self.firstNameSignUpTextField.text!, lastName: self.lastNameSignUpTextField.text!, email:(user?.email)!, taggies: [[],[]], messages: [])
                        let currentUserDetailsDict = ["firstname":currentUser.firstName, "lastname":currentUser.lastName, "taggies":currentUser.taggies]
                        ref.child("users").child(currentUser.userId).child("userDetails").setValue(currentUserDetailsDict)
                        let devicesRef = ref.child("users").child(currentUser.userId).child("devices")
                        token = String(FIRInstanceID.instanceID().token()!)
                        devicesRef.child(token).setValue("loggedin")
                        self.performSegue(withIdentifier: "loginToHome", sender: self)
                        self.hideActivityIndicator()
                    }
                }
            }
        }
    }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.loadingView = UIView()
            self.loadingView.frame = CGRect(x: 0.0, y: 0.0, width: 100.0, height: 100.0)
            self.loadingView.center = self.view.center
            self.loadingView.backgroundColor = UIColor(red:44.0/255.0, green:44.0/255.0, blue:44.0/255.0, alpha:0.5)
            self.loadingView.alpha = 0.7
            self.loadingView.clipsToBounds = true
            self.loadingView.layer.cornerRadius = 10
            self.view.isUserInteractionEnabled = false
            self.spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            self.spinner.frame = CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0)
            self.spinner.center = CGPoint(x:self.loadingView.bounds.size.width / 2, y:self.loadingView.bounds.size.height / 2)
            self.loadingView.addSubview(self.spinner)
            self.view.addSubview(self.loadingView)
            self.spinner.startAnimating()
        }
    }
    
    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.loadingView.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    func searchForDevice() {
        let devicesRef = ref.child("users").child(currentUser.userId).child("devices")
        var found = false
        var count = 0
        token = FIRInstanceID.instanceID().token()!
        devicesRef.observe(.childAdded, with: { snapshot in
            count += 1
            if (snapshot.key ) == token {
                found = true
            }
            if found == false && count == self.deviceCount {
                devicesRef.child(token).setValue("loggedin")
            }
        })
    }
    
    func isError(_ textField : UITextField) {
        if textField.textColor != UIColor.black {
            textField.textColor = UIColor.black
        }
    }
    
    @IBAction func firstNameSignUpTextFieldPressed(_ sender: UITextField) {
        emailLogInTextField.clearsOnBeginEditing = false
        getKeyboardShownValues()
        isError(firstNameSignUpTextField)
    }
    @IBAction func lastNameSignUpTextFieldPressed(_ sender: UITextField) {
        emailLogInTextField.clearsOnBeginEditing = false
        getKeyboardShownValues()
        isError(lastNameSignUpTextField)
    }
    @IBAction func emailSignUpTextFieldPressed(_ sender: UITextField) {
        emailLogInTextField.clearsOnBeginEditing = false
        getKeyboardShownValues()
        isError(emailSignUpTextField)
    }
    @IBAction func passwordSignUpTextFieldPressed(_ sender: UITextField) {
        getKeyboardShownValues()
        isError(passwordSignUpTextField)
        passwordSignUpTextField.isSecureTextEntry = true
    }
    @IBAction func confirmPasswordSignUpTextFieldPressed(_ sender: UITextField) {
        getKeyboardShownValues()
        isError(confirmPasswordSignUpTextField)
        confirmPasswordSignUpTextField.isSecureTextEntry = true
    }
    @IBAction func cancelButtonPressed(_ sender: AnyObject) {
        self.cancelButton.isHidden = true
        self.cancelButton.frame.origin.y -= (self.logInButton.frame.size.height*2)
        if logInPressed {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                self.logInButton.frame.origin.y = self.view.frame.height/2
                self.signUpButton.frame.origin.y = (self.view.frame.height/4)*3
                self.logInEnterLeave(1)
                }, completion: { finished in
                    self.logInPressed = false
            })
        }
        else if signUpPressed {
            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
                self.logInButton.frame.origin.y = self.view.frame.height/2
                self.signUpEnterLeave(1)
                }, completion: { finished in
                    self.signUpPressed = false
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailLogInTextField.delegate = self
        self.passwordLogInTextField.delegate = self
        self.firstNameSignUpTextField.delegate = self
        self.lastNameSignUpTextField.delegate = self
        self.emailSignUpTextField.delegate = self
        self.passwordSignUpTextField.delegate = self
        self.confirmPasswordSignUpTextField.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(searchForDevice), name: NSNotification.Name(rawValue: "searchForDevice"), object: nil)
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        taggyTitleLabel.frame = CGRect(x: (view.frame.width/2)-(view.frame.width/4), y: view.frame.height/32, width: view.frame.width/2, height: view.frame.height/4)
        taggyTitleLabel.adjustsFontSizeToFitWidth = true
        signUpButton.frame = CGRect(x: view.frame.width/2 - view.frame.width*0.4, y: (view.frame.height/4)*3, width: view.frame.width*0.8, height: view.frame.height/8)
        logInButton.frame = CGRect(x: view.frame.width/2 - view.frame.width*0.4, y: view.frame.height/2, width: view.frame.width*0.8, height: view.frame.height/8)
        emailLogInTextField.frame = CGRect(x: view.frame.width, y: (view.frame.height/2)-(view.frame.height/16), width: view.frame.width*0.8, height: view.frame.height/16)
        passwordLogInTextField.frame = CGRect(x: view.frame.width, y: (view.frame.height/2)+(view.frame.height/16), width: view.frame.width*0.8, height: view.frame.height/16)
        firstNameSignUpTextField.frame = CGRect(x: view.frame.width, y: (view.frame.height/2)-(view.frame.height/6), width: view.frame.width*0.8, height: view.frame.height/16)
        lastNameSignUpTextField.frame = CGRect(x: view.frame.width, y: (view.frame.height/2)-(view.frame.height/12), width: view.frame.width*0.8, height: view.frame.height/16)
        emailSignUpTextField.frame = CGRect(x: view.frame.width, y: (view.frame.height/2), width: view.frame.width*0.8, height: view.frame.height/16)
        passwordSignUpTextField.frame = CGRect(x: view.frame.width, y: (view.frame.height/2)+(view.frame.height/12), width: view.frame.width*0.8, height: view.frame.height/16)
        confirmPasswordSignUpTextField.frame = CGRect(x: view.frame.width, y: (view.frame.height/2) + (view.frame.height/6), width: view.frame.width*0.8, height: view.frame.height/16)
        if logInPressed == true {
            self.logInButton.frame.origin.y = (self.view.frame.height/4)*3
            self.signUpButton.frame.origin.y = self.view.frame.height
            logInEnterLeave(-1)
            self.cancelButton.frame.origin.y = (self.view.frame.height/4)*3 + self.logInButton.frame.height+15
            if keyboardShown {
                if keyboardAlreadyShown {
                    logInMove(-1)
                }
                else{
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                        self.logInMove(-1)
                        }, completion: { finished in
                    })
                }
            }
            if keyboardHidden {
                logInMove(-1)
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                    self.logInMove(1)
                    }, completion: { finished in
                        self.keyboardHidden = false
                })
            }
        }
        if signUpPressed == true {
            self.logInButton.frame.origin.y = 0 - self.logInButton.frame.height
            signUpEnterLeave(-1)
            self.cancelButton.frame.origin.y = (self.view.frame.height/4)*3 + self.logInButton.frame.height+15
            if keyboardShown {
                if keyboardAlreadyShown {
                    signUpMove(-1)
                }
                else{
                    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                        self.signUpMove(-1)
                        }, completion: { finished in
                    })
                }
            }
            if keyboardHidden {
                signUpMove(-1)
                UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseOut, animations: {
                    self.signUpMove(1)
                    }, completion: { finished in
                        self.keyboardHidden = false
                })
            }
        }
        
    }
    
    func logInMove(_ upOrDown:Int) {
        emailLogInTextField.frame.origin.y += (self.keyboardFrame.height/5)*CGFloat(upOrDown)
        passwordLogInTextField.frame.origin.y += (self.keyboardFrame.height/5)*CGFloat(upOrDown)
    }
    
    func logInEnterLeave(_ leftOrRight:Int) {
        emailLogInTextField.frame.origin.x += (self.view.frame.width*0.4 + self.view.frame.width/2)*CGFloat(leftOrRight)
        passwordLogInTextField.frame.origin.x += (self.view.frame.width*0.4 + self.view.frame.width/2)*CGFloat(leftOrRight)
    }
    
    func signUpMove(_ upOrDown:Int) {
        firstNameSignUpTextField.frame.origin.y += (self.keyboardFrame.height/2.5)*CGFloat(upOrDown)
        lastNameSignUpTextField.frame.origin.y += (self.keyboardFrame.height/2.5)*CGFloat(upOrDown)
        emailSignUpTextField.frame.origin.y += (self.keyboardFrame.height/2.5)*CGFloat(upOrDown)
        passwordSignUpTextField.frame.origin.y += (self.keyboardFrame.height/2.5)*CGFloat(upOrDown)
        confirmPasswordSignUpTextField.frame.origin.y += (self.keyboardFrame.height/2.5)*CGFloat(upOrDown)
    }
    
    func signUpEnterLeave(_ leftOrRight:Int) {
        firstNameSignUpTextField.frame.origin.x += (self.view.frame.width*0.4 + self.view.frame.width/2)*CGFloat(leftOrRight)
        lastNameSignUpTextField.frame.origin.x += (self.view.frame.width*0.4 + self.view.frame.width/2)*CGFloat(leftOrRight)
        emailSignUpTextField.frame.origin.x += (self.view.frame.width*0.4 + self.view.frame.width/2)*CGFloat(leftOrRight)
        passwordSignUpTextField.frame.origin.x += (self.view.frame.width*0.4 + self.view.frame.width/2)*CGFloat(leftOrRight)
        confirmPasswordSignUpTextField.frame.origin.x += (self.view.frame.width*0.4 + self.view.frame.width/2)*CGFloat(leftOrRight)
        signUpButton.frame.origin.y = (self.view.frame.height/4)*3
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameSignUpTextField {
            lastNameSignUpTextField.becomeFirstResponder()
        }
        else if textField == lastNameSignUpTextField {
            emailSignUpTextField.becomeFirstResponder()
        }
        else if textField == emailSignUpTextField {
            passwordSignUpTextField.becomeFirstResponder()
        }
        else if textField == passwordSignUpTextField {
            confirmPasswordSignUpTextField.becomeFirstResponder()
        }
        else if textField == confirmPasswordSignUpTextField {
            self.view.endEditing(true)
            signUpButtonPressed(self)
        }
        else if textField == emailLogInTextField {
            passwordLogInTextField.becomeFirstResponder()
        }
        else if textField == passwordLogInTextField {
            self.view.endEditing(true)
            logInButtonPressed(self)
        }
        else {
            self.view.endEditing(true)
        }
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
        super.touchesBegan(touches, with: event)
    }
    
    func keyboardWillShow(_ notification: Notification) {
        var info = notification.userInfo!
        keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.keyboardShown = true
        self.keyboardHidden = false
    }
    
    func keyboardWillHide(_ notification: Notification) {
        var info = notification.userInfo!
        keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        self.keyboardShown = false
        self.keyboardHidden = true
    }
}
