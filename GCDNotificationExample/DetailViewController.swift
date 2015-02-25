//
//  DetailViewController.swift
//  GCDNotificationExample
//
//  Created by David Reed on 2/25/15.
//  Copyright (c) 2015 David Reed. All rights reserved.
//

import UIKit

let workCompletedNotificationKey = "com.dave256apps.workCompleted"

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var calculateButton: UIButton!

    var notificationObserver: NSObjectProtocol? = nil

    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }


    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func viewWillDisappear(animated: Bool) {
        // need to remove any observers in case view controller is deallocated
        if let observer = self.notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
            // prevent from being removed again if window re-entered
            self.notificationObserver = nil
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func calculateButtonPressed(sender: AnyObject) {
        doWork()
    }

    func doWork() {
        let startTime = NSDate()
        detailItem = ""
        calculateButton.enabled = false
        spinner.startAnimating()

        notificationObserver =  NSNotificationCenter.defaultCenter().addObserverForName(workCompletedNotificationKey, object: self, queue: nil) { (notification: NSNotification!) -> Void in
            // get the data sent with the notification
            if let userInfo = notification.userInfo {
                self.detailItem = userInfo["result"]
            }
            // update the UI
            self.calculateButton.enabled = true
            self.spinner.stopAnimating()

            if let observer = self.notificationObserver {
                NSNotificationCenter.defaultCenter().removeObserver(observer)
                // prevent from being removed again if window re-entered
                self.notificationObserver = nil
            }
        }

        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        dispatch_async(queue) {

            // strings hold results of work
            var firstResult: String!
            var secondResult: String!

            // group to make certain all work is completed
            let group = dispatch_group_create()

            // do some work that might take a while
            dispatch_group_async(group, queue) {
                firstResult = self.workOne()
            }
            dispatch_group_async(group, queue) {
                secondResult = self.workTwo()
            }

            // when all blocks added to group are completed, we can display the results
            dispatch_group_notify(group, queue) {
                let resultsSummary = firstResult + secondResult

                // notification will be received on same thread as posted so need to post on main thread since block of code in notification is updating the UI
                dispatch_async(dispatch_get_main_queue()) {
                    // instead of updating UI here, post a notification in case the UI has been deallocated (notification listener is removed in viewWillDisappear
                    // may not be necessary to do this since the dispatch group cannot be deallocated until work completes, but better safe than risking a crash; also prevents unnecessary UI work (such as setting an image that was downloaded)

                    // post notification with result in the userInfo parameter
                    NSNotificationCenter.defaultCenter().postNotificationName(workCompletedNotificationKey, object: self, userInfo: ["result" : resultsSummary])
                }
                let endTime = NSDate()
                // can case that completed even if we left the screen by popping the navigation controller
                println("Completed in \(endTime.timeIntervalSinceDate(startTime)) seconds")
            }
        }
    }


    func workOne() -> String {
        NSThread.sleepForTimeInterval(5)
        return "hello "
    }

    func workTwo() -> String {
        NSThread.sleepForTimeInterval(2)
        return "world"
    }
}


