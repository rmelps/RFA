//
//  WordsmithPageViewController.swift
//  RadioFreeAmerica
//
//  Created by Richard Melpignano on 6/20/17.
//  Copyright © 2017 J2MFD. All rights reserved.
//

import UIKit
import FirebaseDatabase

class WordsmithPageViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    var orderedViewControllers: [UIViewController]!
    var signedInUser: User!
    var genreChoice: GenreChoices!
    
    // Index tracking
    var currentIndex = 0
    private var tempIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        signedInUser = AppDelegate.signedInUser!
        
        orderedViewControllers = [
            self.instatiateViewControllers(storyboardID: "wordsmithFirst"),
            self.instatiateViewControllers(storyboardID: "wordsmithSecond"),
            self.instatiateViewControllers(storyboardID: "wordsmithThird")
        ]

        dataSource = self
        
        for vc in orderedViewControllers {
            if let navC = vc as? UINavigationController {
                var wsvc = navC.topViewController as! WordsmithPageViewControllerChild
                wsvc.wordsmithPageVC = self
            } else {
                var wsvc = vc as! WordsmithPageViewControllerChild
                wsvc.wordsmithPageVC = self
            }
        }
        
        if let firstViewController = orderedViewControllers.first as? WordsmithHomeViewController {
            //firstViewController.wordsmithPageVC = self
            firstViewController.firstName = getFirstName(user: signedInUser)
            firstViewController.image = AppDelegate.signedInProfileImage
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
        
        if let secondViewController = orderedViewControllers[1] as? WordsmithChoiceViewController {
            secondViewController.genre = self.genreChoice
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Insert background color gradient
        let gradient = AppDelegate.gradient!
        print(gradient)
        self.view.layer.insertSublayer(gradient, at: 0)
        
        self.view.backgroundColor = .clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        signedInUser = AppDelegate.signedInUser!
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        for view in self.view.subviews {
            if view is UIScrollView {
                view.frame = UIScreen.main.bounds
            } else if let controlView = view as? UIPageControl {
                controlView.backgroundColor = .clear
                controlView.currentPageIndicatorTintColor = UIColor(displayP3Red: 152/255, green: 255/255, blue: 246/255, alpha: 0.85)
            }
        }
    }
    
    private func instatiateViewControllers(storyboardID: String) -> UIViewController {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = mainStoryboard.instantiateViewController(withIdentifier: storyboardID)
        
        return vc
    }
    
    func getFirstName(user: User) -> String {
        
        var firstNameChars = [Character]()
        for char in user.name.characters {
            if char != " " {
                firstNameChars.append(char)
            } else {
               return String(firstNameChars)
            }
        }
        
        return user.name
        
    }
    
    // MARK: UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        print("current index is: \(viewControllerIndex)")
        self.currentIndex = Int(viewControllerIndex)
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            print("returning nil")
            return nil
        }
        
        print("current index is: \(viewControllerIndex)")
        self.currentIndex = Int(viewControllerIndex)
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex < orderedViewControllers.endIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let firstViewController = viewControllers?.first,
            let firstViewControllerIndex = orderedViewControllers.index(of: firstViewController) else {
                return 0
        }
        
        return firstViewControllerIndex
    }

}
