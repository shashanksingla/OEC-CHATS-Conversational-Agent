@isTest
public class waitlistServicesTest {
    static testmethod void waitlistTest(){
        T_SBSD_CASE_WTLST__c wtlstRec = new T_SBSD_CASE_WTLST__c();
        T_SBSD_CASE_WTLST__c wtlstRec1 = new T_SBSD_CASE_WTLST__c();
        T_SBSD_CASE_WTLST__c wtlstRecUpd = new T_SBSD_CASE_WTLST__c();
        
        T_SBSD_CASE__c caseObject = new T_SBSD_CASE__c();
        T_SBSD_CASE__c caseObject1 = new T_SBSD_CASE__c();
        T_COUNTY__c countyObject = new T_COUNTY__c();
        T_COUNTY__c countyObject1 = new T_COUNTY__c();
        List<T_SBSD_CASE_WTLST__c> wtlst = new List<T_SBSD_CASE_WTLST__c>();
        List<T_SBSD_CASE_WTLST__c> wtlst1 = new List<T_SBSD_CASE_WTLST__c>();
        Test.startTest();
        countyObject.CNTY_DEPT_NAME__c = 'Arapahoe County';
        countyObject.CDE_COUNTY__c = 3;
        insert countyObject;
        
        caseObject.CDE_COUNTY__c = countyObject.Id;
        caseObject.IND_ASSIST_PROVR__c = 'N';
        caseObject.CDE_ASST_HSNG__c = 'N';
        insert caseObject;
        
        wtlstRec.IDN_CASE__c = caseObject.Id; 
        wtlstRec.DTE_BEGIN_EFFV_WTLST__c = date.today();
        wtlstRec.DTE_END_EFFV_WTLST__c = date.today() + 1;
        wtlstRec.CDE_STATUS_WTLST__c = 'RFS';
        wtlst.add(wtlstRec);
        insert wtlst;
        waitlistServices.caseWaitlistStatusUpdate(wtlst);
        
        //record for testing version-2
        countyObject1.CNTY_DEPT_NAME__c = 'Arapahoe County';
        countyObject1.CDE_COUNTY__c = 3;
        insert countyObject1;
        
        caseObject1.CDE_COUNTY__c = countyObject1.Id;
        caseObject1.IND_ASSIST_PROVR__c = 'N';
        caseObject1.CDE_ASST_HSNG__c = 'N';
        insert caseObject1;
        
        wtlstRec1.IDN_CASE__c = caseObject1.Id; 
        wtlstRec1.DTE_BEGIN_EFFV_WTLST__c = date.today();
        //wtlstRec1.CDE_REASON_REMOVAL__c = 'ATP';
        wtlstRec1.CDE_STATUS_WTLST__c = 'RFS';
        wtlst1.add(wtlstRec1);
        //system.debug('wtlst1 size : '+wtlst1.size());
        insert wtlstRec1;
        
        wtlstRecUpd.Id = wtlstRec1.Id;
        wtlstRecUpd.CDE_STATUS_WTLST__c = 'REM';
        wtlstRecUpd.CDE_REASON_REMOVAL__c ='ATP';
        wtlstRecUpd.DTE_BEGIN_EFFV_WTLST__c = system.today();
        update wtlstRecUpd;
        
        system.assert([select Id from T_SBSD_CASE_WTLST__c where IDN_CASE__c =:caseObject1.Id].size()>0,'Should return Case waitlist records');
        Test.stopTest();
    }
}