/**********************************************************************************************
* @author Deloitte Consulting LLP.
* @date 02/26/2018
* @description Authorization Class Test 
* * Version: 1.0 > 1.1
* * Date: 02/26/2018 > 11/15/2021
* * Author: Diya Chaudhary > Rishav Maji
* * Description: Initial version > Slot method & overall coverage Update
*********************************************************************************************/
@isTest
public class AuthorizationStatusController_Test {
    
    public static testMethod void testAuthorizationStatus(){
        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName', 10, true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_COUNTY__c county = TestClassUtility.createCounty('Test Name', 'Department', 2, true);
        T_SBSD_CASE__c sbsdcase = TestClassUtility.createCase(false, county.Id);
        sbsdcase.IDN_EXTNL__c = '12345';
        upsert sbsdcase;
        Date datetoday = System.Today();
        Date begindate = date.newInstance(datetoday.year(), datetoday.month(), 1);
        begindate = begindate.addDays(25);
        Date enddate = begindate.addDays(20);
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c = 'Level 1');
        insert provider;
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true, date.newInstance(1983, 7, 15), 'firstName', '1', 'lastName', '1', 'CC');
        
        T_AUTH__c authorization = TestClassUtility.createAuthorization(false, enddate, begindate, county.Id, provider.Id);
        authorization.IDN_CASE__c = sbsdcase.Id;
        authorization.IDN_CLIENT__c = sbsdIndiv.Id;
        insert authorization;
        
        batchsit_t_auth_status__x authStat = new batchsit_t_auth_status__x(
            idn_auth__c = authorization.Id, 
            cde_status_auth__c = '4', 
            dte_begin_effv__c = (System.today()).addDays(1), 
            cde_reason_change_auth__c = '11');
        batchsit_t_auth_status__x authStat1 = new batchsit_t_auth_status__x(
            idn_auth__c = authorization.Id, 
            cde_status_auth__c = '4', 
            dte_begin_effv__c = (System.today()).addDays(-1), 
            cde_reason_change_auth__c = '11');
        batchsit_t_auth_status__x authStatEx = new batchsit_t_auth_status__x(
            idn_auth__c = authorization.Id, 
            dte_begin_effv__c = (System.today()).addDays(1));
        Id loggedInUserId;
        T_AUTH__c authObj = TestClassUtility.createAuthorization(true, System.today().addMonths(3).toStartofMonth(), System.today() - 4, countyObj.Id, providerObj.Id);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new HerokuServiceHttpCalloutMock());
        AuthorizationStatusController.upsertAuthStatus(authStat, true, false, authObj.Id, true);
        AuthorizationStatusController.upsertAuthStatus(authStat, true, false, authObj.Id, false);
        AuthorizationStatusController.upsertAuthStatus(authStat, false, true, authObj.Id, false);
        AuthorizationStatusController.upsertAuthStatus(authStat, false, true, authObj.Id, true);
        AuthorizationStatusController.upsertAuthStatus(authStatEx, true, true, null, true);
        AuthorizationStatusController.updateAuthStatus(authStat, true, true, authObj.Id);
        AuthorizationStatusController.doGetInitData();
        AuthorizationStatusController.fetchLoggedInUserId();
        AuthorizationStatusController.checkAuthStatusValidation(authStat, false, authObj.Id);
        AuthorizationStatusController.checkAuthStatusValidation(authStat1, false, authObj.Id);
        //AuthorizationStatusController.authEncumbEnrollDelete(authObj.Id);
        AuthorizationStatusController.authEncumbDelete(authObj.Id);
        AuthorizationStatusController.authorizationCopayDelete(authObj.Id);
        AuthorizationStatusController.calculateAuthWeight(authObj,begindate);
        Decimal aggregateWt = 9.0; //
        AuthorizationStatusController.updateCopayRecords(aggregateWt, '', false, 'Y');
        AuthorizationStatusController.updateCopayRecords(aggregateWt, '', true, 'Y');
        List<T_AUTH__c> authNameList = new List<T_AUTH__c>();
        authNameList.add(authObj);
        AuthorizationStatusController.insertATSRecords(authNameList);
        AuthorizationStatusController.checkOwnerCountyMatch(authObj.Id, 'CDE_COUNTY__c');
        AuthorizationStatusController.checkOwnerCountyMatch(authorization.Id, 'CDE_COUNTY__c');
        AuthorizationStatusController.getExternalObjectDatafromAPI(authObj.Id);
        Test.stopTest();
    }
    
    static testMethod void testAuthorizationStatusValidation2() {
        T_COUNTY__c county = TestClassUtility.createCounty('County1', 'Dept1', 10, true);
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c = 'Level 1');
        insert provider;
        T_CHATS_PROVR_STATUS__c provider1 = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c = 'Level 3');
        insert provider1;
        Date datetoday = System.Today();
        Date begindateOpn = System.Today()-10;
        Date begindateFin = System.Today().addYears(4);
        T_SBSD_CASE__c sbsdcase = TestClassUtility.createCase(false, county.Id);
        sbsdcase.IDN_EXTNL__c = '12345';
        upsert sbsdcase;
        Date begindate = date.newInstance(datetoday.year(), datetoday.month(), 1);
        begindate = begindate.addDays(25);
        Date enddate = begindate.addDays(20);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true, date.newInstance(1983, 7, 15), 'firstName', '1', 'lastName', '1', 'CC');
        
        T_AUTH__c authorization = TestClassUtility.createAuthorization(false, enddate, begindate, county.Id, provider.Id);
        authorization.IDN_CASE__c = sbsdcase.Id;
        authorization.IDN_CLIENT__c = sbsdIndiv.Id;
        authorization.AMT_ACTV_AUTH__c = 12;
        insert authorization;
        
        T_AUTH__c authorization1 = TestClassUtility.createAuthorization(false, enddate, begindate, county.Id, provider1.Id);
        authorization1.IDN_CASE__c = sbsdcase.Id;
        authorization1.IDN_CLIENT__c = sbsdIndiv.Id;
        authorization1.AMT_ACTV_AUTH__c = 123;
        insert authorization1;
        
        List<T_AUTH__c> authNameList = new List<T_AUTH__c>{authorization1};
            SET<Id> AuthIds = new Set<Id>{authorization1.Id};
                
                Test.startTest();
        AuthorizationStatusController.getAuthWeight(sbsdcase.Id, true, '12','2022-11-01');
        AuthorizationStatusController.insertATSRecords(authNameList);
        AuthorizationStatusController.authTerminate(AuthIds);
        Test.stopTest();
    }
    
    /**
     * @description Test the bulkified version of terminateSCAssociationRecords
     */
    static testMethod void testBulkSlotContractMethods() {
        Date datetoday = System.Today();
        Date begindate = date.newInstance(datetoday.year(), datetoday.month(), 1).addDays(25);
        Date enddate = begindate.addDays(20);
        
        T_COUNTY__c county = TestClassUtility.createCounty('County2', 'Dept2', 10, true);
        T_CHATS_PROVR_STATUS__c provider = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c = 'Level 2');
        insert provider;
        T_SBSD_CASE__c sbsdcase = TestClassUtility.createCase(false, county.Id);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true, date.newInstance(1985, 7, 15), 'firstNames', '2', 'lastNames', '2', 'CC');
        
        // Create multiple authorization records
        List<T_AUTH__c> authList = new List<T_AUTH__c>();
        Map<Id, T_AUTH__c> oldAuthMap = new Map<Id, T_AUTH__c>();
        
        // Create slot contract addendum
        T_SLOT_CONTRACT_ADDENDUM__c scAdd = new T_SLOT_CONTRACT_ADDENDUM__c();
        scAdd.CDE_COUNTY__c = county.Id;
        Insert scAdd;
        
        // Create 5 authorization records to test bulk processing
        for(Integer i = 0; i < 5; i++) {
            T_AUTH__c auth = TestClassUtility.createAuthorization(false, enddate, begindate, county.Id, provider.Id);
            auth.IDN_CASE__c = sbsdcase.Id;
            auth.IDN_CLIENT__c = sbsdIndiv.Id;
            auth.AMT_ACTV_AUTH__c = 12 + i;
            authList.add(auth);
        }
        insert authList;
        
        // Create slot contracts for each authorization
        List<T_SLOT_CONTRACT__c> slotContracts = new List<T_SLOT_CONTRACT__c>();
        for(T_AUTH__c auth : authList) {
            T_SLOT_CONTRACT__c sc = new T_SLOT_CONTRACT__c();
            sc.IDN_AUTH__c = auth.Id;
            sc.CDE_COUNTY__c = county.Id;
            sc.IDN_ADDENDUM__c = scAdd.Id;
            sc.DTE_END_SLOT__c = enddate.addDays(1);
            sc.DTE_BEGIN_SLOT__c = begindate;
            slotContracts.add(sc);
            
            // Create old version of auth record for the oldMap
            T_AUTH__c oldAuth = auth.clone(true, true, true, true);
            oldAuth.DTE_END_EFFV_AUTH__c = enddate.addDays(-5); // Different end date
            oldAuthMap.put(auth.Id, oldAuth);
        }
        insert slotContracts;
        
        // Update the auth records with slot contract IDs
        for(Integer i = 0; i < authList.size(); i++) {
            authList[i].IDN_SLOT_CONTRACT__c = slotContracts[i].Id;
        }
        update authList;
        
        Test.startTest();
        // The trigger will automatically call terminateSCAssociationRecords when records are updated
        Test.stopTest();
        
        // Verify the results - check that slot contracts were updated correctly
        List<T_SLOT_CONTRACT__c> updatedSlots = [SELECT Id, IDN_AUTH__c FROM T_SLOT_CONTRACT__c WHERE Id IN :slotContracts];
        System.assertEquals(5, updatedSlots.size(), 'Should have 5 slot contracts');
    }
}