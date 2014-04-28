@RestResource(urlMapping='/timesheet/*')
global with sharing class TimeReportRestService
{
    global class ItemWeekReport
    {
    	public List<Time_Report__c> WeekValues;
        public TimeItem__c Item;
    }
    
	@HttpGet
        global static List<ItemWeekReport> GetData()
        {
            List<ItemWeekReport> retVal = new List<ItemWeekReport>();
            RestRequest req = RestContext.request;
            String WeekId = req.params.get('WeekId');
            String EmployeeId = req.params.get('EmployeeId');
            
            List<Time_Report__c> vals = [SELECT DayOfWeek__c, Hours__c, Item__c, Week__c, Id, Name,
                                         Item__r.Id, Item__r.Name, Item__r.Description__c
                                         FROM Time_Report__c WHERE Week__r.Week__c = :WeekId
                                         AND Week__r.Employee__c = :EmployeeId
                                         ORDER BY Item__c, Day_Number__c];
            
            Id prevVal;
            ItemWeekReport itReport; 
            For( Time_Report__c TimeReport : vals )
            {
                if(TimeReport.Item__c != prevVal)
                {
                    itReport = new ItemWeekReport();
                    itReport.WeekValues = new List<Time_Report__c>();
                    retVal.add(itReport);
                    itReport.Item = TimeReport.Item__r;
                    prevVal = TimeReport.Item__c;
                }
                itReport.WeekValues.add(TimeReport);
            }
            
            return retVal;
        }
    
    @HttpPost
        global static void postData(List<ItemWeekReport> timesheetData)
        {
            //Parse Parameters
            RestRequest req = RestContext.request;
            List<String> parts = req.RequestURI.split('/',-2);
            String WeekId = parts[parts.size()-1];
            String EmployeeId = parts[parts.size()-2];
            
            //Declare Variables
            System.debug('Posting Data for WeekId=' + WeekId + ' EmployeeId=' + EmployeeId);
            List<Time_Report__c> newReports = new List<Time_Report__c>();
            List<Time_Report__c> updateReports = new List<Time_Report__c>();
            Map<String, List<Time_Report__c>> ReportsPerItem = new Map<String, List<Time_Report__c>>();
            
            //Find Items to insert, update and delete
            Time_Sheet__c tsRecord = null;
            try
            {
            	tsRecord = getIndexedExistingReports(EmployeeId, WeekId, ReportsPerItem);
            }
            catch(Exception e)
            {
                RestContext.Response.statusCode = 400;
                System.debug(e);
				return;                
            }
            
            System.debug('Found existing reports=' + ReportsPerItem.size() + 
                         ' for timesheet=' + JSON.serialize(tsRecord));
            getUpsertReports(timesheetData, ReportsPerItem, newReports, updateReports);
            System.debug('Items to Insert=' + newReports.size() + ' Items to update=' + updateReports.size());
            List<Time_Report__c> deleteReports = getDeleteReports(timesheetData, ReportsPerItem);
            System.debug('Items to Delete=' + deleteReports.size());
            
            //Save data to database as a single transaction
            SavePoint sp = database.setSavepoint();
            try{
            	upsert tsRecord;
				System.Debug('timeSheet Upserted=' + JSON.serialize(tsRecord));
                updateParent(newReports, tsRecord);
            	insert newReports;
             	update updateReports;
            	delete deleteReports;
            } catch( DmlException e ){
                database.rollback(sp);
                System.Debug(e.getMessage());
                RestContext.Response.statusCode = 400;
            }
        }
    
    private static Time_Sheet__c getIndexedExistingReports(
        								String EmployeeId, String WeekId,  
        								Map<String, List<Time_Report__c>> mapResult)
    {
        List<Time_Sheet__c> sheets = [SELECT Id, Name, Approved__c FROM time_sheet__c 
                                  WHERE Employee__r.Id = :EmployeeId AND Week__r.Id = :WeekId LIMIT 1];

        if(sheets.size() < 1)
        {
            sheets.add(new Time_sheet__c());
        	sheets[0].Approved__c = false;
            sheets[0].Employee__c = EmployeeId;
            sheets[0].Week__c = WeekId;
        }
        else
        {
        	For(Time_report__c item : [SELECT DayOfWeek__c, Hours__c, Item__c, Item__r.Name 
                FROM time_report__c WHERE Week__c = :sheets[0].Id])
            {
                if(!mapResult.containsKey(item.Item__r.Name))
                {
                    mapResult.put(item.Item__r.Name, new List<Time_Report__c>());
                }
                List<Time_Report__c> rep = mapResult.get(item.Item__r.Name);
                rep.add(item);
            }
            System.debug('Existing Time Sheet Name=' + sheets[0].Name + 
                         ' Reports = {' + JSON.serialize(mapResult) + '}' );
        }
		return sheets[0];
    }
    
    private static void getUpsertReports(List<ItemWeekReport> Data, 
                                      Map<String, List<Time_Report__c>> ReportsPerItem,
                                      List<Time_Report__c> newItems,
                                      List<Time_Report__c> updateItems)
    {
        System.Debug('Searching ItemWeekReport=' + JSON.serialize(Data));
        for(ItemWeekReport item : Data){
            for(Time_Report__c dayReport : item.WeekValues)
            { 
                if( !ReportsPerItem.containsKey(item.Item.Name))
                {
                    newItems.add(dayReport);
                }
                else 
                {
                    Time_Report__c day = LocateDay(ReportsPerItem.get(item.Item.Name), dayReport.DayOfWeek__c);
                    if( day == null)
                    {
                		newItems.add(dayReport);
                    }
                    else
                    {
                        day.Hours__c = dayReport.Hours__c;
                        updateItems.add(day);
                    }
                }
            }
        }
    }

    private static List<Time_Report__c> getDeleteReports(List<ItemWeekReport> Data, 
                                                      Map<String, List<Time_Report__c>> ReportsPerItem)
    {
		List<Time_Report__c> deleteReports = new List<Time_Report__c>();
        for( String key : ReportsPerItem.keySet())
        {
            If( ! existItem(key, Data) )
            {
                deleteReports.addAll(ReportsPerItem.get(key));
            }
        }
    	return deleteReports;
    }
    
    private static void updateParent(List<Time_Report__c> newReports, Time_Sheet__c newSheet)
    {
        for(Time_Report__c timeReport : newReports)
        {
        	timeReport.Week__c = newSheet.Id;
        }
    }
    
    private static Time_Report__c LocateDay(List<Time_Report__c> days, String targetDay)
    {
        for(Time_Report__c day : days)
        {
			if(day.DayOfWeek__c == targetDay) return day;
        }
        return null;
    }
    
    private static boolean existItem(String ItemName, List<ItemWeekReport> reports)
    {
        for(ItemWeekReport rep : reports)
        {
			if(rep.Item.Name == ItemName) return true;
        }
		return false;
    }
}