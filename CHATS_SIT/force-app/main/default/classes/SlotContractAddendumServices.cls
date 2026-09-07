/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           06/29/2021                                                      
*  @description    Invoked by CustomLightningActionApxCtrl class                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 29-June-2021                                                            
*  * Author: Pragyan P. Nayak                                                     
*  * Description: Initial version       
*********************************************************************************************/
public with sharing class SlotContractAddendumServices {
    
    public static final string DRAFT = 'DFT';
    public static final string FINALIZED = 'FIN';
    
    public static LightningServerResponse finalizeSlotContractAddendumUpdate(String SCRecordId){ 
        List<T_SLOT_CONTRACT_ADDENDUM__c> SCAddRecList=[Select Id, DTE_BEGIN_ADDENDUM__c, DTE_END_ADDENDUM__c, CDE_STATUS__c from T_SLOT_CONTRACT_ADDENDUM__c where Id=:SCRecordId];
        List<T_SLOT_CONTRACT_ADDENDUM__c>existSCAddRecList=new List<T_SLOT_CONTRACT_ADDENDUM__c>();
        if(SCAddRecList.size()>0) {
            for(T_SLOT_CONTRACT_ADDENDUM__c scAddRec:SCAddRecList) {
                scAddRec.CDE_STATUS__c='FIN';
                existSCAddRecList.add(scAddRec);
            }
        }
        if(existSCAddRecList.size()>0) {
            try{    
                GenericDMLHandler.updateRecords(existSCAddRecList,new Map<String,Object>{'Method__c'=>'finalizeSlotContractAddendumUpdate','Class__c'=>'SlotContractAddendumServices'}); 
                //update existSCAddRecList;
            }
            catch(DMLException e){
                ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'slotContractAddendumServices','Method__c'=>'finalizeSlotContractAddendumUpdate'});
                return new LightningServerResponse(false, e.getDmlMessage(0), null);  
            } 
      
        }
        return new LightningServerResponse(true, Label.Record_updated_successfully, null);
    }

    @auraEnabled
    public static LightningServerResponse deleteSlotContractAddendumRecord(String recordId) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        try{
            if(!String.isBlank(recordId)){
                List<T_SLOT_CONTRACT_ADDENDUM__c> addendumList = [select id, IDN_FISCAL_AGREEMENT__c, CDE_COUNTY__c, CDE_COUNTY__r.Name from T_SLOT_CONTRACT_ADDENDUM__c where id = :recordId];               
                if(addendumList.size()>0){
                    Boolean countyMatched = CHATSUtility.checkCountyWithUserCounty(addendumList[0].CDE_COUNTY__c);
                    if(countyMatched){
                        isSuccessful = true;
                        message = 'Slot Contract Addendum deleted Successfully.';
                        objectData.put('redirect',true);
                        objectData.put('recordId',addendumList[0].IDN_FISCAL_AGREEMENT__c);
                        objectData.put('eventParams','{"recordId": "'+addendumList[0].IDN_FISCAL_AGREEMENT__c+'"}');
                        List<Id> recordIdsToBeDeleted = new List<Id>();
                        recordIdsToBeDeleted.add(recordId);
    
                        system.debug('Recoreds Deleted'+recordIdsToBeDeleted);
                        if(recordIdsToBeDeleted.size()>0) {
                            List<T_SLOT_CONTRACT__c> contractList = [select Id from T_SLOT_CONTRACT__c where IDN_ADDENDUM__c = :recordId];
                        	if(!contractList.isEmpty()){  
                            	SlotContractUtility.ALLOW_DELETE=true;
                            	GenericDMLHandler.deleteRecords(contractList,new Map<String,Object>{'Method__c'=>'deleteSlotContractAddendumRecord','Class__c'=>'SlotContractAddendumServices'}); 
                            	//delete contractList;
                       		}

                            system.debug('Records Id inside If'+recordIdsToBeDeleted);
                            GenericWithoutSharingDMLOperations.setRecordsIdsToBeDeleted(recordIdsToBeDeleted);
                            GenericWithoutSharingDMLOperations.deleteRecords(new Map<String, Object>{'Class__c'=>'SlotContractAddendumServices','Method__c'=>'deleteSlotContractAddendumRecord'});
                        }  

                    } else {
                        isSuccessful = false;
                        message = 'The Slot Contract Addendum record that you are trying to delete belongs to '+addendumList[0].CDE_COUNTY__r.Name+' county. This does not match your assigned county(ies).';
                    }
                }
            }
        }catch(Exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'SlotContractAddendumServices','Method__c'=>'deleteSlotContractAddendumRecord'});
            system.debug(e);
        }
        return new LightningServerResponse(isSuccessful,message,objectData); 
    }
    
    public static void beforeDeleteCheckAddendumStatus(List<T_SLOT_CONTRACT_ADDENDUM__c> deleteAddendumList) {
        for(T_SLOT_CONTRACT_ADDENDUM__c addenRec : deleteAddendumList) {
            if(addenRec.CDE_STATUS__c != DRAFT && addenRec.CDE_STATUS__c != FINALIZED) {
                addenRec.adderror('Slot Contract Addendum is not in Draft or Finalized Status, so cannot be deleted.');
            }
        }
    }
    
}