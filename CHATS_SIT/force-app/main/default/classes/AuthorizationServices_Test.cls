/*
*/
@isTest
public class AuthorizationServices_Test {
    
    
    static testMethod void testDuplicateCheck()
    {
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date dob = date.newInstance(datetoday.year()-20, datetoday.month(), 1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, dob, 'firstName', '1', 'lastName', '123', 'CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(true, dob, 'firstNameTest', '1', 'lastNameTest', '123', 'CC');
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        T_SBSD_CASE__c case2 = TestClassUtility.createCase(true, county.Id);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        provider.CDE_ATS_WAIVER__c = true;
        update provider;
        
        T_CHATS_PROVR_STATUS__c provider2 = TestClassUtility.createProvider(true, 'Level 4');
        
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        authorization.IDN_CASE__c= case1.Id;
        authorization.IDN_CLIENT__c= individual.Id;
        authorization.IDN_PROVR__c= provider.Id;
        insert authorization;
        
        T_INDIV_CUST__c indivCust = new T_INDIV_CUST__c();
        indivCust.IDN_CLIENT__c = individual.Id;
        indivCust.DTE_BEGIN_EFFV__c = system.today().addDays(-1) ;
        indivCust.Ignore__c = true;
        insert indivCust;
        
        T_INDIV_CUST__c indivCust2 = new T_INDIV_CUST__c();
        indivCust2.IDN_CLIENT__c = individual.Id;
        indivCust2.DTE_BEGIN_EFFV__c = system.today().addDays(-2) ;
        indivCust2.Ignore__c = true;
        insert indivCust2;
        
        test.startTest();
        List<T_AUTH__c> authList = new List<T_AUTH__c>();
        T_AUTH__c newAuth = TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        newAuth.IDN_CASE__c= case1.Id;
        newAuth.IDN_CLIENT__c= individual2.Id;
        newAuth.IDN_PROVR__c= provider2.Id;
        authList.add(newAuth);
        AuthorizationServices.duplicateCheck(authList);
        
        T_AUTH__c newAuth1 = TestClassUtility.createAuthorization(false,enddate.addDays(10),begindate.addDays(10),county.Id,null);
        newAuth1.IDN_CASE__c= case1.Id;
        newAuth1.IDN_CLIENT__c= individual.Id;
        newAuth1.IDN_PROVR__c= provider.Id;
        authList.clear();
        authList.add(newAuth1);
        AuthorizationServices.duplicateCheck(authList);
        Auth_Schedule_Recurrence__c rec = new Auth_Schedule_Recurrence__c();
        rec.IDN_AUTH__c =newAuth1.Id;
        rec.Fri__c = true;
        rec.DTE_Begin_Date__c = system.today();
        insert rec;
        rec.Mon__c = true;
        update rec;
        rec.Tue__c = true;
        update rec;
        rec.Wed__c = true;
        update rec;
        rec.Thur__c = true;
        update rec;
        rec.Sat__c = true;
        update rec;
        rec.Sun__c = true;
     //   rec.DTE_Begin_Date__c = system.today()-1;
     //   rec.DTE_End_Date__c = system.today()-3;
        update rec;
        
        
        T_AUTH__c newAuth2 = TestClassUtility.createAuthorization(false,enddate.addMonths(1),begindate.addMonths(1),county.Id,null);
        newAuth2.IDN_CASE__c= case1.Id;
        newAuth2.IDN_CLIENT__c= individual.Id;
        newAuth2.IDN_PROVR__c= provider.Id;
        authList.clear();
        authList.add(newAuth2);
        AuthorizationServices.duplicateCheck(authList);
        T_AUTH__c newAuth4 = TestClassUtility.createAuthorization(false,enddate.addMonths(1),begindate.addMonths(1),county.Id,null);
        newAuth4.IDN_CASE__c= case2.Id;
        newAuth4.IDN_CLIENT__c= individual.Id;
        newAuth4.IDN_PROVR__c= provider.Id;
        authList.clear();
        authList.add(newAuth4);
        AuthorizationServices.duplicateCheck(authList);
        List<T_AUTH__c> lstAuthtoBeDeleted = new List<T_AUTH__c>();
        for(T_AUTH__c authRec : [Select Id from T_AUTH__c where IDN_CLIENT__c =: individual.Id]){
            lstAuthtoBeDeleted.add(authRec);
        }
        delete lstAuthtoBeDeleted;
        T_AUTH__c newAuth3 = TestClassUtility.createAuthorization(false,System.today().addMonths(1),System.today(),county.Id,null);
        newAuth3.IDN_CASE__c= case1.Id;
        newAuth3.IDN_CLIENT__c= individual.Id;
        newAuth3.IDN_PROVR__c= provider.Id;
        authList.clear();
        authList.add(newAuth3);
        AuthorizationServices.duplicateCheck(authList);               
        //insert authList;
        system.assert([Select Id from T_AUTH__c limit 10].size()==0,'Query should return zero Auth records');
        test.stopTest();        
    }
    static testMethod void testFiscalActiveCheck()
    {
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date dob = date.newInstance(datetoday.year()-20, datetoday.month(), 1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, dob, 'firstName', '1', 'lastName', '123', 'CC');
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = TestClassUtility.createFiscaAgreement(false, 'name', System.Today(), county.Id);
        fiscalAgreement.ID_SERVICE__c = provider.Id;
        insert fiscalAgreement;
        TestClassUtility.createCaseWaitlist(true, case1.Id, System.today(), System.today().addDays(30), 'WLT');
        
        test.startTest();
        List<T_AUTH__c> authList = new List<T_AUTH__c>();
        T_AUTH__c newAuth = TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        newAuth.IDN_CASE__c= case1.Id;
        newAuth.IDN_CLIENT__c= individual.Id;
        newAuth.IDN_PROVR__c= provider.Id;
        authList.add(newAuth);
        AuthorizationServices.fiscalActiveCheck(authList);
        system.assert([Select Id from T_AUTH__c limit 10].size()==0,'Query should return zero records');
        test.stopTest();
    }
    static testMethod void testcreateChildEnrollmentRecord()
    {
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date dob = date.newInstance(datetoday.year()-20, datetoday.month(), 1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true, dob, 'firstName', '1', 'lastName', '123', 'CC');
        T_SBSD_INDIV__c individual2 = TestClassUtility.createIndividual(true, dob, 'firstNameTest', '1', 'lastNameTest', '123', 'CC');
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        T_SBSD_CASE__c case2 = TestClassUtility.createCase(true, county.Id);
        T_CHATS_PROVR_STATUS__c provider = TestClassUtility.createProvider(true, 'Level 3');
        provider.CDE_ATS_WAIVER__c = true;
        update provider;
        
        T_CHATS_PROVR_STATUS__c provider2 = TestClassUtility.createProvider(true, 'Level 4');
        provider.CDE_ATS_WAIVER__c = false;
        update provider2;
        
        T_CHATS_CHILD_ENROLLMENT__c enroll = new T_CHATS_CHILD_ENROLLMENT__c();
        enroll.IDN_CLIENT__c = individual.Id;
        enroll.IDN_PROVR__c = provider.Id;
        enroll.Enroll_Flag__c='Enrolled';
        enroll.IsWavierProvider__c = true;
        enroll.DTE_BEGIN_EFFV__c=begindate;
        insert enroll;
        
        T_CHATS_CHILD_ENROLLMENT__c enroll1 = new T_CHATS_CHILD_ENROLLMENT__c();
        enroll1.IDN_CLIENT__c = individual2.Id;
        enroll1.IDN_PROVR__c = provider2.Id;
        enroll1.Enroll_Flag__c='Enrolled';
        enroll1.IsWavierProvider__c = true;
        enroll1.DTE_BEGIN_EFFV__c=begindate+1;
        insert enroll1;
        
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        authorization.IDN_CASE__c= case1.Id;
        authorization.IDN_CLIENT__c= individual.Id;
        authorization.IDN_PROVR__c= provider.Id;
        
        T_AUTH__c authorization2=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,null);
        authorization2.IDN_CASE__c= case2.Id;
        authorization2.IDN_CLIENT__c= individual2.Id;
        authorization2.IDN_PROVR__c= provider2.Id;
        
        List<T_AUTH__c> authList = new List<T_AUTH__c>();
        authList.clear();
        authList.add(authorization);
        authList.add(authorization2);
        insert authList;
    }
}