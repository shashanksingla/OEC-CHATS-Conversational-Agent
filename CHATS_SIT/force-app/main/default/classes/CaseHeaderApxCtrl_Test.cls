/*
*/
@isTest
public class CaseHeaderApxCtrl_Test {
    
     public static testMethod void testGetInitData(){
        List<T_SBSD_CASE__c> caseRecords = [SELECT id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseRecords.isEmpty(),'caseRecords should not be empty');
        LightningServerResponse lsr = CaseHeaderApxCtrl.getInitData(caseRecords.get(0).Id);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSucessful should be true');
        System.assertEquals(true, lsr.objectData.containsKey('caseRecord'), 'lsr.objectData should contain caseRecord as key');
         
        CaseHeaderApxCtrl.getInitData('Junk');
    }
    
    public static testMethod void testGetCaseId(){
        LightningServerResponse  lr=  CaseHeaderApxCtrl.getCaseId(null, null);
        System.assertEquals(null, lr, 'r.caseExtId should be null');
       // T_SBSD_CASE__c cases= new T_SBSD_CASE__c(idn_extnl__c='12345');
         LightningServerResponse  lr1=  CaseHeaderApxCtrl.getCaseId('2', 'batchsit_t_fcompsn_eligty__x');
         LightningServerResponse  lr2=  CaseHeaderApxCtrl.getCaseId('2', 'batchsit_t_eligty_run__x');
         LightningServerResponse  lr3=  CaseHeaderApxCtrl.getCaseId('2', 'batchsit_t_fcompsn_indiv_eligty__x');
         
        
            
            }    
    
    @testSetup
    public static void setUpData(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        
        if(user!=null){
            insert user; 
        }
            
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
            TestClassUtility.createCase(true,countyRec.Id);
            TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CI');

        }
    }
}