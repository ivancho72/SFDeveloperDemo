@RestResource(urlMapping='/employees/*')
global with sharing class EmployeesRestService{
	@HttpGet
        global static List<Employee__c> GetData(){
			List<Employee__c> emps = [SELECT Name, Company_Number__c FROM Employee__c Limit 50]; 
            return emps;
        }
}