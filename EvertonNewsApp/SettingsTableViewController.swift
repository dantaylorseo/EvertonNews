//
//  SettingsTableViewController.swift
//  EvertonNewsApp
//
//  Created by Dan Taylor on 18/01/2016.
//  Copyright © 2016 Dan Taylor. All rights reserved.
//

import UIKit
import Parse

class SettingsTableViewController: UITableViewController, SKProductsRequestDelegate {
    
    let currentInstallation = PFInstallation.currentInstallation()
    let productId = "evertonNewsPremium"
    
    @IBOutlet weak var premiumLabel: UILabel!
    @IBOutlet weak var transferSwitch: UISwitch!
    @IBOutlet weak var newsSwitch: UISwitch!
    @IBOutlet weak var updateFeedsSwitch: UISwitch!
    @IBOutlet weak var premiumCell: UITableViewCell!
    
    @IBAction func done(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func notifyTransferNews(sender: AnyObject) {
        
        if transferSwitch.on {
            currentInstallation.addUniqueObject("transferNews", forKey: "channels")
            currentInstallation.saveEventually()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "transferNews")
        } else {
            currentInstallation.removeObject("transferNews", forKey: "channels")
            currentInstallation.saveEventually()
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "transferNews")
        }
        
    }
    
    @IBAction func notifyScores(sender: AnyObject) {
        
        if newsSwitch.on {
            currentInstallation.addUniqueObject("scores", forKey: "channels")
            currentInstallation.saveEventually()
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "scores")
        } else {
            currentInstallation.removeObject("scores", forKey: "channels")
            currentInstallation.saveEventually()
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "scores")
        }
        
    }
    
    @IBAction func autoUpdateFeeds(sender: AnyObject) {
        
        if updateFeedsSwitch.on {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "autoUpdate")
        } else {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "autoUpdate")
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let productID:NSSet = NSSet(object: self.productId);
        let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productID as! Set<String>);
        productsRequest.delegate = self;
        productsRequest.start()
        
        let transferSwitchVal = NSUserDefaults.standardUserDefaults().boolForKey("transferNews")
        let newsSwitchVal = NSUserDefaults.standardUserDefaults().boolForKey("scores")
        let updateSwitchVal = NSUserDefaults.standardUserDefaults().boolForKey("autoUpdate")
        
        transferSwitch.setOn(transferSwitchVal, animated: false)
        newsSwitch.setOn(newsSwitchVal, animated: false)
        updateFeedsSwitch.setOn(updateSwitchVal, animated: false)
        
        if NSUserDefaults.standardUserDefaults().boolForKey("premium") {
            self.premiumLabel.text = "You are a premium member"
            self.premiumCell.accessoryType = .None
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func buyPremium(indexPath: NSIndexPath) {
        PFPurchase.buyProduct("evertonNewsPremium") {
            (error: NSError?) -> Void in
            if error == nil {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "premium")
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                self.premiumLabel.text = "You are a premium member"
                self.premiumCell.accessoryType = .None
            }
        }
    }
    
    func productsRequest(request: SKProductsRequest, didReceiveResponse response: SKProductsResponse) {
        let count : Int = response.products.count
        if (count>0) {
            let validProduct: SKProduct = response.products[0] as SKProduct
            if (validProduct.productIdentifier == self.productId) {
                dump(validProduct)
                if !NSUserDefaults.standardUserDefaults().boolForKey("premium") {
                    let formatter = NSNumberFormatter()
                    formatter.numberStyle = .CurrencyStyle
                    formatter.locale = validProduct.priceLocale
                    let price = formatter.stringFromNumber(validProduct.price)!
                    self.premiumLabel.text = "Upgrade to premium (\(price))"
                }
            }
        } else {
            print("nothing")
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section != 2 {
            return nil
        } else if indexPath.section == 2 && indexPath.row == 0 {
            if !NSUserDefaults.standardUserDefaults().boolForKey("premium") {
                self.buyPremium(indexPath)
                return indexPath
            }
            return nil
        } else {
            return indexPath
        }
    }

}
