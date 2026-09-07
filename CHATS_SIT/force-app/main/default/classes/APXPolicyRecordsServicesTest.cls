/*
* 
* Change Log:
* Developer Name                   Date                Description 
* Shubham Khandelwal             5/12/2018         -Changing variable name form conversionObjectMappings to cnvObjMping
*                                                  -Changing variable name form returnedConversionObjectMappings to retCnvObjMping
*/

@isTest
public class APXPolicyRecordsServicesTest {
    
    public static testMethod void testCreatePolicyRecords(){
        Test.startTest();
        APXPolicyRecordsServices.createPolicyRecords(new List<SObject>(), false);
        
        TestClassUtility.createCounty('Denver','Denver',1,true);
        
        T_APPLN_CASE__c appCase = new T_APPLN_CASE__c();
        
        insert appCase;
        
        T_APPLN_PRCS_QUEUE__c appProcessQueue = new T_APPLN_PRCS_QUEUE__c(
            IDN_APPLN__c = appCase.Id,
            CDE_SOURCE__c = 'PK',
            DTE_RCVD_APPLN__c = System.today().addDays(-15),
            CDE_COUNTY__c = '1'
        );
        insert appProcessQueue;
        
        T_APPLN_DSBLTY__c appDisablilty = new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y', IND_YR_DSBL__c  = 'Y');
        T_APPLN_DSBLTY__c appDisablilty2 = new T_APPLN_DSBLTY__c(IND_CC_GIVE_ABLE__c = 'Y', IND_YR_DSBL__c  = 'N');
        
        T_APPLN_INDIV__c appIndivRec = TestClassUtility.createApplicationIndividual(false, System.today().addYears(-25), 'Test','1', 'Individual', '12345678',appProcessQueue.IDN_APPLN__c);
        appIndivRec.IDN_STATE__c = '11223344';
        appIndivRec.CDE_STATUS_MIL__c = '0';
        
        APXPolicyRecordsServices.createPolicyRecords(new List<SObject>{appDisablilty, appDisablilty2}, false);
        APXPolicyRecordsServices.createPolicyRecords(new List<SObject>{appIndivRec}, true);
        
        Test.stopTest();
    }
    public static testMethod void testMethod2(){
        Test.startTest();
        T_APPLN_CHILD_SUP__c appChildSup = new T_APPLN_CHILD_SUP__c(DTE_BIRTH_CUST_NON__c = System.today(),
                                                                    IDN_STATE_CUST_NON__c = '12',
                                                                    IND_CASE_OPEN__c = 'Y',
                                                                    IND_COOP_PARENT__c = 'Y',
                                                                    NAM_FIRST_CUST_NON__c = null,
                                                                    NAM_LAST_CUST_NON__c = 'test',
                                                                    NBR_SSN_CUST_NON__c = '12'
                                                                   );
        APXPolicyRecordsServices.createPolicyRecords(new List<SObject>{appChildSup}, false);
        for(String schoolType:new List<String>{'02'}){
            APXPolicyRecordsServices.createPolicyRecords(new List<SObject>{new T_APPLN_EDUC__c(
                CDE_TYPE_SCHOOL__c = schoolType,
                NAM_SCHOOL__c = 'test'
            )}, false);
        }
        for(String expenseFreq:new List<String>{'02'}){
            system.assertnotEquals(null,APXPolicyRecordsServices.createPolicyRecords(new List<SObject>{new T_APPLN_EMPLMT__c(
                CDE_FREQ_EXP__c = expenseFreq
            )}, false),'Should return list of Application Employment Records');
        }
        
        Test.stopTest();
    }
    public static testMethod void testProcessRulesException(){
        Object message = APXPolicyRecordsIfElseConditions.processRules(null, null);
        System.assertEquals(true, (Boolean)message, 'message should be true');
    }    
    
    public static testmethod void testingEmploymentRule() {
        Test.startTest();
        for(String frequency:new List<String>{'02','03','04','05','06','08','09','10','12','13'}){
            system.assertnotEquals(null,APXPolicyRecordsServices.createPolicyRecords(new List<SObject>{new T_APPLN_EMPLMT__c(
                CDE_FREQ_EXP__c = frequency
            )}, true),'Should return list of Application Employment Records');
        }
        Test.stopTest();
    }
    
    public static testmethod void testingEducationrule() {
        Test.startTest();
        for(String schoolType:new List<String>{'02','03','04','05','06'}){
            system.assertnotEquals(null,APXPolicyRecordsIfElseConditions.processRules(new T_APPLN_EDUC__c(
                CDE_TYPE_SCHOOL__c = schoolType,
                NAM_SCHOOL__c = 'test'
            ), 'T_APPLN_EDUC_CDE_TYPE_SCHOOL_Rule'),'Should return Application Education Record');
        }
        Test.stopTest();
    }
    
    public static testmethod void testingAddressRule() {
        Test.startTest();
        system.assertnotEquals(null,APXPolicyRecordsIfElseConditions.processRules(new T_APPLN_ADR__c(
            ADR_LINE_1__c = 'test',
            ADR_NAM__c = 'test'
        ), 'T_SBSD_CASE_ADR_ADR_LINE_1_Rule'),'Should return list of Application Address Records');
        Test.stopTest();
    }
    
    public static testMethod void testGetTypeCastedValueDECIMAL(){
        Test.startTest();
        System.assertEquals(48.3, APXPolicyRecordsServices.getTypeCastedValue('DECIMAL', '48.3'), 'Decimal Parsing not done proerply');
        System.assertEquals(48.3, APXPolicyRecordsServices.getTypeCastedValue('DOUBLE', '48.3'), 'Double Parsing not done proerply');
        System.assertEquals(48, APXPolicyRecordsServices.getTypeCastedValue('INTEGER', '48'), 'Integer Parsing not done proerply');
        System.assertEquals(true, APXPolicyRecordsServices.getTypeCastedValue('BOOLEAN', 'Y'), 'Boolean Parsing not done proerply');
        System.assertEquals(false, APXPolicyRecordsServices.getTypeCastedValue('BOOLEAN', 'N'), 'Boolean Parsing not done proerply');
        System.assertEquals(null, APXPolicyRecordsServices.getTypeCastedValue('INTEGER', 'AB'), 'Integer Parsing not done proerply');
        Test.stopTest();
        
    }
}