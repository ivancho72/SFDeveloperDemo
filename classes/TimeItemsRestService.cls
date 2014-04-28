@RestResource(urlMapping='/timeitems/*')
global with sharing class TimeItemsRestService{
	@HttpGet
        global static List<TimeItem__c> GetData(){
			List<TimeItem__c> ti = [SELECT Name, Description__c FROM TimeItem__c Limit 50]; 
            return ti;
        }
}