//
//  MenuTableViewController.swift
//  EvertonNewsApp
//
//  Created by Dan Taylor on 20/01/2016.
//  Copyright © 2016 Dan Taylor. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {
    
    var nextSegue = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            switch (indexPath.row) {
                case 0:
                    nextSegue = "showFixtures"
                    let controller = self.storyboard?.instantiateViewControllerWithIdentifier("allStories") as! AllStoriesViewController
                    controller.nextSegue = nextSegue
                    dismissViewControllerAnimated(true, completion: nil)
                case 1:
                    nextSegue = "showFixtures"
                default:
                    print("default")
            }
        } else if indexPath.section == 2 {
            switch (indexPath.row) {
            case 0:
                //dismissViewControllerAnimated(true, completion: nil)
                performSegueWithIdentifier("showSettings", sender: self)
            default:
                print("default")
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showAllStories" {
            let navController = segue.destinationViewController as! UINavigationController
            let controller = navController.viewControllers.first as! AllStoriesViewController
            controller.nextSegue = nextSegue
        }
    }

}
