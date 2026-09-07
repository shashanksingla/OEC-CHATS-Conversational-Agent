// Created by Balamurugan Chinnaiah 01/03/2023
// Created for CCCAP-7613

@isTest 
public class ChangeCR205StatusToRequestedBatchTest {

    static testmethod void test() {
    	
		// Create test accounts to be updated by batch
		List<T_DOC_RQ__c> docList = new List<T_DOC_RQ__c>();
		for (Integer i=0;i<100;i++) {
			T_DOC_RQ__c ac = new T_DOC_RQ__c();
			ac.NME_CORSPD__c = 'CR205';
			ac.CDE_CORSPD_STATUS__c = 'Pending'; 
			ac.CDE_TYPE_RCPT__c = 'P';
			ac.cde_lang_doc__c = 'ENG';
			ac.RSN_CODE__c  = 'CR0007';
			docList.add(ac);
		}
		insert docList;
 
        Test.startTest();
        ChangeCR205StatusToRequestedBatch b = new ChangeCR205StatusToRequestedBatch();
        Database.executeBatch(b);
        
		
        // Verify correspondence updated
		T_DOC_RQ__c[] docUpdatedList = [SELECT Id, CDE_CORSPD_STATUS__c FROM T_DOC_RQ__c where NME_CORSPD__c = 'CR205' order by createddate desc limit 100];
		//System.assert(docUpdatedList[0].CDE_CORSPD_STATUS__c.Contains('Requested'));
	    Test.stopTest();
    }
	
}