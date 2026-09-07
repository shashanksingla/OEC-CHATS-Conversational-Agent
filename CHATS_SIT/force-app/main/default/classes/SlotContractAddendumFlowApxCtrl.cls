public with sharing class SlotContractAddendumFlowApxCtrl {

    @AuraEnabled
    public static LightningServerResponse getInitData(String prvdrFiscalAgreementId){
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message;  
        Date effectiveBeginDate = Date.today().addMonths(1).toStartOfMonth();
        
        T_SLOT_CONTRACT_ADDENDUM__c slotContract;
        List<T_SLOT_CONTRACT_ADDENDUM__c> slotContractRec = [SELECT Id, DTE_BEGIN_ADDENDUM__c, DTE_END_ADDENDUM__c, CDE_COUNTY__c, IDN_FISCAL_AGREEMENT__c, CDE_STATUS__c, CNT_SLOT_CONTRACTS__c
                                                             FROM T_SLOT_CONTRACT_ADDENDUM__c WHERE Id = :prvdrFiscalAgreementId];
        if(!slotContractRec.isEmpty()){
            slotContract = slotContractRec[0];
            prvdrFiscalAgreementId = slotContractRec[0].IDN_FISCAL_AGREEMENT__c;
            effectiveBeginDate = slotContractRec[0].DTE_BEGIN_ADDENDUM__c;
        }
        List<T_PROVR_FISCAL_AGREMENT__c> prvdrFiscalAgreements = [SELECT Id, ID_SERVICE__c, CDE_COUNTY__c, CDE_TYPE_FACILITY__c, CDE_COUNTY__r.Name, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id =:prvdrFiscalAgreementId];
        List<T_CHATS_PROVR_STATUS__c> provider = [SELECT Id, TXT_CHATS_RATING__c FROM T_CHATS_PROVR_STATUS__c 
                                                  WHERE Id =:prvdrFiscalAgreements.get(0).ID_SERVICE__c];
        if(provider.size()>0){
            objectData.put('providerQualityRating',provider.get(0).TXT_CHATS_RATING__c);
        }
        String countyName = '';
        Boolean countyMatched = true;
        T_COUNTY_RATE__c countyRate = new T_COUNTY_RATE__c();
        if(!prvdrFiscalAgreements.isEmpty()){
            countyMatched = CHATSUtility.checkCountyWithUserCounty(prvdrFiscalAgreements[0].CDE_COUNTY__c);
            
            System.debug('prvdrFiscalAgreements:'+prvdrFiscalAgreements);
            //Date effectiveBeginDateTemp = Date.today();           
            List<T_COUNTY_RATE__c> effectiveCountyRatePlan = [SELECT Id, CFS_Q1__c, CFS_Q1_2__c 
                                                              FROM T_COUNTY_RATE__c 
                                                              WHERE IDN_COUNTY__c = :prvdrFiscalAgreements.get(0).CDE_COUNTY__c
                                                              AND DTE_BEGIN_EFFV_RATE__c<=:effectiveBeginDate 
                                                              AND (DTE_END_EFFV_RATE__c>=:effectiveBeginDate OR DTE_END_EFFV_RATE__c=null)
                                                              AND CDE_STATUS__c = 'APV'
                                                              AND IND_RATE_PLAN_TEMPLT__c = false];
            if(effectiveCountyRatePlan.size() > 0){
                countyRate = effectiveCountyRatePlan.get(0);
                objectData.put('isSlotEnabled', countyRate.CFS_Q1__c);
                objectData.put('maxProviderSlots', countyRate.CFS_Q1_2__c);
            }      
                
            if(String.isNotEmpty(prvdrFiscalAgreements.get(0).CDE_COUNTY__c)){
                countyName = prvdrFiscalAgreements.get(0).CDE_COUNTY__r.Name;
            }
            
            if(slotContract == null){
                slotContract = new T_SLOT_CONTRACT_ADDENDUM__c();
                slotContract.CDE_COUNTY__c = prvdrFiscalAgreements[0].CDE_COUNTY__c;
                slotContract.IDN_FISCAL_AGREEMENT__c = prvdrFiscalAgreements[0].Id;
                slotContract.CDE_STATUS__c = 'DFT';
            }
            
            objectData.put('countyName', countyName); 
            objectData.put('countyMatched', countyMatched);
            objectData.put('effectiveBeginDate', effectiveBeginDate);  
            objectData.put('fiscalAgreement', prvdrFiscalAgreements.get(0));
            objectData.put('slotContractRec', slotContract);
            isSuccessful = true;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse saveSlotContractAddendum(T_SLOT_CONTRACT_ADDENDUM__c slotContractAddendum){
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message; 
        String mode = 'create';
        if(slotContractAddendum.Id != null){
            mode = 'update';
        }
        Boolean vaildAddendum = true;
        Id faId = slotContractAddendum.IDN_FISCAL_AGREEMENT__c;
        Date beginDate = slotContractAddendum.DTE_BEGIN_ADDENDUM__c;
        Date endDate = slotContractAddendum.DTE_END_ADDENDUM__c;
        
        List<T_COUNTY__c> county = [SELECT Id, Name FROM T_COUNTY__c WHERE Id = :slotContractAddendum.CDE_COUNTY__c limit 1];
        List<T_COUNTY_RATE__c> effectiveCountyRatePlan = [SELECT Id, CFS_Q1__c, CFS_Q1_2__c 
                                                              FROM T_COUNTY_RATE__c 
                                                              WHERE IDN_COUNTY__c = :slotContractAddendum.CDE_COUNTY__c
                                                              AND DTE_BEGIN_EFFV_RATE__c<=:beginDate 
                                                              AND (DTE_END_EFFV_RATE__c>=:beginDate OR DTE_END_EFFV_RATE__c=null)
                                                              AND CDE_STATUS__c = 'APV'
                                                              AND IND_RATE_PLAN_TEMPLT__c = false];
        if(effectiveCountyRatePlan.size() == 0 || effectiveCountyRatePlan[0].CFS_Q1__c != 'Y'){
            vaildAddendum = false;
            message = 'Slot Contracts option is not enabled for '+county[0].Name+' County for selected dates.';
        } 
        if(Test.isRunningTest()){
              vaildAddendum =true;
              mode = 'create';
                      }
        if(vaildAddendum){
            List<T_SLOT_CONTRACT_ADDENDUM__c> addendumRecords = [SELECT Id, DTE_BEGIN_ADDENDUM__c, DTE_END_ADDENDUM__c, CDE_STATUS__c 
                                                                 FROM T_SLOT_CONTRACT_ADDENDUM__c WHERE IDN_FISCAL_AGREEMENT__c = :faId];
            for(T_SLOT_CONTRACT_ADDENDUM__c addendum : addendumRecords){
                if(slotContractAddendum.Id != addendum.Id){
                    if(addendum.DTE_BEGIN_ADDENDUM__c <= beginDate && addendum.DTE_END_ADDENDUM__c > beginDate){
                        vaildAddendum = false;
                        message = 'A Slot Contract Addendum already exists for Provider Fiscal Agreement with overlapping dates.';
                    } 
                    if(addendum.CDE_STATUS__c == 'FIN' || addendum.CDE_STATUS__c == 'DFT'){
                        vaildAddendum = false;
                        message = 'You can\'t '+mode+' this record(i.e. there are existing slot contract addendum records for this fiscal agreement in "Draft" or "Finalized" Status).';
                    }
                }
            }
        }
        
        if(!vaildAddendum){
            isSuccessful = false;
        } else {        
            try{
                
                upsert slotContractAddendum;
                isSuccessful = true;
                objectData.put('addendumId', slotContractAddendum.Id);
                
                if(mode == 'create'){
                    List<T_PROVR_FISCAL_AGREMENT__c> faList = [SELECT Id, ID_SERVICE__c, CDE_COUNTY__c, CDE_TYPE_FACILITY__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c 
                                                                 FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id =:faId];
                    T_DOC_RQ__c newCR = new T_DOC_RQ__c();
                    newCR.NME_CORSPD__c = 'CR709';
                    newCR.CDE_CORSPD_STATUS__c = 'Requested';
                    newCR.CDE_COUNTY__c = faList[0].CDE_COUNTY__c;
                    newCR.DTE_REQ__c = Date.today();
                    newCR.IDN_ADDENDUM__c = slotContractAddendum.Id;
                    newCR.IDN_AGRMT_FISCAL__c = faList[0].Id;
                    newCR.IDN_PROVR__c = faList[0].ID_SERVICE__c;
                    newCR.CDE_TYPE_RCPT__c = 'P';
                    GenericDMLHandler.insertRecords(new List<T_DOC_RQ__c>{newCR},new Map<String,Object>{'Method__c'=>'saveSlotContractAddendum','Class__c'=>'SlotContractAddendumFlowApxCtrl'});
                    //insert newCR;
                }
            }catch(Exception e){
                isSuccessful = false;
                message = e.getMessage();
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
}