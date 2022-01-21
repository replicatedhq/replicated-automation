# Salesforce Connector

This repo contains example code to configure a Vendor Salesforce environment to automatically create customer licenses.

# Code

* `License_Creation_Callout.cls`

* `LicenseCreation.tgr`

# Prerequisites:
Create a custom object for your licenses
Go to Setup
Click Object Manager
Create from Spreadsheet and upload the License Template.csv
Update Record Name field = Name
<img width="1088" alt="Screen Shot 2022-01-21 at 2 08 51 PM" src="https://user-images.githubusercontent.com/89656176/150593544-71a58236-b4c8-4539-919d-b81a7a8ff3fe.png">


(Optional but advised) Adjust the Type to a picklist (with values: prod, dev, trial)
Click Next
Adjust the naming and objects settings to your preference
Link this to your account object
Go to your new object (should send you there after saving otherwise go to Setup > Object Manager > [Name of License Object])
Click on fields and relationships
Click New
Select type “Lookup Relationship”
Select Related to “Account”
Select your preferred Security and Layout permissions

Enable authorization of the vendor web URLto connect to SFDC
Go to Setup
Go to Security > Remote Site Settings
Click “New Remote Site”
Add the Vendor Web API site (like below)
<img width="1078" alt="Screen Shot 2022-01-21 at 2 08 57 PM" src="https://user-images.githubusercontent.com/89656176/150593603-5547087b-21c2-4048-9506-e64c4ee4525a.png">

https://www.loom.com/share/57fdca3aec9845a99562bc522fa94923

Generate access token from Vendor Web
Log into Vendor Web
Click on your profile in the top right corner and select Account Settings
Scroll down to user API Tokens and create a new one with Read/Write Access
https://www.loom.com/share/639ac511daff4d8b9775c340d1d15319
