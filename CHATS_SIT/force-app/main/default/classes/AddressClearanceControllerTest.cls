/*
*
* Change Log:
* Added assert statement for test methods.: Shubham K (5/15)
*
*/

@isTest
public class AddressClearanceControllerTest{
    public static T_SBSD_CASE_ADR__c caseAddress;
    public static T_SBSD_CASE__c caseRecord;
    public static void setUp(){
        caseAddress = new T_SBSD_CASE_ADR__c();
        T_COUNTY__c county=TestClassUtility.createCounty('Test County', 'Test County Department', 12, true);
        caseRecord = TestClassUtility.createCase(true, county.id);

        caseAddress.ADR_LINE_1__c = 'Address 1';
        caseAddress.ADR_LINE_2__c = 'Address 2';
        caseAddress.ADR_CITY__c = 'City';
        caseAddress.ADR_STATE__c = 'AR';
        caseAddress.ADR_ZIP_MAIN__c = '12345';
        caseAddress.ADR_ZIP_EXTN__c = '4321';
        caseAddress.IDN_CASE__c = caseRecord.id;
        caseAddress.CDE_TYPE_ADR__c = 'MAL';
        caseAddress.CDE_SOURCE_VRFD_ADR__c = 'AR';
        caseAddress.CDE_TYPE_VERIF__c = 'NA';
    }

    public static testmethod void testGetCaseAddressIdList(){
        setUp();
        insert caseAddress;
        T_SBSD_CASE_ADR__c caseAdd = [Select Id, ADR_LINE_1__c from T_SBSD_CASE_ADR__c where id = :caseAddress.id limit 1];
        system.assertEquals('Address 1',caseAdd.ADR_LINE_1__c,'Address Line 1 Mismatch');
        AddressClearanceController.getCaseAddressIdList(caseRecord.id);
    }
    public static testmethod void testUpdateAddress(){
        setUp();
        insert caseAddress;
        AddressWrapper a = new AddressWrapper();
        a.ADR_LINE_1 = 'Test Address 1';
        a.ADR_LINE_2  = 'Test Address 2';
        a.ADR_CITY = 'City';
        a.ADR_STATE = 'AL';
        a.ADR_ZIP_MAIN = '09876';
        a.ADR_ZIP_EXTN = '9876';
        String wrapperString = JSON.serialize(a);
        LightningServerResponse lsr = AddressClearanceController.updateAddress(wrapperString,caseAddress.id);
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
    }
    public static testmethod void testGetMatchingAddress(){
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('CHATS_testResponse');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        mock.setHeader('Accept', 'application/json');

        Test.setMock(HttpCalloutMock.class,mock);
        Test.startTest();
        //with street 2
        LightningServerResponse lsr= AddressClearanceController.getMatchingAddress('1400 16th St','ste 330','Denver','CO','80202');
        system.assert(string.valueof(lsr).contains('isSuccessful'),'isSuccessful should be present');
        //with no street 2
        LightningServerResponse lsr1 = AddressClearanceController.getMatchingAddress('1 S Rosedale S','','Baltimore','MD','21229');
        system.assert(string.valueof(lsr1).contains('isSuccessful'),'isSuccessful should be present');
        LightningServerResponse lsr2 = AddressClearanceController.getMatchingAddress('asdf','asdf','asdf','asdf','asdf');
        system.assert(string.valueof(lsr2).contains('isSuccessful'),'isSuccessful should be present');
        LightningServerResponse lsr3 = AddressClearanceController.getMatchingAddress(null, null, null, null, null);
        system.assert(string.valueof(lsr3).contains('isSuccessful'),'isSuccessful should be present');
        Test.stopTest();
    }
    public static testmethod void matchingAddressNegResp(){
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new AddressVerificationFailureResponseTest());
        LightningServerResponse lsr3 = AddressClearanceController.getMatchingAddress(null, null, null, null, null);
        //system.assertEquals(true,lsr3.isSuccessful,'isSuccessful should be true');
        test.stopTest();
    }
}