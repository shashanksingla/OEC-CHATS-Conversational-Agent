@isTest
private class DeactivateRepaymentPlanBatchTest {
    
    @testSetup
    static void setupTestData() {
        // Create test counties with county codes
        T_COUNTY__c county1 = TestClassUtility.createCounty('County 1', 'County Dept 1', 1, false);
        T_COUNTY__c county2 = TestClassUtility.createCounty('County 2', 'County Dept 2', 2, false);
        insert new List<T_COUNTY__c>{county1, county2};
        
        // Create test providers
		T_CHATS_PROVR_STATUS__c provider1 = TestClassUtility.createProvider(false, 'Test1');
		T_CHATS_PROVR_STATUS__c provider2 = TestClassUtility.createProvider(false, 'Test2');
		T_CHATS_PROVR_STATUS__c provider3 = TestClassUtility.createProvider(false, 'Test3');

        insert new List<T_CHATS_PROVR_STATUS__c>{provider1, provider2, provider3};

        
        // Create adjustments with active recovery status for county1 with provider1 and provider2
        T_ADJMT__c adj1 = TestClassUtility.createAdjustment(false, county1.Id, null, provider1.Id);
        adj1.CDE_TYPE_ADJMT__c = '2';
        adj1.CDE_STATUS_ADJMT__c = '1';
		adj1.DTE_DISCV_ADJMT_ORIG__c = System.today();
		adj1.IDN_PROVR__c = provider1.Id;
        
        T_ADJMT__c adj2 = TestClassUtility.createAdjustment(false, county1.Id, null, provider2.Id);
        adj2.CDE_TYPE_ADJMT__c = '2';
        adj2.CDE_STATUS_ADJMT__c = '1';
		adj2.DTE_DISCV_ADJMT_ORIG__c = System.today();
		adj2.IDN_PROVR__c = provider2.Id;
        
        // Create adjustment for county2 with provider3
        T_ADJMT__c adj3 = TestClassUtility.createAdjustment(false, county2.Id, null, provider3.Id);
        adj3.CDE_TYPE_ADJMT__c = '2';
        adj3.CDE_STATUS_ADJMT__c = '1';
		adj3.DTE_DISCV_ADJMT_ORIG__c = System.today();
		adj3.IDN_PROVR__c = provider3.Id;
        
        insert new List<T_ADJMT__c>{adj1, adj2, adj3};
        
        // Create repayment plans
        List<T_PMT_PLAN__c> repaymentPlans = new List<T_PMT_PLAN__c>();
        
        // Should remain active - provider1 has an adjustment for county1
        repaymentPlans.add(new T_PMT_PLAN__c(
            IDN_PROVR__c = provider1.Id,
            CDE_COUNTY__c = String.valueOf(county1.CDE_COUNTY__c),
            IND_ACTIVE__c = true
        ));
        
        // Should remain active - provider2 has an adjustment for county1
        repaymentPlans.add(new T_PMT_PLAN__c(
            IDN_PROVR__c = provider2.Id,
            CDE_COUNTY__c = String.valueOf(county1.CDE_COUNTY__c),
            IND_ACTIVE__c = true
        ));
        
        // Should be deactivated - provider3 has no adjustment for county1
        repaymentPlans.add(new T_PMT_PLAN__c(
            IDN_PROVR__c = provider3.Id,
            CDE_COUNTY__c = String.valueOf(county1.CDE_COUNTY__c),
            IND_ACTIVE__c = true
        ));
        
        // Should remain active - provider3 has an adjustment for county2
        repaymentPlans.add(new T_PMT_PLAN__c(
            IDN_PROVR__c = provider3.Id,
            CDE_COUNTY__c = String.valueOf(county2.CDE_COUNTY__c),
            IND_ACTIVE__c = true
        ));
        
        // Should be deactivated - provider1 has no adjustment for county2
        repaymentPlans.add(new T_PMT_PLAN__c(
            IDN_PROVR__c = provider1.Id,
            CDE_COUNTY__c = String.valueOf(county2.CDE_COUNTY__c),
            IND_ACTIVE__c = true
        ));
        
        insert repaymentPlans;
    }
    
    @isTest
    static void testBatchDeactivation() {
        // Run the batch
        Test.startTest();
        DeactivateRepaymentPlanBatch batch = new DeactivateRepaymentPlanBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify results
        List<T_PMT_PLAN__c> updatedPlans = [SELECT Id, IDN_PROVR__c, CDE_COUNTY__c, IND_ACTIVE__c FROM T_PMT_PLAN__c];
        
        // Verify we have all 5 plans
        System.assertEquals(5, updatedPlans.size(), 'Should have 5 repayment plans');
        
        // Map plans by provider and county for easy assertion
        Map<String, Boolean> planStatusMap = new Map<String, Boolean>();
        for(T_PMT_PLAN__c plan : updatedPlans) {
            String key = plan.IDN_PROVR__c + '_' + plan.CDE_COUNTY__c;
            planStatusMap.put(key, plan.IND_ACTIVE__c);
        }
        
        // Get provider IDs
        List<T_CHATS_PROVR_STATUS__c> providers = [SELECT Id FROM T_CHATS_PROVR_STATUS__c ORDER BY Name];
        String provider1Id = providers[0].Id;
        String provider2Id = providers[1].Id;
        String provider3Id = providers[2].Id;
        
        // County code values
        String county1Code = '1';
        String county2Code = '2';
    }
    
    @isTest
    static void testBatchWithNoData() {
        // Delete all the repayment plans
        delete [SELECT Id FROM T_PMT_PLAN__c];
        
        // Run the batch with no data
        Test.startTest();
        DeactivateRepaymentPlanBatch batch = new DeactivateRepaymentPlanBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        System.assertEquals(0, [SELECT COUNT() FROM T_PMT_PLAN__c], 'No repayment plans should exist');
    }
}