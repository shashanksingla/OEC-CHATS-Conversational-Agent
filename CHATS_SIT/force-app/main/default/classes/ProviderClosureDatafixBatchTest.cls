@isTest
private class ProviderClosureDatafixBatchTest {
    private static final String OPEN_RECORD_TYPE = 'Open';
    
    /**
     * @description Sets up test data for provider closure data fix tests
     */
    @testSetup
    static void setupTestData() {
        // Create counties
        List<T_COUNTY__c> counties = new List<T_COUNTY__c>();
        for(Integer i = 1; i <= 3; i++) {
            counties.add(TestClassUtility.createCounty('Test County ' + i, 'Test Department ' + i, i, false));
        }
        insert counties;
        
        // Create providers
        List<T_CHATS_PROVR_STATUS__c> providers = new List<T_CHATS_PROVR_STATUS__c>();
        for(Integer i = 1; i <= 3; i++) {
            providers.add(TestClassUtility.createProvider(false, 'High'));
        }
        insert providers;
        
        // Create provider fiscal agreements - for different counties
        Date beginDate = Date.newInstance(2022, 01, 01);
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get(OPEN_RECORD_TYPE).getRecordTypeId();
        
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreements = new List<T_PROVR_FISCAL_AGREMENT__c>();
        
        // Provider 1 with multiple counties
        T_PROVR_FISCAL_AGREMENT__c fa1 = TestClassUtility.createFiscaAgreement(false, 'FA1', beginDate, String.valueOf(counties[0].Id));
        fa1.ID_SERVICE__c = providers[0].Id;
        fa1.RecordTypeId = openRecordTypeId;
        fa1.CDE_TYPE_STATUS__c = 'OPN';
        fiscalAgreements.add(fa1);
        
        T_PROVR_FISCAL_AGREMENT__c fa2 = TestClassUtility.createFiscaAgreement(false, 'FA2', beginDate, String.valueOf(counties[1].Id));
        fa2.ID_SERVICE__c = providers[0].Id;
        fa2.RecordTypeId = openRecordTypeId;
        fa2.CDE_TYPE_STATUS__c = 'OPN';
        fiscalAgreements.add(fa2);
        
        // Provider 2 with one county
        T_PROVR_FISCAL_AGREMENT__c fa3 = TestClassUtility.createFiscaAgreement(false, 'FA3', beginDate, String.valueOf(counties[2].Id));
        fa3.ID_SERVICE__c = providers[1].Id;
        fa3.RecordTypeId = openRecordTypeId;
        fa3.CDE_TYPE_STATUS__c = 'OPN';
        fiscalAgreements.add(fa3);
        
        // Provider 3 with no fiscal agreements to test null case
        insert fiscalAgreements;
        
        // Create provider closures with null counties (to be fixed by batch)
        List<T_PROVR_CLOSURE__c> closures = new List<T_PROVR_CLOSURE__c>();
        
        // Create closures that match the batch query criteria
        Date closureDate = Date.newInstance(2022, 09, 20); // Before filter date
        
        // Provider 1 - should get updated and have a clone created (multiple counties)
        closures.add(createProviderClosure(providers[0].Id, null, closureDate, true));
        
        // Provider 2 - should get updated with one county
        closures.add(createProviderClosure(providers[1].Id, null, closureDate, true));
        
        // Provider 3 - should remain unchanged (no fiscal agreements)
        closures.add(createProviderClosure(providers[2].Id, null, closureDate, true));
        
        insert closures;
    }
    
    /**
     * @description Helper method to create provider closure
     */
    private static T_PROVR_CLOSURE__c createProviderClosure(Id providerId, String countyId, Date beginDate, Boolean isActive) {
        T_PROVR_CLOSURE__c closure = new T_PROVR_CLOSURE__c(
            IDN_PROVIDER__c = providerId,
            CDE_COUNTY__c = countyId,
            DTE_BEGIN_CLOSURE__c = beginDate,
            IND_ACTIVE__c = isActive,
            TXT_COMMENTS__c = 'Test Comments'
        );
        return closure;
    }
    
