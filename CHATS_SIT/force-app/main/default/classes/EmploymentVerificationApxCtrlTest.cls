/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/23/2017                                                          
*  @description    EmploymentVerificationApxCtrlTest
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 04-Dec-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*  * JIRA Ticket: CHAT-1187
*                                                                                 
*********************************************************************************************/
@isTest
public class EmploymentVerificationApxCtrlTest {
    
    public static testMethod void testGetInitData(){
        String employmentId = '123';
        List<T_SBSD_INDIV__c> ClientList = [Select id,name from T_SBSD_INDIV__c];
        List<T_SBSD_INDIV_EMPLMT__c> EmploymentList = [Select id, name from T_SBSD_INDIV_EMPLMT__c limit 100];
        String emplId = EmploymentList[0].id;
        
        
        T_INDIV_EMPLMT_VERIF__c emplVerification = new T_INDIV_EMPLMT_VERIF__c(IDN_EMPLMT_INDIV__c =emplId);
        insert emplVerification;
        
        T_INDIV_EMPLMT_INFO__c emplInformation = new T_INDIV_EMPLMT_INFO__c(IDN_EMPLMT_INDIV__c =emplId, CDE_TYPE_INFO_EMPLMT__c = 'ML', CDE_TYPE_VERIF__c = 'V');
        insert emplInformation;
        test.startTest();
        EmploymentVerificationApxCtrl.getInitData(emplId);
        EmploymentVerificationApxCtrl.getInitData(employmentId);
        test.stopTest();
        
        system.assertEquals(EmploymentList.size(), 1, 'employement record is present in the list');
    }
    
    @testSetup
    private static void TestSetup(){
        T_SBSD_INDIV__c clientTest = TestClassUtility.createIndividual(false,date.parse('12/12/2017'),'firstName', '1', 'lastName', '123123123','CC');
        //clientTest.Name = 'TestName';
        clientTest.IND_CDE_TYPE_VERIF_DOB__c = 'V';
        clientTest.NBR_SSN__c = '123123123';
        clientTest.CDE_GENDER__c = '1';
        clientTest.CDE_ETNCTY__c = 'U';
        clientTest.CDE_SOURCE_VRFYD_DOB__c = 'AL';
        clientTest.IND_CHILD_IDEA__c = 'Y';
        clientTest.IND_CHILD_SCREEN__c = 'Y';
        clientTest.IND_NOTIFY_SIDMOD__c = 'Y';
        clientTest.CDE_ATTENDING_SCHOOL1__c = 'Y';
       
        insert clientTest;
        
        
        T_SBSD_INDIV_EMPLMT__c testEmployment = new T_SBSD_INDIV_EMPLMT__c();
       // testEmployment.Name = 'TestEmployment';
        testEmployment.ADR_CITY__c = 'City';
        testEmployment.DTE_BEGIN_EFFV__c = date.parse('12/07/2017');
        testEmployment.IDN_CLIENT__c = ClientTest.id;
      //  testEmployment.Name = '123123';
        testEmployment.IND_STUBS_PAY_RCVS__c = 'Y';
        testEmployment.NAM_BUSNS__c = 'Business Name';
        testEmployment.Ignore__c = true;
        
        
        insert testEmployment;
    }
}