//
//  ViewController.swift
//  EvertonNewsApp
//
//  Created by Dan Taylor on 08/01/2016.
//  Copyright © 2016 Dan Taylor. All rights reserved.
//

import Foundation
import UIKit
import Parse
import Haneke
import iAd
import StoreKit

class AllStoriesViewController: UITableViewController, NSXMLParserDelegate, NSURLSessionDelegate {
    
    //var rssUrl = "https://www.everton-news.co.uk/feed/"
    var rssUrl = "http://dev.everton-news.co.uk/rss.xml"
    var stories = [Stories]()
    var xmlParser: NSXMLParser!
    var entryTitle: String!
    var entryDate: String!
    var entrySite: String!
    var entryAuthor: String!
    var entryCategory: String!
    var entryDescription: String!
    var entryContent: String!
    var entryLink: String!
    var entryImage = ""
    var entryThumb = ""
    var currentParsedElement:String! = String()
    var weAreInsideAnItem = false
    var refreshing = false
    var story = Stories()
    var dateFormatter2: NSDateFormatter!
    var shouldDownload: Bool!
    
    var pushStory = Stories()
    var pushLink: String?
    var pushPushed = false  
    
    var nextSegue = ""
    
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    func autoUpdate()
    {
        if NSUserDefaults.standardUserDefaults().boolForKey("autoUpdate") {
            print("Updating")
            self.checkXMLUpdated()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        NSTimer.scheduledTimerWithTimeInterval( 5 * 60 , target: self, selector: Selector("autoUpdate"), userInfo: nil, repeats: true)
        
        settingsButton.title = NSString(string: "\u{2630}") as String
        if let font = UIFont(name: "Helvetica", size: 18.0) {
            self.settingsButton.setTitleTextAttributes([NSFontAttributeName: font], forState: UIControlState.Normal)
        }
        title = "Everton News"
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("premium") {
            self.canDisplayBannerAds = true
        }
        
        let appBuild = NSUserDefaults.standardUserDefaults().stringForKey("appBuild")
        if appBuild !=  NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String {
            self.deleteData()
            print("Deleting data...")
            NSUserDefaults.standardUserDefaults().setValue(NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String, forKey: "appBuild")
        }
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        imageView.contentMode = .ScaleAspectFit
        let image = UIImage(named: "logo-trans-3")
        imageView.image = image
        navigationItem.titleView = imageView
                
        self.refreshControl?.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        //self.deleteData()
        
        //self.getLocalData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checkXMLUpdated()
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("premium") {
            self.canDisplayBannerAds = true
        } else {
            self.canDisplayBannerAds = false
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func unwindToThisViewController(segue: UIStoryboardSegue) {
        //Insert function to be run upon dismiss of VC2
    }
    
    func refresh(sender:AnyObject) {
        refreshing = true
        //self.updateFeed()
        self.checkXMLUpdated()
    }
    
    
    
    func checkShouldDownloadFileAtLocation(urlString:String, completion:((shouldDownload:Bool) -> ())?) {
        let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
        request.HTTPMethod = "HEAD"
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
        
        let session = NSURLSession(configuration: configuration)
        
        let task = session.dataTaskWithRequest(request, completionHandler: { data, response, error -> Void in
            
                var isModified = false
            
                if let httpResp: NSHTTPURLResponse = response as? NSHTTPURLResponse {
                    let lastModifiedDate = httpResp.allHeaderFields["Last-Modified"] as? String
                    //print(lastModifiedDate)
                    if lastModifiedDate != nil {
                        let dateFormatter2 = NSDateFormatter()
                        dateFormatter2.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
                        dateFormatter2.locale = NSLocale(localeIdentifier: "en-GB")
                        
                        let newLastModifiedDate = dateFormatter2.dateFromString(lastModifiedDate!)
                        //print(newLastModifiedDate)
                        if newLastModifiedDate != nil {
                            let currentLastModifiedDate = NSUserDefaults.standardUserDefaults().objectForKey("LastModifiedDate") as? NSDate
                            if currentLastModifiedDate == nil {
                                isModified = true
                            } else {
                                isModified = !newLastModifiedDate!.isEqual(currentLastModifiedDate!)
                            }
                            
                            NSUserDefaults.standardUserDefaults().setObject(newLastModifiedDate!, forKey: "LastModifiedDate")
                            NSUserDefaults.standardUserDefaults().synchronize()
                        }
                    }
                    
                
                
                if completion != nil {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        completion!(shouldDownload: isModified)
                    })
                }
            }
            
            })
        
        task.resume()
    }
    
    func checkXMLUpdated(){
        
        //self.getLocalData()
        if Reach().checkOnline() {
            self.checkShouldDownloadFileAtLocation(self.rssUrl, completion: { (shouldDownload) -> () in
                if shouldDownload {
                    self.updateFeed()
                } else if self.pushPushed {
                    self.loadPushedStory()
                    self.tableView.reloadData()
                } else {
                    self.getLocalData()
                    self.refreshControl?.endRefreshing()
                    self.refreshing = false
                }
                self.tableView.reloadData()
            })
        } else {
            self.getLocalData()
            self.refreshControl?.endRefreshing()
            self.refreshing = false
        }
    }
    
    func deleteData() {
        let query = PFQuery(className: "Stories")
        query.fromLocalDatastore()
        query.findObjectsInBackgroundWithBlock{
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                if let objects = objects {
                    PFObject.unpinAllInBackground(objects)
                }
            }
        }
    }
    