    /**
     * @description Tests successful execution of batch with multiple counties
     */
    @isTest
    static void testBatchWithMultipleCounties() {
        // Find provider with multiple counties
        Map<Id, List<T_PROVR_FISCAL_AGREMENT__c>> providerAgreementMap = new Map<Id, List<T_PROVR_FISCAL_AGREMENT__c>>();
        
        for(T_PROVR_FISCAL_AGREMENT__c agreement : [SELECT ID_SERVICE__c, CDE_COUNTY__c FROM T_PROVR_FISCAL_AGREMENT__c]) {
            if(!providerAgreementMap.containsKey(agreement.ID_SERVICE__c)) {
                providerAgreementMap.put(agreement.ID_SERVICE__c, new List<T_PROVR_FISCAL_AGREMENT__c>());
            }
            providerAgreementMap.get(agreement.ID_SERVICE__c).add(agreement);
        }
        
        // Find a provider with multiple counties
        Id multiCountyProviderId;
        for(Id providerId : providerAgreementMap.keySet()) {
            if(providerAgreementMap.get(providerId).size() > 1) {
                multiCountyProviderId = providerId;
                break;
            }
        }
        
        // Get the provider with multiple counties
        T_CHATS_PROVR_STATUS__c provider = [
            SELECT Id FROM T_CHATS_PROVR_STATUS__c 
            WHERE Id = :multiCountyProviderId
            LIMIT 1
        ];
        
        // Count initial closures
        Integer initialCount = [SELECT COUNT() FROM T_PROVR_CLOSURE__c WHERE IDN_PROVIDER__c = :provider.Id];
        
        // Execute batch
        Test.startTest();
        ProviderClosureDatafixBatch batch = new ProviderClosureDatafixBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify results
        List<T_PROVR_CLOSURE__c> updatedClosures = [
            SELECT Id, CDE_COUNTY__c 
            FROM T_PROVR_CLOSURE__c 
            WHERE IDN_PROVIDER__c = :provider.Id
        ];
    }
    
    /**
     * @description Tests batch with provider having single county
     */
    @isTest
    static void testBatchWithSingleCounty() {
        // Find provider with single county
        Map<Id, List<T_PROVR_FISCAL_AGREMENT__c>> providerAgreementMap = new Map<Id, List<T_PROVR_FISCAL_AGREMENT__c>>();
        
        for(T_PROVR_FISCAL_AGREMENT__c agreement : [SELECT ID_SERVICE__c, CDE_COUNTY__c FROM T_PROVR_FISCAL_AGREMENT__c]) {
            if(!providerAgreementMap.containsKey(agreement.ID_SERVICE__c)) {
                providerAgreementMap.put(agreement.ID_SERVICE__c, new List<T_PROVR_FISCAL_AGREMENT__c>());
            }
            providerAgreementMap.get(agreement.ID_SERVICE__c).add(agreement);
        }
        
        // Find a provider with single county
        Id singleCountyProviderId;
        for(Id providerId : providerAgreementMap.keySet()) {
            if(providerAgreementMap.get(providerId).size() == 1) {
                singleCountyProviderId = providerId;
                break;
            }
        }
        
        // Get the provider with single county
        T_CHATS_PROVR_STATUS__c provider = [
            SELECT Id FROM T_CHATS_PROVR_STATUS__c 
            WHERE Id = :singleCountyProviderId
            LIMIT 1
        ];
        
        // Count initial closures
        Integer initialCount = [SELECT COUNT() FROM T_PROVR_CLOSURE__c WHERE IDN_PROVIDER__c = :provider.Id];
        
        // Execute batch
        Test.startTest();
        ProviderClosureDatafixBatch batch = new ProviderClosureDatafixBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify results
        List<T_PROVR_CLOSURE__c> updatedClosures = [
            SELECT Id, CDE_COUNTY__c 
            FROM T_PROVR_CLOSURE__c 
            WHERE IDN_PROVIDER__c = :provider.Id
        ];
        
        // Should have same number of closures (no clones for single county)
        System.assertEquals(initialCount, updatedClosures.size(), 
                          'Expected same number of closure records for single county');
        
    }
    
    /**
     * @description Tests batch with provider having no fiscal agreements
     */
    @isTest
    static void testBatchWithNoFiscalAgreements() {
        // Get provider with no fiscal agreements
        T_CHATS_PROVR_STATUS__c provider = [
            SELECT Id FROM T_CHATS_PROVR_STATUS__c 
            WHERE Id NOT IN (SELECT ID_SERVICE__c FROM T_PROVR_FISCAL_AGREMENT__c)
            LIMIT 1
        ];
        
        // Get initial closure
        T_PROVR_CLOSURE__c initialClosure = [
            SELECT Id, CDE_COUNTY__c FROM T_PROVR_CLOSURE__c 
            WHERE IDN_PROVIDER__c = :provider.Id
            LIMIT 1
        ];
        System.assertEquals(null, initialClosure.CDE_COUNTY__c, 'Initial county should be null');
        
        // Execute batch
        Test.startTest();
        ProviderClosureDatafixBatch batch = new ProviderClosureDatafixBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify closure remains unchanged
        T_PROVR_CLOSURE__c updatedClosure = [
            SELECT Id, CDE_COUNTY__c FROM T_PROVR_CLOSURE__c 
            WHERE Id = :initialClosure.Id
        ];
        System.assertEquals(null, updatedClosure.CDE_COUNTY__c, 
                          'Provider without fiscal agreements should still have null county');
    }
    
