@isTest
public class caseAddressServicesTest {
    
    public static testmethod void testDoUpdateIndicatorResident(){
        Map<String, SObject> caseData = CaseLastUpdatedTestFactory.createCaseData();
        T_SBSD_CASE__c caseRec = (T_SBSD_CASE__c)caseData.get('caseRec');
        T_SBSD_CASE_ADR__c caseAddr = new T_SBSD_CASE_ADR__c();
        caseAddr.ADR_CITY__c = 'Denver';
        caseAddr.ADR_LINE_1__c = '102 street- test';
        caseAddr.ADR_STATE__c = 'CO';
        caseAddr.ADR_ZIP_MAIN__c = '80111';
        caseAddr.CDE_TYPE_ADR__c = 'HOM';
        caseAddr.IDN_CASE__c = caseRec.Id;
        insert caseAddr;
        caseAddr.ADR_STATE__c = 'AL';
        update caseAddr;
        Map<String, List<T_SBSD_CASE_ADR__c>> caseIdToCaseAddresses = new Map<String, List<T_SBSD_CASE_ADR__c>>();
        caseIdToCaseAddresses.put(caseRec.Id, new List<T_SBSD_CASE_ADR__c>{caseAddr});
        caseRec.ADR_STATE_PROVR__c = 'CO';
        caseAddressServices.updateCase(new List<T_SBSD_CASE__c>{caseRec}, caseIdToCaseAddresses);
        system.assertEquals('AL',[Select ADR_STATE__c from T_SBSD_CASE_ADR__c where Id=:caseAddr.Id].ADR_STATE__c,'State should match');
        
    }
      public static testmethod void testUpdateIndicatorResident(){
        Map<Id, T_SBSD_CASE_ADR__c> caseData = new Map<Id, T_SBSD_CASE_ADR__c>();
        T_COUNTY__c county= TestClassUtility.createCounty('countyName', 'countyDepartmentName', 01, true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, county.Id);
        T_SBSD_CASE_ADR__c caseAddr = new T_SBSD_CASE_ADR__c();
        caseAddr.ADR_CITY__c = 'Denver';
        caseAddr.ADR_LINE_1__c = '102 street- test';
        caseAddr.ADR_STATE__c = 'CO	';
        caseAddr.ADR_ZIP_MAIN__c = '80111';
        caseAddr.CDE_TYPE_ADR__c = 'HOM';
        caseAddr.IDN_CASE__c = caseRec.Id;
        insert caseAddr;
        List<T_SBSD_CASE_ADR__c> cadrrec;
        caseAddr.ADR_STATE__c = 'AL';
        caseAddr.CDE_TYPE_ADR__c = 'MAL';
        update caseAddr;
        caseData.put(caseAddr.Id,caseAddr );      
        caseAddressServices.doUpdateIndicatorResident(new List<T_SBSD_CASE_ADR__c>{caseAddr}, caseData);
        
    }
    