    func getLocalData() {
        stories.removeAll(keepCapacity: false)
        let query = PFQuery(className: "Stories")
        query.fromLocalDatastore()
        query.orderByDescending("date")
        
        do {
            let objects = try query.findObjects()
                if let objects = objects as [PFObject]? {
                    if objects.count == 0 {
                        if Reach().checkOnline() {
                            self.updateFeed()
                        } else {
                            let alertController = UIAlertController(title: "Offline", message:
                                "You must be online to download the latest Everton News", preferredStyle: UIAlertControllerStyle.Alert)
                            alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Default,handler: nil))
                            
                            self.presentViewController(alertController, animated: true, completion: nil)
                        }
                    } else {
                        for object in objects {
                            let story = Stories()
                            story.title = object.objectForKey("title") as! String
                            story.date = object.objectForKey("date") as! NSDate
                            story.author = object.objectForKey("author") as! String
                            story.site = object.objectForKey("site") as! String
                            story.category = object.objectForKey("category") as! String
                            story.link = object.objectForKey("link") as! String
                            story.content = object.objectForKey("content") as! String
                            story.desc = object.objectForKey("desc") as! String
                            story.image = object.objectForKey("image") as? String
                            story.thumb = object.objectForKey("thumb") as? String
                            self.stories.append(story)
                        }
                        self.tableView.reloadData()
                    }
                }
        } catch {
            print("Error");
        }
    }
    
    func updateFeed() {
        
        let request = NSMutableURLRequest(URL: NSURL(string: rssUrl)!)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        
        
                configuration.requestCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
        
                let session = NSURLSession(configuration: configuration)
                var indicator = UIActivityIndicatorView()
                
                request.HTTPMethod = "GET"
                if !self.refreshing {
                    
                    
                    indicator = UIActivityIndicatorView(frame: CGRectMake(0, 0, 90, 90))
                    indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.WhiteLarge
                    indicator.center = self.view.center
                    self.view.addSubview(indicator)
                    
                    indicator.startAnimating()
                    indicator.backgroundColor = UIColor.grayColor()
                    indicator.alpha = 0.6
                }
        
                let task = session.dataTaskWithRequest(request) {
                    (data, response, error) -> Void in

                    dispatch_sync(dispatch_get_main_queue(), {
                        self.xmlParser = NSXMLParser(data: data!)
                        self.xmlParser.delegate = self
                        self.xmlParser.parse()
                        indicator.stopAnimating()
                        self.refreshControl?.endRefreshing()
                        self.refreshing = false
                        self.getLocalData()
                        self.tableView.reloadData()
                        if self.pushPushed {
                            self.tableView.reloadData()
                        }
                    })
                    
                    
                }
                task.resume()
        
    }
    
    func loadPushedStory() {
        
        let query = PFQuery(className: "Stories")
        query.fromLocalDatastore()
        query.whereKey("link", equalTo:pushLink!)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if objects!.count > 0 {
                let pStory = Stories()
                for item in objects! {
                    pStory.link = item["link"] as! String
                    pStory.title = item["title"] as! String
                    pStory.date = item["date"] as! NSDate
                    pStory.author = item["author"] as! String
                    pStory.site = item["site"] as! String
                    pStory.category = item["category"] as! String
                    pStory.content = item["content"] as! String
                    pStory.image = item["image"] as? String
                }
                self.pushStory = pStory
                //dump(pStory)
                self.performSegueWithIdentifier("ShowStory", sender: self)
                self.pushPushed = false
                self.refreshControl?.endRefreshing()
                self.refreshing = false
            } else {
                self.pushPushed = false
            }
        }
        //dump(pushStory)
        //
        
    }
    
    func parserDidStartDocument(parser: NSXMLParser) {
        self.stories = [Stories]()
    }
    
    func parser(parser: NSXMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes attributeDict: [String : String]){
            if elementName == "item" {
                weAreInsideAnItem = true
            }
            if weAreInsideAnItem {
                if elementName == "title"{
                    entryTitle = String()
                    currentParsedElement = "title"
                }
                if elementName == "pubDate" {
                    entryDate = String()
                    currentParsedElement = "date"
                }
                if elementName == "author" {
                    entryAuthor = String()
                    currentParsedElement = "author"
                }
                if elementName == "feedtitle" {
                    entrySite = String()
                    currentParsedElement = "feedtitle"
                }
                if elementName == "category" {
                    entryCategory = String()
                    currentParsedElement = "category"
                }
                if elementName == "description"{
                    entryDescription = String()
                    currentParsedElement = "description"
                }
                if elementName == "content"{
                    entryContent = String()
                    currentParsedElement = "content"
                }
                if elementName == "link"{
                    entryLink = String()
                    currentParsedElement = "link"
                }
                if elementName == "image"{
                    entryImage = String()
                    currentParsedElement = "image"
                }
                if elementName == "media:content" {
                    currentParsedElement = "image"
                    entryImage = attributeDict["url"]! as String
                }
                if elementName == "thumbnail" {
                    entryThumb = String()
                    currentParsedElement = "thumbnail"
                }
            }
            
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        
        if weAreInsideAnItem {
            if currentParsedElement == "title"{
                entryTitle = entryTitle + string
            }
            if currentParsedElement == "description"{
                entryDescription = entryDescription + string
            }
            if currentParsedElement == "content"{
                entryContent = entryContent + string
            }
            if currentParsedElement == "link"{
                entryLink = entryLink + string
            }
            if currentParsedElement == "date" {
                entryDate = entryDate + string
            }
            if currentParsedElement == "author" {
                entryAuthor = entryAuthor + string
            }
            if currentParsedElement == "feedtitle" {
                entrySite = entrySite + string
            }
            if currentParsedElement == "category" {
                entryCategory = entryCategory + string
            }
            if currentParsedElement == "image" {
                entryImage = entryImage + string
            }
            if currentParsedElement == "thumbnail" {
                entryThumb = entryThumb + string
            }
        }
        
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        if weAreInsideAnItem {
            if elementName == "title"{
                story.title = entryTitle
            }
            if elementName == "pubDate" {
                let dateFormatter = NSDateFormatter()
                
                dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
                dateFormatter.locale = NSLocale(localeIdentifier: "en-GB")
                let date = dateFormatter.dateFromString(entryDate)
                
                story.date = date
            }
            if elementName == "author" {
                story.author = entryAuthor
            }
            if elementName == "feedtitle" {
                story.site = entrySite
            }
            if elementName == "category" {
                story.category = entryCategory
            }
            if elementName == "link"{
                story.link = entryLink
            }
            if elementName == "description"{
                story.desc = entryDescription
            }
            if elementName == "content" {
                story.content = entryContent
            }
            if elementName == "image"{
                story.image = entryImage
            }
            if elementName == "thumbnail"{
                story.thumb = entryThumb
            }
        }
        if elementName == "item" {
            if story.title != nil {
                self.findOrInsertStory(story)
                story = Stories()
            }
        }
    }
    
    func findOrInsertStory(story: Stories) {
        let query = PFQuery(className: "Stories")
        query.fromLocalDatastore()
        query.whereKey("link", equalTo:story.link)
        query.countObjectsInBackgroundWithBlock{
            (count: Int32, error: NSError?) -> Void in
            if count == 0 {
                let saveStory = PFObject(className: "Stories")
                saveStory["title"] = story.title
                saveStory["date"] = story.date
                saveStory["author"] = story.author
                saveStory["site"] = story.site
                saveStory["category"] = story.category
                saveStory["link"] = story.link
                saveStory["content"] = story.content
                saveStory["desc"] = story.desc
                if story.image != nil {
                    saveStory["image"] = story.image
                } else {
                    saveStory["image"] = ""
                }
                if story.thumb != nil {
                    saveStory["thumb"] = story.thumb
                } else {
                    saveStory["thumb"] = ""
                }
                //saveStory["thumb"] = story.thumb
                do {
                    try saveStory.pin()
                } catch {
                    print("Error")
                }
                /*saveStory.pinInBackgroundWithBlock({
                    (success: Bool, error: NSError?) -> Void in
                    //self.getLocalData()
                })*/
            }
        }
    }
    
    func parserDidEndDocument(parser: NSXMLParser){
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            //self.tableView.reloadData()
            //self.getLocalData()
        })
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row != 0 {
            return 120
        } else {
            return UITableViewAutomaticDimension
        }
    }
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let item = stories[indexPath.row]
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "d MMM yyyy @ HH:mm"
        let newdate = formatter.stringFromDate(item.date!)
        
        let subTitle = "\(item.site) - \(newdate)"
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("TopCell", forIndexPath: indexPath)
            cell.accessoryType = .None
            let title = cell.viewWithTag(11) as! UILabel
            title.text = item.title
            
            let cellSub = cell.viewWithTag(12) as! UILabel
            cellSub.text = subTitle
            
            let imageCont = cell.viewWithTag(10) as! UIImageView
            
            if(item.image != "" ) {
                
                let cache = Shared.imageCache
                
                let URL = NSURL(string: item.image!)!
                cache.fetch(URL: URL).onSuccess { image in
                    //let newImage = self.resizeImage(image, toTheSize: CGSizeMake(537, 250))
                    imageCont.image = image
                }
                
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
            
            cell.textLabel!.text = item.title
            cell.detailTextLabel!.text = subTitle
            
            let image = UIImage(named: "logo-150")
            let newImage = self.resizeImage(image!, toTheSize: CGSizeMake(100, 100))
            //let cellImageLayer:CALayer? = cell.imageView?.layer
            //cellImageLayer!.cornerRadius = 35
            //cellImageLayer!.masksToBounds = true
            cell.imageView?.image = newImage
            if(item.thumb != "" ) {
                
                let cache = Shared.imageCache
                
                let URL = NSURL(string: item.thumb!)!
                cache.fetch(URL: URL).onSuccess { image in
                    let newImage = self.resizeImage(image, toTheSize: CGSizeMake(100, 100))
                    //let cellImageLayer:CALayer? = cell.imageView?.layer
                    //cellImageLayer!.cornerRadius = 35
                    //cellImageLayer!.masksToBounds = true
                    cell.imageView?.image = newImage
                }
                
            }
            return cell
        }
        
        
    
    }

    func resizeImage(image:UIImage, toTheSize size:CGSize)->UIImage{
        
        
        let scale = CGFloat(max(size.width/image.size.width,
            size.height/image.size.height))
        let width:CGFloat  = image.size.width * scale
        let height:CGFloat = image.size.height * scale;
        
        let rr:CGRect = CGRectMake( 0, 0, width, height);
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        image.drawInRect(rr)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        return newImage
    }

    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowStory" {
            let controller = segue.destinationViewController as! ViewStoryViewController
            if pushPushed == true {
                controller.story = pushStory
            } else {
                if let indexPath = tableView.indexPathForCell(sender as! UITableViewCell) {
                    controller.story = stories[indexPath.row]
                }
            }
            let backItem = UIBarButtonItem()
            backItem.title = ""
            navigationItem.backBarButtonItem = backItem
        } else if segue.identifier == "showMenu" {
            
            let navController = segue.destinationViewController as! UINavigationController
            let controller = navController.viewControllers.first as! UITableViewController
            controller.tableView.backgroundColor = UIColor.clearColor()
            
            let blurEffect = UIBlurEffect(style: .Dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            
            controller.tableView.backgroundView = blurEffectView
            controller.tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        }
    }

}

