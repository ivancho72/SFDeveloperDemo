@isTest
public class TimeReportRestServiceTests{
	//Used to create test data
    private static List<string> daysOfWeek = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'};
    
    public static List<Time_Sheet__c> initializeData(List<Employee__c> emps, 
                                                     List<Schedule_Week__c> weeks, 
                                                     boolean withTimeSheets){
        List<TimeItem__c> items = new List<TimeItem__c>();
        List<Time_Sheet__c> ts = new List<Time_Sheet__c>();
        
        emps.add(createEmployee('Emp1', '001'));
        emps.add(createEmployee('Emp2', '002'));
        emps.add(createEmployee('Emp3', '003'));
        
        items.add(createTimeItem('01', 'Item 01'));
        items.add(createTimeItem('02', 'Item 02'));
        items.add(createTimeItem('03', 'Item 03'));
        
        weeks.add(createScheduleWeek(Date.newInstance(2013, 01, 07)));
        weeks.add(createScheduleWeek(Date.newInstance(2013, 01, 14)));
        weeks.add(createScheduleWeek(Date.newInstance(2013, 01, 21)));
        
        if(withTimeSheets)
        {
            ts.add(createTimeSheet(weeks[0], emps[0], items, new List<decimal> {40}));
            ts.add(createTimeSheet(weeks[0], emps[1], items, new List<decimal> {20, 10, 10}));
            ts.add(createTimeSheet(weeks[1], emps[1], items, new List<decimal> {40, 40, 30}));
            ts.add(createTimeSheet(weeks[1], emps[2], items, new List<decimal> {5, 5, 30}));
            ts.add(createTimeSheet(weeks[2], emps[0], items, new List<decimal> {10, 10}));
        }
        return ts;
    }
    
    public static Employee__c createEmployee(string Name, string CNumber){
        Employee__c newEmp = new Employee__c();
        newEmp.Company_Number__c = CNumber;
        newEmp.Name = Name;
        insert newEmp;
        return newEmp;
    }
    
    public static TimeItem__c createTimeItem(string code, string name){
		TimeItem__c newTi = new TimeItem__c();
        newTi.Name = code;
        newTi.Description__c = name;
        insert newTi;
        return newTi;
    }
    
    public static Schedule_Week__c createScheduleWeek(Date startDate){
		Schedule_Week__c newSw = new Schedule_week__c();
        newSw.Start_Date__c = startDate;
        insert newSw;
        return newSw;
    }
    
    public static Time_Sheet__c createTimeSheet(Schedule_Week__c week, Employee__c emp, 
                                                List<TimeItem__c> items, List<Decimal> hours){
        
        Time_Sheet__c newTs = new Time_Sheet__c();
        newTs.Employee__c = emp.Id;
        newTs.Week__c = week.Id;
        insert newTs;
        integer ct = 0;
        for(TimeItem__c item : items){
            if(hours.size() >= ct + 1){
                decimal hoursWorked = hours[ct];            
                for(string day : daysOfWeek)
                {   
                    if(hoursWorked > 8 ){
                        createTimeReport(item, 8, newTs, day);
                        hoursWorked -= 8;
                    }
                    else if( hoursWorked > 0){
                        createTimeReport(item, hoursWorked, newTs, day);
                        hoursWorked = 0;
                    }
                    else {
                        //createTimeReport(item, 0, newTs, day);
                    }
                }
                ct++;
            }
        }
		return newTs;
    }
    
    public static Time_Report__c createTimeReport(TimeItem__c ti, decimal hours, 
                                                  Time_Sheet__c ts, string day){
    	Time_Report__c newTr = new Time_Report__c();
        newTr.Hours__c = hours;
        newTr.DayOfWeek__c = day;
        newTr.Item__c = ti.Id;                                                     
        newTr.Week__c = ts.Id;
        insert newTr;
        return newTr;
    }
    
    static private List<Time_Report__c> addTimeReports(List<double> weekHours){
    	List<Time_Report__c> reports = new List<Time_Report__c>();        
        for(integer i = 0; i < 7; i++){
            if(weekHours.size() > i){
            Time_Report__c rep = new Time_Report__c();
            rep.DayOfWeek__c = DaysOfWeek[i];
            rep.Hours__c = weekHours[i];
            reports.add(rep);
        }
        }
        return reports;
    }

    static testmethod void testTimeSheetRetrieval()
    {
        System.Debug('Start testTimeSheetRetrieval()'); 
        //Initialize Data
        List<Employee__c> emps = new List<Employee__c>();
        List<Schedule_Week__c> weeks = new List<Schedule_Week__c>();
        initializeData(emps, weeks, true);
        RestRequest req = new RestRequest();
        req.addParameter('EmployeeId', emps[1].Id);
        req.addParameter('WeekId', weeks[1].Id);
        RestContext.request = req;
        
        Test.startTest();
        	List<TimeReportRestService.ItemWeekReport> rows = TimeReportRestService.GetData();
        Test.stopTest();
        
        System.assertEquals(3, rows.size(), 'Incorrect # of WeekItems Retrieved');
        System.assertEquals(5, rows[0].WeekValues.Size(), '# of days not correct for Item 1');
        System.assertEquals(5, rows[1].WeekValues.Size(), '# of days not correct for Item 2');
        System.assertEquals(4, rows[2].WeekValues.Size(), '# of days not correct for Item 3');        
    }
    
