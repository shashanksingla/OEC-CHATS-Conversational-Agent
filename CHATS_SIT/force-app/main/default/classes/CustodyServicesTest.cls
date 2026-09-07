/*
*/
@isTest
public class CustodyServicesTest {
    
    @testSetup
    public static void setUpData(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.uesername','ttes');
        
        if(user!=null){
        	insert user;
        }
             
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id);
            T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(true,System.today().addYears(-15), 'firstName','1', 'lastName','123456789','CI');
            insert new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
            
            
            T_INDIV_CUST__c custody = new T_INDIV_CUST__c(IDN_CLIENT__c=indivRec.Id,Ignore__c=true);
            insert custody;
          
           system.assertEquals(custody.Id,[select IDN_EXTNL__c from T_INDIV_CUST__c where Id=:custody.Id].IDN_EXTNL__c );
        }
    }
    
}