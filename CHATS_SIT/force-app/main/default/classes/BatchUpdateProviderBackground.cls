/**
* @author Raina Yeole
* 
* @verison 1.0
*
* Batch Class to Update the Provider Background Check from Cleared to In Progress 
* when there is a QE Home Provider Fiscal Agreement which is end dating 60 days from today()
*
* @Change History
*
* 02/08/2023 - Initial version of BatchUpdateProviderBackground @version 1.0
@version 2.0 changed the logic to consider 90 days from 60 days.
*/

global class BatchUpdateProviderBackground implements Database.Batchable<sObject>{
    
    global List<T_PROVR_CBC__c> CBCToUpdate = new List<T_PROVR_CBC__c>();
    
	global Database.QueryLocator start(Database.BatchableContext BC) {     
        Date today = Date.today()+90; // Changin to 90 as part of CCCAP-13931
        String query = 'select id,ID_SERVICE__r.CDE_TYPE_PROVR__c from T_PROVR_FISCAL_AGREMENT__c where DTE_END_AGRMT__c =: today AND (CDE_TYPE_STATUS__c = \'FIN\' OR CDE_TYPE_STATUS__c = \'OPN\') AND ID_SERVICE__r.CDE_TYPE_PROVR__c=\'EFACH\' AND ID_SERVICE__r.CDE_REQ_BGC_CHK_STATE__c = \'Cleared\' AND ID_SERVICE__r.CDE_STATUS_PROVR__c = \'Open\'';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<T_PROVR_FISCAL_AGREMENT__c> FiscalAgreement){
        Map<Id,T_PROVR_CBC__c> providerCBCMap = new Map<Id,T_PROVR_CBC__c>(); // CCCAP-9318
        set<Id> provrRcrdId = new set<Id>();
        
        for(T_PROVR_FISCAL_AGREMENT__c PFA : FiscalAgreement) {
            if(!String.isBlank(PFA.ID_SERVICE__c)) {
                provrRcrdId.add(PFA.ID_SERVICE__c);
            }
        }
        //CCCAP-9318
        for(T_PROVR_CBC__c ProvrCBC : [select Id, IDN_PROVR__c,CDE_BGC_CHK_STATUS__c,createdDate FROM T_PROVR_CBC__c where IDN_PROVR__c IN:provrRcrdId order by createdDate desc ]){
            if(!String.isBlank(ProvrCBC.IDN_PROVR__c) && ProvrCBC.CDE_BGC_CHK_STATUS__c == 'Cleared'){
                if(providerCBCMap.containsKey(ProvrCBC.IDN_PROVR__c)){
                    if (providerCBCMap.get(ProvrCBC.IDN_PROVR__c).createdDate < ProvrCBC.createdDate){
                    providerCBCMap.put(ProvrCBC.IDN_PROVR__c,ProvrCBC);
                    }
                }else{
                    providerCBCMap.put(ProvrCBC.IDN_PROVR__c,ProvrCBC);
                }
                
            }
        }
        for(T_PROVR_CBC__c ProvrCBC:providerCBCMap.values()){
            ProvrCBC.CDE_BGC_CHK_STATUS__c = 'In Progress';
            CBCToUpdate.add(ProvrCBC);
        }
        //END CCCAP-9318
        if(!CBCToUpdate.isEmpty()){
            Database.SaveResult[] saveResultList = Database.update(CBCToUpdate, false);
            
            // Iterate through saveResultList based on isSuccess capture the failed records
            for (Database.SaveResult sr : saveResultList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Update the Provider ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Provider fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
    }
}