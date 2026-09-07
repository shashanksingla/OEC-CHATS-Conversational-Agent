@isTest
public class AssessEligibilityFlowApxCtrlTest {
    @testSetup
    public static void doSetupData(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);

    }
    
    public static testMethod void testgetDoInit(){
        T_SBSD_CASE__c caseRecone=new T_SBSD_CASE__c();
        caseRecone.Is_CBMS_Data__c=TRUE;
        caseRecone.CDE_CBMS_REF_TYP__c='New';
        T_CASE_APPLN_DTE__c applnDateRec = new T_CASE_APPLN_DTE__c(DTE_APPLN_OLD__c=system.today().addYears(-1), DTE_APPLN_NEW__c=system.today(), RSN_OVERRIDE__c='4',CMT_OVERRIDE__c='test', Reopened_or_Elig__c='Eligibility');
        Test.startTest();
        AssessEligibilityFlowApxCtrl.insertApplnDateInfoRec(applnDateRec,caseRecone);
        insert caseRecone;
        AssessEligibilityFlowApxCtrl.getDoInit(caseRecone.Id);
        AssessEligibilityFlowApxCtrl.insertApplnDateInfoRec(applnDateRec,caseRecone);
        EligibilityFlowCmpApxCtrl.updateCaseApplnDateInfo(caseRecone.Id);
        Test.stopTest(); 
    }
    
    public static testMethod void testValidateCaseForEligibilityError(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            LightningServerResponse lsr=AssessEligibilityFlowApxCtrl.validateCaseForEligibility(null, null);
            system.assertEquals(false,lsr.isSuccessful,'isSuccessful should be false as we are passing null values');
        }        
    }
    
    public static testMethod void testValidateCaseForEligibility(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            CaseLastUpdatedServices.isPeakApplicationContext = true;
            List<T_SBSD_CASE__c> cases = [SELECT Id,(SELECT id FROM CaseIndividuals__r) FROM T_SBSD_CASE__c limit 100];
            List<T_SBSD_INDIV__c> individuals = [SELECT Id FROM T_SBSD_INDIV__c limit 100];
            System.assertEquals(false,cases.isEmpty(),'cases should not be empty');
            System.assertEquals(false, cases.get(0).CaseIndividuals__r.isEmpty(),'Case Individuals must exist');
            System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
            T_SBSD_INDIV__c indiv2 = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
            
            T_SBSD_INDIV_INFO__c indivInfo= new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = indiv2.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5), CDE_TYPE_INFO_INDIV__c = 'CS');                
            T_SBSD_INDIV_EMPLMT__c employment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',
                                                                           IDN_CLIENT__c=individuals.get(0).Id,
                                                                           NAM_BUSNS__c='test',
                                                                           DTE_BEGIN_EFFV__c=system.today().addDays(-5),
                                                                           RecordTypeId = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Employment').getRecordTypeId(),
                                                                           Ignore__c=true);
            T_SBSD_INDIV_EMPLMT__c selfEmployment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',
                                                                               IDN_CLIENT__c=individuals.get(0).Id,
                                                                               NAM_BUSNS__c='test',
                                                                               DTE_BEGIN_EFFV__c=system.today().addDays(-5),
                                                                               RecordTypeId = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Self-Employment').getRecordTypeId(),
                                                                               Ignore__c=true);
           /* insert new List<SObject>{new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = cases.get(0).Id, DTE_BEGIN_EFFV__c=System.today().addDays(-5), CDE_STATUS_CASE__c='CLS'),
                new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c = cases.get(0).CaseIndividuals__r.get(0).Id, DTE_BEGIN_EFFV__c=System.today().addDays(-5)),
                TestClassUtility.createCaseIndividual(false, cases.get(0).Id, indiv2.Id,false),
                indivInfo, employment, selfEmployment
                };
                    insert new List<SObject>{new T_INDIV_VERIF__c(IDN_CLIENT__c = indivInfo.Id,CDE_TYPE_INFO_INDIV__c='CS')
                        };  */
            Test.startTest();
            AssessEligibilityFlowApxCtrl.validateCaseForEligibility(cases.get(0).Id, 'TF');
            Test.stopTest();
        }        
    }
    
    public static testMethod void testValidateCaseForEligibility2(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            CaseLastUpdatedServices.isPeakApplicationContext = true;
            List<T_SBSD_CASE__c> cases = [SELECT Id,(SELECT id FROM CaseIndividuals__r) FROM T_SBSD_CASE__c limit 100];
            List<T_SBSD_INDIV__c> individuals = [SELECT Id FROM T_SBSD_INDIV__c limit 100];
            System.assertEquals(false,cases.isEmpty(),'cases should not be empty');
            System.assertEquals(false, cases.get(0).CaseIndividuals__r.isEmpty(),'Case Individuals must exist');
            System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
            T_SBSD_INDIV__c indiv2 = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
            
            T_SBSD_INDIV_INFO__c indivInfo= new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = indiv2.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5), CDE_TYPE_INFO_INDIV__c = 'CS');                
            T_SBSD_INDIV_EMPLMT__c employment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',
                                                                           IDN_CLIENT__c=individuals.get(0).Id,
                                                                           NAM_BUSNS__c='test',
                                                                           DTE_BEGIN_EFFV__c=system.today().addDays(-5),
                                                                           DTE_END_EFFV__c=system.today().addDays(5),
                                                                           RecordTypeId = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Employment').getRecordTypeId(),
                                                                           Ignore__c=true);
            T_SBSD_INDIV_EMPLMT__c selfEmployment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',
                                                                               IDN_CLIENT__c=individuals.get(0).Id,
                                                                               NAM_BUSNS__c='test',
                                                                               DTE_BEGIN_EFFV__c=system.today().addDays(-5),
                                                                               DTE_END_EFFV__c=system.today().addDays(6),
                                                                               RecordTypeId = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Self-Employment').getRecordTypeId(),
                                                                               Ignore__c=true);
            /*insert new List<SObject>{new T_SBSD_CASE_STATUS_MODE__c(IDN_CASE__c = cases.get(0).Id, DTE_BEGIN_EFFV__c=System.today().addDays(-5), CDE_STATUS_CASE__c='REO', CDE_MODE_CASE__c = 'INT'),
                new T_INDIV_CAT_RQ__c(IDN_CASE_INDIV__c = cases.get(0).CaseIndividuals__r.get(0).Id, DTE_BEGIN_EFFV__c=System.today().addDays(-5)),
                TestClassUtility.createCaseIndividual(false, cases.get(0).Id, indiv2.Id,false),
                indivInfo, employment, selfEmployment
                };
                    insert new List<SObject>{new T_INDIV_VERIF__c(IDN_CLIENT__c = indivInfo.Id,CDE_TYPE_INFO_INDIV__c='CS')
                        };   */   
            Test.startTest();
            AssessEligibilityFlowApxCtrl.validateCaseForEligibility(cases.get(0).Id, 'TF');
            Test.stopTest();
        }        
    }
    
    public static testMethod void testValidateCaseForEligibility3(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            CaseLastUpdatedServices.isPeakApplicationContext = true;
            
            List<T_SBSD_CASE__c> cases = [SELECT Id,(SELECT id FROM CaseIndividuals__r) FROM T_SBSD_CASE__c limit 100];
            List<T_SBSD_INDIV__c> individuals = [SELECT Id FROM T_SBSD_INDIV__c limit 100];
            System.assertEquals(false,cases.isEmpty(),'cases should not be empty');
            System.assertEquals(false, cases.get(0).CaseIndividuals__r.isEmpty(),'Case Individuals must exist');
            System.assertEquals(false, individuals.isEmpty(), 'individuals should not be empty');
            T_SBSD_INDIV__c indiv2 = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
            T_SBSD_INDIV_INFO__c indivInfo= new T_SBSD_INDIV_INFO__c(IDN_CLIENT__c = indiv2.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5), CDE_TYPE_INFO_INDIV__c = 'CS');                
            T_SBSD_INDIV_EMPLMT__c employment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',
                                                                           IDN_CLIENT__c=individuals.get(0).Id,
                                                                           NAM_BUSNS__c='test',
                                                                           DTE_BEGIN_EFFV__c=system.today().addDays(-5),      
                                                                           RecordTypeId = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Employment').getRecordTypeId(),
                                                                           Ignore__c=true);
            T_SBSD_INDIV_EMPLMT__c selfEmployment = new T_SBSD_INDIV_EMPLMT__c(ADR_CITY__c='NY',
                                                                               IDN_CLIENT__c=individuals.get(0).Id,
                                                                               NAM_BUSNS__c='test',
                                                                               DTE_BEGIN_EFFV__c=system.today().addDays(-5),              
                                                                               RecordTypeId = Schema.SObjectType.T_SBSD_INDIV_EMPLMT__c.getRecordTypeInfosByName().get('Self-Employment').getRecordTypeId(),
                                                                               Ignore__c=true);                            
            Test.startTest();
            AssessEligibilityFlowApxCtrl.validateCaseForEligibility(cases.get(0).Id, 'FT');
            Test.stopTest();
        }
    }
   
}