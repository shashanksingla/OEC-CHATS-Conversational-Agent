@isTest
public class ChildCareRequestFlowApxCtrlTest {
    public static testMethod void testGetInitData(){
        List<T_SBSD_CASE__c> caseRecords = [SELECT id FROM T_SBSD_CASE__c limit 100];
        System.assertEquals(false, caseRecords.isEmpty(),'caseRecords should not be empty');
        LightningServerResponse lsr = ChildCareRequestFlowApxCtrl.getInitData(caseRecords.get(0).Id);
        System.assertEquals(true, lsr.isSuccessful, 'lsr.isSucessful should be true');
        System.assertEquals(true, lsr.objectData.containsKey('caseIndividuals'), 'lsr.objectData should contain caseIndividuals as key');
    }
    
    public static testMethod void testSubmitData(){
        List<T_SBSD_CASE__c> caseRecords = [SELECT id FROM T_SBSD_CASE__c limit 100];
        LightningServerResponse lsr = ChildCareRequestFlowApxCtrl.getInitData(caseRecords.get(0).Id);
        Map<String,Object> mapCaseIndivIdToCCR = new Map<String,Object>();
        Id caseIndivId = [SELECT Id FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__r.NAM_FIRST__c = 'firstNameE'][0].Id;
        for(T_SBSD_CASE_INDIV__c caseIndiv:(List<T_SBSD_CASE_INDIV__c>)lsr.objectData.get('caseIndividuals')){
            if(caseIndiv.Child_Care_Requests__r.isEmpty()){
                mapCaseIndivIdToCCR.put(caseIndiv.Id,new Map<String,Object>{
                    'ccRequest'=>true,
                        'reasonEndingCare'=>null
                        });
            }else{
                if(caseIndivId == caseIndiv.Id ){
                    mapCaseIndivIdToCCR.put(caseIndiv.Id,new Map<String,Object>{
                        'ccRequest'=>true,
                            'reasonEndingCare'=>null
                            });
                }else{
                mapCaseIndivIdToCCR.put(caseIndiv.Id,new Map<String,Object>{
                    'ccRequest'=>false,
                        'reasonEndingCare'=>'10P'
                        });
                }
            }
        }
        lsr = ChildCareRequestFlowApxCtrl.submitData(JSON.serialize(mapCaseIndivIdToCCR));
        system.assertEquals(true,lsr.isSuccessful,'isSuccessful should be true');
    }
    
    public static testMethod void testafterSubmitData(){
        LightningServerResponse lsr=ChildCareRequestFlowApxCtrl.afterSubmitData([Select Id,IDN_CASE_INDIV__c from T_INDIV_CAT_RQ__c Limit 10]);
        system.assert(String.valueOf(lsr).contains('isSuccessful=true'),'Wrong response');
		LightningServerResponse lsr2=ChildCareRequestFlowApxCtrl.afterSubmitData([Select Id from T_INDIV_CAT_RQ__c Limit 10]);
        //system.assert(String.valueOf(lsr2).contains('isSuccessful=false'),'Wrong response');              
    }
    
    @testSetup
    public static void setUpData(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserwithPS(userProfile.Id,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.uesername','ttes');
             
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
            T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true,countyRec.Id);
            T_SBSD_INDIV__c indivRec = TestClassUtility.createIndividual(false,System.today().addYears(-15), 'firstNameA','1', 'lastNameA','123456789','CC');
            T_SBSD_INDIV__c indivRec2 = TestClassUtility.createIndividual(false,System.today().addYears(-25), 'firstNameB','1', 'lastNameB','3267376','CC');
            T_SBSD_INDIV__c indivRec3 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameC','1', 'lastNameC','3327123','CC');
            T_SBSD_INDIV__c indivRec4 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameD','1', 'lastNameD','3327123','CC');
            T_SBSD_INDIV__c indivRec5 = TestClassUtility.createIndividual(false,System.today().addYears(-10), 'firstNameE','1', 'lastNameE','3327123','CC');
            
            insert new List<SObject>{indivRec, indivRec2, indivRec3, indivRec4, indivRec5};
                
            T_SBSD_CASE_INDIV__c caseIndiv3 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=true, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec3.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
            T_SBSD_CASE_INDIV__c caseIndiv5 =  new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec5.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5));
            insert new List<SObject>{ caseIndiv3, caseIndiv5, 
                new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5)),
                new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec2.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5)),
                new T_SBSD_CASE_INDIV__c(IND_CRTKR__c=false, IDN_CASE__c=caseRec.Id,IDN_CLIENT__c=indivRec4.Id, DTE_BEGIN_EFFV__c = System.today().addDays(-5))
                //new T_INDIV_REL__c(IDN_CLIENT_RELTD__c = indivRec.Id, IDN_CLIENT__c = indivRec3.Id, CDE_TYPE_REL_INDIV__c = 'M')
                };
                    insert new List<SObject>{new T_INDIV_CAT_RQ__c(CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today()-10, IDN_CASE_INDIV__c = caseIndiv3.Id),
                        new T_INDIV_CAT_RQ__c(CDE_CAT_PROG__c = 'CC', DTE_BEGIN_EFFV__c = System.today()-14, DTE_END_EFFV__c= System.today(), IDN_CASE_INDIV__c = caseIndiv5.Id)
                        };            
        }
        
    }
}