    static testmethod void testExistingTimeSheetUpdate()
    {
        System.Debug('Start testExistingTimeSheetUpdate()'); 
        //Initialize Data
        List<Employee__c> emps = new List<Employee__c>();
        List<Schedule_Week__c> weeks = new List<Schedule_Week__c>();
        List<TimeReportRestService.ItemWeekReport> timeToPost = new List<TimeReportRestService.ItemWeekReport>();
		TimeReportRestService.ItemWeekReport modifiedTimeReport = new TimeReportRestService.ItemWeekReport();
        
        List<Time_Sheet__c> tsData = initializeData(emps, weeks, true);
        RestRequest req = new RestRequest();
        req.requestURI = 'https://na15.salesforce.com/services/apexrest/timesheet/' + emps[1].Id + '/' + weeks[1].Id;
        RestContext.request = req;
        
        modifiedTimeReport.Item = new TimeItem__c();
        modifiedTimeReport.Item.Name = '02';
        modifiedTimeReport.Item.Description__c = 'Item 02';
        modifiedTimeReport.WeekValues = addTimeReports(new List<double> {8,8,8,8,8,0,0});
        timeToPost.add(modifiedTimeReport);
		
        //Act
        DateTime timeBeforeTestStart = DateTime.Now();        
        Test.startTest();
        	TimeReportRestService.PostData(timeToPost);
        Test.stopTest();
        
        //Assertion for updated items        
        List<Time_report__c> updatedRecords = [SELECT CreatedDate FROM Time_Report__c WHERE Week__c = :tsData[2].Id];        
        System.assertEquals(7, updatedRecords.size());
        System.assert(updatedRecords[0].CreatedDate < timeBeforeTestStart);
        List<Time_Sheet__c> tsActual = [SELECT Total_Hours__c FROM Time_Sheet__c WHERE Id = :tsData[2].Id];
        System.assertEquals(40, tsActual[0].Total_Hours__c);
    }
    
    static testmethod void testNewTimeSheetCreated()
    {
        System.Debug('Start testNewTimeSheetCreated()'); 
		//Initialize Data
        List<Employee__c> emps = new List<Employee__c>();
        List<Schedule_Week__c> weeks = new List<Schedule_Week__c>();
        List<TimeReportRestService.ItemWeekReport> timeToPost = new List<TimeReportRestService.ItemWeekReport>();
		TimeReportRestService.ItemWeekReport newTimeReport = new TimeReportRestService.ItemWeekReport();
        
        initializeData(emps, weeks, false);
        RestRequest req = new RestRequest();
        req.requestURI = 'https://na15.salesforce.com/services/apexrest/timesheet/' + emps[1].Id + '/' + weeks[1].Id;
        RestContext.request = req;
        
        newTimeReport.Item = new TimeItem__c();
        newTimeReport.Item.Name = '02';
        newTimeReport.Item.Description__c = 'Item 02';
        newTimeReport.WeekValues = addTimeReports(new List<double> {8,8,8,8,8,0,0});
        timeToPost.add(newTimeReport);
		
        //Act
        Test.startTest();
        	TimeReportRestService.PostData(timeToPost);
        Test.stopTest();
        
        //Assertion for new items        
        List<Time_Sheet__c> tsActual = [SELECT Id, Total_Hours__c FROM Time_Sheet__c WHERE 
                                        Employee__c = :emps[1].Id AND Week__c = :weeks[1].Id];
        System.assertEquals(40, tsActual[0].Total_Hours__c);        
        List<Time_report__c> newRecords = [SELECT CreatedDate FROM Time_Report__c WHERE Week__c = :tsActual[0].Id];        
        System.assertEquals(7, newRecords.size());
    }
    
    static testmethod void testNonExistentEmployeeOrWeek()
    {
        System.Debug('Start testNonExistentEmployeeOrWeek()'); 
		//Initialize Data
        List<Employee__c> emps = new List<Employee__c>();
        List<Schedule_Week__c> weeks = new List<Schedule_Week__c>();
        List<TimeReportRestService.ItemWeekReport> timeToPost = new List<TimeReportRestService.ItemWeekReport>();
		TimeReportRestService.ItemWeekReport newTimeReport = new TimeReportRestService.ItemWeekReport();
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        req.requestURI = 'https://na15.salesforce.com/services/apexrest/timesheet/a00i000000B4TwCAAV/a04i00000076tNTAAY';
        RestContext.request = req;
        RestContext.response = resp;
        
        newTimeReport.Item = new TimeItem__c();
        newTimeReport.Item.Name = '02';
        newTimeReport.Item.Description__c = 'Item 02';
        newTimeReport.WeekValues = addTimeReports(new List<double> {8,8,8,8,8,0,0});
        timeToPost.add(newTimeReport);
		
        //Act
        Test.startTest();
        	TimeReportRestService.PostData(timeToPost);
        Test.stopTest();
        
        //Assertion for new items        
        System.assertEquals(resp.statusCode, 400);
    }

    static testmethod void testInvalidEmployeeOrWeek()
    {
        System.Debug('Start testInvalidEmployeeOrWeek()'); 
		//Initialize Data
        List<TimeReportRestService.ItemWeekReport> timeToPost = new List<TimeReportRestService.ItemWeekReport>();
        
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();
        req.requestURI = 'https://na15.salesforce.com/services/apexrest/timesheet/000/999';
        RestContext.request = req;
        RestContext.response = resp;
        		
        //Act
        Test.startTest();
        	TimeReportRestService.PostData(timeToPost);
        Test.stopTest();
        
        //Assertion for new items        
        System.assertEquals(resp.statusCode, 400);
    }
}