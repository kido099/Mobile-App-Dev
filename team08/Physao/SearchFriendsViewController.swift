//
//  SearchFriendsViewController.swift
//  Physao
//
//  Created by Weiqi Wei on 15/11/26.
//  Copyright © 2015年 Physaologists. All rights reserved.
//

import UIKit
import Parse

class SearchFriendsViewController: UIViewController, UITableViewDelegate,UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var mySearchBar: UISearchBar!
    
    @IBOutlet weak var myTableView: UITableView!
    let names:[String] = ["wwq", "hl"]
    var searchResult:[String] = []
    var name_From: String = ""
    var name_To: String = ""
    var patient: Patient = Patient()
    var friendsInfo:[String: Patient] = [:]
    var invitationSent: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPatientInfo(name_From)
        getUserInvitation()
        friendsInfo.removeAll()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return searchResult.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = myTableView.dequeueReusableCellWithIdentifier("cell") as! SendInvitationTableViewCell
        let name = searchResult[indexPath.row]
        cell.nameLabel?.text = name
        cell.connectButton.tag = indexPath.row
        if hasSentBefore(name){
            cell.connectButton.setTitle("Invitation Sent", forState: .Normal)
            cell.connectButton.enabled = false
        }
        else {
            cell.connectButton.addTarget(self, action: Selector("SendInvitationAction:"), forControlEvents: .TouchUpInside)
        }
        //name_To = searchResult[indexPath.row]
        //print(name_To)
        return cell
    }
    
    @IBAction func SendInvitationAction(sender: UIButton){
        let str: String = "Invitation Sent"
        sender.setTitle(str, forState: .Normal)
        sender.enabled = false
        name_To = searchResult[sender.tag]
        if !hasSentBefore(name_To){
            SaveInvitation(name_From, nameTo: name_To)
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        mySearchBar.resignFirstResponder()
        
        let query = PFQuery(className: "FriendsInfo")
        let str: String = mySearchBar.text!
        query.whereKey("name", matchesRegex: "(?i)\(str)")
        
        query.findObjectsInBackgroundWithBlock{
            (objects:[PFObject]?, error: NSError?)-> Void in
            if error == nil{
                print("successfully")
                if let array = objects{
                    for item in array{
                        print(item)
                        let fullName = item.objectForKey("name") as! String
                        if fullName != self.name_From && !self.hasExistInResult(fullName){
                            let times = item.objectForKey("times") as! String
                            let untilDate = item.objectForKey("untilDate") as! String
                            let patient = Patient(name: fullName, times: times, date: untilDate)
                            self.friendsInfo[fullName] = patient
                            self.searchResult.append(fullName)
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.myTableView.reloadData()
                self.mySearchBar.resignFirstResponder()
                
            }
        }
    }
    
    func hasExistInResult(name: String) -> Bool{
        for item in self.searchResult{
            if item == name{
                return true
            }
        }
        return false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar){
        mySearchBar.resignFirstResponder()
        mySearchBar.text = ""
    }
    
    func SaveInvitation(nameFrom: String, nameTo: String){
        let InvitationObject = PFObject(className: "InvitationObject")
        let acl = PFACL()
        acl.publicReadAccess = true
        acl.publicWriteAccess = true
        
        InvitationObject.ACL = acl
        InvitationObject["nameFrom"] = nameFrom
        InvitationObject["nameTo"] = nameTo
        InvitationObject["hasAdded"] = "0"
        if let patient = friendsInfo[nameTo]{
            InvitationObject["timesTo"] = patient.totoalTimes
            InvitationObject["untilDateTo"] = patient.untilDate
        }
        else{
            InvitationObject["timesTo"] = "0"
            InvitationObject["untilDateTo"] = self.getCurrentDate()
        }
        
        InvitationObject["timesFrom"] = "0"
        InvitationObject["untilDateFrom"] = self.getCurrentDate()
        
        InvitationObject.saveInBackgroundWithBlock{
            (success: Bool, error: NSError?) -> Void in
            print("Invitation Object has been saved")
        }
    }
    
    func getPatientInfo(patientName: String){
        let query = PFQuery(className: "FriendsInfo")
        query.whereKey("name", equalTo: patientName)
        query.findObjectsInBackgroundWithBlock{
            (objects:[PFObject]?, error: NSError?) -> Void in
            if error == nil{
                print("get patient info successfully")
                if let array = objects{
                    for item in array{
                        let untilDate = item.objectForKey("untilDate") as! String
                        let patientTimes = item.objectForKey("times") as! String
                        self.patient = Patient(name: patientName, times: patientTimes, date: untilDate)
                    }
                }
            }
        }
    }
    
    func getUserInvitation(){
        let query = PFQuery(className: "InvitationObject")
        query.whereKey("nameFrom", equalTo: name_From)
        query.findObjectsInBackgroundWithBlock{
            (objects:[PFObject]?, error: NSError?) -> Void in
            if error == nil{
                print("get all invitation info")
                if let array = objects{
                    for item in array{
                        let name = item.objectForKey("nameTo") as! String
                        self.invitationSent.append(name)
                    }
                }
            }
        }
    }
    
    func getCurrentDate()->String{
        let date = NSDate()
        let formatter = NSDateFormatter()
        let dateFormat = NSDateFormatter.dateFormatFromTemplate("MMddyyyy", options: 0, locale: NSLocale(localeIdentifier: "en-US"))
        //gbDateFormat now contains an optional string "dd/MM/yyyy"
        formatter.dateFormat = dateFormat
        let dateString = formatter.stringFromDate(date)
        
        print(dateString)
        return dateString
    }
    
    func hasSentBefore(name: String) -> Bool{
        for item in invitationSent{
            if item == name{
                return true
            }
        }
        return false
    }
}

