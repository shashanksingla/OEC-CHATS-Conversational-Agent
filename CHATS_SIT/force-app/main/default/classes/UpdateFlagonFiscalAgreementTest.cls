@isTest
public class UpdateFlagonFiscalAgreementTest {
    public static final String OPEN = 'OPN';
    public static final String openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
    public testMethod static void testBatchClass(){
        List<T_COUNTY__c> countyList = new List<T_COUNTY__c>();
        List<T_CHATS_PROVR_STATUS__c> providerList = new List<T_CHATS_PROVR_STATUS__c >();
        T_PROVR_FISCAL_AGREMENT__c fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreementList = new List<T_PROVR_FISCAL_AGREMENT__c>();
        
        Date datetoday=System.Today();
        Date begindateOpn=System.Today()-10;
        Date begindateFin=System.Today();
         for(Integer i=0;i<200;i++) {
            countyList.add((T_COUNTY__c)TestClassUtility.createCounty('County'+i,'Dept1',10,false));
            
        }
        
        insert countyList;
        
        for(Integer i=0;i<200;i++) {
            providerList.add(new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1'));
            
        }
        
        insert providerList;
        
                          
        Test.startTest();
        
        for(Integer i=0;i<100;i++) {
            fiscalAgreement = new T_PROVR_FISCAL_AGREMENT__c();
            fiscalAgreement = TestClassUtility.createFiscaAgreement(false,'FA'+i,begindateOpn,countyList[i].Id);
            fiscalAgreement.RecordtypeId=openRecordTypeId;
            fiscalAgreement.CDE_TYPE_STATUS__c=OPEN;
            fiscalAgreement.ID_SERVICE__c=providerList[i].Id;     
            fiscalAgreementList.add(fiscalAgreement);
                  
        }
    
       insert fiscalAgreementList;
    
       Database.executeBatch(new UpdateFlagonFiscalAgreement());
       
       Test.stopTest();
    }
    
        
}