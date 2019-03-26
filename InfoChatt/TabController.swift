//
//  TabController.swift
//  InfoChatt
//
//  Created by Unal Celik on 1.02.2017.
//  Copyright © 2017 InfoMedya. All rights reserved.
//

import UIKit

class TabController: UITabBarController, UITabBarControllerDelegate {

    var baseController: FirstScreenController?
    
    override func viewWillAppear(_ animated: Bool) {
        setupControllers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.delegate = self
    }

    func setupControllers() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let homeController = storyboard.instantiateViewController(withIdentifier: "home") as! UINavigationController
        addShadow(toView: homeController.navigationBar)
        homeController.tabBarItem.selectedImage = UIImage(named: "selectedHome")?.withRenderingMode(.alwaysOriginal)
        homeController.tabBarItem.image = UIImage(named: "unselectedHome")?.withRenderingMode(.alwaysOriginal)
        if let homeVC = homeController.viewControllers[0] as? HomeController {
            homeVC.baseController = self
        }
        
        let searchController = storyboard.instantiateViewController(withIdentifier: "search") as! UINavigationController
        addShadow(toView: searchController.navigationBar)
        searchController.tabBarItem.selectedImage = UIImage(named: "selected Search")?.withRenderingMode(.alwaysOriginal)
        searchController.tabBarItem.image = UIImage(named: "unselectedSearch")?.withRenderingMode(.alwaysOriginal)
        // Handle SearchController from here if something should be loaded at first.
        /*
         if let searchVC = searchController.viewControllers[0] as? SearchController {
            
         }
         */
        
        let messController = storyboard.instantiateViewController(withIdentifier: "messages") as! UINavigationController
        addShadow(toView: messController.navigationBar)
        messController.tabBarItem.selectedImage = UIImage(named: "selectedEnvelope")?.withRenderingMode(.alwaysOriginal)
        messController.tabBarItem.image = UIImage(named: "unselectedEnvelope")?.withRenderingMode(.alwaysOriginal)
        // Handle MessagesViewController from here if something should be loaded at first.
        /*
         if let messVC = messController.viewControllers[0] as? MessagesController {
            
         }
         */
        
        let profileController = storyboard.instantiateViewController(withIdentifier: "profile") as! UINavigationController
        addShadow(toView: profileController.navigationBar)
        profileController.tabBarItem.selectedImage = UIImage(named: "selected Avatar")?.withRenderingMode(.alwaysOriginal)
        profileController.tabBarItem.image = UIImage(named: "unselectedAvatar")?.withRenderingMode(.alwaysOriginal)
        if let profVC = profileController.viewControllers[0] as? ProfileController {
            profVC.getNotifications()
        }

        self.viewControllers = [homeController, searchController, messController, profileController]
    }
}
