/*
*/
@isTest
public class UpdateFlagOnAuthorizationTest {
    public testMethod static void testBatchClass(){
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date dob = date.newInstance(datetoday.year()-20, datetoday.month(), 1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'name', System.Today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        TestClassUtility.createCaseWaitlist(true, case1.Id, System.today(), System.today().addDays(30), 'WLT');
        List<T_SBSD_INDIV__c> individuals = new List<T_SBSD_INDIV__c>();
        Test.startTest();
        T_SBSD_INDIV__c individual;
        for(Integer i=0;i<1;i++){
            individual= TestClassUtility.createIndividual(false, dob, 'firstName', '1', 'lastName', 'SSN'+i, 'CC');
            individual.NBR_SSN__c = '123';
            individuals.add(individual);
         }
        insert individuals;
        List<T_AUTH__c> authRecords = new List<T_AUTH__c>();
        T_AUTH__c newAuth;
        for(T_SBSD_INDIV__c indiv:individuals){
            newAuth = TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
            indiv.NBR_SSN__c='123';
            newAuth.IDN_CASE__c= case1.Id;
            newAuth.IDN_CLIENT__c= indiv.Id;
            newAuth.IDN_PROVR__c= provider.Id;
            authRecords.add(newAuth);
        }
        insert authRecords;
        System.assert([select Id from T_AUTH__c WHERE Authorization_Status__c='2' AND Batch_Flag__c=false].size()==1,'There should be 100 authorised records');
        UpdateFlagOnAuthorization updateAuthBatch= new UpdateFlagOnAuthorization();
        Database.executeBatch(updateAuthBatch);     
        Test.stopTest();
        System.assert([select Id from T_AUTH__c WHERE Authorization_Status__c='2' AND Batch_Flag__c=false].isEmpty(),'Query should return zero rows as all records should get terminated');
    }
}