public with sharing class ParentFeeDelinquencyCntrl {
    
    @AuraEnabled
    public static authCopayWrapper getDoInit(String recordId){
        batchsit_t_auth_copay__x authCopayObj = new batchsit_t_auth_copay__x();
        authCopayWrapper wrap = new authCopayWrapper();
        if(!String.isBlank(recordId)){
            for( batchsit_t_auth_copay__x authCopayObjTemp : [Select id,ExternalId,idn_copay_auth__c from batchsit_t_auth_copay__x where id=:recordId]){
                authCopayObj = authCopayObjTemp;
            } 
            if(authCopayObj != null){
                wrap.authCopay = authCopayObj;
            }
            wrap.authCopay = authCopayObj;
            wrap.loggedInUserId =UserInfo.getUserId();
            wrap.loggedUserName =UserInfo.getName();
            wrap.getSobjectName =CHATSAuraUtility.getSobjectName(recordId);
        }
        return wrap;
    }
    
    @AuraEnabled
    public static LightningServerResponse saveParentFeeDelinq(T_COPAY_DELINQC__c newParentFeeDelinquencyObj){
        List<batchsit_t_auth_copay__x> authCopayObj = new List<batchsit_t_auth_copay__x>();
        Map<String, Object> objectData = new map<String, Object>();
        List<SObject> lstSObject = new List<SObject>();
        if(newParentFeeDelinquencyObj != null){
            authCopayObj = [Select id,ExternalId,idn_copay_auth__c from batchsit_t_auth_copay__x where id=:newParentFeeDelinquencyObj.IDN_COPAY_AUTH__c];
            if(authCopayObj.size()>0){
                newParentFeeDelinquencyObj.IDN_COPAY_AUTH__c =String.valueOf(authCopayObj[0].idn_copay_auth__c);
            }
            lstSObject.add(newParentFeeDelinquencyObj);
            system.debug('newParentFeeDelinquencyObj--'+newParentFeeDelinquencyObj);
        }
        if(lstSObject.size()>0){
            return GenericDataSaverApxCtrl.upsertRecordsFinal(lstSObject,true);
        }
        return new LightningServerResponse(true,'Message',objectData);
    }
    
    public class authCopayWrapper {
        @AuraEnabled public batchsit_t_auth_copay__x authCopay;
        @AuraEnabled public T_COPAY_DELINQC__c copayDelinq;
        @AuraEnabled public Id loggedInUserId;
        @AuraEnabled public String loggedUserName;
        @AuraEnabled public String authCopayId;
        @AuraEnabled public String getSobjectName;
        public authCopayWrapper(batchsit_t_auth_copay__x authCopay,String loggedInUserId, T_COPAY_DELINQC__c copayDelinq, String authCopayId,String loggedUserName,String getSobjectName){
            this.authCopay = authCopay;
            this.loggedInUserId = loggedInUserId;
            this.copayDelinq = copayDelinq;
            this.authCopayId = authCopayId;
            this.getSobjectName = getSobjectName;
            this.loggedUserName = loggedUserName;
        }
        
        public authCopayWrapper(){
        /** 
   		* Creates instance of {@authCopayWrapper}. Used for calling the default constructor explicitly
   		*/    
        }
    }
}