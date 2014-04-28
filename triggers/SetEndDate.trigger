trigger SetEndDate on Schedule_Week__c (before insert, before update) {
    For(Integer i = 0; i < Trigger.new.Size(); i ++){
        // first validates that no record exists for the same date
        List<Schedule_Week__c> swList = [SELECT id FROM Schedule_Week__c s 
                                         WHERE s.Start_Date__c = :Trigger.new[i].Start_Date__c];
        
        if(swList.Size() > 0 && swList[0].Id <> Trigger.new[i].Id ){
         Trigger.new[i].addError('Duplicated schedule week record');
        }else{        
            //Assign End Date if everything is fine
            Trigger.new[i].End_Date__c = Trigger.new[i].Start_Date__c + 6;
        }
    }
}