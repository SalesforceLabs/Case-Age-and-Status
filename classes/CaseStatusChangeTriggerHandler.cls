public with sharing class CaseStatusChangeTriggerHandler {

    public static void OnAfterInsert(Case[] newObjects){
        
        List<Case_Status_Change__c> statusChanges = new List<Case_Status_Change__c>();
        statusChanges.addAll(createCaseStatus(newObjects, null));

        //check if user has permission to create Case_Status_Change__c records
        if (!Schema.sObjectType.Case_Status_Change__c.fields.Status_From__c.isCreateable()
             || !Schema.sObjectType.Case_Status_Change__c.fields.Name.isCreateable()
               || !Schema.sObjectType.Case_Status_Change__c.fields.Case__c.isCreateable()
                 || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Name__c.isCreateable()
                   || !Schema.sObjectType.Case_Status_Change__c.fields.Current_Case_Owner__c.isCreateable()
                     || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isCreateable()){
             throw new DmlException('Insufficient permissions to create Case Status Change');
        }
        
        insert statusChanges;
    }
    
    public static void OnAfterUpdate(Case[] updatedObjects, Map<Id, Case> oldObjectMap){
         
        List<Case_Status_Change__c> statusChanges = new List<Case_Status_Change__c>();
        List<Case_Status_Change__c> statusChangesToUpdate = new List<Case_Status_Change__c>();
        List<String> oldStatuses = new List<String>();
        List<Id> caseIds = new List<Id>();

        statusChanges.addAll(createCaseStatus(updatedObjects, oldObjectMap));
        
        //construct old status List and Ids to retrieve old case status changes to update the business hours
        for (Case_Status_Change__c statusChange: statusChanges) {
            
            oldStatuses.add(statusChange.Status_From__c);
            caseIds.add(statusChange.Case__c);            
        }
        
        //CRUD/FLS checks
        if (!Schema.sObjectType.Case_Status_Change__c.isAccessible() 
             ||!Schema.sObjectType.Case_Status_Change__c.fields.Name.isAccessible() 
               || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isAccessible()
                 || !Schema.sObjectType.BusinessHours.isAccessible()){
             throw new QueryException('Insufficient access to Case Status Change or business hours objects');
        }
        
        if (caseIds.size()>0 && oldStatuses.size()>0) {
           
           List<Case_Status_Change__c> oldStatusChanges = [select Id, Name, Set_Time__c from Case_Status_Change__c where Status_Name__c IN :oldStatuses and Case__c IN :caseIds and Change_Time__c=null];
           BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
          
           for (Case_Status_Change__c oldStatusChange: oldStatusChanges) {
                
                // calculate business hours               
                oldStatusChange.Change_Time__c = Datetime.now();
                Double milliseconds = BusinessHours.diff(bh.Id, oldStatusChange.Set_Time__c, oldStatusChange.Change_Time__c);                 
                oldStatusChange.Status_Time__c = (Decimal.valueOf(milliseconds)).Divide((60*60*1000), 2);
                oldStatusChange.Age__c = getAge(milliseconds);
                statusChangesToUpdate.add(oldStatusChange);
            }
        }
                
        //check if user has permission to create Case_Status_Change__c records
        if (!Schema.sObjectType.Case_Status_Change__c.fields.Status_From__c.isCreateable()
             || !Schema.sObjectType.Case_Status_Change__c.fields.Name.isCreateable()
               || !Schema.sObjectType.Case_Status_Change__c.fields.Case__c.isCreateable()
                 || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Name__c.isCreateable()
                   || !Schema.sObjectType.Case_Status_Change__c.fields.Current_Case_Owner__c.isCreateable()
                     || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isCreateable()){
             throw new DmlException('Insufficient permissions to create Case Status Change');
        }
        
        insert statusChanges;
        
        //check if user has permission to update
        if (!Schema.sObjectType.Case_Status_Change__c.fields.Change_Time__c.isUpdateable()
             || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Time__c.isUpdateable()
               || !Schema.sObjectType.Case_Status_Change__c.fields.Age__c.isUpdateable()
                 || !Schema.sObjectType.Case_Status_Change__c.fields.Status_From__c.isUpdateable()
                   || !Schema.sObjectType.Case_Status_Change__c.fields.Name.isUpdateable()
                     || !Schema.sObjectType.Case_Status_Change__c.fields.Case__c.isUpdateable()
                       || !Schema.sObjectType.Case_Status_Change__c.fields.Status_Name__c.isUpdateable()
                         || !Schema.sObjectType.Case_Status_Change__c.fields.Current_Case_Owner__c.isUpdateable()
                           || !Schema.sObjectType.Case_Status_Change__c.fields.Set_Time__c.isUpdateable()
                   ){
             throw new DmlException('Insufficient permissions to update Case Status Change');
        }
        
        update statusChangesToUpdate;
    
    }
    
    
    private static List<Case_Status_Change__c> createCaseStatus(Case[] caseObjects, Map<Id, Case> oldObjectMap){
        
        List<Case_Status_Change__c> statusChanges = new List<Case_Status_Change__c>();
  
         //CRUD/FLS checks
        if (!Schema.sObjectType.Case.isAccessible() 
             ||!Schema.sObjectType.Case.fields.CaseNumber.isAccessible() 
                 || !Schema.sObjectType.User.isAccessible()
                   || !Schema.sObjectType.User.fields.Name.isAccessible()){
             throw new QueryException('Insufficient access to Case or User objects');
        }
   
        Map<Id, Case> cases = new Map<Id, Case>([SELECT CaseNumber, Owner.Name from Case where id in:caseObjects]);

        for (Case caseObject: caseObjects) {
            Case_Status_Change__c  statusChange = null;
            
            if (cases.size()>0) {
                //this is the update case, check if the status has changed or not, if changed
                //a new case status change record is created 
                if (oldObjectMap!=null){
                    Case oldObject = oldObjectMap.get(caseObject.Id);
                    if (caseObject.Status != oldObject.Status) { 
                      
                       statusChange = new Case_Status_Change__c();
                       statusChange.Status_From__c  = oldObject.Status;
                       statusChange.Name = cases.get(caseObject.id).CaseNumber+' from '+oldObject.Status +' to '+caseObject.Status;
                    }
               }
               // this is the new case, the first case status change record is created
               else{
                    statusChange = new Case_Status_Change__c();
                    statusChange.Name = cases.get(caseObject.id).CaseNumber+' status: '+caseObject.Status;                 
               }
               
               //populate the rest of fields, add it to the result list to return 
               if (statusChange!=null) {
                   
                    statusChange.Case__c = caseObject.Id;
                    statusChange.Status_Name__c = caseObject.Status;
                    statusChange.Current_Case_Owner__c = cases.get(caseObject.id).Owner.Name;
                    statusChange.Set_Time__c = Datetime.now();
                    statusChanges.add(statusChange);
               }   
            }
        }
        return statusChanges;
    }
    
    private static String getAge(Double milliseconds) {
        
        Double duration = milliseconds;
        Double d = Math.floor(duration/86400000); //Get whole days
        duration -= d*86400000;
        Double h = Math.floor(duration/3600000); //Get whole hours
        duration -= h*3600000;
        Double m = Math.floor(duration/60000);
        duration -= m*60000;
        Double s = Math.floor(duration/1000);
        return d.format()+' days '+h.format()+' hours '+ m.format() + ' minutes ' + s.format() +' seconds';
    }
   
}