    static testmethod void caseAddresstest(){
        List<T_SBSD_CASE_ADR__c> caseAddrList = new List<T_SBSD_CASE_ADR__c>();
        List<T_SBSD_CASE_ADR__c> caseAddrList1 = new List<T_SBSD_CASE_ADR__c>();
        //Removed unused variable on 5/14/2018 BG  
        T_SBSD_CASE_ADR__c caseAddr = new T_SBSD_CASE_ADR__c();
        T_SBSD_CASE_ADR__c caseAddr1 = new T_SBSD_CASE_ADR__c();
        //Removed unused variable on 5/14/2018 BG  
        T_SBSD_CASE_ADR__c caseAddr4 = new T_SBSD_CASE_ADR__c();
        T_SBSD_CASE_ADR__c caseAddr5 = new T_SBSD_CASE_ADR__c();
        T_SBSD_CASE__c caseObject = new T_SBSD_CASE__c();
        T_SBSD_CASE__c caseObject1 = new T_SBSD_CASE__c();
        T_COUNTY__c countyObject = new T_COUNTY__c();
        T_SBSD_CASE_HOMELESS__c caseHomeless = new T_SBSD_CASE_HOMELESS__c();
        T_SBSD_CASE_HOMELESS__c caseHomeless1 = new T_SBSD_CASE_HOMELESS__c();
        Test.startTest();
        countyObject.CNTY_DEPT_NAME__c = 'Denver County';
        countyObject.CDE_COUNTY__c = 20;
        insert countyObject;
        
        caseObject.CDE_COUNTY__c = countyObject.Id;
        caseObject.IND_ASSIST_PROVR__c = 'N';
        caseObject.CDE_ASST_HSNG__c = 'N';
        insert caseObject;
        caseObject1.CDE_COUNTY__c = countyObject.Id;
        caseObject1.IND_ASSIST_PROVR__c = 'N';
        caseObject1.CDE_ASST_HSNG__c = 'N';
        insert caseObject1;
        
        caseHomeless.IDN_CASE__c = caseObject.Id;
        caseHomeless.Is_family_homeless__c = 'N';
        caseHomeless.DTE_BEGIN_EFFV__c = date.today();
        insert caseHomeless;
        caseHomeless1.IDN_CASE__c = caseObject1.Id;
        caseHomeless1.Is_family_homeless__c = 'Y';
        caseHomeless1.DTE_BEGIN_EFFV__c = date.today();
        caseHomeless1.IND_LVG_CAMPGROUND__c = true;
        insert caseHomeless1;
        
        caseAddr.ADR_CITY__c = 'Denver';
        caseAddr.ADR_LINE_1__c = '102 street- test';
        caseAddr.ADR_STATE__c = 'CO';
        caseAddr.ADR_ZIP_MAIN__c = '80111';
        caseAddr.CDE_TYPE_ADR__c = 'HOM';
        caseAddr.IDN_CASE__c = caseObject.Id;
        caseAddrList.add(caseAddr);
        insert caseAddrList;
        
        caseAddr1.ADR_CITY__c = 'Denver';
        caseAddr1.ADR_LINE_1__c = '102 street- test';
        caseAddr1.ADR_STATE__c = 'CO';
        caseAddr1.ADR_ZIP_MAIN__c = '80111';
        caseAddr1.CDE_TYPE_ADR__c = 'HOM';
        caseAddr1.IDN_CASE__c = caseObject1.Id;
        caseAddrList1.add(caseAddr1);
        insert caseAddrList1;
        
        caseAddr4.ADR_CITY__c = 'Denver';
        caseAddr4.ADR_LINE_1__c = '102 street- test';
        caseAddr4.ADR_STATE__c = 'CO';
        caseAddr4.ADR_ZIP_MAIN__c = '80111';
        caseAddr4.CDE_TYPE_ADR__c = 'HOM';
        caseAddr4.IDN_CASE__c = caseObject1.Id;
        try{
            insert caseAddr4;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Each Case cannot have more than one Home Address Type') ? true : false;
           // System.AssertEquals(expectedExceptionThrown, true);
        }
        
        caseAddr5.ADR_CITY__c = 'Denver';
        caseAddr5.ADR_LINE_1__c = '102 street- test';
        caseAddr5.ADR_STATE__c = 'CO';
        caseAddr5.ADR_ZIP_MAIN__c = '80111';
        caseAddr5.CDE_TYPE_ADR__c = 'MAL';
        caseAddr5.IDN_CASE__c = caseObject1.Id;
        try{
            insert caseAddr5;
        }
        catch(Exception e){
            System.debug(e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains('Each Case cannot have more than one Mailing Address Type') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        caseAddressServices.caseAddressValidations(caseAddrList);
        caseAddressServices.caseAddressValidations(caseAddrList1);
        
        test.stopTest();
        
    }
    static testmethod void caseAddresstestHOM(){
        List<T_SBSD_CASE_ADR__c> caseAddrList = new List<T_SBSD_CASE_ADR__c>();
        List<T_SBSD_CASE_ADR__c> caseAddrList1 = new List<T_SBSD_CASE_ADR__c>();
        //Removed unused variable on 5/14/2018 BG  
        T_SBSD_CASE_ADR__c caseAddr = new T_SBSD_CASE_ADR__c();
        T_SBSD_CASE_ADR__c caseAddr1 = new T_SBSD_CASE_ADR__c();
        //Removed unused variable on 5/14/2018 BG  
        T_SBSD_CASE_ADR__c caseAddr4 = new T_SBSD_CASE_ADR__c();
        T_SBSD_CASE_ADR__c caseAddr5 = new T_SBSD_CASE_ADR__c();
        T_SBSD_CASE__c caseObject = new T_SBSD_CASE__c();
        T_SBSD_CASE__c caseObject1 = new T_SBSD_CASE__c();
        T_COUNTY__c countyObject = new T_COUNTY__c();
        T_SBSD_CASE_HOMELESS__c caseHomeless = new T_SBSD_CASE_HOMELESS__c();
        T_SBSD_CASE_HOMELESS__c caseHomeless1 = new T_SBSD_CASE_HOMELESS__c();
        Test.startTest();
        countyObject.CNTY_DEPT_NAME__c = 'Denver County';
        countyObject.CDE_COUNTY__c = 20;
        insert countyObject;
        
        caseObject.CDE_COUNTY__c = countyObject.Id;
        caseObject.IND_ASSIST_PROVR__c = 'N';
        caseObject.CDE_ASST_HSNG__c = 'N';
        insert caseObject;
        caseObject1.CDE_COUNTY__c = countyObject.Id;
        caseObject1.IND_ASSIST_PROVR__c = 'N';
        caseObject1.CDE_ASST_HSNG__c = 'N';
        insert caseObject1;
        
        caseHomeless.IDN_CASE__c = caseObject.Id;
        caseHomeless.Is_family_homeless__c = 'N';
        caseHomeless.DTE_BEGIN_EFFV__c = date.today();
        insert caseHomeless;
        caseHomeless1.IDN_CASE__c = caseObject1.Id;
        caseHomeless1.Is_family_homeless__c = 'Y';
        caseHomeless1.DTE_BEGIN_EFFV__c = date.today();
        caseHomeless1.IND_LVG_CAMPGROUND__c = true;
        insert caseHomeless1;
        
        caseAddr.ADR_CITY__c = 'Denver';
        caseAddr.ADR_LINE_1__c = '102 street- test';
        caseAddr.ADR_STATE__c = 'CO';
        caseAddr.ADR_ZIP_MAIN__c = '80111';
        caseAddr.CDE_TYPE_ADR__c = 'HOM';
    	caseAddr.DTE_BEGIN_EFFV__c = System.today();
        caseAddr.IDN_CASE__c = caseObject.Id;
        caseAddrList.add(caseAddr);
        insert caseAddrList;
        
        caseAddr1.ADR_CITY__c = 'Denver';
        caseAddr1.ADR_LINE_1__c = '102 street- test';
        caseAddr1.ADR_STATE__c = 'CO';
        caseAddr1.ADR_ZIP_MAIN__c = '80111';
        caseAddr1.CDE_TYPE_ADR__c = 'HOM';
    	caseAddr1.DTE_BEGIN_EFFV__c = System.today();
        caseAddr1.IDN_CASE__c = caseObject1.Id;
        caseAddrList1.add(caseAddr1);
        insert caseAddrList1;
        
        caseAddr4.ADR_CITY__c = 'Denver';
        caseAddr4.ADR_LINE_1__c = '102 street- test';
        caseAddr4.ADR_STATE__c = 'CO';
        caseAddr4.ADR_ZIP_MAIN__c = '80111';
        caseAddr4.CDE_TYPE_ADR__c = 'HOM';
    caseAddr4.DTE_BEGIN_EFFV__c = System.today().addDays(4);
        caseAddr4.IDN_CASE__c = caseObject1.Id;
        try{
            insert caseAddr4;
        }
        catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('Each Case cannot have more than one Home Address Type') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        caseAddr5.ADR_CITY__c = 'Denver';
        caseAddr5.ADR_LINE_1__c = '102 street- test';
        caseAddr5.ADR_STATE__c = 'CO';
        caseAddr5.ADR_ZIP_MAIN__c = '80111';
        caseAddr5.CDE_TYPE_ADR__c = 'MAL';
    caseAddr5.DTE_BEGIN_EFFV__c = System.today();
        caseAddr5.IDN_CASE__c = caseObject1.Id;
        try{
            insert caseAddr5;
        }
        catch(Exception e){
            System.debug(e.getMessage());
            Boolean expectedExceptionThrown =  e.getMessage().contains('Each Case cannot have more than one Mailing Address Type') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }
        
        caseAddressServices.caseAddressValidations(caseAddrList);
        caseAddressServices.caseAddressValidations(caseAddrList1);
        
        test.stopTest();
        
    }    
    static testMethod void deleteCasePhoneEndDate(){
        T_SBSD_CASE__c caseObject = new T_SBSD_CASE__c();
        T_COUNTY__c countyObject = new T_COUNTY__c();
         countyObject.CNTY_DEPT_NAME__c = 'Denver County';
        countyObject.CDE_COUNTY__c = 20;
        insert countyObject;
        
        caseObject.CDE_COUNTY__c = countyObject.Id;
        caseObject.IND_ASSIST_PROVR__c = 'N';
        caseObject.CDE_ASST_HSNG__c = 'N';
        insert caseObject;
        
        List<T_SBSD_CASE_PHONE__c> casePhones = new List<T_SBSD_CASE_PHONE__c>();
        List<T_SBSD_CASE_PHONE__c> casePhones2 = new List<T_SBSD_CASE_PHONE__c>();
        casePhones.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='HOM',DTE_BEGIN_EFFV__c=System.today()));
        casePhones2.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='HOM',DTE_BEGIN_EFFV__c=System.today().addDays(2)));
        casePhones2.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='MOB',DTE_BEGIN_EFFV__c=System.today().addDays(2)));
        casePhones.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='MOB',DTE_BEGIN_EFFV__c=System.today()));
        casePhones.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='WOR',DTE_BEGIN_EFFV__c=System.today()));
        casePhones2.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='WOR',DTE_BEGIN_EFFV__c=System.today().addDays(2)));
        casePhones2.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='EMR',DTE_BEGIN_EFFV__c=System.today().addDays(2)));
        casePhones.add(new T_SBSD_CASE_PHONE__c(IDN_CASE__c=caseObject.id,CDE_TYPE_PHONE__c='EMR',DTE_BEGIN_EFFV__c=System.today()));
        Test.startTest();
        insert casePhones;
        insert casePhones2;
        delete casePhones2;
        Test.stopTest();
    }
    static testMethod void deleteCaseAddressEndDate(){
        T_SBSD_CASE__c caseObject = new T_SBSD_CASE__c();
        T_COUNTY__c countyObject = new T_COUNTY__c();
         countyObject.CNTY_DEPT_NAME__c = 'Denver County';
        countyObject.CDE_COUNTY__c = 20;
        insert countyObject;
        
        caseObject.CDE_COUNTY__c = countyObject.Id;
        caseObject.IND_ASSIST_PROVR__c = 'N';
        caseObject.CDE_ASST_HSNG__c = 'N';
        insert caseObject;
        
        List<T_SBSD_CASE_ADR__c> caseAdr = new List<T_SBSD_CASE_ADR__c>();
        List<T_SBSD_CASE_ADR__c> caseAdr2 = new List<T_SBSD_CASE_ADR__c>();
        caseAdr.add(new T_SBSD_CASE_ADR__c(IDN_CASE__c=caseObject.id,CDE_TYPE_ADR__c='HOM',DTE_BEGIN_EFFV__c=System.today()));
        caseAdr2.add(new T_SBSD_CASE_ADR__c(IDN_CASE__c=caseObject.id,CDE_TYPE_ADR__c='HOM',DTE_BEGIN_EFFV__c=System.today().addDays(2)));
        caseAdr2.add(new T_SBSD_CASE_ADR__c(IDN_CASE__c=caseObject.id,CDE_TYPE_ADR__c='MAL',DTE_BEGIN_EFFV__c=System.today().addDays(2),ADR_CITY__c='ABC',ADR_LINE_1__c = '102 street- test',ADR_STATE__c = 'CO',ADR_ZIP_MAIN__c = '80111'));
        caseAdr.add(new T_SBSD_CASE_ADR__c(IDN_CASE__c=caseObject.id,CDE_TYPE_ADR__c='MAL',DTE_BEGIN_EFFV__c=System.today(),ADR_CITY__c='ABC',ADR_LINE_1__c = '102 street- test',ADR_STATE__c = 'CO',ADR_ZIP_MAIN__c = '80111'));
        Test.startTest();
        insert caseAdr;
        insert caseAdr2;
        delete caseAdr2;
        Test.stopTest();
    }

}