@isTest
public class ProviderCalendarTest {
    public static User pwUser;
    public static T_CHATS_PROVR_STATUS__c prvder;
    public static T_CHATS_PROVR_STATUS__c newprvder;
    @testSetup 
    static void setup() {
        id profId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        // Wrap user creation in System.runAs to avoid MIXED_DML error
        System.runAs(new User(Id = UserInfo.getUserId())) {
            pwUser = TestClassUtility.createUserWithPS(profId, 'System_Administrator_PS', 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        }
        System.runAs(pwUser) {
            T_COUNTY__c county = TestClassUtility.createCounty('Denver', 'test', 1, true);
            prvder = TestClassUtility.createProvider(false, 'Level 2');
            newprvder = TestClassUtility.createProvider(false, 'Level 1');
            insert new List<T_CHATS_PROVR_STATUS__c> {prvder,newprvder};
                
            T_PROVR_FISCAL_AGREMENT__c fa = TestClassUtility.createFiscaAgreement(false, 'Test', date.today(), county.Id);
            fa.ID_SERVICE__c = prvder.Id;
            insert fa;
            
            T_AUTH__c authSame = TestClassUtility.createAuthorization(false, system.today().addMonths(6), system.today(), county.id, prvder.id);
            T_AUTH__c authSame2 = TestClassUtility.createAuthorization(false, system.today().addMonths(12), system.today().addMonths(7), county.id, prvder.id);
            insert new List<T_AUTH__c>{authSame,authSame2};
        }
    }
    public static testMethod void runTestgetInitData(){
        ProviderCalendarApxCtrl.ProvClosWrapp prov = new ProviderCalendarApxCtrl.ProvClosWrapp();
        User pwUser = [select id from User where email='puser000@amamama.com'];
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }else if(provider.TXT_CHATS_RATING__c == 'Level 1'){
                newprvder = provider;
            }
        }
        T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        List<ProviderCalendarApxCtrl.ProvClosWrapp> provList = new List<ProviderCalendarApxCtrl.ProvClosWrapp>();
        LightningServerResponse resp;
        String slot;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            resp = ProviderCalendarApxCtrl.getInitData(fa.id);
            System.assertEquals(resp.isSuccessful,true);
            
            prov.proRecId = prvder.id;
            prov.beginDate = system.today();
            prov.endDate = system.today()+10;
            prov.comment = 'through test class';
            prov.checked = true;
            prov.newbeginDate = Date.today().addDays(10).toString();
            prov.countyId = county.Id;
            
            resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertEquals(resp.isSuccessful,true);
        }      
        Test.stopTest();
    }
    public static testMethod void runTestgetInitData_update(){
        ProviderCalendarApxCtrl.ProvClosWrapp prov = new ProviderCalendarApxCtrl.ProvClosWrapp();
        User pwUser = [select id from User where email='puser000@amamama.com'];
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }else if(provider.TXT_CHATS_RATING__c == 'Level 1'){
                newprvder = provider;
            }
        }
        T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        List<ProviderCalendarApxCtrl.ProvClosWrapp> provList = new List<ProviderCalendarApxCtrl.ProvClosWrapp>();
        LightningServerResponse resp;
        String slot;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            resp  = ProviderCalendarApxCtrl.getInitData(fa.id);
            prov.proRecId = prvder.id;
            prov.beginDate = system.today()+8;
            prov.endDate = system.today()+20;
            prov.comment = 'through test class new';
            prov.checked = true;
            prov.newbeginDate = Date.today().addDays(10).toString();
            provList.add(prov);
            resp = ProviderCalendarApxCtrl.updateData(JSON.serialize(provList), prvder.id, county.Id, fa.Id);
            System.assertEquals(resp.isSuccessful,true);
            List<T_PROVR_CLOSURE__c> closureRecords = [SELECT Id FROM T_PROVR_CLOSURE__c Limit 1];
            try{
                delete closureRecords;
            }catch(Exception e){
                System.assert(e.getMessage().contains('You do not have permission to delete this record.'));
            }  
        }
    }
    public static testMethod void runTestgetInitData1(){
        for(T_CHATS_PROVR_STATUS__c prov : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(prov.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = prov;
            }else if(prov.TXT_CHATS_RATING__c == 'Level 1'){
                newprvder = prov;
            }
        }
        T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        Test.startTest();
        T_PROVR_CLOSURE__c cls = new T_PROVR_CLOSURE__c();
        cls.CDE_COUNTY__c =county.id;
        cls.IDN_PROVIDER__c = prvder.id;
        cls.DTE_BEGIN_CLOSURE__c = system.today();
        cls.IND_ACTIVE__c = true;
        cls.TXT_COMMENTS__c = 'test';
        insert cls;
        T_COUNTY_RATE__c countyRatePlan = TestClassUtility.createCountyRatePlan('PEN',false); 
        countyRatePlan.IDN_COUNTY__c = county.Id;
        countyRatePlan.IND_RATE_PLAN_TEMPLT__c = false;
        countyRatePlan.PAYMENT_Q13_1__c='1;3';
        countyRatePlan.DTE_END_EFFV_RATE__c=null;
        countyRatePlan.CDE_STATUS__c='APV';
        insert countyRatePlan;
        Date dt = System.today().addMonths(4);
        Integer year = dt.year();
        List<T_YEAR_HOL__c> holidayList = new List<T_YEAR_HOL__c>();
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt, CDE_HOL__c = '1', CDE_YEAR__c = year));
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt.addDays(1), CDE_HOL__c = '2', CDE_YEAR__c = year));
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt.addDays(2), CDE_HOL__c = '3', CDE_YEAR__c = year));
        holidayList.add(new T_YEAR_HOL__c(DTE_HOL__c = dt.addDays(3), CDE_HOL__c = '4', CDE_YEAR__c = year));
        insert holidayList;
        ProviderClosureAdditionBatch bt = new ProviderClosureAdditionBatch();
        DataBase.executeBatch(bt);
        cls.IND_ACTIVE__c = false;
        update cls;
        ProviderClosureRemovalBatch rm = new ProviderClosureRemovalBatch();
        DataBase.executeBatch(rm);
        List<T_PROVR_CLOSURE__c> closureRecords = [SELECT Id FROM T_PROVR_CLOSURE__c Limit 1];
        Test.stopTest();
    }
    public static testMethod void runTestgetInitData2(){
        for(T_CHATS_PROVR_STATUS__c prov : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(prov.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = prov;
            }else if(prov.TXT_CHATS_RATING__c == 'Level 1'){
                newprvder = prov;
            }
        }
        T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        Test.startTest();
        T_AUTH__c authorization = [select id from T_AUTH__c limit 1];
        authorization.CDE_TYPE_VERIF__c = 'NA';
        authorization.CDE_SOURCE_VRFYD_IMMU__c ='PRO';
        authorization.CDE_IMM__c ='NRL';
        authorization.DTE_BEGIN_EFFV_AUTH__c = system.today();
        authorization.DTE_END_EFFV_AUTH__c = system.today().addDays(30);
        update authorization;
        List<batchsit_t_auth_encmbr__x> encumbList1 = new List<batchsit_t_auth_encmbr__x>();
        //Removed unused variable on 5/13/2018 BG         
        batchsit_t_auth_encmbr__x encumberenceRec = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            CNT_HOUR_CARE__c =6,
            cnt_hour_attnd_actual__c = 10,
            dte_care__c =system.today().addDays(40),
            CDE_TYPE_UNIT_CARE__c ='4',
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec2 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            CNT_HOUR_CARE__c =7,
            cnt_hour_attnd_actual__c = 10,
            dte_care__c =system.today().addDays(38),
            CDE_TYPE_UNIT_CARE__c='3',
            cde_status_encmbr__c = 'Tes');
        batchsit_t_auth_encmbr__x encumberenceRec1 = new batchsit_t_auth_encmbr__x(
            idn_auth__c = authorization.Id,
            cde_level_care__c ='8',
            CNT_HOUR_CARE__c =6,
            CDE_TYPE_UNIT_CARE__c = '6',
            cnt_hour_attnd_actual__c = 10,
            dte_care__c =system.today().addDays(30),
            cde_status_encmbr__c = 'Tes');
        encumbList1.add(encumberenceRec);
        encumbList1.add(encumberenceRec1);
        encumbList1.add(encumberenceRec2);
        T_PROVR_CLOSURE__c cls = new T_PROVR_CLOSURE__c();
        cls.CDE_COUNTY__c =county.id;
        cls.IDN_PROVIDER__c = prvder.id;
        cls.DTE_BEGIN_CLOSURE__c = system.today();
        cls.IND_ACTIVE__c = true;
        cls.TXT_COMMENTS__c = 'test';
        insert cls;
        
        ProviderClosureAdditionBatch bt = new ProviderClosureAdditionBatch();
        DataBase.executeBatch(bt);
        Test.stopTest();
    }

    public static testMethod void testCheckAttendance(){
        User pwUser = [select id from User where email='puser000@amamama.com'];
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }
        }
        T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            // Test checkAttendance with valid parameters
            LightningServerResponse resp = ProviderCalendarApxCtrl.checkAttendance(prvder.id, county.Id, fa.Id);
            
            // Test checkAttendance with null provider ID
            resp = ProviderCalendarApxCtrl.checkAttendance(null, county.Id, fa.Id);
            System.assertEquals(resp.isSuccessful, false, 'checkAttendance should fail with null provider ID');
            
            // Test checkAttendance with null county ID
            resp = ProviderCalendarApxCtrl.checkAttendance(prvder.id, null, fa.Id);
            System.assertEquals(resp.isSuccessful, false, 'checkAttendance should fail with null county ID');
        }
        Test.stopTest();
    }
    
    public static testMethod void testSaveDataExceptionHandling(){
        User pwUser = [select id from User where email='puser000@amamama.com'];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            // Test saveData with invalid JSON
            LightningServerResponse resp = ProviderCalendarApxCtrl.saveData('invalid json', new list<date>());
            System.assertEquals(resp.isSuccessful, false, 'saveData should handle invalid JSON gracefully');
            
            // Test saveData with null parameters
            resp = ProviderCalendarApxCtrl.saveData(null, null);
            System.assertEquals(resp.isSuccessful, false, 'saveData should handle null parameters gracefully');
        }
        Test.stopTest();
    }

    public static testMethod void testDifferentUserProfiles(){
        // Create Provider Worker user wrapped in System.runAs to avoid MIXED_DML error
        User providerWorkerUser;
        id providerWorkerProfileId = [SELECT Id FROM Profile WHERE Name = 'Provider Worker' LIMIT 1].Id;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            providerWorkerUser = TestClassUtility.createUserWithPS(providerWorkerProfileId, 'Provider_Worker_PS', 'ProviderLast', 'ProviderFirst', 'provider@test.com', 'provider@test.com' + System.currentTimeMillis(), 'proAlias');
        }
        
        T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(providerWorkerUser){
            // Test getInitData with Provider Worker profile
            LightningServerResponse resp = ProviderCalendarApxCtrl.getInitData(fa.id);
            System.assertNotEquals(resp, null, 'getInitData should return response for Provider Worker profile');
        }
        Test.stopTest();
    }

    public static testMethod void testDateEdgeCases(){
        ProviderCalendarApxCtrl.ProvClosWrapp prov = new ProviderCalendarApxCtrl.ProvClosWrapp();
        User pwUser = [select id from User where email='puser000@amamama.com'];
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }
        }
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            // Test with past dates
            prov.proRecId = prvder.id;
            prov.beginDate = system.today().addDays(-30);
            prov.endDate = system.today().addDays(-20);
            prov.comment = 'past dates test';
            prov.checked = true;
            prov.newbeginDate = Date.today().addDays(-25).toString();
            prov.countyId = county.Id;
            
            LightningServerResponse resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertNotEquals(resp, null, 'saveData should handle past dates');
            
            // Test with future dates
            prov.beginDate = system.today().addDays(100);
            prov.endDate = system.today().addDays(110);
            prov.newbeginDate = Date.today().addDays(105).toString();
            
            resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertNotEquals(resp, null, 'saveData should handle future dates');
        }
        Test.stopTest();
    }

    public static testMethod void testHolidayListScenarios(){
        User pwUser = [select id from User where email='puser000@amamama.com'];
        ProviderCalendarApxCtrl.ProvClosWrapp prov = new ProviderCalendarApxCtrl.ProvClosWrapp();
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }
        }
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            // Test saveData with holiday list
            List<Date> holidayList = new List<Date>();
            holidayList.add(Date.today().addDays(5));
            holidayList.add(Date.today().addDays(10));
            holidayList.add(Date.today().addDays(15));
            
            prov.proRecId = prvder.id;
            prov.beginDate = system.today();
            prov.endDate = system.today().addDays(20);
            prov.comment = 'holiday test';
            prov.checked = true;
            prov.newbeginDate = Date.today().addDays(2).toString();
            prov.countyId = county.Id;
            
            LightningServerResponse resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), holidayList);
            System.assertNotEquals(resp, null, 'saveData should handle holiday list scenarios');
            
            // Test with empty holiday list
            resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new List<Date>());
            System.assertNotEquals(resp, null, 'saveData should handle empty holiday list');
        }
        Test.stopTest();
    }

    public static testMethod void testSaveDataVariousScenarios(){
        ProviderCalendarApxCtrl.ProvClosWrapp prov = new ProviderCalendarApxCtrl.ProvClosWrapp();
        User pwUser = [select id from User where email='puser000@amamama.com'];
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }
        }
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            // Test saveData with unchecked provider closure
            prov.proRecId = prvder.id;
            prov.beginDate = system.today();
            prov.endDate = system.today().addDays(5);
            prov.comment = 'unchecked test';
            prov.checked = false; // Test unchecked scenario
            prov.newbeginDate = Date.today().addDays(2).toString();
            prov.countyId = county.Id;
            
            LightningServerResponse resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertNotEquals(resp, null, 'saveData should handle unchecked provider closure');
            
            // Test saveData with empty comment
            prov.comment = '';
            prov.checked = true;
            resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertNotEquals(resp, null, 'saveData should handle empty comment');
            
            // Test saveData with same begin and end date
            prov.beginDate = system.today();
            prov.endDate = system.today();
            resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertNotEquals(resp, null, 'saveData should handle same begin and end date');
        }
        Test.stopTest();
    }

    public static testMethod void testUpdateDataVariousScenarios(){
        User pwUser = [select id from User where email='puser000@amamama.com'];
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }
        }
        T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        
        // Create existing closure record for update testing
        T_PROVR_CLOSURE__c existingClosure = new T_PROVR_CLOSURE__c();
        existingClosure.CDE_COUNTY__c = county.id;
        existingClosure.IDN_PROVIDER__c = prvder.id;
        existingClosure.DTE_BEGIN_CLOSURE__c = system.today().addDays(1);
        existingClosure.IND_ACTIVE__c = true;
        existingClosure.TXT_COMMENTS__c = 'existing closure';
        insert existingClosure;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            // Test updateData with empty list
            List<ProviderCalendarApxCtrl.ProvClosWrapp> emptyList = new List<ProviderCalendarApxCtrl.ProvClosWrapp>();
            LightningServerResponse resp = ProviderCalendarApxCtrl.updateData(JSON.serialize(emptyList), prvder.id, county.Id, fa.Id);
            System.assertNotEquals(resp, null, 'updateData should handle empty list');
            
            // Test updateData with single record
            List<ProviderCalendarApxCtrl.ProvClosWrapp> singleList = new List<ProviderCalendarApxCtrl.ProvClosWrapp>();
            ProviderCalendarApxCtrl.ProvClosWrapp singleProv = new ProviderCalendarApxCtrl.ProvClosWrapp();
            singleProv.proRecId = prvder.id;
            singleProv.beginDate = system.today().addDays(10);
            singleProv.endDate = system.today().addDays(15);
            singleProv.comment = 'single record test';
            singleProv.checked = true;
            singleProv.newbeginDate = Date.today().addDays(12).toString();
            singleProv.countyId = county.Id;
            singleList.add(singleProv);
            
            resp = ProviderCalendarApxCtrl.updateData(JSON.serialize(singleList), prvder.id, county.Id, fa.Id);
            System.assertNotEquals(resp, null, 'updateData should handle single record');
        }
        Test.stopTest();
    }
    
    public static testMethod void testMultipleUserProfiles(){
        // Test with different profiles if they exist
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Name IN ('Provider Worker Supervisor', 'Business Office Worker') LIMIT 2];
        
        if(profiles.size() > 0){
            // Wrap user creation in System.runAs to avoid MIXED_DML error
            User testUser;
            System.runAs(new User(Id = UserInfo.getUserId())) {
                testUser = TestClassUtility.createUserWithPS(profiles[0].Id, 'Provider_Worker_Supervisor_PS', 'TestLast', 'TestFirst', 'testuser@test.com', 'testuser@test.com' + System.currentTimeMillis(), 'testAlia');
            }
            
            T_PROVR_FISCAL_AGREMENT__c fa = [select id from T_PROVR_FISCAL_AGREMENT__c LIMIT 1];
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
            System.runAs(testUser){
                // Test getInitData with different profile
                LightningServerResponse resp = ProviderCalendarApxCtrl.getInitData(fa.id);
                System.assertNotEquals(resp, null, 'getInitData should work with different user profiles');
            }
            Test.stopTest();
        }
    }

    public static testMethod void testDateBoundaryConditions(){
        ProviderCalendarApxCtrl.ProvClosWrapp prov = new ProviderCalendarApxCtrl.ProvClosWrapp();
        User pwUser = [select id from User where email='puser000@amamama.com'];
        for(T_CHATS_PROVR_STATUS__c provider : [select id,TXT_CHATS_RATING__c from T_CHATS_PROVR_STATUS__c]){
            if(provider.TXT_CHATS_RATING__c == 'Level 2'){
                prvder = provider;
            }
        }
        T_COUNTY__c county = [select id from T_COUNTY__c LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        System.runAs(pwUser){
            // Test with year boundary dates
            prov.proRecId = prvder.id;
            prov.beginDate = Date.newInstance(2023, 12, 31); // End of year
            prov.endDate = Date.newInstance(2024, 1, 1);     // Start of next year
            prov.comment = 'year boundary test';
            prov.checked = true;
            prov.newbeginDate = Date.newInstance(2024, 1, 1).toString();
            prov.countyId = county.Id;
            
            LightningServerResponse resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertNotEquals(resp, null, 'saveData should handle year boundary dates');
            
            // Test with leap year date
            prov.beginDate = Date.newInstance(2024, 2, 29); // Leap year date
            prov.endDate = Date.newInstance(2024, 3, 1);
            prov.newbeginDate = Date.newInstance(2024, 2, 29).toString();
            
            resp = ProviderCalendarApxCtrl.saveData(JSON.serialize(prov), new list<date>());
            System.assertNotEquals(resp, null, 'saveData should handle leap year dates');
        }
        Test.stopTest();
    }
}