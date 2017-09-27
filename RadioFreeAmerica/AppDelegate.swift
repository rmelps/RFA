//
//  AppDelegate.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/12/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import Firebase
import FacebookCore
import FirebaseDatabase
import FirebaseStorage
import FacebookLogin
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    static var signedInProfileImage: UIImage?
    static var signedInUser: RFAUser?
    static var gradient: CAGradientLayer?
    static let userDBRef = Database.database().reference().child("users")
    static let profPicStorRef = Storage.storage().reference().child("profilePics")
    static let nameDBRef = Database.database().reference().child("names")


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        AppDelegate.clearProfPicTempDir()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        let handler: Bool = SDKApplicationDelegate.shared.application(app, open: url, options: options)
        
        GIDSignIn.sharedInstance().handle(url,
                                          sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                          annotation: [:])
        return handler
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        let rootVC = self.window?.rootViewController as? MainViewController
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        
        if let rootVC = rootVC {
            activityIndicator.hidesWhenStopped = true
            activityIndicator.center = rootVC.wordsmithPortalButton.center
            rootVC.view.addSubview(activityIndicator)
            activityIndicator.startAnimating()
        }
        
        if let error = error {
            print(error.localizedDescription)
            activityIndicator.stopAnimating()
            rootVC?.logInWithFacebookButton.isEnabled = true
            rootVC?.logInWithGoogleButton.isEnabled = true
            return
        }
        
        guard let authentication = user.authentication else {
            activityIndicator.stopAnimating()
            rootVC?.logInWithFacebookButton.isEnabled = true
            rootVC?.logInWithGoogleButton.isEnabled = true
            return
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        Auth.auth().signIn(with: credential, completion: { (user:User?, error:Error?) in
            
            activityIndicator.stopAnimating()
            rootVC?.logInWithFacebookButton.isEnabled = true
            rootVC?.logInWithGoogleButton.isEnabled = true
            
            if let error = error {
                print(error.localizedDescription)
                
                return
            }
            
            if let rootVC = rootVC {
                rootVC.resizeAndMoveLogInButton(button: rootVC.logInWithGoogleButton, type: .google, signingIn: true)
            }
            
            if let firUser = user {
                
                let userDBRef = Database.database().reference().child("users")
                let profPicStorRef = Storage.storage().reference().child("profilePics")
                let nameBDRef = Database.database().reference().child("names")
                
                let thisUserDBRef = userDBRef.child(firUser.uid)
                
                for profile in firUser.providerData {
                    
                    let profPic = String(describing: profile.photoURL!)
                    
                    userDBRef.observeSingleEvent(of: .value, with: { (snapShot) in
                        
                        if snapShot.hasChild(firUser.uid) {
                            let snap = snapShot.childSnapshot(forPath: firUser.uid)
                            let snapVal = snap.value as? [String: Any]
                            
                            let userProf = RFAUser(uid: firUser.uid, snapShot: snap, picURL: profPic, nameFromProvider: nil)
                            AppDelegate.signedInUser = userProf
                            
                            if let url = snapVal?["photoPath"] as? String {
                                print("found URL")
                                
                                /*
                                if url != profPic {
                                    print("url's are not the same")
                                    self.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                                } else {
                                */
                                    let thisProfPicStoreRef = profPicStorRef.child(firUser.uid)
                                    
                                    thisProfPicStoreRef.getData(maxSize: 5 * 1024 * 1024, completion: { (data, error) in
                                        print("finished grabbing data from storage...")
                                        
                                        if let error = error {
                                        print(error.localizedDescription)
                                        }
                                        
                                        if error == nil, data != nil {
                                            print("retrieved image data")
                                            AppDelegate.signedInProfileImage = UIImage(data: data!)
                                        }
                                    })
                             //   }
                                
                                // thisUserDBRef.setValue(userProf.toAny())
                            }
                        } else {
                            let userProf = RFAUser(uid: firUser.uid, name: profile.displayName!, photoPath: profPic)
                            AppDelegate.signedInUser = userProf
                            self.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                            thisUserDBRef.setValue(userProf.toAny())
                            nameBDRef.updateChildValues([userProf.name: userProf.uid] as [AnyHashable : Any])
                        }
                        
                    })
                    
                }
                
            }
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any actions when user disconnects with app here...
    }
    
    func fetchAndSaveProfileImage(url: URL, storeRef: StorageReference, uid: String) {
        
        print("fetching image...")
        
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            if error == nil, data != nil {
                storeRef.child(uid).putData(data!)
                AppDelegate.signedInProfileImage = UIImage(data: data!)
            }
        }
        task.resume()
    }
    
    static func presentErrorAlert(withMessage message: String, fromViewController cont: UIViewController) {
        let alert = UIAlertController(title: "Error!", message: message, preferredStyle: .alert)
        let confirm = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(confirm)
        cont.present(alert, animated: true, completion: nil)
    }
    static func clearProfPicTempDir() {
        let profPicDir = FileManager.default.temporaryDirectory.appendingPathComponent("profPics")
        do{
            try FileManager.default.removeItem(at: profPicDir)
        } catch {
            print("could not remove dir: \(error.localizedDescription)")
        }
    }
}

