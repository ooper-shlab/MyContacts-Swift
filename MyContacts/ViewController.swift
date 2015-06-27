//
//  ViewController.swift
//  MyContacts
//
//  Created by OOPer on 2015/6/27.
//  Copyright © 2015 OOPer (NAGATA, Atsuyuki). See LICENSE.txt .
//

import UIKit

import Contacts
import ContactsUI


enum ActionType: Int {
    case PickContact = 0
    case CreateNewContact
    case DisplayContact
    case EditUnknownContact
}

// Height for the Edit Unknown Contact row
let kUIEditUnknownContactRowHeight: CGFloat = 81.0


class ViewController: UITableViewController, CNContactPickerDelegate, CNContactViewControllerDelegate {
    
    private var store: CNContactStore!
    private var menuArray: NSMutableArray?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        store = CNContactStore()
        checkContactsAccess()
    }
    
    private func checkContactsAccess() {
        switch CNContactStore.authorizationStatusForEntityType(.Contacts) {
            // Update our UI if the user has granted access to their Contacts
        case .Authorized:
            self.accessGrantedForContacts()
            
            // Prompt the user for access to Contacts if there is no definitive answer
        case .NotDetermined :
            self.requestContactsAccess()
            
            // Display a message if the user has denied or restricted access to Contacts
        case .Denied,
        .Restricted:
            let alert = UIAlertController(title: "Privacy Warning!",
                message: "Permission was not granted for Contacts.",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func requestContactsAccess() {
        
        store.requestAccessForEntityType(.Contacts) {granted, error in
            if granted {
                dispatch_async(dispatch_get_main_queue()) {
                    self.accessGrantedForContacts()
                    return
                }
            }
        }
    }
    
    // This method is called when the user has granted access to their address book data.
    private func accessGrantedForContacts() {
        // Load data from the plist file
        let plistPath = NSBundle.mainBundle().pathForResource("Menu", ofType:"plist")
        self.menuArray = NSMutableArray(contentsOfFile: plistPath!)
        self.tableView.reloadData()
    }
    
    
    //MARK: Table view methods
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.menuArray?.count ?? 0
    }
    
    // Customize the number of rows in the table view.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Customize the appearance of table view cells.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let DefaultCellIdentifier = "DefaultCell"
        let SubtitleCellIdentifier = "SubtitleCell"
        var aCell: UITableViewCell?
        // Make the Display Picker and Create New Contact rows look like buttons
        if indexPath.section < 2 {
            aCell = tableView.dequeueReusableCellWithIdentifier(DefaultCellIdentifier)
            //dequeueReusableCellWithIdentifier(DefaultCellIdentifier) as! UITableViewCell?
            if aCell == nil {
                aCell = UITableViewCell(style: .Default, reuseIdentifier: DefaultCellIdentifier)
            }
            aCell!.textLabel?.textAlignment = .Center
        } else {
            aCell = tableView.dequeueReusableCellWithIdentifier(SubtitleCellIdentifier)
            if aCell == nil {
                aCell = UITableViewCell(style: .Subtitle, reuseIdentifier: SubtitleCellIdentifier)
                aCell!.accessoryType = .DisclosureIndicator
                aCell!.detailTextLabel?.numberOfLines = 0
            }
            // Display descriptions for the Edit Unknown Contact and Display and Edit Contact rows
            aCell!.detailTextLabel?.text = self.menuArray![indexPath.section].valueForKey("description") as! String?
        }
        
        aCell!.textLabel?.text = self.menuArray![indexPath.section].valueForKey("title") as! String?
        return aCell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let actionType = ActionType(rawValue: indexPath.section) {
            switch actionType {
            case .PickContact:
                self.showContactPickerController()
            case .CreateNewContact:
                showNewContactViewController()
            case .DisplayContact:
                showContactViewController()
            case .EditUnknownContact:
                showUnknownContactViewController()
            }
        } else {
            self.showContactPickerController()
        }
    }
    
    //MARK: TableViewDelegate method
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Change the height if Edit Unknown Contact is the row selected
        return (indexPath.section == ActionType.EditUnknownContact.rawValue) ? kUIEditUnknownContactRowHeight : tableView.rowHeight
    }
    
    //MARK: Show all contacts
    // Called when users tap "Display Picker" in the application. Displays a list of contacts and allows users to select a contact from that list.
    // The application only shows the phone, email, and birthdate information of the selected contact.
    private func showContactPickerController() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        
        // Display only a person's phone, email, and birthdate
        let displayedItems = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactBirthdayKey]
        picker.displayedPropertyKeys = displayedItems
        
        // Show the picker
        self.presentViewController(picker, animated: true, completion: nil)
    }
    
    
    //MARK: Display and edit a person
    // Called when users tap "Display and Edit Contact" in the application. Searches for a contact named "Appleseed" in
    // in the address book. Displays and allows editing of all information associated with that contact if
    // the search is successful. Shows an alert, otherwise.
    private func showContactViewController() {
        // Search for the person named "Appleseed" in the Contacts
        let name = "Appleseed"
        let predicate: NSPredicate = CNContact.predicateForContactsMatchingName(name)
        let descriptor = CNContactViewController.descriptorForRequiredKeys()
        let contacts: [CNContact]
        do {
            contacts = try store.unifiedContactsMatchingPredicate(predicate, keysToFetch: [descriptor])
        } catch {
            contacts = []
        }
        // Display "Appleseed" information if found in the address book
        if !contacts.isEmpty {
            let contact = contacts[0]
            let cvc = CNContactViewController(forContact: contact)
            cvc.delegate = self
            // Allow users to edit the person’s information
            cvc.allowsEditing = true
            self.navigationController?.pushViewController(cvc, animated: true)
        } else {
            // Show an alert if "Appleseed" is not in Contacts
            let alert = UIAlertController(title: "Error",
                message: "Could not find \(name) in the Contacts application.",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: Create a new person
    // Called when users tap "Create New Contact" in the application. Allows users to create a new contact.
    private func showNewContactViewController() {
        let npvc = CNContactViewController(forNewContact: nil)
        npvc.delegate = self
        
        let navigation = UINavigationController(rootViewController: npvc)
        self.presentViewController(navigation, animated: true, completion: nil)
    }
    
    //MARK: Add data to an existing person
    // Called when users tap "Edit Unknown Contact" in the application.
    private func showUnknownContactViewController() {
        let aContact = CNMutableContact()
        let newEmail = CNLabeledValue(label: CNLabelOther, value: "John-Appleseed@mac.com")
        aContact.emailAddresses.append(newEmail)
        
        let ucvc = CNContactViewController(forUnknownContact: aContact)
        ucvc.delegate = self
        ucvc.allowsEditing = true
        ucvc.allowsActions = true
        ucvc.alternateName = "John Appleseed"
        ucvc.title = "John Appleseed"
        ucvc.message = "Company, Inc"
        
        self.navigationController?.pushViewController(ucvc, animated: true)
    }
    
    
    //MARK: CNContactViewControllerDelegate methods
    // Dismisses the new-person view controller.
    func contactViewController(viewController: CNContactViewController, didCompleteWithContact contact: CNContact?) {
        //
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func contactViewController(viewController: CNContactViewController, shouldPerformDefaultActionForContactProperty property: CNContactProperty) -> Bool {
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

