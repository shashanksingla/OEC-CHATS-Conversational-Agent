@isTest
public class IndividulCareLevelServices_Test {
    public static List<T_INDIV_CAT_RQ__c> childCareList= new List<T_INDIV_CAT_RQ__c>();
    public static testMethod void testGetInitData(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserWithPS(userProfile.Id ,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.uesername','ttes');
            
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id);
            T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstNameA','1', 'LastNameA','123456789','CC');
            T_SBSD_INDIV__c indivRec2 = TestClassUtility.createIndividual(false,System.today().addYears(-25), 'firstNameB','1', 'LastNameB','3267376','CC');
            T_SBSD_INDIV__c indivRec3 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameC','1', 'LastNameC','3327123','CC');
            T_SBSD_INDIV__c indivRec4 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameD','1', 'LastNameD','3327123','CC');
            T_SBSD_INDIV__c indivRec5 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameE','1', 'LastNameE','3327123','CC');
            
            insert new List<SObject>{indivRec, indivRec2, indivRec3, indivRec4, indivRec5};
                
                T_SBSD_CASE_INDIV__c caseIndiv3 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=true, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec3.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
            T_SBSD_CASE_INDIV__c caseIndiv5 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec5.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
            insert new List<SObject>{ caseIndiv3, caseIndiv5, 
                new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5)),
                new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec2.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5)),
                new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec4.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5))
                //new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = indivRec.Id, IDN_CLIENT__c = indivRec3.Id, CDE_TYPE_REL_INDIV__c = 'M')
                };
                    childCareList= new List<T_INDIV_CAT_RQ__c>{new T_INDIV_CAT_RQ__c(CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today()-10, IDN_CASE_INDIV__c = caseIndiv3.Id),
                        new T_INDIV_CAT_RQ__c(CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today()-14, DTE_END_EFFV__c= System.today(), IDN_CASE_INDIV__c = caseIndiv5.Id)
                        };            
                            }
        Test.startTest();
        IndividulCareLevelServices.doMethod(childCareList);
        
        // 5/16 : Added Assert statement for Code Review changes - Shubham K
        
        List<batchsit_t_sbsd_indiv_care_level__x> lstIndivCareLevel = [SELECT id,lastmodifiedbyid__c FROM batchsit_t_sbsd_indiv_care_level__x];
        if(lstIndivCareLevel.size() > 0 && lstIndivCareLevel!= NULL){
            batchsit_t_sbsd_indiv_care_level__x indivCareLvl = lstIndivCareLevel.get(0);
            System.assertEquals(user.id,indivCareLvl.lastmodifiedbyid__c,'Last modifield id should be as run as user');       
        }
        Test.stopTest();
    }
}