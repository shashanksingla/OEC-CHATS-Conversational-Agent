/*********************************************************************************************
*  Modification Log:
*
*  * Updating lstAccRcrdsToDelete field name with lstAccRecToDel : Shubham K -5/13
*  * Updating size and null check before DML Operation on line number 95 : Shubham K -5/14
*  * CCCAP-4831: Quality Rating is Continously updated FROM Level 1 to Blank for every update on the Provider Record.
*                Quality Rating will be Blank in CHATS for Exempt Providers.
*  * CCCAP-7502: FLS Update will not work with 'Connection User' which processes ATS data
*********************************************************************************************/
public with sharing class AccountServices {
    
    public Static void chatProvrUpd(list<Account> lstAccounts){
        try {
        System.debug('[AccountServices.chatProvrUpd]--In Account Service');
        Set<String> provrId = new Set<String>();
        //Removed unused variable on 5/13/2018 BG
        List<Account> lstAccRecToDel = new List<Account>();
        List<Id> lstAccountIdsToDelete = new List<Id>();
        Map<String, Account> accMap = new Map<String, Account>();
        //Removed unused variable on 5/13/2018 BG
        Map<Id, T_CHATS_PROVR_STATUS__c> provrUpdMap = new Map<Id, T_CHATS_PROVR_STATUS__c>();
        List<T_CHATS_PROVR_STATUS__c> lstProvrInsert = new List<T_CHATS_PROVR_STATUS__c>();
        List<T_CHATS_PROVR_STATUS__c> newProvrUpdList = new List<T_CHATS_PROVR_STATUS__c>();
        Map<String, String> servicetypeCodes = new map <String, String>{'DCC' => 'CCC', 'LDCH' => 'LFCH', 'DCH' => 'FCCH', 'DCH3' => 'FCCH3'};
            Set<String> countySet = new Set<String>();
        Map<String, Id> countySfidMap = new Map<String, Id>();
        String lcnNmbr;
        Set<String> exemptProvidersSet = new Set<String>{'DEFAB','DEFAH','EFACH'};
            
            for(Account eachAccount: lstAccounts){
                if(eachAccount.License_Number__c != NULL){
                    String licNmbr =  String.valueOf(eachAccount.License_Number__c);
                    accMap.put(licNmbr, eachAccount);
                    countySet.add(eachAccount.County_Lookup__c);
                }
            }
        
        for(T_COUNTY__C eachCounty : [SELECT Id, Name FROM T_COUNTY__C WHERE Name IN :countySet WITH SECURITY_ENFORCED]) {
            countySfidMap.put(eachCounty.Name , eachCounty.Id);
        }
        System.debug('[AccountServices.chatProvrUpd]--accMap.size()-->'+accMap.size());
        for(T_CHATS_PROVR_STATUS__c eachProvr: [SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c WHERE Name IN:accMap.keySet() WITH SECURITY_ENFORCED]){
            if(accMap.get(eachProvr.Name) != NULL){
                eachProvr.DTE_END_EFFV__c = accMap.get(eachProvr.Name).License_Expiration_Date__c; //This is License Closed Date FROM OEC
                eachProvr.DTE_BEGIN_EFFV__c = accMap.get(eachProvr.Name).License_Effective_Date__c;
                eachProvr.CDE_STATUS_PROVR__c = accMap.get(eachProvr.Name).Licensing_Status__c;
                eachProvr.CDE_TYPE_LICENSE__c = accMap.get(eachProvr.Name).License_Certification_Type__c;
                eachProvr.OwnerId = accMap.get(eachProvr.Name).OwnerId;
                eachProvr.CDE_COUNTY_OWNER__c = countySfidMap.get(accMap.get(eachProvr.Name).County_Lookup__c);
                eachProvr.NBR_PHONE_PRIM__c = accMap.get(eachProvr.Name).Phone_Program_Site_Phone__c;
                eachProvr.ADR_EMAIL__c = accMap.get(eachProvr.Name).Primary_Email__c;
                eachProvr.Name = String.valueOf(accMap.get(eachProvr.Name).License_Number__c);
                if(accMap.get(eachProvr.Name).Monday_Start_Time__c != Null && accMap.get(eachProvr.Name).Monday_End_Time__c != Null){
                    eachProvr.Operation_Hours_on_Monday__c = accMap.get(eachProvr.Name).Monday_Start_Time__c + ' ' + 'to' + ' ' + accMap.get(eachProvr.Name).Monday_End_Time__c;
                } else {
                    eachProvr.Operation_Hours_on_Monday__c = Null;
                }
                if(accMap.get(eachProvr.Name).Tuesday_Start_Time__c != Null && accMap.get(eachProvr.Name).Tuesday_End_Time__c != Null){
                    eachProvr.Operation_Hours_on_Tuesday__c = accMap.get(eachProvr.Name).Tuesday_Start_Time__c + ' ' + 'to' + ' ' + accMap.get(eachProvr.Name).Tuesday_End_Time__c;
                } else {
                    eachProvr.Operation_Hours_on_Tuesday__c = Null;
                }
                if(accMap.get(eachProvr.Name).Wednesday_Start_Time__c != Null && accMap.get(eachProvr.Name).Wednesday_End_Time__c != Null){
                    eachProvr.Operation_Hours_on_Wednesday__c = accMap.get(eachProvr.Name).Wednesday_Start_Time__c + ' ' + 'to' + ' ' + accMap.get(eachProvr.Name).Wednesday_End_Time__c;
                } else {
                    eachProvr.Operation_Hours_on_Wednesday__c = Null;
                }
                if(accMap.get(eachProvr.Name).Thursday_Start_Time__c != Null && accMap.get(eachProvr.Name).Thursday_End_Time__c != Null){
                    eachProvr.Operation_Hours_on_Thursday__c = accMap.get(eachProvr.Name).Thursday_Start_Time__c + ' ' + 'to' + ' ' + accMap.get(eachProvr.Name).Thursday_End_Time__c;
                } else {
                    eachProvr.Operation_Hours_on_Thursday__c = Null;
                }
                if(accMap.get(eachProvr.Name).Friday_Start_Time__c != Null && accMap.get(eachProvr.Name).Friday_End_Time__c != Null){
                    eachProvr.Operation_Hours_on_Friday__c = accMap.get(eachProvr.Name).Friday_Start_Time__c + ' ' + 'to' + ' ' + accMap.get(eachProvr.Name).Friday_End_Time__c;
                } else {
                    eachProvr.Operation_Hours_on_Friday__c = Null;
                }
                if(accMap.get(eachProvr.Name).Saturday_Start_Time__c != Null && accMap.get(eachProvr.Name).Saturday_End_Time__c != Null){
                    eachProvr.Operation_Hours_on_Saturday__c = accMap.get(eachProvr.Name).Saturday_Start_Time__c + ' ' + 'to' + ' ' + accMap.get(eachProvr.Name).Saturday_End_Time__c;
                } else {
                    eachProvr.Operation_Hours_on_Saturday__c = Null;
                }
                if(accMap.get(eachProvr.Name).Sunday_Start_Time__c != Null && accMap.get(eachProvr.Name).Sunday_Start_Time__c != Null){
                    eachProvr.Operation_Hours_on_Sunday__c = accMap.get(eachProvr.Name).Sunday_Start_Time__c + ' ' + 'to' + ' ' + accMap.get(eachProvr.Name).Sunday_End_Time__c;
                } else {
                    eachProvr.Operation_Hours_on_Sunday__c = Null;
                }
                eachProvr.NAM_FACILITY__c = accMap.get(eachProvr.Name).Name;
                if(exemptProvidersSet.contains(accMap.get(eachProvr.Name).Service_Type__c)){
                    eachProvr.TXT_CHATS_RATING__c = '';
                } else {
                    eachProvr.TXT_CHATS_RATING__c = accMap.get(eachProvr.Name).QRIS_Rating__c;
                }
                eachProvr.ADR_LINE1__c = accMap.get(eachProvr.Name).BillingStreet;
                eachProvr.ADR_LINE1_MLNG__c = accMap.get(eachProvr.Name).ShippingStreet;
                eachProvr.ADR_STATE__c = accMap.get(eachProvr.Name).BillingState;
                eachProvr.ADR_STATE_MLNG__c = accMap.get(eachProvr.Name).ShippingState;
                eachProvr.ADR_ZIP__c = accMap.get(eachProvr.Name).BillingPostalCode;
                eachProvr.ADR_ZIP_MLNG__c = accMap.get(eachProvr.Name).ShippingPostalCode;
                eachProvr.ADR_CITY__c = accMap.get(eachProvr.Name).BillingCity;
                eachProvr.ADR_CITY_MLNG__c = accMap.get(eachProvr.Name).ShippingCity;
                eachProvr.Last_Contact_Date__c = accMap.get(eachProvr.Name).Last_Contact_Date__c;
                if(servicetypeCodes.ContainsKey(accMap.get(eachProvr.Name).Service_Type__c) ) {
                    eachProvr.CDE_TYPE_PROVR__c = servicetypeCodes.get(accMap.get(eachProvr.Name).Service_Type__c);
                } else {
                    eachProvr.CDE_TYPE_PROVR__c = accMap.get(eachProvr.Name).Service_Type__c;
                }
                eachProvr.Is_UPK_Provider__c = accMap.get(eachProvr.Name).Is_UPK_Provider__c; // added for CCCAP-15329,CCCAP-15350
            
                if(accMap.get(eachProvr.Name).SSN_FEIN__c != null){
                    String ssn = accMap.get(eachProvr.Name).SSN_FEIN__c;
                    if(String.isNotEmpty(ssn)){
                        if(ssn.length()>9 && ssn.contains('.')){
                            ssn = ssn.split('\\.')[0];
                        }
                        ssn = ssn.replaceAll('[^a-zA-Z0-9]', '');
                    }
                    eachProvr.NBR_SSN__c = ssn;
                } else {
                    eachProvr.NBR_SSN__c = accMap.get(eachProvr.Name).SSN_FEIN__c;
                }
                eachProvr.NBR_FEIN__c = accMap.get(eachProvr.Name).FEIN__c;
                eachProvr.External_ID__c = String.valueOf(accMap.get(eachProvr.Name).License_Number__c);
                if(accMap.get(eachProvr.Name).Program_Name__c != NULL){
                    eachProvr.Program_Name__c = accMap.get(eachProvr.Name).Program_Name__c;
                }
                eachProvr.Slot_Contract_Suggestion__c = accMap.get(eachProvr.Name).Slot_Contract_Suggestion__c;
                provrUpdMap.put(eachProvr.Id, eachProvr);
                provrId.add(eachProvr.Name);
                //Moving the records into the list to delete FROM Account Object
                lstAccRecToDel.add(accMap.get(eachProvr.Name));
                lstAccountIdsToDelete.add(accMap.get(eachProvr.Name).Id);
            }    
        }
        
        for(Account eachAccInsert : lstAccounts){
            System.debug('[AccountServices.chatProvrUpd]--insertion reached');
            lcnNmbr = String.valueOf(eachAccInsert.License_Number__c);
            System.debug('[AccountServices.chatProvrUpd]--provrId.size()-->'+provrId.size());
            System.debug('[AccountServices.chatProvrUpd]--lcnNmbr-->'+lcnNmbr);
            if(!provrId.contains(lcnNmbr)){
                System.debug('[AccountServices.chatProvrUpd]--In insert-->'+String.valueOf(eachAccInsert.License_Number__c));
                T_CHATS_PROVR_STATUS__c newProvRec = new T_CHATS_PROVR_STATUS__c();
                newProvRec.DTE_END_EFFV__c = eachAccInsert.License_Expiration_Date__c; //This is License Closed Date FROM OEC
                newProvRec.DTE_BEGIN_EFFV__c = eachAccInsert.License_Effective_Date__c;
                newProvRec.CDE_STATUS_PROVR__c = eachAccInsert.Licensing_Status__c;
                newProvRec.CDE_TYPE_LICENSE__c = eachAccInsert.License_Certification_Type__c;
                newProvRec.OwnerId = eachAccInsert.OwnerId;
                newProvRec.CDE_COUNTY_OWNER__c = countySfidMap.get(eachAccInsert.County_Lookup__c);
                newProvRec.NBR_PHONE_PRIM__c = eachAccInsert.Phone_Program_Site_Phone__c;
                newProvRec.ADR_EMAIL__c = eachAccInsert.Primary_Email__c;
                newProvRec.Name =  String.valueOf(eachAccInsert.License_Number__c);
                if(eachAccInsert.Monday_Start_Time__c != Null && eachAccInsert.Monday_End_Time__c != Null){
                    newProvRec.Operation_Hours_on_Monday__c = eachAccInsert.Monday_Start_Time__c + ' ' + 'to' + ' ' + eachAccInsert.Monday_End_Time__c;
                } else {
                    newProvRec.Operation_Hours_on_Monday__c = Null;
                }
                if(eachAccInsert.Tuesday_Start_Time__c != Null && eachAccInsert.Tuesday_End_Time__c != Null){
                    newProvRec.Operation_Hours_on_Tuesday__c = eachAccInsert.Tuesday_Start_Time__c + ' ' + 'to' + ' ' + eachAccInsert.Tuesday_End_Time__c;
                } else {
                    newProvRec.Operation_Hours_on_Tuesday__c = Null;
                }
                if(eachAccInsert.Wednesday_Start_Time__c != Null && eachAccInsert.Wednesday_End_Time__c != Null){
                    newProvRec.Operation_Hours_on_Wednesday__c = eachAccInsert.Wednesday_Start_Time__c + ' ' + 'to' + ' ' + eachAccInsert.Wednesday_End_Time__c;
                } else {
                    newProvRec.Operation_Hours_on_Wednesday__c = Null;
                }
                if(eachAccInsert.Thursday_Start_Time__c != Null && eachAccInsert.Thursday_End_Time__c != Null){
                    newProvRec.Operation_Hours_on_Thursday__c = eachAccInsert.Thursday_Start_Time__c + ' ' + 'to' + ' ' + eachAccInsert.Thursday_End_Time__c;
                } else {
                    newProvRec.Operation_Hours_on_Thursday__c = Null;
                }
                if(eachAccInsert.Friday_Start_Time__c != Null && eachAccInsert.Friday_End_Time__c != Null){
                    newProvRec.Operation_Hours_on_Friday__c = eachAccInsert.Friday_Start_Time__c + ' ' + 'to' + ' ' + eachAccInsert.Friday_End_Time__c;
                } else {
                    newProvRec.Operation_Hours_on_Friday__c = Null;
                }
                if(eachAccInsert.Saturday_Start_Time__c != Null && eachAccInsert.Saturday_End_Time__c != Null){
                    newProvRec.Operation_Hours_on_Saturday__c = eachAccInsert.Saturday_Start_Time__c + ' ' + 'to' + ' ' + eachAccInsert.Saturday_End_Time__c;
                } else {
                    newProvRec.Operation_Hours_on_Saturday__c = Null;
                }
                if(eachAccInsert.Sunday_Start_Time__c != Null && eachAccInsert.Sunday_Start_Time__c != Null){
                    newProvRec.Operation_Hours_on_Sunday__c = eachAccInsert.Sunday_Start_Time__c + ' ' + 'to' + ' ' + eachAccInsert.Sunday_End_Time__c;
                } else {
                    newProvRec.Operation_Hours_on_Sunday__c = Null;
                }
                newProvRec.NAM_FACILITY__c = eachAccInsert.Name;
                if(exemptProvidersSet.contains(eachAccInsert.QRIS_Rating__c)){
                    newProvRec.TXT_CHATS_RATING__c = '';
                } else {
                    newProvRec.TXT_CHATS_RATING__c = eachAccInsert.QRIS_Rating__c;
                }
                newProvRec.ADR_LINE1__c = eachAccInsert.BillingStreet;
                newProvRec.ADR_LINE1_MLNG__c = eachAccInsert.ShippingStreet;
                newProvRec.ADR_STATE__c = eachAccInsert.BillingState;
                newProvRec.ADR_STATE_MLNG__c = eachAccInsert.ShippingState;
                newProvRec.ADR_ZIP__c = eachAccInsert.BillingPostalCode;
                newProvRec.ADR_ZIP_MLNG__c = eachAccInsert.ShippingPostalCode;
                newProvRec.ADR_CITY__c = eachAccInsert.BillingCity;
                newProvRec.ADR_CITY_MLNG__c = eachAccInsert.ShippingCity;
                newProvRec.Last_Contact_Date__c = eachAccInsert.Last_Contact_Date__c;
                newProvRec.Is_UPK_Provider__c = eachAccInsert.Is_UPK_Provider__c; // added for CCCAP-15329,CCCAP-15350
                
                if(servicetypeCodes.ContainsKey(eachAccInsert.Service_Type__c) ) {
                    newProvRec.CDE_TYPE_PROVR__c = servicetypeCodes.get(eachAccInsert.Service_Type__c);
                } else {
                    newProvRec.CDE_TYPE_PROVR__c = eachAccInsert.Service_Type__c;
                }
                if(eachAccInsert.SSN_FEIN__c != null){
                    String ssn = eachAccInsert.SSN_FEIN__c;
                    if(String.isNotEmpty(ssn)){
                        if(ssn.length()>9 && ssn.contains('.')){
                            ssn = ssn.split('\\.')[0];
                        }
                        ssn = ssn.replaceAll('[^a-zA-Z0-9]', '');
                    }
                    newProvRec.NBR_SSN__c = ssn;
                } else {
                    newProvRec.NBR_SSN__c = eachAccInsert.SSN_FEIN__c;
                }
                newProvRec.NBR_FEIN__c = eachAccInsert.FEIN__c;
                newProvRec.External_ID__c = String.valueOf(eachAccInsert.License_Number__c);
                if(eachAccInsert.Program_Name__c != NULL){
                    newProvRec.Program_Name__c = eachAccInsert.Program_Name__c;
                }    
                lstProvrInsert.add(newProvRec);
                System.debug('[AccountServices.chatProvrUpd]--lstProvrInsert.size()-->'+lstProvrInsert.size());
                lstAccRecToDel.add(eachAccInsert);
                lstAccountIdsToDelete.add(eachAccInsert.Id);
            }
        }
        if(lstProvrInsert != NULL){
            try {
                GenericDMLHandler.insertRecords(lstProvrInsert, false, new Map<String, Object>{'Method__c'=>'chatProvrUpd', 'Class__c'=>'AccountServices'});
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(new Exception_Log__c(Class__c = 'AccountServices', Method__c = 'chatProvrUpd', Exception_Message__c = 'Provider Insert: '+ex.getMessage()+ ' .The Record is - '+lstProvrInsert.get(0), Exception_Type__c = 'Error')); 
            }
        }
        if(!provrUpdMap.isEmpty() && provrUpdMap != NULL){
            Map<Id,T_CHATS_PROVR_STATUS__C> prvListMap = new Map<Id, T_CHATS_PROVR_STATUS__C>([SELECT Id, Name, CDE_STATUS_PROVR__c, CDE_TYPE_PROVR__c,DTE_END_EFFV__c FROM T_CHATS_PROVR_STATUS__C WHERE Id IN :provrUpdMap.keySet() WITH SECURITY_ENFORCED]);
            integer lastClosedDuration;
            for(T_CHATS_PROVR_STATUS__C newProvrUpdRec : provrUpdMap.values()){
                if(	(provrUpdMap.get(newProvrUpdRec.Id).CDE_STATUS_PROVR__c == 'Pending') && 
                   (provrUpdMap.get(newProvrUpdRec.Id).CDE_TYPE_PROVR__c == 'FCCH') &&
                   (prvListMap.get(newProvrUpdRec.Id).CDE_STATUS_PROVR__c == 'Open') && 
                   (prvListMap.get(newProvrUpdRec.Id).CDE_TYPE_PROVR__c == 'EFACH' || prvListMap.get(newProvrUpdRec.Id).CDE_TYPE_PROVR__c == 'EFACB')){
                       // -----
                   } else if((provrUpdMap.get(newProvrUpdRec.Id).CDE_STATUS_PROVR__c == 'Pending') && 
                             (provrUpdMap.get(newProvrUpdRec.Id).CDE_TYPE_PROVR__c == 'FCCH') &&
                             (prvListMap.get(newProvrUpdRec.Id).CDE_STATUS_PROVR__c == 'Closed') && 
                             (prvListMap.get(newProvrUpdRec.Id).CDE_TYPE_PROVR__c == 'EFACH' || prvListMap.get(newProvrUpdRec.Id).CDE_TYPE_PROVR__c == 'EFACB'))
                   {
                       if(date.today() > prvListMap.get(newProvrUpdRec.Id).DTE_END_EFFV__c){
                           lastClosedDuration = prvListMap.get(newProvrUpdRec.Id).DTE_END_EFFV__c.daysBetween(date.today());
                       } else if ((date.today() < prvListMap.get(newProvrUpdRec.Id).DTE_END_EFFV__c)){
                           lastClosedDuration = date.today().daysBetween(prvListMap.get(newProvrUpdRec.Id).DTE_END_EFFV__c);
                       } else {
                           lastClosedDuration = 0;
                       }
                       if(lastClosedDuration != null && lastClosedDuration <= 30){
                           T_CHATS_PROVR_STATUS__C updExmptProviderToOpen = new T_CHATS_PROVR_STATUS__C();
                           updExmptProviderToOpen.Id = newProvrUpdRec.Id;
                           updExmptProviderToOpen.CDE_STATUS_PROVR__c = 'Open';
                           newProvrUpdList.add(updExmptProviderToOpen); 
                       }
                   } else {
                       newProvrUpdList.add(newProvrUpdRec);
                   }
            }
            try {
                GenericDMLHandler.updateRecords(newProvrUpdList,false,new Map<String,Object>{'Method__c'=>'chatProvrUpd','Class__c'=>'AccountServices'});
            } catch (Exception ex) {
                ExceptionLoggingServices.captureExceptionLog(new Exception_Log__c(Class__c = 'AccountServices', Method__c = 'chatProvrUpd', Exception_Message__c = 'Provider Update: '+ex.getMessage()+ ' .The Record is - '+provrUpdMap.values().get(0), Exception_Type__c = 'Error'));
            }
        }
        if(lstAccRecToDel !=NULL && Schema.sObjectType.Account.isDeletable()){
            //GenericDMLHandler.deleteRecords(lstAccRecToDel, null);
            Database.DELETE(lstAccountIdsToDelete);
        }
        } catch (Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String, Object>{'Class__c' => 'AccountServices', 'Method__c' => 'chatProvrUpd'});
        }
    }
}