    /**
     * @description Tests batch exception handling
     */
    @isTest
    static void testBatchWithException() {
        T_PROVR_CLOSURE__c invalidClosure = new T_PROVR_CLOSURE__c(
            IND_ACTIVE__c = true
        );
        insert invalidClosure;
        
        // Execute batch
        Test.startTest();
        ProviderClosureDatafixBatch batch = new ProviderClosureDatafixBatch();
        
        Database.executeBatch(batch);
        Test.stopTest();
    }
/**
 * @description Tests the execute method directly with data matching query criteria
 */
@isTest
static void testExecuteMethodCoverage() {
    
    // Create counties
    List<T_COUNTY__c> counties = new List<T_COUNTY__c>();
    for(Integer i = 1; i <= 3; i++) {
        counties.add(TestClassUtility.createCounty('Test County ' + i, 'Test Department ' + i, i, false));
    }
    insert counties;
    
    // Create providers
    List<T_CHATS_PROVR_STATUS__c> providers = new List<T_CHATS_PROVR_STATUS__c>();
    for(Integer i = 1; i <= 3; i++) {
        providers.add(TestClassUtility.createProvider(false, 'High'));
    }
    insert providers;
    
    Date fiscalBeginDate = Date.newInstance(2022, 01, 01);
    Date fiscalEndDate = Date.newInstance(2023, 01, 01);
    Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get(OPEN_RECORD_TYPE).getRecordTypeId();
    
    List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreements = new List<T_PROVR_FISCAL_AGREMENT__c>();
    
    // Provider 1 with multiple counties
    T_PROVR_FISCAL_AGREMENT__c fa1 = TestClassUtility.createFiscaAgreement(false, 'FA1', fiscalBeginDate, String.valueOf(counties[0].Id));
    fa1.ID_SERVICE__c = providers[0].Id;
    fa1.RecordTypeId = openRecordTypeId;
    fa1.CDE_TYPE_STATUS__c = 'OPN';
    fa1.DTE_END_AGRMT__c = fiscalEndDate;
    fiscalAgreements.add(fa1);
    
    T_PROVR_FISCAL_AGREMENT__c fa2 = TestClassUtility.createFiscaAgreement(false, 'FA2', fiscalBeginDate, String.valueOf(counties[1].Id));
    fa2.ID_SERVICE__c = providers[0].Id;
    fa2.RecordTypeId = openRecordTypeId;
    fa2.CDE_TYPE_STATUS__c = 'OPN';
    fa2.DTE_END_AGRMT__c = fiscalEndDate;
    fiscalAgreements.add(fa2);
    
    // Provider 2 with one county
    T_PROVR_FISCAL_AGREMENT__c fa3 = TestClassUtility.createFiscaAgreement(false, 'FA3', fiscalBeginDate, String.valueOf(counties[2].Id));
    fa3.ID_SERVICE__c = providers[1].Id;
    fa3.RecordTypeId = openRecordTypeId;
    fa3.CDE_TYPE_STATUS__c = 'OPN';
    fa3.DTE_END_AGRMT__c = fiscalEndDate;
    fiscalAgreements.add(fa3);
    
    insert fiscalAgreements;
  
    Date closureDate = Date.newInstance(2022, 09, 20);
    
    List<T_PROVR_CLOSURE__c> closures = new List<T_PROVR_CLOSURE__c>();
    
    T_PROVR_CLOSURE__c closure1 = createProviderClosure(providers[0].Id, null, closureDate, true);
    T_PROVR_CLOSURE__c closure2 = createProviderClosure(providers[1].Id, null, closureDate, true);
    T_PROVR_CLOSURE__c closure3 = createProviderClosure(providers[2].Id, null, closureDate, true);
    
    closures.add(closure1);
    closures.add(closure2);
    closures.add(closure3);
    Test.startTest();
    // Create the batch
    ProviderClosureDatafixBatch batch = new ProviderClosureDatafixBatch();
    for(T_PROVR_CLOSURE__c closure : closures) {
        batch.providerId.add(closure.IDN_PROVIDER__c);
    }
    batch.execute(null, closures);
    
    Test.stopTest();
}
}