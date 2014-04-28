public with sharing class MyController {
    public Id selectedAccount { get; set; }
    public List<Contact> contactsInformation { get; set; }
    public List<Account> getMyaccounts() {
        return [SELECT Id, Name, AccountNumber FROM Account ORDER BY
                LastModifiedDate DESC LIMIT 10];        
    }
    
    public void accountClicked() { 
        contactsInformation = [SELECT FirstName, LastName FROM Contact WHERE AccountID = :selectedAccount];
    }
}