/*********************************************************************************************
*  @author         Deloitte Consulting                                             
*  @date           03/10/2021                                                          
*  @description    Test class for Employment Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 10-March-2021                                                             
*  * Author: Barkha Jain                                                     
*  * Description: Initial version                                                 
*********************************************************************************************/
@isTest
private class EmploymentServicesTest {
    
    static testmethod void empservicetest(){
        T_COUNTY__c county= TestClassUtility.createCounty('countyName', 'countyDepartmentName', 01, true);
        T_SBSD_CASE__c caserec= TestClassUtility.createCase(true,county.Id);
        T_SBSD_CASE__c caserecone= TestClassUtility.createCase(true,county.Id);
        T_SBSD_INDIV__c indivrec= TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        TestClassUtility.createCaseIndividual(true, caserec.Id, indivrec.Id, true);
        TestClassUtility.createCaseIndividual(true, caserecone.Id, indivrec.Id, false);
        List<T_SBSD_INDIV_EMPLMT__c>record=new List<T_SBSD_INDIV_EMPLMT__c>();
        T_SBSD_INDIV_EMPLMT__c emprec=new T_SBSD_INDIV_EMPLMT__c();
        emprec.ADR_CITY__c='Puri';
        emprec.DTE_BEGIN_EFFV__c=date.newInstance(1983, 7, 15);
        emprec.IDN_CLIENT__c=indivrec.Id;
        emprec.IDN_CASE__c=caserec.Id;
        emprec.NAM_BUSNS__c='Testing';
        emprec.IND_STUBS_PAY_RCVS__c='Y';
        
        Profile userProfile=[Select id from Profile where Name ='CHATS System Administrator'];
        User user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '1';
            insert user; 
        }
        System.runAs(user){
            Test.startTest();
            insert emprec;
            emprec.IDN_CASE__c=caserecone.Id;
            update emprec;
            Test.stopTest();  
        }
    }
}