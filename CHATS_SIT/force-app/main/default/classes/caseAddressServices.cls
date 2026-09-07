/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/20/2017                                                          
*  @description    Handler class for Case Address Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 20-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  *CHAT-1158: Adr City is required for AdrType is "Mailing" and is not Homeless
*  *           Adr City is required for AdrType is "HOME" - Validation Rule implemented
*  *CHAT-1170: If IND_IS_HOMELESS = YES from T_SBSD_CASE_HOMELESS, then default to "Declared Homeless"
*  *CHAT-1159: Adr Line 1 is required for AdrType is "Mailing" and is not Homeless
*  *           Adr Line 1 is required for AdrType is "HOME" - Validation Rule implemented
*  *CHAT-1171: A case can only have one related Residential Address record (CDE_TYPE_ADR = 'HOM') and 
*  *           one related Mailing Address record (CDE_TYPE_ADR = 'MAL')
*  *CHATS-3540: SJ Added "doUpdateIndicatorResident" & "updateCase" method to update case whenever any case address 
*  *           of type 'Home' and with state 'CO' is created/updated/deleted.
*********************************************************************************************/

public with sharing class caseAddressServices {
    public static Boolean disableTrigger = false; // added for CCCAP-14909
    public static final String declaredHomeless = 'HL';
    public static void caseAddressValidations(List<T_SBSD_CASE_ADR__c> newCaseAddressList){
        Map<Id,T_SBSD_CASE_ADR__c> caseIdsInfoMap = new Map<Id,T_SBSD_CASE_ADR__c>();
        Map<Id,T_SBSD_CASE_ADR__c> caseIdsDefaultHomelessMap = new Map<Id,T_SBSD_CASE_ADR__c>();
        Map<Id,T_SBSD_CASE_ADR__c> caseIdsList = new Map<Id,T_SBSD_CASE_ADR__c>();
        List<string> cases = new List<string>();
        List<Id> caseAdrRcrdIds = new List<Id>();
        for(T_SBSD_CASE_ADR__c eachCaseAddr: newCaseAddressList){
            if((eachCaseAddr.IDN_CASE__c != null) && (eachCaseAddr.CDE_TYPE_ADR__c == 'HOM')){
                caseIdsInfoMap.put(eachCaseAddr.IDN_CASE__c,eachCaseAddr);
            }
            if(eachCaseAddr.IDN_CASE__c != null){
                caseIdsDefaultHomelessMap.put(eachCaseAddr.IDN_CASE__c,eachCaseAddr);
                caseIdsList.put(eachCaseAddr.IDN_CASE__c,eachCaseAddr);
                cases.add(eachCaseAddr.IDN_CASE__c);
            }
            if(eachCaseAddr.Id != null){
                caseAdrRcrdIds.add(eachCaseAddr.Id);
            }
        }
        if(!caseIdsInfoMap.isEmpty()){
            for(T_SBSD_CASE_HOMELESS__c eachCaseHomeless: [select IDN_CASE__c, IDN_CASE__r.Is_Peak_Data__c,IDN_CASE__r.Is_CBMS_Data__c, Is_family_homeless__c from T_SBSD_CASE_HOMELESS__c where IDN_CASE__c IN:caseIdsInfoMap.keySet() and Is_family_homeless__c = 'N']){
                T_SBSD_CASE_ADR__c caseAdrRecord = caseIdsInfoMap.get(eachCaseHomeless.IDN_CASE__c);
                if(caseAdrRecord.ADR_CITY__c == NULL && !eachCaseHomeless.IDN_CASE__r.Is_Peak_Data__c && !eachCaseHomeless.IDN_CASE__r.Is_CBMS_Data__c){
                    caseAdrRecord.ADR_CITY__c.addError('Address City is required for Address Type equals Home and is not Homeless');
                }
                if(caseAdrRecord.ADR_LINE_1__c == NULL && !eachCaseHomeless.IDN_CASE__r.Is_Peak_Data__c && !eachCaseHomeless.IDN_CASE__r.Is_CBMS_Data__c){
                    caseAdrRecord.ADR_LINE_1__c.addError('Address Line 1 is required for Address Type equals Home and is not Homeless');
                }
            }
        }
        
        //Default Homeless
        if(!caseIdsDefaultHomelessMap.isEmpty()){
            for(T_SBSD_CASE_HOMELESS__c eachCaseHomeless: [select IDN_CASE__c, Is_family_homeless__c from T_SBSD_CASE_HOMELESS__c where IDN_CASE__c IN:caseIdsDefaultHomelessMap.keySet() and Is_family_homeless__c = 'Y' and  DTE_BEGIN_EFFV__c <= :system.today() and (DTE_END_EFFV__c = NULL OR DTE_END_EFFV__c >= :system.today()) ]){
                T_SBSD_CASE_ADR__c caseAdrRecord = caseIdsDefaultHomelessMap.get(eachCaseHomeless.IDN_CASE__c);
                caseAdrRecord.CDE_TYPE_VERIF__c = declaredHomeless; 
                caseAdrRecord.CDE_SOURCE_VRFD_ADR__c = declaredHomeless;
            }
        }    
        Integer caseAddMailCount =0;
        Integer caseAddHomeCount =0;
        //for(string singleCase : cases){
            /*for(T_SBSD_CASE_ADR__c eachCaseAdrMailHome: [select CDE_TYPE_ADR__c,DTE_END_EFFV__c,DTE_BEGIN_EFFV__c, IDN_CASE__c, IDN_CASE__r.Is_Peak_Data__c from T_SBSD_CASE_ADR__c where IDN_CASE__c IN:cases AND Id NOT IN:caseAdrRcrdIds]){
                T_SBSD_CASE_ADR__c caseAdrCount = caseIdsList.get(eachCaseAdrMailHome.IDN_CASE__c);   
                if(eachCaseAdrMailHome.DTE_END_EFFV__c == null && eachCaseAdrMailHome.CDE_TYPE_ADR__c == 'MAL'){
                    caseAddMailCount++;
                }
                if(eachCaseAdrMailHome.DTE_END_EFFV__c == null && eachCaseAdrMailHome.CDE_TYPE_ADR__c == 'HOM'){
                    caseAddHomeCount++;
                }
               	if(caseAdrCount.CDE_TYPE_ADR__c == eachCaseAdrMailHome.CDE_TYPE_ADR__c && !eachCaseAdrMailHome.IDN_CASE__r.Is_Peak_Data__c && caseAddMailCount>1 && caseAdrCount.CDE_TYPE_ADR__c == 'MAL'){
                   caseAdrCount.addError('Each Case cannot have more than one currently effective Mailing Address Type.');
                }
                if(caseAdrCount.DTE_BEGIN_EFFV__c <= eachCaseAdrMailHome.DTE_BEGIN_EFFV__c && caseAdrCount.CDE_TYPE_ADR__c == 'MAL' && caseAdrCount.CDE_TYPE_ADR__c == eachCaseAdrMailHome.CDE_TYPE_ADR__c){
                    caseAdrCount.addError('Begin date can not be less than currenlty effective case address begin date.');
                }
                if(caseAdrCount.CDE_TYPE_ADR__c == eachCaseAdrMailHome.CDE_TYPE_ADR__c && !eachCaseAdrMailHome.IDN_CASE__r.Is_Peak_Data__c && caseAddHomeCount>1 && caseAdrCount.CDE_TYPE_ADR__c == 'HOM'){
                   caseAdrCount.addError('Each Case cannot have more than one currently effective Home Address Type.');
                }
                if(caseAdrCount.DTE_BEGIN_EFFV__c <= eachCaseAdrMailHome.DTE_BEGIN_EFFV__c && caseAdrCount.CDE_TYPE_ADR__c == 'HOM' && caseAdrCount.CDE_TYPE_ADR__c == eachCaseAdrMailHome.CDE_TYPE_ADR__c){
                    caseAdrCount.addError('Begin date can not be less than currently effective case address begin date.');
                }
            }*/
        //}
    }
	
    //[4/19 SJ: To set the "Indicator Resident" flag at case level]
    public static void doUpdateIndicatorResident(List<T_SBSD_CASE_ADR__c> caseAddresses, Map<Id, T_SBSD_CASE_ADR__c> oldMapCaseAddresses){
        Map<String, List<T_SBSD_CASE_ADR__c>> caseIdToCaseAddresses = new Map<String, List<T_SBSD_CASE_ADR__c>>();
        for(T_SBSD_CASE_ADR__c caseAddress:caseAddresses){
            if((caseAddress.CDE_TYPE_ADR__c=='HOM' && caseAddress.ADR_STATE__c=='CO') ||
              (oldMapCaseAddresses!=null && oldMapCaseAddresses.containsKey(caseAddress.Id) && 
               ((caseAddress.CDE_TYPE_ADR__c!=oldMapCaseAddresses.get(caseAddress.Id).CDE_TYPE_ADR__c || caseAddress.ADR_STATE__c!=oldMapCaseAddresses.get(caseAddress.Id).ADR_STATE__c)))){
                List<T_SBSD_CASE_ADR__c> existingCaseAddresses = caseIdToCaseAddresses.containsKey(caseAddress.IDN_CASE__c)?caseIdToCaseAddresses.get(caseAddress.IDN_CASE__c):new List<T_SBSD_CASE_ADR__c>();
                existingCaseAddresses.add(caseAddress);
                caseIdToCaseAddresses.put(caseAddress.IDN_CASE__c, existingCaseAddresses);
            }
        }        
        System.debug('caseIdToCaseAddresses:'+caseIdToCaseAddresses);
        List<T_SBSD_CASE__c> caseToBeUpdated = new List<T_SBSD_CASE__c>();
        for(T_SBSD_CASE__c caseRec:[SELECT Id,(SELECT Id FROM T_SBSD_CASE3__r WHERE CDE_TYPE_ADR__c = 'HOM' AND ADR_STATE__c='CO') FROM T_SBSD_CASE__c WHERE Id IN:caseIdToCaseAddresses.keySet()]){
            if(caseRec.T_SBSD_CASE3__r.isEmpty()){
                caseRec.IND_RESDT__c = false;
            }else{
                caseRec.IND_RESDT__c = true;
            }     
            caseToBeUpdated.add(caseRec);
        }
        System.debug('caseToBeUpdated:'+caseToBeUpdated);
        if(!caseToBeUpdated.isEmpty()){
            updateCase(caseToBeUpdated, caseIdToCaseAddresses);
        }
    }

    //[4/19 SJ: updateCase method used to update case and show errors on case address in case of any error]
    public static void updateCase(List<T_SBSD_CASE__c> caseToBeUpdated, Map<String, List<T_SBSD_CASE_ADR__c>> caseIdToCaseAddresses){
        List<DMLResult> lstDMLResult = GenericDMLHandler.updateRecords(caseToBeUpdated,true, new Map<String,Object>{'Method__c'=>'caseToBeUpdated','Class__c'=>'caseAddressServices'});
        System.debug('lstDMLResult After Insert:'+lstDMLResult);
        List<Database.SaveResult> updateSaveResults =GenericDMLHandler.getSaveResultsFromDMLResults(lstDMLResult);
        //= Database.update(caseToBeUpdated, false); System.debug('updateSaveResults:'+updateSaveResults);
        for(Integer i=0;i<updateSaveResults.size();i++){
            Database.SaveResult updateSaveResult = updateSaveResults[i];
            if(!updateSaveResult.isSuccess()){
                List<Database.Error> lstError = updateSaveResult.getErrors();
                String failedDML;
                for(Database.Error error : lstError){
                    failedDML = failedDML + '\n' + error.getMessage();
                }
                if(caseIdToCaseAddresses.containsKey(caseToBeUpdated[i].Id)){
                    for(T_SBSD_CASE_ADR__c caseAddress:caseIdToCaseAddresses.get(caseToBeUpdated[i].Id)){
                        caseAddress.addError('Error while updating the related case record:'+failedDML);
                    }
                }
            }
        }
    }
     public static void updateCaseAddressEndDate(List<T_SBSD_CASE_ADR__c> newCaseAddressList){
        List<T_SBSD_CASE_ADR__c> oldCaseAddressList = new List<T_SBSD_CASE_ADR__c>();
        Set<String>caseAddressIds = new Set<String>();
        Set<String>caseIds = new Set<String>();
       Map<String,T_SBSD_CASE_ADR__c> newCaseAddressHomeMap = new Map<String,T_SBSD_CASE_ADR__c>();
        Map<String,T_SBSD_CASE_ADR__c> newCaseAddressMailMap = new Map<String,T_SBSD_CASE_ADR__c>();
        for(T_SBSD_CASE_ADR__c csAddr : newCaseAddressList){
            if(csAddr.DTE_BEGIN_EFFV__c > csAddr.DTE_END_EFFV__c){
                csAddr.addError('End date can not be less than begin date.');
            }
            if(csAddr.CDE_TYPE_ADR__c == 'HOM'){
                newCaseAddressHomeMap.put(csAddr.IDN_CASE__c, csAddr);
            }
            if(csAddr.CDE_TYPE_ADR__c == 'MAL'){
                newCaseAddressMailMap.put(csAddr.IDN_CASE__c, csAddr);
            }
            caseAddressIds.add(csAddr.id);
            if(csAddr.IDN_CASE__c!=null){
	            caseIds.add(csAddr.IDN_CASE__c);                
            }
        }
        system.debug('newCaseAddressList--'+newCaseAddressList);
        system.debug('newCaseAddressMailMap---'+newCaseAddressMailMap);
        system.debug('newCaseAddressHomeMap---'+newCaseAddressHomeMap);
        system.debug('caseAddressIds---'+caseAddressIds);
        if(!caseIds.isEmpty()){
            for(T_SBSD_CASE_ADR__c csAdd :[SELECT id,IDN_CASE__c,CDE_TYPE_ADR__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from T_SBSD_CASE_ADR__c where IDN_CASE__c IN:caseIds and id NOT IN:caseAddressIds and DTE_END_EFFV__c =:null ]){
                system.debug('csAdd.CDE_TYPE_ADR__c--'+csAdd.CDE_TYPE_ADR__c); 
                if(csAdd.CDE_TYPE_ADR__c == 'HOM'){
                    if(newCaseAddressHomeMap.containsKey(csAdd.IDN_CASE__c)){
                        system.debug('newCaseAddressHomeMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c--'+newCaseAddressHomeMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c);
                        csAdd.DTE_END_EFFV__c =(newCaseAddressHomeMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c).addDays(-1);
                        oldCaseAddressList.add(csAdd);
                    }
                }
                if(csAdd.CDE_TYPE_ADR__c == 'MAL'){
                    if(newCaseAddressMailMap.containsKey(csAdd.IDN_CASE__c)){
                        system.debug('newCaseAddressMailMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c--'+newCaseAddressMailMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c);
                        csAdd.DTE_END_EFFV__c =(newCaseAddressMailMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c).addDays(-1);
                        oldCaseAddressList.add(csAdd);
                    }
                }
            }
        }
        if(oldCaseAddressList.size()>0){
            GenericDMLHandler.updateRecords(oldCaseAddressList,new Map<String,Object>{'Method__c'=>'updateCaseAddressEndDate','Class__c'=>'caseAddressServices'}); 
         
        }
        
    }
    public static void updateCasePhoneEndDate(List<T_SBSD_CASE_PHONE__c> newCasePhoneList){
        List<T_SBSD_CASE_PHONE__c> oldCasePhoneList = new List<T_SBSD_CASE_PHONE__c>();
        Set<String>casePhonesIds = new Set<String>();
        Set<String>caseIds = new Set<String>();
         Map<String,T_SBSD_CASE_PHONE__c> newCasePhoneHomeMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        Map<String,T_SBSD_CASE_PHONE__c> newCasePhoneMobMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        Map<String,T_SBSD_CASE_PHONE__c> newCasePhoneWorkMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        Map<String,T_SBSD_CASE_PHONE__c> newCasePhoneEMRMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        for(T_SBSD_CASE_PHONE__c csAddr : newCasePhoneList){
            if(csAddr.DTE_BEGIN_EFFV__c > csAddr.DTE_END_EFFV__c){
                csAddr.addError('End date can not be less than begin date.');
            }
            if(csAddr.CDE_TYPE_PHONE__c == 'HOM'){
                newCasePhoneHomeMap.put(csAddr.IDN_CASE__c, csAddr);
            }
            if(csAddr.CDE_TYPE_PHONE__c == 'MOB'){
                newCasePhoneMobMap.put(csAddr.IDN_CASE__c, csAddr);
            }
            if(csAddr.CDE_TYPE_PHONE__c == 'WOR'){
                newCasePhoneWorkMap.put(csAddr.IDN_CASE__c, csAddr);
            }
            if(csAddr.CDE_TYPE_PHONE__c == 'EMR'){
                newCasePhoneEMRMap.put(csAddr.IDN_CASE__c, csAddr);
            }
            casePhonesIds.add(csAddr.id);
            if(csAddr.IDN_CASE__c!=null){
	            caseIds.add(csAddr.IDN_CASE__c);                
            }
        }
        
        if(!caseIds.isEmpty()){
            for(T_SBSD_CASE_PHONE__c csAdd :[SELECT id,IDN_CASE__c,CDE_TYPE_PHONE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from T_SBSD_CASE_PHONE__c where IDN_CASE__c IN:caseIds and id NOT IN:casePhonesIds and DTE_END_EFFV__c =:null ]){
                
                if(csAdd.CDE_TYPE_PHONE__c == 'HOM'){
                    if(newCasePhoneHomeMap.containsKey(csAdd.IDN_CASE__c)){
                        if(newCasePhoneHomeMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c){
                            newCasePhoneHomeMap.get(csAdd.IDN_CASE__c).addError('Begin date can not be less than currenlty effective case phone begin date.');
                        }else{
                            csAdd.DTE_END_EFFV__c =(newCasePhoneHomeMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c).addDays(-1);
                            oldCasePhoneList.add(csAdd);
                        }
                        
                    }
                }
                if(csAdd.CDE_TYPE_PHONE__c == 'MOB'){
                    if(newCasePhoneMobMap.containsKey(csAdd.IDN_CASE__c)){
                        if(newCasePhoneMobMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c){
                            newCasePhoneMobMap.get(csAdd.IDN_CASE__c).addError('Begin date can not be less than currenlty effective case phone begin date.');
                        }else{
                            csAdd.DTE_END_EFFV__c =(newCasePhoneMobMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c).addDays(-1);
                            oldCasePhoneList.add(csAdd);
                        }
                    }
                }
                if(csAdd.CDE_TYPE_PHONE__c == 'WOR'){
                    if(newCasePhoneWorkMap.containsKey(csAdd.IDN_CASE__c)){
                        if(newCasePhoneWorkMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c){
                            newCasePhoneWorkMap.get(csAdd.IDN_CASE__c).addError('Begin date can not be less than currenlty effective case phone begin date.');
                        }else{
                            csAdd.DTE_END_EFFV__c =(newCasePhoneWorkMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c).addDays(-1);
                            oldCasePhoneList.add(csAdd);
                        }
                    }
                }
                if(csAdd.CDE_TYPE_PHONE__c == 'EMR'){
                    if(newCasePhoneEMRMap.containsKey(csAdd.IDN_CASE__c)){
                        if(newCasePhoneEMRMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c <=csAdd.DTE_BEGIN_EFFV__c){
                            newCasePhoneEMRMap.get(csAdd.IDN_CASE__c).addError('Begin date can not be less than currenlty effective case phone begin date.');
                        }else{
                            csAdd.DTE_END_EFFV__c =(newCasePhoneEMRMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c).addDays(-1);
                            oldCasePhoneList.add(csAdd);
                        }
                    }
                }
            }
        }
        if(oldCasePhoneList.size()>0){
        GenericDMLHandler.updateRecords(oldCasePhoneList,new Map<String,Object>{'Method__c'=>'deleteCasePhoneEndDate','Class__c'=>'caseAddressServices'}); 
         //  update oldCasePhoneList; 
        }
        
    }
    public static void deleteCaseAddressEndDate(List<T_SBSD_CASE_ADR__c> newCaseAddressList){
        List<T_SBSD_CASE_ADR__c> oldCaseAddressList = new List<T_SBSD_CASE_ADR__c>();
        Set<String>caseAddressIds = new Set<String>();
        Set<String>caseIds = new Set<String>();
        Map<String,T_SBSD_CASE_ADR__c> oldCaseHomAddressMap = new Map<String,T_SBSD_CASE_ADR__c>();
        Map<String,T_SBSD_CASE_ADR__c> oldCaseMailAddressMap = new Map<String,T_SBSD_CASE_ADR__c>();
        Map<String,T_SBSD_CASE_ADR__c> newCaseAddressMap = new Map<String,T_SBSD_CASE_ADR__c>();
        for(T_SBSD_CASE_ADR__c csAddr : newCaseAddressList){
            newCaseAddressMap.put(csAddr.IDN_CASE__c, csAddr);
            caseAddressIds.add(csAddr.id);
            caseIds.add(csAddr.IDN_CASE__c);
        }
        for(T_SBSD_CASE_ADR__c csAdd :[SELECT id,IDN_CASE__c,CDE_TYPE_ADR__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from T_SBSD_CASE_ADR__c where IDN_CASE__c IN:caseIds and id NOT IN:caseAddressIds]){
            if(csAdd.CDE_TYPE_ADR__c == 'HOM'){
                if(oldCaseHomAddressMap.containsKey(csAdd.IDN_CASE__c)){
                    if(csAdd.DTE_BEGIN_EFFV__c >oldCaseHomAddressMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c){
                        oldCaseHomAddressMap.put(csAdd.IDN_CASE__c,csAdd);
                    } 
                }else{
                    oldCaseHomAddressMap.put(csAdd.IDN_CASE__c,csAdd);
                }
            }
            if(csAdd.CDE_TYPE_ADR__c == 'MAL'){
                if(oldCaseMailAddressMap.containsKey(csAdd.IDN_CASE__c)){
                    if(csAdd.DTE_BEGIN_EFFV__c >oldCaseMailAddressMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c){
                        oldCaseMailAddressMap.put(csAdd.IDN_CASE__c,csAdd);
                    } 
                }else{
                    oldCaseMailAddressMap.put(csAdd.IDN_CASE__c,csAdd);
                }
            }
        }
        for(T_SBSD_CASE_ADR__c csAdd : newCaseAddressList){
            if(csAdd.CDE_TYPE_ADR__c == 'HOM'){
                if(oldCaseHomAddressMap.containsKey(csAdd.IDN_CASE__c)){   
                    oldCaseHomAddressMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c = null;
                    oldCaseAddressList.add(oldCaseHomAddressMap.get(csAdd.IDN_CASE__c));
                }
            }
            if(csAdd.CDE_TYPE_ADR__c == 'MAL'){
                if(oldCaseMailAddressMap.containsKey(csAdd.IDN_CASE__c)){   
                    oldCaseMailAddressMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c = null;
                    oldCaseAddressList.add(oldCaseMailAddressMap.get(csAdd.IDN_CASE__c));
                }
            }
        }
        if(oldCaseAddressList.size()>0){
            GenericDMLHandler.updateRecords(oldCaseAddressList,new Map<String,Object>{'Method__c'=>'updateCaseAddressEndDate','Class__c'=>'caseAddressServices'}); 
         
         //  update oldCaseAddressList; 
        }
    }
    public static void deleteCasePhoneEndDate(List<T_SBSD_CASE_PHONE__c> newCaseAddressList){
        List<T_SBSD_CASE_PHONE__c> oldCasePhoneList = new List<T_SBSD_CASE_PHONE__c>();
        Set<String>caseAddressIds = new Set<String>();
        Set<String>caseIds = new Set<String>();
        Map<String,T_SBSD_CASE_PHONE__c> oldCaseHomPhoneMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        Map<String,T_SBSD_CASE_PHONE__c> oldCaseMobPhoneMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        Map<String,T_SBSD_CASE_PHONE__c> oldCaseWorkPhoneMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        Map<String,T_SBSD_CASE_PHONE__c> oldCaseEmrPhoneMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        Map<String,T_SBSD_CASE_PHONE__c> newCaseAddressMap = new Map<String,T_SBSD_CASE_PHONE__c>();
        for(T_SBSD_CASE_PHONE__c csAddr : newCaseAddressList){
            newCaseAddressMap.put(csAddr.IDN_CASE__c, csAddr);
            caseAddressIds.add(csAddr.id);
            caseIds.add(csAddr.IDN_CASE__c);
        }
        for(T_SBSD_CASE_PHONE__c csAdd :[SELECT id,IDN_CASE__c,CDE_TYPE_PHONE__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from T_SBSD_CASE_PHONE__c where IDN_CASE__c IN:caseIds and id NOT IN:caseAddressIds]){
            if(csAdd.CDE_TYPE_PHONE__c == 'HOM'){
                if(oldCaseHomPhoneMap.containsKey(csAdd.IDN_CASE__c)){
                    if(csAdd.DTE_BEGIN_EFFV__c >oldCaseHomPhoneMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c){
                        oldCaseHomPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                    } 
                }else{
                    oldCaseHomPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                }
            }
            if(csAdd.CDE_TYPE_PHONE__c == 'MOB'){
                if(oldCaseMobPhoneMap.containsKey(csAdd.IDN_CASE__c)){
                    if(csAdd.DTE_BEGIN_EFFV__c >oldCaseMobPhoneMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c){
                        oldCaseMobPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                    } 
                }else{
                    oldCaseMobPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                }
            }
            if(csAdd.CDE_TYPE_PHONE__c == 'WOR'){
                if(oldCaseWorkPhoneMap.containsKey(csAdd.IDN_CASE__c)){
                    if(csAdd.DTE_BEGIN_EFFV__c >oldCaseWorkPhoneMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c){
                        oldCaseWorkPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                    } 
                }else{
                    oldCaseWorkPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                }
            }
            if(csAdd.CDE_TYPE_PHONE__c == 'EMR'){
                if(oldCaseEmrPhoneMap.containsKey(csAdd.IDN_CASE__c)){
                    if(csAdd.DTE_BEGIN_EFFV__c >oldCaseEmrPhoneMap.get(csAdd.IDN_CASE__c).DTE_BEGIN_EFFV__c){
                        oldCaseEmrPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                    } 
                }else{
                    oldCaseEmrPhoneMap.put(csAdd.IDN_CASE__c,csAdd);
                }
            }
        }
        for(T_SBSD_CASE_PHONE__c csAdd : newCaseAddressList){
            if(csAdd.CDE_TYPE_PHONE__c == 'HOM'){
                if(oldCaseHomPhoneMap.containsKey(csAdd.IDN_CASE__c)){  
                    if(oldCaseHomPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c != null){
                        oldCaseHomPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c = null;
                        oldCasePhoneList.add(oldCaseHomPhoneMap.get(csAdd.IDN_CASE__c));
                    }
                }
            }
            if(csAdd.CDE_TYPE_PHONE__c == 'MOB'){
                if(oldCaseMobPhoneMap.containsKey(csAdd.IDN_CASE__c)){   
                    if(oldCaseMobPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c != null){
                        oldCaseMobPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c = null;
                        oldCasePhoneList.add(oldCaseMobPhoneMap.get(csAdd.IDN_CASE__c));
                    }
                }
            }
            if(csAdd.CDE_TYPE_PHONE__c == 'WOR'){
                if(oldCaseWorkPhoneMap.containsKey(csAdd.IDN_CASE__c)){   
                    if(oldCaseWorkPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c != null){
                        oldCaseWorkPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c = null;
                        oldCasePhoneList.add(oldCaseWorkPhoneMap.get(csAdd.IDN_CASE__c));
                    }
                }
            }
            if(csAdd.CDE_TYPE_PHONE__c == 'EMR'){
                if(oldCaseEmrPhoneMap.containsKey(csAdd.IDN_CASE__c)){   
                    if(oldCaseEmrPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c != null){
                        oldCaseEmrPhoneMap.get(csAdd.IDN_CASE__c).DTE_END_EFFV__c = null;
                        oldCasePhoneList.add(oldCaseEmrPhoneMap.get(csAdd.IDN_CASE__c));
                    }
                }
            }
        }
        if(oldCasePhoneList.size()>0){
                        GenericDMLHandler.updateRecords(oldCasePhoneList,new Map<String,Object>{'Method__c'=>'updateCaseAddressEndDate','Class__c'=>'caseAddressServices'}); 

         // update oldCasePhoneList;   
        }
    }


   public static void avoidDuplicateCaseAddresses(List<T_SBSD_CASE_ADR__c> newCaseAdrRecords){
        map<string,T_SBSD_CASE_ADR__c> newCaseAdrMap = new map<string,T_SBSD_CASE_ADR__c>();
        Boolean caseAddrRecordValid = true;
        List<string> caseAdrRcrdIds = new List<string>();
        for(T_SBSD_CASE_ADR__c eachNewCaseAdr : newCaseAdrRecords){
            if(eachNewCaseAdr.IDN_CASE__c != null ){
                newCaseAdrMap.put(eachNewCaseAdr.IDN_CASE__c,eachNewCaseAdr);
                caseAdrRcrdIds.add(eachNewCaseAdr.Id);
            }
        }
        
        for(T_SBSD_CASE_ADR__c eachExistingCaseAdr : [select CDE_TYPE_ADR__c,DTE_END_EFFV__c,DTE_BEGIN_EFFV__c, IDN_CASE__c, IDN_CASE__r.Is_Peak_Data__c,IDN_CASE__r.Is_CBMS_Data__c from T_SBSD_CASE_ADR__c where IDN_CASE__c IN:newCaseAdrMap.keySet() AND Id NOT IN:caseAdrRcrdIds]){
            
            if(eachExistingCaseAdr != null && newCaseAdrMap.containsKey(eachExistingCaseAdr.IDN_CASE__c) &&
               newCaseAdrMap.get(eachExistingCaseAdr.IDN_CASE__c).CDE_TYPE_ADR__c == eachExistingCaseAdr.CDE_TYPE_ADR__c && eachExistingCaseAdr.DTE_END_EFFV__c == null) {
                   
                   T_SBSD_CASE_ADR__c newCaseAddrRecord = newCaseAdrMap.get(eachExistingCaseAdr.IDN_CASE__c); 
                   
                   if(newCaseAddrRecord.DTE_BEGIN_EFFV__c <= eachExistingCaseAdr.DTE_BEGIN_EFFV__c &&  (newCaseAddrRecord.DTE_END_EFFV__c == NULL) && newCaseAddrRecord.CDE_TYPE_ADR__c == 'MAL'){
                       newCaseAdrMap.get(eachExistingCaseAdr.IDN_CASE__c).addError('Begin date can not be less than or equal to currently effective case address begin date.');
                       caseAddrRecordValid = false;
                   }
                   if(newCaseAddrRecord.DTE_BEGIN_EFFV__c <= eachExistingCaseAdr.DTE_BEGIN_EFFV__c && (newCaseAddrRecord.DTE_END_EFFV__c == NULL)  && newCaseAddrRecord.CDE_TYPE_ADR__c == 'HOM'){
                       newCaseAdrMap.get(eachExistingCaseAdr.IDN_CASE__c).addError('Begin date can not be less than or equal to currently effective case address begin date.');
                       caseAddrRecordValid = false;
                   }
               }
        }
        if(Trigger.isInsert && caseAddrRecordValid){
            updateCaseAddressEndDate(newCaseAdrRecords);
        }
    }
 //DC : Trigger tasks T190 and T191 as part of JIRA CCCAP-14034 June 2026 release
    public static void caseAddressesChangeTaskTrigger(List<T_SBSD_CASE_ADR__c> newCaseAddressList, Map<Id, T_SBSD_CASE_ADR__c> oldMapCaseAddresses){
        try{
            Map<Id,T_SBSD_CASE_ADR__c> caseIdsInfoMap = new Map<Id,T_SBSD_CASE_ADR__c>();
            List<String> providerType = new List<String>{'EFACH'};
            List<Id> caseAdrRcrdIds = new List<Id>();
            
            List<T_AUTH__c> authList = new List<T_AUTH__c>();
            Set<Id> providerIds = new Set<ID>();
            Date twelveMonthsAgo = Date.today().addMonths(-12);
            Map<String,List<T_PROVR_FISCAL_AGREMENT__c>> taskValidFAMap = new Map<String,List<T_PROVR_FISCAL_AGREMENT__c>>();
            Map<String,Set<String>> caseProviderMap = new Map<String,Set<String>>();
            Map<String,Set<String>> providerAuthMap = new Map<String,Set<String>>();
            Map<Id,String> caseNameMap = new Map<Id,String>();
            Date todayDate = system.today();
            List<Task> taskstoBeCreated = new List<Task>();
            for(T_SBSD_CASE_ADR__c eachCaseAddr: newCaseAddressList){
                if((eachCaseAddr.IDN_CASE__c != null) && (eachCaseAddr.CDE_TYPE_ADR__c == 'HOM') && oldMapCaseAddresses == null){
                    caseIdsInfoMap.put(eachCaseAddr.IDN_CASE__c,eachCaseAddr);
                }else if((eachCaseAddr.IDN_CASE__c != null) && (eachCaseAddr.CDE_TYPE_ADR__c == 'HOM') && oldMapCaseAddresses != null ){
                    T_SBSD_CASE_ADR__c oldAdd = oldMapCaseAddresses.get(eachCaseAddr.id);
                    if((!(eachCaseAddr.ADR_LINE_1__c).equals(oldAdd.ADR_LINE_1__c)) || (!(eachCaseAddr.ADR_LINE_2__c).equals(oldAdd.ADR_LINE_2__c)) ||
                       (!(eachCaseAddr.ADR_CITY__c).equals(oldAdd.ADR_CITY__c)) || (!(eachCaseAddr.ADR_STATE__c).equals(oldAdd.ADR_STATE__c)) ||
                       (!(eachCaseAddr.ADR_ZIP_MAIN__c).equals(oldAdd.ADR_ZIP_MAIN__c)) || (!(eachCaseAddr.ADR_ZIP_EXTN__c).equals(oldAdd.ADR_ZIP_EXTN__c)) ){
                           caseIdsInfoMap.put(eachCaseAddr.IDN_CASE__c,eachCaseAddr);
                       }
                    
                }
            }
            Set<String> authCounty = new Set<String>();
            Map<Id,Id> caseCountyMap= new Map<Id,Id>();
            if(caseIdsInfoMap !=null){
                for(T_SBSD_CASE_STATUS_MODE__c caseStatusMode: [select IDN_CASE__c, CDE_MODE_CASE__c,CDE_STATUS_CASE__c FROM T_SBSD_CASE_STATUS_MODE__c WHERE IDN_CASE__c IN:caseIdsInfoMap.keySet() AND DTE_BEGIN_EFFV__c <=: system.today() AND
                                                                (DTE_END_EFFV__c = Null OR DTE_END_EFFV__c >=: system.today()) and CDE_STATUS_CASE__c='OPN']){
                                                                    caseAdrRcrdIds.add(caseStatusMode.IDN_CASE__c);
                }
                for(T_AUTH__c auth :[Select id,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c,IDN_PROVR__r.Name,Name,IDN_CASE__c,IDN_CASE__r.Name,IDN_CLIENT__c,CDE_COUNTY__c,IDN_PROVR__c from T_AUTH__c where IDN_CASE__c IN:caseAdrRcrdIds and
                                     IDN_PROVR__r.CDE_TYPE_PROVR__c IN:providerType  and DTE_END_EFFV_AUTH__c >= :twelveMonthsAgo  WITH SECURITY_ENFORCED]){
                                         providerIds.add(auth.IDN_PROVR__c);
                                         caseCountyMap.put(auth.IDN_CASE__c,auth.CDE_COUNTY__c);
                                         caseNameMap.put(auth.IDN_CASE__c,auth.IDN_CASE__r.Name);
                                         if(providerAuthMap.containsKey(auth.IDN_CASE__c)){
                                             //Get all case provider info
                                             Set<String> providerLst = providerAuthMap.get(auth.IDN_CASE__c);
                                             providerLst.add(auth.IDN_PROVR__c);
                                             providerAuthMap.put(auth.IDN_CASE__c,providerLst);
                                             // Get all unique provide Name
                                             Set<String> providerNameLst = providerAuthMap.get(auth.IDN_CASE__c);
                                             providerNameLst.add(auth.IDN_PROVR__r.Name);
                                             caseProviderMap.put(auth.IDN_CASE__c,providerNameLst);
                                         }else{
                                             providerAuthMap.put(auth.IDN_CASE__c,new Set<String>{auth.IDN_PROVR__c});
                                             caseProviderMap.put(auth.IDN_CASE__c,new Set<String>{auth.IDN_PROVR__r.Name});
                                         }
                                     }
                for(T_PROVR_FISCAL_AGREMENT__c prov : [SELECT Id, ID_SERVICE__c,ID_SERVICE__r.Name,CDE_COUNTY__c, DTE_BEGIN_AGRMT__c,OwnerId,CDE_TYPE_STATUS__c, DTE_END_AGRMT__c, ID_SERVICE__r.CDE_COUNTY_OWNER__c,ID_SERVICE__r.CDE_STATUS_PROVR__c,
                                                       ID_SERVICE__r.DTE_END_EFFV__c,ID_SERVICE__r.DTE_BEGIN_EFFV__c,ID_SERVICE__r.CDE_TYPE_PROVR__c 
                                                       FROM T_PROVR_FISCAL_AGREMENT__c WHERE ID_SERVICE__c IN:providerIds and CDE_COUNTY__c IN:caseCountyMap.values()  AND 
                                                       (
                                                           (DTE_BEGIN_AGRMT__c <= TODAY AND (DTE_END_AGRMT__c >=TODAY OR DTE_END_AGRMT__c = null) and CDE_TYPE_STATUS__c !='CLS' ) //OR 
                                                          // ( DTE_END_AGRMT__c >=:twelveMonthsAgo and CDE_TYPE_STATUS__c ='CLS')
                                                       ) WITH SECURITY_ENFORCED]){
                                                           IF(prov.CDE_TYPE_STATUS__c =='CLS' && prov.DTE_BEGIN_AGRMT__c <=prov.DTE_END_AGRMT__c){
                                                               if(taskValidFAMap.containsKey(prov.ID_SERVICE__c)){
                                                                   List<T_PROVR_FISCAL_AGREMENT__c> ownerId = taskValidFAMap.get(prov.ID_SERVICE__c);
                                                                   ownerId.add(prov);
                                                                   taskValidFAMap.put(prov.ID_SERVICE__c,ownerId);
                                                               }else{
                                                                   taskValidFAMap.put(prov.ID_SERVICE__c,new List<T_PROVR_FISCAL_AGREMENT__c>{prov});
                                                               }
                                                           }else if(prov.DTE_END_AGRMT__c >=todayDate && prov.CDE_TYPE_STATUS__c !='CLS' ){
                                                               if(taskValidFAMap.containsKey(prov.ID_SERVICE__c)){
                                                                   List<T_PROVR_FISCAL_AGREMENT__c> ownerId = taskValidFAMap.get(prov.ID_SERVICE__c);
                                                                   ownerId.add(prov);
                                                                   taskValidFAMap.put(prov.ID_SERVICE__c,ownerId);
                                                               }else{
                                                                   taskValidFAMap.put(prov.ID_SERVICE__c,new List<T_PROVR_FISCAL_AGREMENT__c>{prov});
                                                               }
                                                               
                                                           }
                                                           
                                                       }
				Map<String,String> faOwnerMap = new Map<String,String>();
                for(String caseId: caseAdrRcrdIds){
                    Set<String> taskProviderIds = new Set<String>();
                    if(providerAuthMap != null && providerAuthMap.containsKey(caseId)){
                        Set<Id> ownerIdSet = new Set<Id>();
                        Set<String> providerNameSet = caseProviderMap.get(caseId);
                        String providerStr='';
                        for(String providerId :providerAuthMap.get(caseId)){
                            if(taskValidFAMap != null && taskValidFAMap.containsKey(providerId) ){
                                for(T_PROVR_FISCAL_AGREMENT__c faTemp :taskValidFAMap.get(providerId)){
                                    if(faTemp.CDE_COUNTY__c == caseCountyMap.get(caseId)){
                                        ownerIdSet.add(faTemp.OwnerId);
                                        if(!providerStr.contains(faTemp.ID_SERVICE__r.Name)){
                                            providerStr = providerStr+ faTemp.ID_SERVICE__r.Name + ' ,';
                                        }
                                        if(faOwnerMap.containsKey(faTemp.OwnerId)){
                                           String provideName = faOwnerMap.get(faTemp.OwnerId);
                                            provideName = provideName+ faTemp.ID_SERVICE__r.Name + ' ,';
                                            faOwnerMap.put(faTemp.OwnerId, provideName);
                                        }else{
                                            String provideName =faTemp.ID_SERVICE__r.Name + ' ,';
                                            faOwnerMap.put(faTemp.OwnerId,provideName);
                                        }
                                        
                                    }
                                }
                            }
                        }
                        providerStr = providerStr.removeEnd(' ,');
                        if(ownerIdSet != null && ownerIdSet.size()>0){
                            // Trigger T190 Task
                            for(ID ownerIdFA : ownerIdSet){
								String providersName = faOwnerMap.get(ownerIdFA);
                                providersName = providersName.removeEnd(' ,');
                                Task tsk = new Task();
                                tsk.Subject = System.Label.Task_T190_Subject;
                                tsk.WhatId = caseId;
                                tsk.OwnerId = ownerIdFA;
                                tsk.Status = 'Not Started';
                                tsk.Priority = 'Normal';
                                tsk.ActivityDate = system.today().addDays(10);
                                tsk.Description = 'There has been an address change on a case related to a qualified exempt provider '+providersName+' . Please complete the following steps:'+ '\n' +
                                    +'1. Verify if the change of address impacts the location of CCCAP care and/or if an address update is required in the qualified exempt provider profile.'+ '\n' +
                                    +' 2. If there is an address change to the location of CCCAP care, follow the fiscal agreement county procedure to create an amendment to the current qualified exempt fiscal agreement, documenting the address change and new location of CCCAP care.'+ '\n' +
                                    +'3. Notify State CCCAP via CHATS that there has been a change in the CCCAP qualified exempt child care location.'+ '\n' +
                                    +' 4. Document all actions and outcomes in a provider note /case comment';
                                
                                taskstoBeCreated.add(tsk); 
                            }
                            // Trigger T191 Task
                            Task tsk1 = new Task();
                            tsk1.Subject = System.Label.Task_T191_Subject;
                            tsk1.WhatId = caseId;
                            tsk1.OwnerId = System.Label.Task_T191_Owner;
                            tsk1.Status = 'Not Started';
                            tsk1.Priority = 'Normal';
                            tsk1.ActivityDate = system.today().addDays(10);
                            tsk1.Description = 'There has been an address change on a case '+ caseNameMap.get(caseId) +' related to a qualified exempt provider '+providerStr+' . Please complete the following steps:'+ '\n' +
                                +'1. Update the location/relationship to the child field in the related authorizations, if applicable.'+ '\n' +
                                +' 2. Determine if additional background checks are required and send guidance to the FA owner regarding next steps.';
                            taskstoBeCreated.add(tsk1); 
                        }
                        
                    }
                    
                }
            }
            if(taskstoBeCreated != null && taskstoBeCreated.size()>0){
                GenericDMLHandler.insertRecords(taskstoBeCreated,new Map<String,Object>{'Method__c'=>'caseAddressesChangeTaskTrigger','Class__c'=>'caseAddressServices'});
            }
        }catch(Exception e){
            
        }
    }
}