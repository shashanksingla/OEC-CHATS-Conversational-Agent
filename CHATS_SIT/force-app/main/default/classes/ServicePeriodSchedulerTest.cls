@isTest
private class ServicePeriodSchedulerTest {
    
    @TestSetup
    static void setup() {
        // Create Service Period Configuration
        Service_Period_Config__c config = new Service_Period_Config__c(
            Service_Period_Frequency__c = '2',
            Payment_Release_Day__c = '3', // Wednesday
            Payment_Calculation_Day__c = '2'
        );
        insert config;
        
        // Create an existing service period for testing continuation logic
        T_SERV_PERIOD__c existingPeriod = new T_SERV_PERIOD__c(
            Name = '795',
            DTE_BEGIN_EFFV__c = Date.newInstance(2023, 10, 28),
            DTE_END_EFFV__c = Date.newInstance(2023, 11, 3),
            IDN_EXTNL__c = '795'
        );
        insert existingPeriod;
    }
    
    @isTest
    static void testExecuteWithExistingPeriod() {
        Test.startTest();
        
        ServicePeriodScheduler scheduler = new ServicePeriodScheduler();
        scheduler.execute(null);
        
        Test.stopTest();
        
        // Verify service periods were created
        List<T_SERV_PERIOD__c> createdPeriods = [
            SELECT Id, Name, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, 
            Payment_Calculations_Date__c, Service_Period_Id__c,
            DTE_BATCH_PRCS_PMT__c, DTE_BATCH_FILE_PMT__c
            FROM T_SERV_PERIOD__c 
            WHERE Name != '795'
            ORDER BY DTE_BEGIN_EFFV__c
            LIMIT 10
        ];
        
        System.assert(!createdPeriods.isEmpty(), 'Service periods should be created');
        
        // Verify first period starts after existing period
        T_SERV_PERIOD__c firstPeriod = createdPeriods[0];
        System.assertEquals('796', firstPeriod.Name, 'First new period should have name 796');
        System.assertEquals(Date.newInstance(2023, 11, 4), firstPeriod.DTE_BEGIN_EFFV__c, 'Begin date should be day after existing period end');
        System.assertEquals(Date.newInstance(2023, 11, 10), firstPeriod.DTE_END_EFFV__c, 'End date should be 6 days after begin date');
    }
}