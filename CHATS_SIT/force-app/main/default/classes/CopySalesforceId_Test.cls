/*
*/
@isTest
private class CopySalesforceId_Test {

    @testSetup static void setup() {
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        List<T_SBSD_CASE__c> caseList = new List<T_SBSD_CASE__c>();
        List<T_SBSD_INDIV__c> indivList = new List<T_SBSD_INDIV__c>();
        List<T_CHATS_PROVR_STATUS__c> providerList = new List<T_CHATS_PROVR_STATUS__c >();
        List<T_PAYMT__c> pmtList= new List<T_PAYMT__c>();
        List<T_SERV_PERIOD__c> servPeriodList= new List<T_SERV_PERIOD__c>();
        List<T_AUTH__c> authList= new List<T_AUTH__c>();
        
        for(Integer i=0;i<100;i++) {
            caseList.add((T_SBSD_CASE__c)TestClassUtility.createCase(false,county.Id));      
        }
        
        insert caseList;
        
        for(Integer i=0;i<100;i++) {
            indivList.add((T_SBSD_INDIV__c)TestClassUtility.createIndividual(false,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC'));      
        }
        
        insert indivList;
        
        for(Integer i=0;i<100;i++) {
            providerList.add(new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1'));      
        }
        
        insert providerList;
              
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        
       
        for(Integer i=0;i<100;i++) {
            authList.add((T_AUTH__c)TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,providerList[i].Id));
            authList[i].IDN_CASE__c=caseList[i].Id;
            authList[i].IDN_CLIENT__c=indivList[i].Id;
        }
         
       insert authList;
       
       for(Integer i=0;i<100;i++) {
            pmtList.add(new T_PAYMT__c());      
        }
        
        insert pmtList;
        
        for(Integer i=0;i<100;i++) {
            servPeriodList.add(new T_SERV_PERIOD__c(DTE_BEGIN_EFFV__c=system.today()));      
        }
        
        insert servPeriodList;
        
       
    }
        
    static testMethod void CopySalesforceIdBulkTest() {
        List<T_SBSD_CASE__c> caseList = [select Id, IDN_EXTNL__c from T_SBSD_CASE__c Limit 202];
        List<T_SBSD_INDIV__c> indivList = [select Id, IDN_EXTNL__c from T_SBSD_INDIV__c Limit 202];
        List<T_AUTH__c> authList= [select Id, IDN_EXTNL__c from T_AUTH__c Limit 202];
        List<T_PAYMT__c> pmtList= [select Id, IDN_EXTNL__c from T_PAYMT__c Limit 202];
        List<T_SERV_PERIOD__c> servPeriodList= [select Id, IDN_EXTNL__c from T_SERV_PERIOD__c Limit 202];
        Test.starttest();
        
        system.assert(caseList.size()>99,'Incorrect list of records returned');
        system.assert(indivList.size()>99,'Incorrect list of records returned');
        system.assert(authList.size()>99,'Incorrect list of records returned');
        system.assert(pmtList.size()>99,'Incorrect list of records returned');
        system.assert(servPeriodList.size()>99,'Incorrect list of records returned');
        
        
        //Authorization object check
        for(T_AUTH__c authEach:authList) {
           system.assertEquals(authEach.Id,authEach.IDN_EXTNL__c,'External Id is not matching with record Id');
        }
        
        //Case object check
        for(T_SBSD_CASE__c caseEach:caseList) {
           system.assertEquals(caseEach.Id,caseEach.IDN_EXTNL__c,'External Id is not matching with record Id');
        }
        
        //Individual object check
        for(T_SBSD_INDIV__c indivEach:indivList) {
           system.assertEquals(indivEach.Id,indivEach.IDN_EXTNL__c,'External Id is not matching with record Id');
        }
        
        //Payment object check
        for(T_PAYMT__c pmtEach:pmtList) {
           system.assertEquals(pmtEach.Id,pmtEach.IDN_EXTNL__c,'External Id is not matching with record Id');
        }
        
        //Service Period object check
        for(T_SERV_PERIOD__c servPeriodEach:servPeriodList) {
           system.assertEquals(servPeriodEach.Id,servPeriodEach.IDN_EXTNL__c,'External Id is not matching with record Id');
        }
        
        
        Test.stoptest();
    }
}