@RestResource(urlMapping='/schedweeks/*')
global with sharing class ScheduleWeekRestService{
	@HttpGet
        global static List<Schedule_Week__c> GetData(){
			List<Schedule_Week__c> sw = [SELECT Name, Start_Date__c, End_Date__c 
                                         FROM Schedule_Week__c ORDER BY Start_Date__c Desc Limit 50]; 
            return sw;
        }
}