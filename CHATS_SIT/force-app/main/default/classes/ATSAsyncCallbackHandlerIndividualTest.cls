@isTest
private class ATSAsyncCallbackHandlerIndividualTest  {
    
    static testMethod void myUnitTest() {
        
        
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual.IDN_EXTNL__c='12345';
        
         T_SBSD_INDIV__c individual1 = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual1.IDN_EXTNL__c='12345';
        individual1.NBR_SSN__c= '1234543212';	
        
        
        Profile prof =[select id from profile where name = 'System Administrator'];
        User us = [select id,profileId from user where profileId =:prof.Id and IsActive = true LIMIT 1];
        
        System.runAs(us){
            
            // Start the Test  
            Test.startTest();
            
            Database.Saveresult res = Database.Insert(individual);
            ATSAsyncCallbackHandlerIndividual obj = new ATSAsyncCallbackHandlerIndividual();
            obj.processSave(res);
			Database.Saveresult res1 = Database.Insert(individual1, false);
            obj.processSave(res1);
            Test.stoptest();
            
        }
        
    }
}