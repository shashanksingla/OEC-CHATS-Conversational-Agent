/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           01/07/2018                                                          
*  @description    Test class for Eligibility - Individual Flow
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 07-Jan-2018                                                            
*  * Author: Gaurav Dharra                                                      
*  * Description: Initial version                                                 
*                                                                                 
*  * Version: 2.0                                                                             
*  * Date: 04-Apr-2018                                                            
*  * Author: Shubham Jain
*  * Description: Updates as per the new design
*********************************************************************************************/
@isTest
public class IndividualFlowCtrl_Test {
    
    public static testMethod void testgetInitData() {
        IndividualFlowCtrl.getInitData(null);
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(false,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        individual.IDN_EXTNL__c='12345';
        insert individual;
        TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        IndividualFlowCtrl.getInitData('123');
        delete individual;
        LightningServerResponse lsr=IndividualFlowCtrl.getInitData('123');
        
        system.assertEquals(false,lsr.isSuccessful,'isSuccessful should be false');
    }
    
    public static testMethod void testGetIneligibleReason(){
        LightningServerResponse lsr = IndividualFlowCtrl.getIneligibleReason(123);
        System.assertEquals(false, lsr.isSuccessful);
        insert new T_INELIG_REASON__c(IDN_DOC__c = 'CR115', CDE_REASON__c='564');
        IndividualFlowCtrl.getIneligibleReason(123);
        System.assertEquals(false, lsr.isSuccessful);
    }
    
}