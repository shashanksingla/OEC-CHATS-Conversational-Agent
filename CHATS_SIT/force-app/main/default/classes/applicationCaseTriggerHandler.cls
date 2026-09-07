public without sharing class applicationCaseTriggerHandler {

    /*
If a new Application is being received for a UFE Requested Application (reference: Referral Id), mark the UFE_Request_Flag__c on current.
Added for UFE by Shashank 08/14
*/
    public static void checkfor_UFE_Identifier(List<T_APPLN_CASE__c> newAppList){
        Map<String,T_APPLN_CASE__c> refVsApplication 		= new Map<String,T_APPLN_CASE__c>();
        Map<Id,T_APPLN_CASE__c> appsToUpdate 				= new Map<Id,T_APPLN_CASE__c>();
        Map<String,T_APPLN_CASE__c> UFE_BufferEmails 		= new Map<String,T_APPLN_CASE__c>();
        Map<Id,UFEChangeInterface__e> ufeInfoUpdateEventMap	= new Map<Id,UFEChangeInterface__e>();
        Map<Id,T_UFE_INDIV_EML__c> emToDelete				= new Map<Id,T_UFE_INDIV_EML__c>();
        
        for(T_APPLN_CASE__c app: newAppList){
            if(app.IDN_CBMS_REF__c!=null){
                refVsApplication.put(app.IDN_CBMS_REF__c,app);
            }
            if(app.CDE_INFO_EM__c!=null){
                UFE_BufferEmails.put(app.CDE_INFO_EM__c.toLowerCase(),app);
            }
        }
        // if matching Referral Id application exists with UFE Request flag as true, bring the UFE Request Flag to New App as well and fire PE.
        for(T_APPLN_CASE__c existingApp :[SELECT id,IDN_CBMS_REF__c FROM T_APPLN_CASE__c 
                                          WHERE IDN_CBMS_REF__c in :refVsApplication.keySet() AND UFE_Request_Flag__c=true])
        {
            T_APPLN_CASE__c currentApp = refVsApplication.get(existingApp.IDN_CBMS_REF__c);
            appsToUpdate.put(currentApp.Id, new T_APPLN_CASE__c(Id=currentApp.Id,UFE_Request_Flag__c=true));
            ufeInfoUpdateEventMap.put(currentApp.Id,new UFEChangeInterface__e(IdNumber__c=currentApp.Id,Type__c='application'));    
        }
        // if mathcing Email Id of new application exists in T_UFE_INDIV_EML__c then set UFE Request flag as true, delete the Email from T_UFE_INDIV_EML__c and fire PE.
        for(T_UFE_INDIV_EML__c ufeEmail : [select id,UFE_Email__c from T_UFE_INDIV_EML__c where UFE_Email__c in:UFE_BufferEmails.keyset()]){
            T_APPLN_CASE__c currentApp = UFE_BufferEmails.get(ufeEmail.UFE_Email__c.toLowerCase());
            appsToUpdate.put(currentApp.Id, new T_APPLN_CASE__c(Id=currentApp.Id,UFE_Request_Flag__c=true));
            emToDelete.put(ufeEmail.Id,ufeEmail);
            ufeInfoUpdateEventMap.put(currentApp.Id,new UFEChangeInterface__e(IdNumber__c=currentApp.Id,Type__c='application'));
        }
        if(!emToDelete.isEmpty()){
            GenericDMLHandler.deleteRecords(emToDelete.values(), new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_UFE_INDIV_EML__c'},'Method__c'=>'checkfor_UFE_Identifier','Class__c'=>'applicationCaseTriggerHandler'});
        }
        if(!appsToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(appsToUpdate.values(), new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_APPLN_CASE__c'},'Method__c'=>'checkfor_UFE_Identifier','Class__c'=>'applicationCaseTriggerHandler'});
        }
        Eventbus.publish(ufeInfoUpdateEventMap.values());
    }
}