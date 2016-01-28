//
//  SettingsViewController.swift
//  JamAlpha2
//
//  Created by Song Liao on 11/19/15.
//  Copyright © 2015 Song Liao. All rights reserved.
//

import UIKit
import MessageUI


class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var isFromUnLoginVC: Bool = false
    var mc: MFMailComposeViewController!
    let firstSectionContent = ["About", "Like us on Facebook", "Rate Twistjam", "FAQ", "Contact Us","Demo Mode", "Tutorial"]
    
    let contentsNotLoggedIn = ["About", "Like us on Facebook", "Rate Twistjam", "FAQ", "Demo Mode", "Tutorial"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isFromUnLoginVC {
            presentViewAnimation()
        }
        setUpNavigationBar()
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }
    
    func presentViewAnimation() {
        let animationView: UIView = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height))
        self.view.addSubview(animationView)
        animationView.backgroundColor = UIColor.whiteColor()
        self.view.userInteractionEnabled = false
        UIView.animateWithDuration(0.3, animations: {
            animated in
            animationView.backgroundColor = UIColor.clearColor()
            }, completion: {
                completed in
                animationView.removeFromSuperview()
                self.view.userInteractionEnabled = true
        })
    }
    
    func setUpNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        self.navigationController?.navigationBar.barTintColor = UIColor.mainPinkColor()
        self.navigationController?.navigationBar.translucent = false
        self.navigationItem.title = "Setting"
        tableView.registerClass(SettingFBCell.self, forCellReuseIdentifier: "fbcell")
        if isFromUnLoginVC {
            let leftButton: UIBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "pressLeftButton:")
            self.navigationItem.setLeftBarButtonItem(leftButton, animated: false)
        }
    }
    
    func pressLeftButton(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if CoreDataManager.getCurrentUser() == nil {
            return 1
        }
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if CoreDataManager.getCurrentUser() == nil {
            return contentsNotLoggedIn.count
        }
        if section == 0 {
            return firstSectionContent.count
        }
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
       
        if indexPath.section == 0 {
            if indexPath.item == 1 {
                let cell: SettingFBCell = self.tableView.dequeueReusableCellWithIdentifier("fbcell") as! SettingFBCell
                cell.initialCell(self.view.frame.size.width)
                cell.selectionStyle = UITableViewCellSelectionStyle.None
                cell.titleLabel.text = "Like us on facebook"
                return cell
            } else {
                let cell = tableView.dequeueReusableCellWithIdentifier("settingscell", forIndexPath:
                    indexPath)
                
                var contents = CoreDataManager.getCurrentUser() == nil ? contentsNotLoggedIn : firstSectionContent
                cell.textLabel?.text = contents[indexPath.item]
    
                return cell
            }
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("settingscell", forIndexPath: indexPath)
            cell.textLabel?.text = "Log out"
            cell.textLabel!.textAlignment = .Center
            cell.accessoryType = .None
            return cell
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            
            let indexofDemoMode = CoreDataManager.getCurrentUser() == nil ? 4 : 5
            let indexOfTutorialMode = CoreDataManager.getCurrentUser() == nil ? 5 : 6
            if indexPath.item == 0 {
                let aboutVC: AboutViewController = self.storyboard?.instantiateViewControllerWithIdentifier("aboutVC") as! AboutViewController
                self.navigationController?.pushViewController(aboutVC, animated: true)
            } else if indexPath.item == 2 {
                self.rateTwistjam()
            } else if indexPath.item == 3  {
                let faqVC: FAQViewController = self.storyboard?.instantiateViewControllerWithIdentifier("faqVC") as! FAQViewController
                self.navigationController?.pushViewController(faqVC, animated: true)
            } else if indexPath.item == 4 && CoreDataManager.getCurrentUser() != nil {
                self.contactUs()
            } else if indexPath.item == indexofDemoMode {
                let demoVC: DemoViewController = self.storyboard?.instantiateViewControllerWithIdentifier("demoVC") as! DemoViewController
                demoVC.isFromUnLoginVC = self.isFromUnLoginVC
                self.navigationController?.pushViewController(demoVC, animated: true)
            } else if indexPath.item == indexOfTutorialMode {
                let demoVC: DemoViewController = self.storyboard?.instantiateViewControllerWithIdentifier("demoVC") as! DemoViewController
                demoVC.isFromUnLoginVC = self.isFromUnLoginVC
                demoVC.isDemo = false
                self.navigationController?.pushViewController(demoVC, animated: true)
            }
        } else {
            
            let refreshAlert = UIAlertController(title: "Log Out", message: "Are you sure you want to Log Out?", preferredStyle: UIAlertControllerStyle.Alert)
            refreshAlert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                self.dismissViewControllerAnimated(false, completion: nil)
            }))
            refreshAlert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { (action: UIAlertAction!) in
                CoreDataManager.logoutUser()
                self.navigationController?.popViewControllerAnimated(false)
            }))
            self.presentViewController(refreshAlert, animated: true, completion: nil)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func contactUs() {
        let emailTitle = "[\(CoreDataManager.getCurrentUser()!.email)]'s feed back"
        let messageBody = ""
        let toRecipents = ["jun@twistjam.com"]
        
        mc = MFMailComposeViewController()
        mc.navigationBar.tintColor = UIColor.mainPinkColor()
        
        if MFMailComposeViewController.canSendMail() {
            mc.title = "Feed Back"
            mc.mailComposeDelegate = self
            mc.setSubject(emailTitle)
            mc.setMessageBody(messageBody, isHTML: false)
            mc.setToRecipients(toRecipents)
            self.presentViewController(mc, animated: true, completion: nil)
            //UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(mc, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result.rawValue {
        case MFMailComposeResultCancelled.rawValue:
            print("cancel")
        case MFMailComposeResultSaved.rawValue:
            print("saved")
        case MFMailComposeResultSent.rawValue:
            print("sent")
        case MFMailComposeResultFailed.rawValue:
            print("failed")
        default:
            break
        }
        self.mc.dismissViewControllerAnimated(true, completion: nil)
        //UIApplication.sharedApplication().keyWindow?.rootViewController?.dismissViewControllerAnimated(false, completion: nil)
    }
    
    func show() {
//        let alertController = UIAlertController(title: nil, message: "You have cancelled the email.", preferredStyle: UIAlertControllerStyle.Alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
//        self.presentViewController(alertController, animated: true, completion: nil)
//        
//        let alertController = UIAlertController(title: nil, message: "You have saved the email.", preferredStyle: UIAlertControllerStyle.Alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
//        self.presentViewController(alertController, animated: true, completion: nil)
//        
//        let alertController = UIAlertController(title: nil, message: "The email has been sent.", preferredStyle: UIAlertControllerStyle.Alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
//        self.presentViewController(alertController, animated: true, completion: nil)
//        
//        let alertController = UIAlertController(title: nil, message: "Sorry, please check your networking and account setting and try again.", preferredStyle: UIAlertControllerStyle.Alert)
//        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default,handler: nil))
//        self.presentViewController(alertController, animated: true, completion: nil)
    }

    func rateTwistjam() {
//        let url = "itms-apps://itunes.apple.com/app/id\(APP_STORE_ID)"
//        UIApplication.sharedApplication().openURL(NSURL(string: url)!)
    }
}
