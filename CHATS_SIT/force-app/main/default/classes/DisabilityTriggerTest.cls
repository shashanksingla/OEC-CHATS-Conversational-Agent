/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Disability Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class DisabilityTriggerTest {
    
    public static testMethod void testStampSalesforceIdToExternalId(){
         Date childBirth = System.today().addYears(-10);
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, childBirth, 'firstName', '1', 'lastName', '01234567', 'CC'); 
        Test.startTest();
        T_INDIV_DSBLTY__c indivDisObj = TestClassUtility.createIndivDisability(true, indivObj.Id);
        T_INDIV_DSBLTY__c indivDisObjAfterInsert = [select Id,IDN_EXTNL__c from T_INDIV_DSBLTY__c where Id=:indivDisObj.Id];
        Test.stopTest();
        
        System.assert(indivDisObjAfterInsert.IDN_EXTNL__c!=null && indivDisObjAfterInsert.IDN_EXTNL__c == indivDisObjAfterInsert.Id, 
                      'Salesforce ID was successfully stamped to external ID');
    }

	
}