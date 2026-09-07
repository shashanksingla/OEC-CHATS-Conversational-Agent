public with sharing class IndividualSearchApxCtrl {
    
    Static Boolean isOtherFlter = false;
    
    @auraEnabled
    public static LightningServerResponse searchIndividuals(String indivSearchWrapperStr ){
        Map<String, Object> objectData = new map<String, Object>();
        List<T_SBSD_INDIV__c> listIndiv = new List<T_SBSD_INDIV__c>();
        Boolean isSuccessful;
        String message;
        IndividualSearchWrapper indivSearchWrapper = (IndividualSearchWrapper)JSON.deserialize(indivSearchWrapperStr, IndividualSearchWrapper.class);
        Set<Id> setOnlyCaseIds = new Set<Id>();
        Set<Id> setCaseIdsFromAddress = new Set<Id>();
        Set<Id> setCaseIdsFromPhone = new Set<Id>();
        Set<Id> setCaseIds = new Set<Id>();
        Set<Id> setIndivIds = new Set<Id>();
        String firstName = String.isBlank(indivSearchWrapper.indivRec.NAM_FIRST__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_FIRST__c);
        String lastName = String.isBlank(indivSearchWrapper.indivRec.NAM_LAST__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_LAST__c);
        String dob = String.isBlank(String.valueOf(indivSearchWrapper.indivRec.DTE_DOB__c)) ? null : String.escapeSingleQuotes(String.valueOf(indivSearchWrapper.indivRec.DTE_DOB__c));
        String ssn = String.isBlank(indivSearchWrapper.indivRec.NBR_SSN__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.NBR_SSN__c);
        String stateId = String.isBlank(indivSearchWrapper.indivRec.IDN_STATE__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.IDN_STATE__c);
        String caseName = String.isBlank(indivSearchWrapper.caseId) ? null : String.escapeSingleQuotes(indivSearchWrapper.caseId);
        String phone = String.isBlank(indivSearchWrapper.phone) ? null : String.escapeSingleQuotes(indivSearchWrapper.phone);
        String emailId = String.isBlank(indivSearchWrapper.emailId) ? null : String.escapeSingleQuotes(indivSearchWrapper.emailId); // Added by Rishav for CCCAP-3239
        if(indivSearchWrapper.caseId != null && indivSearchWrapper.caseId != ''){
            setOnlyCaseIds = getCaseIdsFromCase(indivSearchWrapper.caseId);
            //setCaseIds.addAll(setOnlyCaseIds);
        }
        if(indivSearchWrapper != null){
            if(String.isBlank(phone) && String.isBlank(firstName) && String.isBlank(lastName) && String.isBlank(dob) && String.isBlank(ssn) && String.isBlank(stateId) && String.isBlank(emailId)){
                isOtherFlter = false;
                setCaseIdsFromAddress = getCaseIdsFromAddress(indivSearchWrapper);
                if(setCaseIdsFromAddress.size()>2000){
                    objectData.put('listIndiv',listIndiv);
                    return new LightningServerResponse(false,'More Than 2000 Records',objectData);
                }
            }else{
                setCaseIdsFromAddress.clear();
                isOtherFlter = true;
            }
        }
        // Start: Added by Rishav for CCCAP-3239
        if(!String.isBlank(emailId)){
            isOtherFlter = false;
            Set<Id> indivIdsFromEmail = getIndivIdsFromEmail(emailId);
            if(indivIdsFromEmail.size()>2000){
                objectData.put('listIndiv', listIndiv);
                return new LightningServerResponse(false, 'More Than 2000 Records', objectData);
            } else {
                setIndivIds.addAll(indivIdsFromEmail);
            }
        }
        // End: CCCAP-3239
        if(indivSearchWrapper.phone != null){
            if(setCaseIds.size()>2000){
                objectData.put('listIndiv',listIndiv);
                return new LightningServerResponse(false,'More Than 2000 Records',objectData);
            }else{
                setCaseIdsFromPhone = getCaseIdsFromPhone(String.escapeSingleQuotes(indivSearchWrapper.phone), String.isBlank(indivSearchWrapper.county) ? null : String.escapeSingleQuotes(indivSearchWrapper.county));
            }
        }
        if(setOnlyCaseIds.size()>0){
            Set<Id> finalcaseIdSet = new Set<Id>();
            if(setCaseIdsFromAddress.size()>0 && setCaseIdsFromPhone.size()>0){
                for(Id c : setCaseIdsFromAddress){
                    if(setCaseIdsFromPhone.contains(c)){
                        finalcaseIdSet.add(c);
                    }
                }
                if(finalcaseIdSet.size()>0){
                    for(Id c : finalcaseIdSet){
                        if(setOnlyCaseIds.contains(c)){
                            setCaseIds.add(c);
                        }
                    }
                }
            }
            else if(setCaseIdsFromAddress.size()>0 && setCaseIdsFromPhone.size() == 0){
                for(Id c : setCaseIdsFromAddress){
                    if(setOnlyCaseIds.contains(c)){
                        setCaseIds.add(c);
                    }
                }
            }
            else if(setCaseIdsFromAddress.size() == 0 && setCaseIdsFromPhone.size()>0){
                for(Id c : setCaseIdsFromPhone){
                    if(setOnlyCaseIds.contains(c)){
                        setCaseIds.add(c);
                    }
                }
            }else{
                if(isOtherFlter && (indivSearchWrapper.phone == null || indivSearchWrapper.phone == '')){
                    setCaseIds.addAll(setOnlyCaseIds);
                }
            }
        }else if(setCaseIdsFromAddress.size()>0 && setCaseIdsFromPhone.size()>0 && (indivSearchWrapper.caseId == null || String.isBlank(indivSearchWrapper.caseId))){
            for(Id c : setCaseIdsFromAddress){
                if(setCaseIdsFromPhone.contains(c)){
                    setCaseIds.add(c);
                }
            }
        }else if(setCaseIdsFromAddress.size()>0 && setCaseIdsFromPhone.size() == 0 && (indivSearchWrapper.caseId == null || String.isBlank(indivSearchWrapper.caseId))){
            setCaseIds.addAll(setCaseIdsFromAddress);
        }else if(setCaseIdsFromAddress.size() == 0 && setCaseIdsFromPhone.size()>0 && (indivSearchWrapper.caseId == null || String.isBlank(indivSearchWrapper.caseId))){
            setCaseIds.addAll(setCaseIdsFromPhone);
        }
        if(!setCaseIds.isEmpty()){
            setIndivIds.addAll(getIndivIdsFromCaseIndividual(setCaseIds));
            if(setIndivIds.size()>2000){
                objectData.put('listIndiv',listIndiv);
                return new LightningServerResponse(false,'More Than 2000 Records',objectData);
            }
        }
        if(indivSearchWrapper.searchType != null && indivSearchWrapper.searchType == 'SoundexSearch'){
            listIndiv.addAll(doSoundexSearch(indivSearchWrapper,setIndivIds));
            objectData.put('listIndiv',listIndiv);
            if(listIndiv.size() >2000){
                return new LightningServerResponse(false,'More Than 2000 Records',objectData);  
            } else {
                return new LightningServerResponse(true,'Success',objectData);   
            }
        } else if(indivSearchWrapper.searchType != null && indivSearchWrapper.searchType == 'StringSearch') {
            listIndiv.addAll(doSimpleSearch(indivSearchWrapper,setIndivIds));
            objectData.put('listIndiv',listIndiv);
            if(listIndiv.size() >2000){
                return new LightningServerResponse(false,'More Than 2000 Records',objectData);  
            } else {
                return new LightningServerResponse(true,'Success',objectData);   
            }
        }
        return new LightningServerResponse(true,'Success',objectData);
    }

    public static Set<Id> getCaseIdsFromCase(String caseId){
        Set<Id> setCaseIds = new Set<Id>();
        if(caseId != null){
            for(T_SBSD_CASE__c cse : [SELECT id,Name,IDN_EXTNL__c from T_SBSD_CASE__c where Name =:caseId WITH SECURITY_ENFORCED]){
                setCaseIds.add(cse.Id);
            } 
        }
        return setCaseIds;
    }

    private static Set<Id> getCaseIdsFromAddress(IndividualSearchWrapper indivSearchWrapper){
        Set<Id> setCaseIds = new Set<Id>();
        List<String> listConditions = new List<String>();
        String city = String.isBlank(indivSearchWrapper.city) ? null : String.escapeSingleQuotes(indivSearchWrapper.city);
        String state = String.isBlank(indivSearchWrapper.state) ? null : String.escapeSingleQuotes(indivSearchWrapper.state);
        String zip = String.isBlank(indivSearchWrapper.zip) ? null : String.escapeSingleQuotes(indivSearchWrapper.zip);
        String county = String.isBlank(indivSearchWrapper.county) ? null : String.escapeSingleQuotes(indivSearchWrapper.county);
        String caseId = String.isBlank(indivSearchWrapper.caseId) ? null : String.escapeSingleQuotes(indivSearchWrapper.caseId);
        Boolean isQuery = false;
        List<T_SBSD_CASE_ADR__c> listCaseAddress = new List<T_SBSD_CASE_ADR__c>();
        String queryString = 'SELECT IDN_CASE__c,IDN_CASE__r.CDE_COUNTY__c FROM T_SBSD_CASE_ADR__c ';
        
        if(indivSearchWrapper.city != null && indivSearchWrapper.city != ''){
            listConditions.add('ADR_CITY__c = :city');
        }
        if(indivSearchWrapper.state != null && indivSearchWrapper.state != ''){
            listConditions.add('ADR_STATE__c = :state');
        }
        if(indivSearchWrapper.zip != null){
            listConditions.add('ADR_ZIP_MAIN__c = :zip');
        }
        if(indivSearchWrapper.county != null && indivSearchWrapper.county != ''){
            listConditions.add('IDN_CASE__r.CDE_COUNTY__c = :county');
        }
        if(indivSearchWrapper.caseId != null && indivSearchWrapper.caseId != ''){
            Set<Id> setOnlyCaseIds = new Set<Id>();
            setOnlyCaseIds = getCaseIdsFromCase(indivSearchWrapper.caseId);
            listConditions.add('IDN_CASE__c IN :setOnlyCaseIds');
        } 
        if(!listConditions.isEmpty()){
            for(Integer i=0;i<listConditions.size();i++){
                if(i==0){
                    queryString += 'WHERE '+ listConditions.get(i);
                }else{
                    queryString += ' AND '+listConditions.get(i);
                }
            }
            queryString+='  LIMIT 45000';
            listCaseAddress = Database.query(queryString);
        }
        if(!listCaseAddress.isEmpty()){
            for(T_SBSD_CASE_ADR__c caseAddress : listCaseAddress){
                setCaseIds.add(caseAddress.IDN_CASE__c);
            }
        }
        return setCaseIds;
    }
    
    private static Set<Id> getCaseIdsFromPhone(String phone, String county){
        Set<Id> setCaseIds = new Set<Id>();
        List<String> listConditions = new List<String>();
        List<T_SBSD_CASE_PHONE__c> listCasePhone = new List<T_SBSD_CASE_PHONE__c>();
        String casPhone = String.valueOf(phone);
        String queryString = 'SELECT IDN_CASE__c,IDN_CASE__r.CDE_COUNTY__c FROM T_SBSD_CASE_PHONE__c ';
        if(phone !=  null){
            listConditions.add('NBR_PHONE__c = :casPhone');
        }
        if(county != null && county != ''){
            listConditions.add('IDN_CASE__r.CDE_COUNTY__c = :county');
        }
        if(!listConditions.isEmpty()){
            for(Integer i=0;i<listConditions.size();i++){
                if(i==0){
                    queryString += 'WHERE '+ listConditions.get(i);
                }else{
                    queryString += ' AND '+listConditions.get(i);
                }
            }
            queryString+='  LIMIT 5000';
            listCasePhone = Database.query(queryString);
        }
        if(!listCasePhone.isEmpty()){
            for(T_SBSD_CASE_PHONE__c casePhone : listCasePhone){
                setCaseIds.add(casePhone.IDN_CASE__c);
            }
        }
        return setCaseIds;
    }
    
    private static Set<Id> getIndivIdsFromCaseIndividual(Set<Id> setCaseIds){
        Set<Id> setIndivIds = new Set<Id>();
        if(setCaseIds != null && !setCaseIds.isEmpty()){
            for(T_SBSD_CASE_INDIV__c caseIndiv :[SELECT IDN_CASE__c,IDN_CLIENT__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c IN :setCaseIds WITH SECURITY_ENFORCED LIMIT 2002]){
                setIndivIds.add(caseIndiv.IDN_CLIENT__c);
            }
        }
        return setIndivIds;
    }
    
    private static List<T_SBSD_INDIV__c> doSoundexSearch(IndividualSearchWrapper indivSearchWrapper,Set<Id> setIndivIds){
        List<String> listConditions = new List<String>();
        List<T_SBSD_INDIV__c> listIndiv = new List<T_SBSD_INDIV__c>();
        List<T_SBSD_INDIV__c> finalListIndiv = new List<T_SBSD_INDIV__c>();
        List<T_SBSD_INDIV__c> filteredListIndiv = new List<T_SBSD_INDIV__c>();
        //String soundexString = indivSearchWrapper.indivRec.NAM_FIRST__c + indivSearchWrapper.indivRec.NAM_LAST__c;
        //String soundexValue = SoundexUtil.toSoundex(soundexString);
        //String soundexValue = (indivSearchWrapper.indivRec.NAM_LAST__c !=null? SoundexUtil.toSoundex(indivSearchWrapper.indivRec.NAM_LAST__c).RightPad(6,'0'):'')+SoundexUtil.toSoundex(indivSearchWrapper.indivRec.NAM_FIRST__c); // as per CHATS-2950
        String soundexValue = '';
        Boolean fnLnProvided = false;
        if((indivSearchWrapper.indivRec.NAM_LAST__c !=null && indivSearchWrapper.indivRec.NAM_LAST__c !='') && (indivSearchWrapper.indivRec.NAM_FIRST__c != null && indivSearchWrapper.indivRec.NAM_FIRST__c != '')){
            soundexValue = (indivSearchWrapper.indivRec.NAM_LAST__c !=null? SoundexUtil.toSoundex(String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_LAST__c)).RightPad(6,'0'):'')+SoundexUtil.toSoundex(String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_FIRST__c)); 
            fnLnProvided = true;
        } else if((indivSearchWrapper.indivRec.NAM_LAST__c !=null && indivSearchWrapper.indivRec.NAM_LAST__c != '') && (indivSearchWrapper.indivRec.NAM_FIRST__c == null || indivSearchWrapper.indivRec.NAM_FIRST__c == '')){
            soundexValue =(indivSearchWrapper.indivRec.NAM_LAST__c !=null? SoundexUtil.toSoundex(String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_LAST__c)).RightPad(6,'0'):'');
            fnLnProvided = false;
        } else if((indivSearchWrapper.indivRec.NAM_LAST__c ==null || indivSearchWrapper.indivRec.NAM_LAST__c == '') && (indivSearchWrapper.indivRec.NAM_FIRST__c != null && indivSearchWrapper.indivRec.NAM_FIRST__c != '')){
            soundexValue =SoundexUtil.toSoundex(String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_FIRST__c));
            fnLnProvided = false;
        }
        if(soundexValue!=null && soundexValue !=''){
            soundexValue = soundexValue.replace('0', '_');
        }
        if(soundexValue != null){
            // if(fnLnProvided)
            //    listConditions.add('TXT_SNDX__c = :soundexValue');
            // else
            listConditions.add('TXT_SNDX__c LIKE \'%'+String.escapeSingleQuotes(soundexValue)+'%\'');
        }
        Date dob = indivSearchWrapper.indivRec.DTE_DOB__c;
        String ssn = String.isBlank(indivSearchWrapper.indivRec.NBR_SSN__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.NBR_SSN__c);
        String stateId = String.isBlank(indivSearchWrapper.indivRec.IDN_STATE__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.IDN_STATE__c);
        String query = 'SELECT Id,Name,IDN_STATE__c,NAM_LAST__c,NAM_FIRST__c,NAM_MI__c,DTE_DOB__c,NBR_SSN__c FROM T_SBSD_INDIV__c ';
        if(!setIndivIds.isEmpty()){
            listConditions.add('Id IN :setIndivIds');
        }
        if(dob != null){
            listConditions.add('DTE_DOB__c = :dob');
        }
        if(ssn != null && ssn != ''){
            listConditions.add('NBR_SSN__c = :ssn');
        }
        if(stateId != null && stateId != ''){
            listConditions.add('IDN_STATE__c = :stateId');
        }
        if(!listConditions.isEmpty()){
            for(Integer i=0;i<listConditions.size();i++){
                if(i==0){
                    query += 'WHERE '+ listConditions.get(i);
                }else{
                    query += ' AND '+listConditions.get(i);
                }
            }
            query+='  LIMIT 2002';
            listIndiv = Database.query(query);
            if(isOtherFlter){
                Set<Id> IndivIdSet = new Set<Id>();
                List<Id> caseIdsSet = new List<Id>();
                Set<Id> filterCaseIdsSet = new Set<Id>();
                List<Id> filterCaseIdsList = new List<Id>();
                for(T_SBSD_INDIV__c indiv : listIndiv){
                    IndivIdSet.add(indiv.Id);
                }
                List<Id> IndivIds = new List<Id>();
                IndivIds.addAll(IndivIdSet);
                if(IndivIds.size()>0){
                    caseIdsSet = getCaseRelatedToIndividuals(IndivIds);
                    if(caseIdsSet.size()>0){
                        filterCaseIdsSet = getCaseIdsSetFromAddress(indivSearchWrapper,caseIdsSet);
                        filterCaseIdsList.addAll(filterCaseIdsSet);
                        filteredListIndiv = getIndivRelatedToCases(IndivIds,filterCaseIdsList);
                        finalListIndiv =filteredListIndiv;
                    }
                }
            }else{
                finalListIndiv =listIndiv;
            }
        }
        return finalListIndiv;
    }
    
    private static List<T_SBSD_INDIV__c> doSimpleSearch(IndividualSearchWrapper indivSearchWrapper,Set<Id> setIndivIds){
        String firstName = String.isBlank(indivSearchWrapper.indivRec.NAM_FIRST__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_FIRST__c);
        String lastName = String.isBlank(indivSearchWrapper.indivRec.NAM_LAST__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.NAM_LAST__c);
        Date dob = indivSearchWrapper.indivRec.DTE_DOB__c;
        String ssn = String.isBlank(indivSearchWrapper.indivRec.NBR_SSN__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.NBR_SSN__c);
        String stateId = String.isBlank(indivSearchWrapper.indivRec.IDN_STATE__c) ? null : String.escapeSingleQuotes(indivSearchWrapper.indivRec.IDN_STATE__c);
        List<String> listConditions = new List<String>();
        List<T_SBSD_INDIV__c> listIndiv = new List<T_SBSD_INDIV__c>();
        List<T_SBSD_INDIV__c> finalListIndiv = new List<T_SBSD_INDIV__c>();
        List<T_SBSD_INDIV__c> filteredListIndiv = new List<T_SBSD_INDIV__c>();
        String query = 'SELECT Id,Name,IDN_STATE__c,NAM_LAST__c,NAM_FIRST__c,NAM_MI__c,DTE_DOB__c,NBR_SSN__c'+' FROM T_SBSD_INDIV__c ';
        if(firstName != null && firstName != ''){
            listConditions.add('NAM_First__c = :firstName');
        }
        if(lastName != null && lastName != ''){
            listConditions.add('NAM_LAST__c = :lastName');
        }
        if(setIndivIds!= null && !setIndivIds.isEmpty()){
            listConditions.add('Id IN :setIndivIds');
        }
        if(dob != null){
            listConditions.add('DTE_DOB__c = :dob');
        }
        if(ssn != null && ssn != '' ){
            listConditions.add('NBR_SSN__c = :ssn');
        }
        if(stateId != null && stateId != ''){
            listConditions.add('IDN_STATE__c = :stateId');
        }
        if(!listConditions.isEmpty()){
            for(Integer i=0;i<listConditions.size();i++){
                if(i==0){
                    query += 'WHERE '+ listConditions.get(i);
                }else{
                    query += ' AND '+listConditions.get(i);
                }
            }
            query+='  LIMIT 2002';
            listIndiv = Database.query(query);
            if(isOtherFlter){
                Set<Id> IndivIdSet = new Set<Id>();
                List<Id> caseIdsSet = new List<Id>();
                Set<Id> filterCaseIdsSet = new Set<Id>();
                List<Id> filterCaseIdsList = new List<Id>();
                for(T_SBSD_INDIV__c indiv : listIndiv){
                    IndivIdSet.add(indiv.Id);
                }
                List<Id> IndivIds = new List<Id>();
                IndivIds.addAll(IndivIdSet);
                if(IndivIds.size()>0){
                    caseIdsSet = getCaseRelatedToIndividuals(IndivIds);
                    if(caseIdsSet.size()>0){
                        filterCaseIdsSet = getCaseIdsSetFromAddress(indivSearchWrapper,caseIdsSet);
                        filterCaseIdsList.addAll(filterCaseIdsSet);
                        filteredListIndiv = getIndivRelatedToCases(IndivIds,filterCaseIdsList);
                        finalListIndiv =filteredListIndiv;
                    }
                }
            }else{
                finalListIndiv =listIndiv;
            }
        }
        return finalListIndiv;
    }

    private static Set<Id> getCaseIdsSetFromAddress(IndividualSearchWrapper indivSearchWrapper, List<Id> caseIds){
        Set<Id> setCaseIds = new Set<Id>();
        List<String> listConditions = new List<String>();
        String city = String.isBlank(indivSearchWrapper.city) ? null : String.escapeSingleQuotes(indivSearchWrapper.city);
        String state = String.isBlank(indivSearchWrapper.state) ? null : String.escapeSingleQuotes(indivSearchWrapper.state);
        String zip = String.isBlank(indivSearchWrapper.zip) ? null : String.escapeSingleQuotes(indivSearchWrapper.zip);
        String county = String.isBlank(indivSearchWrapper.county) ? null : String.escapeSingleQuotes(indivSearchWrapper.county);
        String caseId = String.isBlank(indivSearchWrapper.caseId) ? null : String.escapeSingleQuotes(indivSearchWrapper.caseId);
        Boolean isQuery = false;
        List<T_SBSD_CASE_ADR__c> listCaseAddress = new List<T_SBSD_CASE_ADR__c>();
        String queryString = 'SELECT IDN_CASE__c,IDN_CASE__r.CDE_COUNTY__c FROM T_SBSD_CASE_ADR__c ';
        
        if(indivSearchWrapper.city != null && indivSearchWrapper.city != ''){
            listConditions.add('ADR_CITY__c = :city');
        }
        if(indivSearchWrapper.state != null && indivSearchWrapper.state != ''){
            listConditions.add('ADR_STATE__c = :state');
        }
        if(indivSearchWrapper.zip != null){
            listConditions.add('ADR_ZIP_MAIN__c = :zip');
        }
        if(indivSearchWrapper.county != null && indivSearchWrapper.county != ''){
            listConditions.add('IDN_CASE__r.CDE_COUNTY__c = :county');
        }
        if(caseIds.size()>0){
            Set<Id> setOnlyCaseIds = new Set<Id>();
            setOnlyCaseIds.addAll(caseIds);
            listConditions.add('IDN_CASE__c IN :setOnlyCaseIds');
        }
        if(!listConditions.isEmpty()){
            for(Integer i=0;i<listConditions.size();i++){
                if(i==0){
                    queryString += 'WHERE '+ listConditions.get(i);
                }else{
                    queryString += ' AND '+listConditions.get(i);
                }
            }
            queryString+='  LIMIT 45000';
            listCaseAddress = Database.query(queryString);
        }
        if(!listCaseAddress.isEmpty()){
            for(T_SBSD_CASE_ADR__c caseAddress : listCaseAddress){
                setCaseIds.add(caseAddress.IDN_CASE__c);
            }
        }
        return setCaseIds;
    }

    @auraEnabled
    public static List<Id> getCaseRelatedToIndividuals(List<Id> individualIdSet){
        List<Id> lstCaseId = new List<Id>();
        for(T_SBSD_CASE_INDIV__c caseIndiv :[SELECT IDN_CASE__c from T_SBSD_CASE_INDIV__c where IDN_CLIENT__c IN:individualIdSet WITH SECURITY_ENFORCED]){
            lstCaseId.add(caseIndiv.IDN_CASE__c);
        }
        return lstCaseId;
    }

    @auraEnabled
    public static List<T_SBSD_INDIV__c> getIndivRelatedToCases(List<Id> individualIdSet, List<Id> caseIdSet){
        List<Id> lstCaseId = new List<Id>();
        Set<Id> IndivIdSet = new Set<Id>();
        String query = 'SELECT Id,Name,IDN_STATE__c,NAM_LAST__c,NAM_FIRST__c,NAM_MI__c,DTE_DOB__c,NBR_SSN__c'+' FROM T_SBSD_INDIV__c WHERE ';
        List<T_SBSD_INDIV__c> listIndiv = new List<T_SBSD_INDIV__c>();
        for (T_SBSD_CASE_INDIV__c caseIndiv :[SELECT IDN_CASE__c,IDN_CLIENT__c from T_SBSD_CASE_INDIV__c where IDN_CLIENT__c IN:individualIdSet and IDN_CASE__c IN:caseIdSet WITH SECURITY_ENFORCED]){
            IndivIdSet.Add(caseIndiv.IDN_CLIENT__c);    
        }
        if(IndivIdSet.size()>0){
            query =query+' Id IN:IndivIdSet';
            query+='  LIMIT 2002';
            listIndiv = Database.query(query);
        }
        return listIndiv;
    }

    @auraEnabled
    public static LightningServerResponse getCaseRelatedToIndividual(String individualId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<IndividualCaseDetailWrapper> lstCaseDetailWrapper = new List<IndividualCaseDetailWrapper>();
        List<Id> lstCaseId = new List<Id>();
        for(T_SBSD_CASE_INDIV__c caseIndiv :[SELECT IDN_CASE__c from T_SBSD_CASE_INDIV__c where IDN_CLIENT__c=:individualId WITH SECURITY_ENFORCED]){
            lstCaseId.add(caseIndiv.IDN_CASE__c);
        }
        for(T_SBSD_INDIV__c individualRec :[SELECT NAM_FIRST__c,NAM_LAST__c, NAM_MI__c from T_SBSD_INDIV__c where ID =: individualId WITH SECURITY_ENFORCED]){
            String fullName= (String.isBlank(individualRec.NAM_LAST__c)? '' : individualRec.NAM_LAST__c) +','+(String.isBlank(individualRec.NAM_FIRST__c)? '' : ' '+individualRec.NAM_FIRST__c)+(String.isBlank(individualRec.NAM_MI__c)? '' :' '+individualRec.NAM_MI__c);
            objectData.put('fullName',fullName );
        }
        for(T_SBSD_Case__c caseRec: [Select Id, Name, CDE_COUNTY__r.name,
                                      (Select ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c 
                                       from T_SBSD_CASE3__r where CDE_TYPE_ADR__c = 'HOM'),
                                      (Select toLabel(CDE_STATUS_CASE__c) from T_SBSD_CASE10__r where DTE_BEGIN_EFFV__c <= TODAY
                                       and (DTE_END_EFFV__c >= TODAY or DTE_END_EFFV__c = null))
                                      from T_SBSD_Case__c where ID in : lstCaseId WITH SECURITY_ENFORCED]){
                                          Id caseRecID = caseRec.Id;
                                          String caseID =caseRec.Name;
                                          String countyName= caseRec.CDE_COUNTY__r.name;
                                          String address= ' ';
                                          if(caseRec.T_SBSD_CASE3__r.size()>0){
                                              if(caseRec.T_SBSD_CASE3__r.get(0).ADR_LINE_1__c !=null){
                                                  address+= caseRec.T_SBSD_CASE3__r.get(0).ADR_LINE_1__c;
                                              }
                                              if(caseRec.T_SBSD_CASE3__r.get(0).ADR_LINE_2__c !=null){
                                                  address+= ' '+ caseRec.T_SBSD_CASE3__r.get(0).ADR_LINE_2__c;
                                              }
                                              if(caseRec.T_SBSD_CASE3__r.get(0).ADR_CITY__c !=null){
                                                  address+= ' '+ caseRec.T_SBSD_CASE3__r.get(0).ADR_CITY__c;
                                              }
                                              if(caseRec.T_SBSD_CASE3__r.get(0).ADR_STATE__c !=null){
                                                  address+= ' '+ caseRec.T_SBSD_CASE3__r.get(0).ADR_STATE__c;
                                              }
                                              if(caseRec.T_SBSD_CASE3__r.get(0).ADR_ZIP_MAIN__c !=null){
                                                  address+= ' '+ caseRec.T_SBSD_CASE3__r.get(0).ADR_ZIP_MAIN__c;
                                              }
                                              if(caseRec.T_SBSD_CASE3__r.get(0).ADR_ZIP_EXTN__c !=null){
                                                  address+= ' '+ caseRec.T_SBSD_CASE3__r.get(0).ADR_ZIP_EXTN__c;
                                              }
                                          }
                                          String caseStatus = ' ';
                                          if(caseRec.T_SBSD_CASE10__r.size()>0){
                                              caseStatus   = caseRec.T_SBSD_CASE10__r.get(0).CDE_STATUS_CASE__c;
                                          }
                                          lstCaseDetailWrapper.add(new IndividualCaseDetailWrapper(caseRecID,caseID,caseStatus,address,countyName));
                                      }
        objectData.put('lstCaseDetailWrapper', lstCaseDetailWrapper);
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }

    @AuraEnabled
    public static Boolean getCaseButtonVisibility(){
        try{
            Boolean caseButtonVisible = true;
            //CCCAP-14993 using custom permission
           /* List<String> lstProfilesNoAccess = Label.CaseButtonVisibility.split(';') ;
            Set<String> setProfilesNoAccess = new Set<String>(lstProfilesNoAccess);
            String profileId = UserInfo.getProfileId();
            // CCCAP-6479: Intentionally not adding 'WITH SECURITY_ENFORCED' as it causes issue with non-admin profiles
            Profile profile = [SELECT Id, Name FROM Profile WHERE Id =: profileId];*/
            if(FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') || FeatureManagement.checkPermission('Read_Only_User') ||
            FeatureManagement.checkPermission('Provider_Worker') ||FeatureManagement.checkPermission('Provider_Worker_Supervisor') ||FeatureManagement.checkPermission('Business_Office_Worker') || FeatureManagement.checkPermission('Business_Office_Supervisor')) {
                caseButtonVisible = false;
            }
            return caseButtonVisible;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    // Added by Rishav for CCCAP-3239
    private static Set<Id> getIndivIdsFromEmail(String emailId){
        Set<Id> indivIdSet = new Set<Id>();
        emailId = '%'+emailId+'%';
        List<Individual_E_mail__c> indivEmailList = [SELECT Id, Individual__c, Email_Information__c FROM Individual_E_mail__c WHERE Email_Information__c LIKE: emailId WITH SECURITY_ENFORCED];
        for(Individual_E_mail__c ie : indivEmailList){
            indivIdSet.add(ie.Individual__c);
        }
        return indivIdSet;
    }

    @AuraEnabled
    public static LightningServerResponse checkRejectedReferral(Id recordId){
        try {
            Map<String, Object> objectData = new Map<String, Object>();
            Boolean isSuccessful = true;
            String message='';
            String sObjName = recordId.getSObjectType().getDescribe().getName();
            Boolean isRejectedReferral = false;
            if(sObjName == 'T_APPLN_PRCS_QUEUE__c'){
                T_APPLN_PRCS_QUEUE__c appProcessQueue = [SELECT Id, CDE_SOURCE__c, CDE_STATUS_APPLN__c, IDN_APPLN__r.IDN_CBMS_REF__c FROM T_APPLN_PRCS_QUEUE__c WHERE Id =:recordId LIMIT 1];
                if(appProcessQueue.CDE_SOURCE__c == 'CB' && appProcessQueue.CDE_STATUS_APPLN__c == 'REJ'){
                    isRejectedReferral = true;
                }
                objectData.put('applnProcessQueueRec',appProcessQueue);
            }            
            objectData.put('isRejectedReferral',isRejectedReferral);
            return new LightningServerResponse(isSuccessful, message, objectData);            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}