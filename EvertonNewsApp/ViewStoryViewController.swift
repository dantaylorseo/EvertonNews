//
//  ViewStoryViewController.swift
//  EvertonNewsApp
//
//  Created by Dan Taylor on 08/01/2016.
//  Copyright © 2016 Dan Taylor. All rights reserved.
//

import UIKit

class ViewStoryViewController: UIViewController, UIWebViewDelegate {
    
    var story:Stories!
    
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    @IBOutlet weak var storyContent: UIWebView!
    @IBAction func shareButtonClicked(sender: AnyObject) {
        
        let textToShare = story.title
        
        if let myWebsite = NSURL(string: story.link)
        {
            let objectsToShare = [textToShare, myWebsite]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        storyContent.scrollView.bounces = false;
        storyContent.scrollView.contentInset = UIEdgeInsetsZero
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        loading.hidden = false
        loading.startAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        loading.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if !NSUserDefaults.standardUserDefaults().boolForKey("premium") {
            self.canDisplayBannerAds = true
        } else {
            self.canDisplayBannerAds = false
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("premium") {
            self.canDisplayBannerAds = true
        }
        
        storyContent.delegate = self
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        let newdate = formatter.stringFromDate(story.date!)
        
        var storyHTML = "<html><head><link rel=\"stylesheet\" href=\"style.css\"><script src=\"https://platform.twitter.com/widgets.js\" type=\"text/javascript\"></script></head><body>"
        if story.image != nil {
            storyHTML = storyHTML + "<img src=\"\(story.image!)\" class=\"img-responsive\">"
        }
        storyHTML = storyHTML + "<div id=\"content\"><small>Posted by \(story.author) in \(story.category) on \(newdate)</small>"
        storyHTML = storyHTML + "<h1>\(story.title)</h1>"
        storyHTML = storyHTML + "\(story.content)</div>"
        storyHTML = storyHTML + "</body></html>"
        
        let cssFile = NSBundle.mainBundle().pathForResource("style", ofType: "css")
        let bundleURL = NSURL(fileURLWithPath: cssFile!)
        
        if Reach().checkOnline() {
            storyContent.loadRequest(NSURLRequest(URL: NSURL(string: story.link)!))
        } else {
            storyContent.loadHTMLString(storyHTML, baseURL: bundleURL)
        }
        title = story.title
    }
}
