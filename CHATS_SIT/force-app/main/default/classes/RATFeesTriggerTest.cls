@isTest
public class RATFeesTriggerTest {
    public static testMethod void testRATFeesTrigger() {
        //Removed unused variable on 5/14/2018 BG  
        test.startTest();
        T_COUNTY__c countyObj = new T_COUNTY__c(CNTY_DEPT_NAME__c = 'Arapahoe County', CDE_COUNTY__c = 3);
        insert countyObj;

        //T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_CHATS_PROVR_STATUS__c providerObj = new T_CHATS_PROVR_STATUS__c ( NAM_FACILITY__c = 'Provider Test');
        insert providerObj;

        T_PROVR_FISCAL_AGREMENT__c fiscAgreement = new T_PROVR_FISCAL_AGREMENT__c ( DTE_BEGIN_AGRMT__c=date.today(), CDE_TYPE_STATUS__c = 'DFT', 
                                                                                   	ID_SERVICE__c = providerObj.Id, CDE_COUNTY__c = countyObj.Id
        																			);
        insert fiscAgreement;

        T_FISCAL_SCH__c rateSchedule = TestClassUtility.createRateSchedule(true,date.today(),date.today() + 1,fiscAgreement.Id,'1');
        T_FISCAL_RAT_FEES__c RAtFees = new T_FISCAL_RAT_FEES__c( IDN_FISCAL_SCH__c = rateSchedule.Id);
        insert RAtFees;
        
        system.assertEquals(rateSchedule.Id,[Select IDN_FISCAL_SCH__c from T_FISCAL_RAT_FEES__c where Id=:RAtFees.Id].IDN_FISCAL_SCH__c,'Should have samw Rate schedule');
        test.stopTest();
        /*
        test.startTest();
        insert RAtFees;

        ratFees1.Id = RAtFees.Id;
        ratFees1.CDE_REG_FREQ__c = 'MTH';
        update ratFees1;
        test.stopTest();
		*/
    }
}