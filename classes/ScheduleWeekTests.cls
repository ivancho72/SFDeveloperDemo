@isTest
public class ScheduleWeekTests{
    public static Schedule_Week__c createScheduleWeek(Date startDate){
        return createScheduleWeek(startDate, NULL);
    }
    
    public static Schedule_Week__c createScheduleWeek(Date startDate, Date endDate){
		Schedule_Week__c newSw = new Schedule_week__c();
        newSw.Start_Date__c = startDate;
        if(endDate != null) newSw.End_Date__c = endDate;
        insert newSw;
        return newSw;
    }
    
    //Verifiy that an error is generated for an invalid Monday
    static testmethod void testInvalidStartDateForScheduleWeek(){        
        try
        {
            Test.startTest();
			createScheduleWeek(Date.newInstance(2013,01,01));
           	Test.stopTest();
        }catch( DMLException e ){
            system.assert(e.getDmlMessage(0) == 'Start date must be on \'Monday\' and End date cannot be more than 6 days from the start date.');
        }
    }
    
    //Verify that a valid Monday is accepted as start date
    static testmethod void testValidStartDateForScheduleWeek(){
        test.startTest();
		createScheduleWeek(Date.newInstance(2012, 05, 21));
       	List<Schedule_Week__c> rows = [SELECT Id FROM Schedule_Week__c];
        test.stopTest();
        System.assert(rows.size() == 1);        
    }
    
    //Verify that calculated end date is on sunday after June-29-2013
    static testmethod void testValidCalculatedValuesForScheduleWeek(){
        test.startTest();
		createScheduleWeek(Date.newInstance(2013, 07, 29));
       	List<Schedule_Week__c> rows = [SELECT Id, End_Date__c FROM Schedule_Week__c];
        test.stopTest();
        System.assert(rows[0].End_Date__c == Date.newInstance(2013, 08, 04));        
    }
    
    //Verify that assigning a wrong EndDate will generate an error
    static testmethod void testInvalidEndDateForScheduleWeek(){        
        try
        {
            Test.startTest();
			createScheduleWeek(Date.newInstance(2012,05,21), Date.newInstance(2012, 05, 28));
           	Test.stopTest();
        }catch( DMLException e ){
            system.assert(e.getDmlMessage(0) == 'Start date must be on \'Monday\' and End date cannot be more than 6 days from the start date.');
        }
    }
    
    //Verify no duplicate weeks are allowed
    static testmethod void testDuplicatedStartDateForScheduleWeek(){        
        try
        {
            Test.startTest();
			createScheduleWeek(Date.newInstance(2012,05,21));
			createScheduleWeek(Date.newInstance(2012,05,21));
           	Test.stopTest();
        }catch( DMLException e ){
            system.assert(e.getDmlMessage(0) == 'Duplicated schedule week record');
        }
    }
}