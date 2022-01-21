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

https://www.loom.com/share/57fdca3aec9845a99562bc522fa94923

Generate access token from Vendor Web
Log into Vendor Web
Click on your profile in the top right corner and select Account Settings
Scroll down to user API Tokens and create a new one with Read/Write Access
https://www.loom.com/share/639ac511daff4d8b9775c340d1d15319
