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
    case pickContact = 0
    case createNewContact
    case displayContact
    case editUnknownContact
}

// Height for the Edit Unknown Contact row
let kUIEditUnknownContactRowHeight: CGFloat = 81.0


class ViewController: UITableViewController, CNContactPickerDelegate, CNContactViewControllerDelegate {
    
    fileprivate var store: CNContactStore!
    fileprivate var menuArray: NSMutableArray?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        store = CNContactStore()
        checkContactsAccess()
    }
    
    fileprivate func checkContactsAccess() {
        switch CNContactStore.authorizationStatus(for: .contacts) {
            // Update our UI if the user has granted access to their Contacts
        case .authorized:
            self.accessGrantedForContacts()
            
            // Prompt the user for access to Contacts if there is no definitive answer
        case .notDetermined :
            self.requestContactsAccess()
            
            // Display a message if the user has denied or restricted access to Contacts
        case .denied,
        .restricted:
            let alert = UIAlertController(title: "Privacy Warning!",
                message: "Permission was not granted for Contacts.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func requestContactsAccess() {
        
        store.requestAccess(for: .contacts) {granted, error in
            if granted {
                DispatchQueue.main.async {
                    self.accessGrantedForContacts()
                    return
                }
            }
        }
    }
    
    // This method is called when the user has granted access to their address book data.
    fileprivate func accessGrantedForContacts() {
        // Load data from the plist file
        let plistPath = Bundle.main.path(forResource: "Menu", ofType:"plist")
        self.menuArray = NSMutableArray(contentsOfFile: plistPath!)
        self.tableView.reloadData()
    }
    
    
    //MARK: Table view methods
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.menuArray?.count ?? 0
    }
    
    // Customize the number of rows in the table view.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    // Customize the appearance of table view cells.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let DefaultCellIdentifier = "DefaultCell"
        let SubtitleCellIdentifier = "SubtitleCell"
        var aCell: UITableViewCell?
        // Make the Display Picker and Create New Contact rows look like buttons
        if indexPath.section < 2 {
            aCell = tableView.dequeueReusableCell(withIdentifier: DefaultCellIdentifier)
            if aCell == nil {
                aCell = UITableViewCell(style: .default, reuseIdentifier: DefaultCellIdentifier)
            }
            aCell!.textLabel?.textAlignment = .center
        } else {
            aCell = tableView.dequeueReusableCell(withIdentifier: SubtitleCellIdentifier)
            if aCell == nil {
                aCell = UITableViewCell(style: .subtitle, reuseIdentifier: SubtitleCellIdentifier)
                aCell!.accessoryType = .disclosureIndicator
                aCell!.detailTextLabel?.numberOfLines = 0
            }
            // Display descriptions for the Edit Unknown Contact and Display and Edit Contact rows
            aCell!.detailTextLabel?.text = (self.menuArray![indexPath.section] as AnyObject).value(forKey: "description") as! String?
        }
        
        aCell!.textLabel?.text = (self.menuArray![indexPath.section] as AnyObject).value(forKey: "title") as! String?
        return aCell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let actionType = ActionType(rawValue: indexPath.section) {
            switch actionType {
            case .pickContact:
                self.showContactPickerController()
            case .createNewContact:
                showNewContactViewController()
            case .displayContact:
                showContactViewController()
            case .editUnknownContact:
                showUnknownContactViewController()
            }
        } else {
            self.showContactPickerController()
        }
    }
    
    //MARK: TableViewDelegate method
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Change the height if Edit Unknown Contact is the row selected
        return (indexPath.section == ActionType.editUnknownContact.rawValue) ? kUIEditUnknownContactRowHeight : tableView.rowHeight
    }
    
    //MARK: Show all contacts
    // Called when users tap "Display Picker" in the application. Displays a list of contacts and allows users to select a contact from that list.
    // The application only shows the phone, email, and birthdate information of the selected contact.
    fileprivate func showContactPickerController() {
        let picker = CNContactPickerViewController()
        picker.delegate = self
        
        // Display only a person's phone, email, and birthdate
        let displayedItems = [CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactBirthdayKey]
        picker.displayedPropertyKeys = displayedItems
        
        // Show the picker
        self.present(picker, animated: true, completion: nil)
    }
    
    
    //MARK: Display and edit a person
    // Called when users tap "Display and Edit Contact" in the application. Searches for a contact named "Appleseed" in
    // in the address book. Displays and allows editing of all information associated with that contact if
    // the search is successful. Shows an alert, otherwise.
    fileprivate func showContactViewController() {
        // Search for the person named "Appleseed" in the Contacts
        let name = "Appleseed"
        let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: name)
        let descriptor = CNContactViewController.descriptorForRequiredKeys()
        let contacts: [CNContact]
        do {
            contacts = try store.unifiedContacts(matching: predicate, keysToFetch: [descriptor])
        } catch {
            contacts = []
        }
        // Display "Appleseed" information if found in the address book
        if !contacts.isEmpty {
            let contact = contacts[0]
            let cvc = CNContactViewController(for: contact)
            cvc.delegate = self
            // Allow users to edit the person’s information
            cvc.allowsEditing = true
            //cvc.contactStore = self.store //seems to work without setting this.
            self.navigationController?.pushViewController(cvc, animated: true)
        } else {
            // Show an alert if "Appleseed" is not in Contacts
            let alert = UIAlertController(title: "Error",
                message: "Could not find \(name) in the Contacts application.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: Create a new person
    // Called when users tap "Create New Contact" in the application. Allows users to create a new contact.
    fileprivate func showNewContactViewController() {
        let npvc = CNContactViewController(forNewContact: nil)
        npvc.delegate = self
        //npvc.contactStore = self.store //seems to work without setting this.
        
        let navigation = UINavigationController(rootViewController: npvc)
        self.present(navigation, animated: true, completion: nil)
    }
    
    //MARK: Add data to an existing person
    // Called when users tap "Edit Unknown Contact" in the application.
    fileprivate func showUnknownContactViewController() {
        let aContact = CNMutableContact()
        let newEmail = CNLabeledValue(label: CNLabelOther, value: "John-Appleseed@mac.com" as NSString)
        aContact.emailAddresses.append(newEmail)
        
        let ucvc = CNContactViewController(forUnknownContact: aContact)
        ucvc.delegate = self
        ucvc.allowsEditing = true
        ucvc.allowsActions = true
        ucvc.alternateName = "John Appleseed"
        ucvc.title = "John Appleseed"
        ucvc.message = "Company, Inc"
        ucvc.contactStore = self.store //needed for editing/adding contacts?
        
        self.navigationController?.pushViewController(ucvc, animated: true)
    }
    
    //MARK: CNContactPickerDelegate methods
    // The selected person and property from the people picker.
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        let contact = contactProperty.contact
        let contactName = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
        let propertyName = CNContact.localizedString(forKey: contactProperty.key)
        let message = "Picked \(propertyName) for \(contactName)"
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Picker Result",
                message: message,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // Implement this if you want to do additional work when the picker is cancelled by the user.
    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true, completion: {})
    }
    
    
    //MARK: CNContactViewControllerDelegate methods
    // Dismisses the new-person view controller.
    func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        //
        self.dismiss(animated: true, completion: nil)
    }
    
    func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

