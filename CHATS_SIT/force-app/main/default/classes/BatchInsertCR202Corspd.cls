/**
* @author Raina Yeole
* 
* @verison 1.0
*
* Batch Class to insert CR202 Correspondence Request for Corrrespondence Creation
*
* @Change History
*
* 15/11/2022 - Initial version of BatchInsertCR202Corspd @version 1.0
*/

global class BatchInsertCR202Corspd implements Database.Batchable<sObject>{
   	global List<T_DOC_RQ__c> docs = new List<T_DOC_RQ__c>();
	global String year = String.valueOf(Date.today().year());
    
	global Database.QueryLocator start(Database.BatchableContext BC) {      
        String query = 'select id, name, Provider__c, Case__c, County__c, Adjustment__c, Adjustment__r.Outstanding_Recovery_Balance__c, Type__c,Responsible_Party_Id__c from Tax_Intercept__c where Tax_Year__c = :year and Intercept_Status__c = \'Active\' and Adjustment__r.Outstanding_Recovery_Balance__c > 25 order by Case__c';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Tax_Intercept__c> taxIntercept){
        for (Tax_Intercept__c tax: taxIntercept) {
            system.debug('[Output] Tax Interecept :' +tax);
            T_DOC_RQ__c doc = new T_DOC_RQ__c();
        
            // Provider
            if(!String.isBlank(tax.Provider__c)) {
                doc.IDN_PROVR__c = tax.Provider__c;
                doc.CDE_TYPE_RCPT__c = 'P';
            }
        
            // Case
            if(!String.isBlank(tax.Case__c)) {		
                doc.IDN_CASE__c = tax.Case__c;                
                doc.CDE_TYPE_RCPT__c = 'C';
            }
        
            if(!String.isEmpty(tax.Adjustment__c)) {
                doc.IDN_ADJMT__c = tax.Adjustment__c;   // Adjustment
            }
            if(!String.isEmpty(tax.County__c)) {
                doc.CDE_COUNTY__c = tax.County__c;     // County
            }
            doc.NME_CORSPD__c = 'CR202';
            doc.RSN_CODE__c = 'CR0024';
            doc.CDE_CORSPD_STATUS__c = 'Requested';
            doc.DTE_REQ__c = Date.today();
            doc.Responsible_Party_Id__c = tax.Responsible_Party_Id__c; // added for CCCAP-12508
            docs.add(doc);
            system.debug('[Output]  T_DOC_RQ__c :' +doc);
        }
        
        system.debug('[Output] Count T_DOC_RQ__c :' +docs.size());

        if(!docs.isEmpty()){
            Database.SaveResult[] saveResultList = Database.insert(docs, false);
            
            // Iterate through saveResultList based on isSuccess capture the failed records
            for (Database.SaveResult sr : saveResultList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted CR202 request. TDOC ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('TDOC fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}