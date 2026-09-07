public with sharing class ContactServices {

    public Static void upsertIndividualPIN(list<Contact> lstOfContactRecords){
        try {
        
        set<string> indivIdsList = new set<string>();
        list<string> indivSfid = new list<string>();
        map<string,string> clientIdtoSfidMap = new map<string,string>(); 
        map<string, T_SBSD_INDIV_PIN_INFO__c> clientToIndivPinInfo = new map<string, T_SBSD_INDIV_PIN_INFO__c>();
        list<T_SBSD_INDIV_PIN_INFO__c> listOfPINInfoRecordsForUpdate = new list<T_SBSD_INDIV_PIN_INFO__c>();
        list<T_SBSD_INDIV_PIN_INFO__c> listOfPINInfoRecordsForInsert = new list<T_SBSD_INDIV_PIN_INFO__c>();
        list<Id> listOfContactsToDelete = new list<Id>();
        
        for(Contact eachContact: lstOfContactRecords) {
            if(eachContact.CI_Client_Id__c != null){
                //indivIdsList.add(string.valueOf(eachContact.CI_Client_Id__c));
                indivIdsList.add(string.valueOf(eachContact.Client_ID_String__c));
            }
        }
        for(T_SBSD_INDIV__c eachIndiv : [select Id, Name from T_SBSD_INDIV__c where Name in:indivIdsList]){
            indivSfid.add(eachIndiv.Id);
            clientIdtoSfidMap.put(eachIndiv.Name, eachIndiv.Id);
        }
        for(T_SBSD_INDIV_PIN_INFO__c eachPinInfo: [select Id, IDN_CLIENT__c, Last_Successful_Login__c, Pin_Reset_Code_Generated_Time__c, PIN_Status__c FROM T_SBSD_INDIV_PIN_INFO__c WHERE IDN_CLIENT__c in:indivSfid]){
            clientToIndivPinInfo.put(eachPinInfo.IDN_CLIENT__c, eachPinInfo );
        }
        
        for(Contact eachcntct : lstOfContactRecords){
            if(eachcntct.CI_Client_Id__c != null){
                if(clientToIndivPinInfo.ContainsKey(clientIdtoSfidMap.get(eachcntct.Client_ID_String__c))){
                    T_SBSD_INDIV_PIN_INFO__c PINInfoRecordforUpdate = new T_SBSD_INDIV_PIN_INFO__c();
                    PINInfoRecordforUpdate.Id = clientToIndivPinInfo.get(clientIdtoSfidMap.get(eachcntct.Client_ID_String__c)).Id;
                    PINInfoRecordforUpdate.IDN_CLIENT__c = clientToIndivPinInfo.get(clientIdtoSfidMap.get(eachcntct.Client_ID_String__c)).IDN_CLIENT__c;
                    PINInfoRecordforUpdate.Last_Successful_Login__c = eachcntct.Last_Successful_Login__c;
                    PINInfoRecordforUpdate.Pin_Reset_Code_Generated_Time__c = eachcntct.Pin_Reset_Code_Generated_Time__c;
                    PINInfoRecordforUpdate.PIN_Status__c = eachcntct.PIN_Status__c;
                    listOfPINInfoRecordsForUpdate.add(PINInfoRecordforUpdate);
                    listOfContactsToDelete.add(eachcntct.Id);
                } else {
                    T_SBSD_INDIV_PIN_INFO__c PINInfoRecordforInsert = new T_SBSD_INDIV_PIN_INFO__c();
                    PINInfoRecordforInsert.IDN_CLIENT__c = clientIdtoSfidMap.get(eachcntct.Client_ID_String__c);
                    PINInfoRecordforInsert.Last_Successful_Login__c = eachcntct.Last_Successful_Login__c;
                    PINInfoRecordforInsert.Pin_Reset_Code_Generated_Time__c = eachcntct.Pin_Reset_Code_Generated_Time__c;
                    PINInfoRecordforInsert.PIN_Status__c = eachcntct.PIN_Status__c;
                    listOfPINInfoRecordsForInsert.add(PINInfoRecordforInsert);
                    listOfContactsToDelete.add(eachcntct.Id);
                }
            }else {
                listOfContactsToDelete.add(eachcntct.Id);
            }
            
        }
        
        
        if(!listOfPINInfoRecordsForInsert.isEmpty()){
            GenericDMLHandler.insertRecords(listOfPINInfoRecordsForInsert,false,new Map<String,Object>{'Method__c'=>'upsertIndividualPIN','Class__c'=>'ContactServices'});
        }
        if(!listOfPINInfoRecordsForUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(listOfPINInfoRecordsForUpdate,false,new Map<String,Object>{'Method__c'=>'upsertIndividualPIN','Class__c'=>'ContactServices'});
        }
        if(!listOfContactsToDelete.isEmpty()){
            if(!Test.isRunningTest()){
                Database.DELETE(listOfContactsToDelete);    
            }
        }
        } catch (Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String, Object>{'Class__c' => 'ContactServices', 'Method__c' => 'upsertIndividualPIN'});
        }
    }

}