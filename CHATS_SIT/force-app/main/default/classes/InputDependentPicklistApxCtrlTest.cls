/*************************************************************************************************************
** User Story: 
**************************************************************************************************************
** Name             : InputDependentPicklistApxCtrlTest
** Description      : Test class for InputDependentPicklistApxCtrl Apex Class
** Version          : 1.0
**------------------------------------------------------------------------------------------------------------
** Modification Log:
************************************************************************************/ 
@isTest
public class InputDependentPicklistApxCtrlTest {
  /********************************************************
METHOD NAME    : getDependentOptionsImplTest
DESCRIPTION    : Test method for positive scenario of getDependentOptionsImpl()
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/  
    public static testMethod void getDependentOptionsImplTest(){
        Map<String,List<String>> objResults;
        Test.startTest();
        objResults = InputDependentPicklistApxCtrl.getDependentOptionsImpl('T_SBSD_INDIV_INFO__c','CDE_TYPE_INFO_INDIV__c','CDE_VALUE_INFO_INDIV__c');
        Test.stopTest();
        System.assertEquals(true, !objResults.isEmpty() && objResults.size()>0, 'objResults should not be null');
    }
    
/********************************************************
METHOD NAME    : getDependentOpsNegativeTest
DESCRIPTION    : Test method for negative scenario of getDependentOptionsImpl()
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/ 
    public static testMethod void getDependentOpsNegativeTest(){
        Map<String,List<String>> objResults;
        Test.startTest();
        objResults = InputDependentPicklistApxCtrl.getDependentOptionsImpl('','','');
        Test.stopTest();
        System.assertEquals(true, objResults == null, 'objResults should be null');
    }
    
/********************************************************
METHOD NAME    : testWrapperClass
DESCRIPTION    : Test method for APXPicklistEntryWrapper() in APXPicklistEntryWrapper Apex Class
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/
    public static testMethod void testWrapper(){
        List<APXPicklistEntryWrapper> lstPEWrapper = new List<APXPicklistEntryWrapper>(); 
        Schema.DescribeFieldResult fieldResult = T_SBSD_INDIV_INFO__c.CDE_VALUE_INFO_INDIV__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        APXPicklistEntryWrapper objDepPLE = new APXPicklistEntryWrapper();
        String pEntryStructure;
        for( Schema.PicklistEntry f : ple)
        {
            pEntryStructure = JSON.serialize(f);
            objDepPLE = (APXPicklistEntryWrapper)JSON.deserialize(pEntryStructure, APXPicklistEntryWrapper.class);
            objDepPLE.active = '';
            objDepPLE.defaultValue = '';
            objDepPLE.value = '';
            lstPEWrapper.add(objDepPLE);
        }   
        System.assertEquals(true, lstPEWrapper.size()>0, 'size of lstPEWrapper should be greater than 0');
    }
}