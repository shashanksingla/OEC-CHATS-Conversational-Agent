public with sharing class SlotContractUtility {
    public static boolean ALLOW_DELETE=false;
    
    @AuraEnabled
    public static LightningServerResponse getSlotContractHistory(String recordId){
        T_SLOT_CONTRACT__c slotContract = [SELECT SLOT_CONTRACT_DESCRIPTION__c FROM T_SLOT_CONTRACT__c WHERE Id = :recordId];
            
        List<T_SLOT_CONTRACT__c> data = [SELECT Id, Name, IDN_AUTH__c, IDN_AUTH__r.Name, IND_AVAILABLE__c, toLabel(CDE_CARE_LEVEL__c), toLabel(CDE_CARE_UNIT__c),
                                         	SLOT_CONTRACT_DESCRIPTION__c, CNT_DAYS_OF_MONTH__c, toLabel(CDE_PRG_TYPE__c), toLabel(CDE_RATE_TYPE__c), DTE_BEGIN_SLOT__c, DTE_END_SLOT__c
                                          FROM T_SLOT_CONTRACT__c 
                                          WHERE SLOT_CONTRACT_DESCRIPTION__c = :slotContract.SLOT_CONTRACT_DESCRIPTION__c ORDER BY DTE_BEGIN_SLOT__c DESC];
        
        Map<String,Object> objectData = new Map<String,Object>();
        objectData.put('isSuccessful',true);
        objectData.put('data',data);
        return new LightningServerResponse(true,'Success',objectData);
    }
    public static void checkIfDeleteAllowed(List<T_SLOT_CONTRACT__c> slotContractList)
    {
        List<T_SLOT_CONTRACT__c> toDelete=new List<T_SLOT_CONTRACT__c>();
        for(T_SLOT_CONTRACT__c slotRec : slotContractList) {
            if(ALLOW_DELETE==false) {
                slotRec.adderror('You do not have permission to delete this record.');
            }else{
                toDelete.add(slotRec);
            }
        }
        if(toDelete.size()>0)
        {
            insertATSRecord(toDelete);
        }
    }
    public static void insertATSRecord(List<T_SLOT_CONTRACT__c> slotContractList) {
        List<batchsit_t_pos_trans_queue_ats__x> lstATSRecords = new List<batchsit_t_pos_trans_queue_ats__x>();
        Set<Id> providerIdset = new Set<Id>();
        Set<Id> countyIdset = new Set<Id>();
        Set<Id> authIdSet = new Set<Id>();
        Map<Id, String> providerIdtoNameMap = new Map<Id, String>();
        Map<Id, T_COUNTY__c> countyIdtoCountyMap = new Map<Id, T_COUNTY__c>();
        Map<Id, String> authIdtoNameMap = new Map<Id, String>();
        
        for(T_SLOT_CONTRACT__c sc : slotContractList) {
            providerIdset.add(sc.IDN_PROVIDER__c);
            countyIdset.add(sc.CDE_COUNTY__c);
            authIdSet.add(sc.IDN_AUTH__c);
        }
        for(T_CHATS_PROVR_STATUS__c provider : [Select Id, Name from T_CHATS_PROVR_STATUS__c where Id IN :providerIdset]){
            providerIdtoNameMap.put(provider.Id, provider.Name);
        }
        for(T_COUNTY__c county: [Select Id, Name, CDE_COUNTY__c from T_COUNTY__c where Id IN :countyIdset]){
            countyIdtoCountyMap.put(county.Id, county);
        }
        for(T_AUTH__c auth : [Select Id, Name from T_AUTH__c where Id IN :authIdSet]){
            authIdtoNameMap.put(auth.Id, auth.Name);
        }
        batchsit_t_pos_trans_queue_ats__x atsRecord;
        for(T_SLOT_CONTRACT__c sc : slotContractList) {
            atsRecord = new batchsit_t_pos_trans_queue_ats__x();
            atsRecord.CDE_STATUS_TRANS__c = '1';
            atsRecord.CDE_TYPE_TRANS__c = '9';
            if(sc.Name != null) {
                atsRecord.idn_slot_contract__c = sc.Name;  
                atsRecord.slot_contract_description__c = sc.SLOT_CONTRACT_DESCRIPTION__c; 
            }
            if(providerIdtoNameMap.containsKey(sc.IDN_PROVIDER__c)){
                atsRecord.IDN_PROVR__c = providerIdtoNameMap.get(sc.IDN_PROVIDER__c);
            }
            if(countyIdtoCountyMap.containsKey(sc.CDE_COUNTY__c)){
                atsRecord.CDE_COUNTY__c = String.valueOf(countyIdtoCountyMap.get(sc.CDE_COUNTY__c).CDE_COUNTY__c); 
            }
            if(sc.IDN_AUTH__c != null && authIdtoNameMap.containsKey(sc.IDN_AUTH__c)){
                atsRecord.IDN_AUTH__c = authIdtoNameMap.get(sc.IDN_AUTH__c);
            }
            atsRecord.DTE_CHANGE_LAST__c = system.today();
            lstATSRecords.add(atsRecord);            
        }
        if(!lstATSRecords.isEmpty()){
            ATSHandler.insertATSRecord(true, lstATSRecords);
        }
    }
    
    //method to update authorization begin date if slot is deleted
    public static void updateAuthSlotBegin(List<T_SLOT_CONTRACT__c> slotContractList){
        Map<id,id> authKeyVsSlot=new Map<id,id>();        
        for(T_SLOT_CONTRACT__c sc : slotContractList){            
            if(string.isNotBlank(sc.IDN_AUTH__c)){
                authKeyVsSlot.put(sc.IDN_AUTH__c, sc.id);
            }
        }
        
        List<T_AUTH__c> authListToUpdate = new List<T_AUTH__c>([SELECT id, IDN_SLOT_CONTRACT__c, DTE_BEGIN_SLOT__c 
                                                                FROM T_AUTH__c WHERE id in :authKeyVsSlot.keySet()]);
        
        if(authListToUpdate!=null && !authListToUpdate.isEmpty()){
            for(T_AUTH__c indAuth : authListToUpdate){ 
                if(indAuth.IDN_SLOT_CONTRACT__c == authKeyVsSlot.get(indAuth.id)){
                    indAuth.DTE_BEGIN_SLOT__c = null;
 
                }
            }
            GenericDMLHandler.updateRecords(authListToUpdate,new Map<String,Object>{'Method__c'=>'updateAuthSlotBegin','Class__c'=>'SlotContractUtility'});
        }
    }

}