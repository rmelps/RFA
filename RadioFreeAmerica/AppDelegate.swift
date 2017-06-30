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


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FIRApp.configure()
        
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
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
            return
        }
        
        guard let authentication = user.authentication else {
            activityIndicator.stopAnimating()
            return
        }
        
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        FIRAuth.auth()?.signIn(with: credential, completion: { (user:FIRUser?, error:Error?) in
            
            activityIndicator.stopAnimating()
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let rootVC = rootVC {
                rootVC.resizeAndMoveLogInButton(button: rootVC.logInWithGoogleButton, type: .google, signingIn: true)
            }
            
            if let firUser = user {
                print("found user...")
                
                let userDBRef = FIRDatabase.database().reference().child("users")
                let profPicStorRef = FIRStorage.storage().reference().child("profilePics")
                
                let thisUserDBRef = userDBRef.child(firUser.uid)
                
                for profile in firUser.providerData {
                    print("found provider data...")
                    
                    let profPic = profile.photoURL!
                    let userProf = User(uid: firUser.uid, name: profile.displayName!, photoPath: String(describing: profPic))
                    
                    userDBRef.observeSingleEvent(of: .value, with: { (snapShot) in
                        
                        if snapShot.hasChild(firUser.uid) {
                            let snapVal = snapShot.childSnapshot(forPath: firUser.uid).value as? [String: Any]
                            print("observing user database...")
                            
                            if let url = snapVal?["photoPath"] as? String {
                                print("found URL")
                                
                                let providerURL = String(describing:profPic)
                                
                                if url != providerURL {
                                    print("url's are not the same")
                                    self.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                                }
                                
                                thisUserDBRef.setValue(userProf.toAny())
                            }
                        } else {
                            self.fetchAndSaveProfileImage(url: profile.photoURL!, storeRef: profPicStorRef, uid: firUser.uid)
                            thisUserDBRef.setValue(userProf.toAny())
                        }
                        
                    })
                    
                }
                
            }
        })
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any actions when user disconnects with app here...
    }
    
    func fetchAndSaveProfileImage(url: URL, storeRef: FIRStorageReference, uid: String) {
        
        print("fetching image...")
        
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request) { (data:Data?, response:URLResponse?, error:Error?) in
            if error == nil, data != nil {
                storeRef.child(uid).put(data!)
            }
        }
        task.resume()
    }
    
}

