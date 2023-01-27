@IsTest
public class CaseStatusChangeTriggerHandlerTest {

    @testSetup static void setupTestdata() {
        
        Case newCase = new Case();
        newCase.Subject = 'Unittest';
        newCase.Status = 'New';
        insert newCase; 
        
        Case testCase = [select Subject, Status from Case where Subject = 'Unittest']; 
        System.assertEquals(testCase.Subject, 'Unittest');
    }
    
    
    
    @IsTest static void testOnAfterInsert(){

        Case[] testCase = [select Subject, CaseNumber, Status, Owner.Name from Case where Subject = 'Unittest'];
        
        CaseStatusChangeTriggerHandler.OnAfterInsert(testCase);
        
        Case_Status_Change__c[] caseStatusChange = [select Name from Case_Status_Change__c where Case__r.Id =:testCase[0].Id];
        
        System.assertEquals(caseStatusChange[0].Name, testCase[0].CaseNumber + ' status: New');
    
    }
    
    
    @IsTest static void testOnAfterUpdate(){

        Map<Id, Case> oldObjectMap = new Map<Id, Case>();
          
        Case[] testCase = [select Subject, CaseNumber, Status, Owner.Name from Case where Subject = 'Unittest'];
        
        Case_Status_Change__c  statusChange = new  Case_Status_Change__c();
        statusChange.Name = testCase[0].CaseNumber + ' status: New';
        statusChange.Case__c = testCase[0].Id;
        statusChange.Status_Name__c = testCase[0].Status;
        statusChange.Set_Time__c = Datetime.now();
        insert statusChange;
        
        testCase[0].Status = 'Escalated';

        Case oldCase = new Case();
        oldCase.Subject ='Unittest';
        oldCase.Status = 'New';
        oldCase.Id=testCase[0].Id;
        oldObjectMap.put(testCase[0].Id, oldCase);

        
        CaseStatusChangeTriggerHandler.OnAfterUpdate(testCase, oldObjectMap);
        
        Case_Status_Change__c[] caseStatusChange = [select Name from Case_Status_Change__c where Case__r.Id=:testCase[0].Id and Change_Time__c = null];
        
        
        System.assertEquals(caseStatusChange[0].Name, testCase[0].CaseNumber + ' from New to Escalated');
    
    }
     
    /**
     *Tests if the user does not have access to Case and Case_Status_Change__c objects
     */
    @IsTest static void testAccessible1(){
       
        User u = getUser('NotAccessible1');

        System.runAs(u) {
            try {
                testOnAfterInsert();
                System.assert(false, 'fail the test if no exception thrown ');
            }
            catch (QueryException e) {
                 System.assertEquals(e.getMessage(), 'Insufficient access to Case or User objects');         
            }   
        }
  
    }
    
    @IsTest static void testAccessible2(){
        
        User u = getUser('NotAccessible2');
        
        System.runAs(u) {
            try {
                testOnAfterUpdate();
                System.assert(false, 'fail the test if no exception thrown ');
            }
            catch (QueryException e) {
                 System.assertEquals(e.getMessage(), 'Insufficient access to Case Status Change or business hours objects');         
            }   
        }
    }
    
    @IsTest static void testCreatable(){
        
        User u = getUser('NotCreatable');
        
        System.runAs(u) {
            try {
                testOnAfterInsert();
                System.assert(false, 'fail the test if no exception thrown ');
            }
            catch (DmlException e) {
                 System.assertEquals(e.getMessage(), 'Insufficient permissions to create Case Status Change');         
            }    
        }
        
        System.runAs(u) {
            try {
                testOnAfterUpdate();
                System.assert(false, 'fail the test if no exception thrown ');
            }
            catch (DmlException e) {
                 System.assertEquals(e.getMessage(), 'Insufficient permissions to create Case Status Change');         
            }    
        }     
    }
    
    @IsTest static void testUpdatable(){
        
        User u = getUser('NotUpdatable');
        
        System.runAs(u) {
            try {
                testOnAfterUpdate();
                System.assert(false, 'fail the test if no exception thrown ');
            }
            catch (DmlException e) {
                 System.assertEquals(e.getMessage(), 'Insufficient permissions to update Case Status Change');         
            }
            
        }      
    }
    
    
    public static User getUser(String profileName) {
        
        Profile p = [SELECT Id FROM Profile WHERE Name=:profileName limit 1];
        
        String testemail = 'atest@test.demo';
        User pu = new User(profileId = p.Id, username = testemail, email = testemail, 
                           emailencodingkey = 'UTF-8', localesidkey = 'en_US', 
                           languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles', 
                           alias='cspu', lastname='lastname');
        
        return pu;
        
        
    }
    
}