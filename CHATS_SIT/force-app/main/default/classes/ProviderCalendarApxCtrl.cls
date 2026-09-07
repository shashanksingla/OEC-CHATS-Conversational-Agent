/*
Author : Pooja Pramod Aher
Description : Class for Creation of Provider Calendar Functionality.
Test Class : ProviderCalendarTest.apxc
*/
public class ProviderCalendarApxCtrl {
    private static Map<id, T_AUTH__c> authMap = new map<id,T_AUTH__c>();
    private static Map<String,List<batchsit_t_auth_encmbr__x>> fetchedEncumberence = new Map<String,List<batchsit_t_auth_encmbr__x>>();
    private static List<batchsit_t_auth_encmbr__x> listOfencumberance=new List<batchsit_t_auth_encmbr__x>();
    private static List<T_AUTH_ENCUMBR__c> recToInsert = new List<T_AUTH_ENCUMBR__c>();
    private static Map<Id,T_AUTH__c> authUpdateMap = new Map<Id,T_AUTH__c>();
    private static string anyAuthId;
    //method to get initial details
    @AuraEnabled
    public static LightningServerResponse getInitData(string recordid){        
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message; 
        
        Map<string,id> provCloMap = new Map<string,id>();
        List<ProvClosWrapp> closWrapList = new List<ProvClosWrapp>();
        List<T_PROVR_FISCAL_AGREMENT__c> faList = [SELECT Id, CDE_COUNTY__c, ID_SERVICE__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c
                                                   FROM T_PROVR_FISCAL_AGREMENT__c WHERE Id = :recordid];
        T_PROVR_FISCAL_AGREMENT__c faRec = faList[0];
        Id providerId = faRec.ID_SERVICE__c;
        Id countyId = faRec.CDE_COUNTY__c;
        
        set<string> holidaySet = new set<string>();
        List<T_COUNTY_RATE__c> crpList = [SELECT Id, PAYMENT_Q13_1__c, DTE_BEGIN_EFFV_RATE__c, DTE_END_EFFV_RATE__c 
                                          FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c = :countyId AND CDE_STATUS__c = 'APV'
                                          AND IND_RATE_PLAN_TEMPLT__c = false AND PAYMENT_Q13_1__c != null AND (DTE_BEGIN_EFFV_RATE__c <=today or DTE_BEGIN_EFFV_RATE__c >=today)
                                          AND (DTE_END_EFFV_RATE__c >= TODAY OR DTE_END_EFFV_RATE__c = LAST_N_DAYS:9 OR DTE_END_EFFV_RATE__c = null)];
        for(T_COUNTY_RATE__c crp : crpList){
            if((crp.DTE_END_EFFV_RATE__c == null || crp.DTE_END_EFFV_RATE__c > faRec.DTE_BEGIN_AGRMT__c) 
            && crp.DTE_BEGIN_EFFV_RATE__c < faRec.DTE_END_AGRMT__c){
                holidaySet.addAll(crp.PAYMENT_Q13_1__c.split(';'));
            }
        }
        
        set<date> holidayDates = new set<date>();
        Date holDt;
        for(T_YEAR_HOL__c holiday : [SELECT DTE_HOL__c, DTE_OBSERVED_HOL__c, CDE_HOL__c FROM T_YEAR_HOL__c 
                                     WHERE CDE_HOL__c IN :holidaySet AND ((DTE_HOL__c >= TODAY OR DTE_HOL__c = LAST_N_DAYS:9) or (DTE_OBSERVED_HOL__c >= TODAY OR DTE_OBSERVED_HOL__c = LAST_N_DAYS:9)) AND
(DTE_HOL__c <= :faRec.DTE_END_AGRMT__c or DTE_OBSERVED_HOL__c <= :faRec.DTE_END_AGRMT__c)]){
            holDt = holiday.DTE_OBSERVED_HOL__c != null ? holiday.DTE_OBSERVED_HOL__c : holiday.DTE_HOL__c;
            for(T_COUNTY_RATE__c crp : crpList){
                String crpHol = crp.PAYMENT_Q13_1__c+';';
                if(holiday.DTE_OBSERVED_HOL__c != null //&& crp.DTE_BEGIN_EFFV_RATE__c <= holiday.DTE_OBSERVED_HOL__c  //&& (crp.DTE_END_EFFV_RATE__c >= holiday.DTE_OBSERVED_HOL__c || crp.DTE_END_EFFV_RATE__c == null)
                  		&& crpHol.contains(holiday.CDE_HOL__c+';')){
                    holidayDates.add(holiday.DTE_OBSERVED_HOL__c);
                     
                } 
                if(holiday.DTE_HOL__c != null //&& crp.DTE_BEGIN_EFFV_RATE__c <= holiday.DTE_HOL__c // && (crp.DTE_END_EFFV_RATE__c >= holiday.DTE_HOL__c || crp.DTE_END_EFFV_RATE__c == null)
                  		&& crpHol.contains(holiday.CDE_HOL__c+';')){
                    holidayDates.add(holiday.DTE_HOL__c);
                }                              
            }  
        }
        
        List<T_CHATS_PROVR_STATUS__c> provider = [SELECT Id, Name, NAM_FACILITY__c, 
                                                	(SELECT Id, DTE_BEGIN_CLOSURE__c, IND_ACTIVE__c, IDN_PROVIDER__c, TXT_COMMENTS__c, CDE_COUNTY__c
                                                     FROM Provider_Closure__r WHERE CDE_COUNTY__c = :countyId)
                                                  FROM T_CHATS_PROVR_STATUS__c WHERE id = :providerId];
        
        if(provider[0].Provider_Closure__r != null && !provider[0].Provider_Closure__r.isEmpty()){
            for(T_PROVR_CLOSURE__c indiClosure : provider[0].Provider_Closure__r){
                ProvClosWrapp indiWrap = new ProvClosWrapp();
                Date beginDate = indiClosure.DTE_BEGIN_CLOSURE__c;
                
                provCloMap.put(beginDate.year()+'-'+beginDate.month()+'-'+beginDate.day(),
                               indiClosure.id);
                indiWrap.beginDate = beginDate;
                indiWrap.newbeginDate = beginDate.year()+'-'+beginDate.month()+'-'+beginDate.day();
                indiWrap.comment = indiClosure.TXT_COMMENTS__c;
                indiWrap.checked = indiClosure.IND_ACTIVE__c;
                closWrapList.add(indiWrap);
            }
        }
        objectData.put('provCloMap', provCloMap);
        objectData.put('prov', provider[0]);
        objectData.put('provClosure',closWrapList);
        objectData.put('countyId', countyId);
        objectData.put('faRec', faRec);
        objectData.put('holidayDates', holidayDates);
        
        isSuccessful = true;
        /* Using Custom Permission CCCAP-14993
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
        String MyProflieName = PROFILE[0].Name;*/
        //MyProflieName=='System Administrator' || 
        if(FeatureManagement.checkPermission('Eligibility_Worker') || FeatureManagement.checkPermission('Eligibility_Worker_Supervisor') 
        || FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') || FeatureManagement.checkPermission('Read_Only_User')){
            objectData.put('profileCheck', true);
           // objectData.put('profileName', MyProflieName); Commenting out since not used in UI CCCAP-14993
        }
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse saveData(string recordData, list<date> holidayList){
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message;  
        set<date> encumRecoToupdate = new set<date>();
        set<date> allDatesModified = new set<date>(); 
        Savepoint sp;
        try{
            ProvClosWrapp provDe = (ProvClosWrapp)System.JSON.deserialize(recordData,ProvClosWrapp.class);  
            
            List<T_PROVR_CLOSURE__c> provList = [SELECT Id, Name, DTE_BEGIN_CLOSURE__c, CDE_COUNTY__c,
                                                 	IDN_PROVIDER__c,TXT_COMMENTS__c,IND_ACTIVE__c  
                                                 FROM T_PROVR_CLOSURE__c 
                                                 WHERE IDN_PROVIDER__c =:provDe.proRecId AND CDE_COUNTY__c =:provDe.countyId];
            
            Map<date,T_PROVR_CLOSURE__c> exiRec = new Map<date,T_PROVR_CLOSURE__c>();
            Map<date,T_PROVR_CLOSURE__c> exiRec2 = new Map<date,T_PROVR_CLOSURE__c>();
            List<T_PROVR_CLOSURE__c> recordToInsert = new List<T_PROVR_CLOSURE__c>();
            if(provList.size() > 0 ){
                for(T_PROVR_CLOSURE__c indProv : provList){
                    exiRec.put(indProv.DTE_BEGIN_CLOSURE__c,indProv);
                }  
                exiRec2 = exiRec.deepClone();
            }            
            
            Integer betDays = provDe.beginDate.daysBetween(provDe.endDate);
            Date beginDate = provDe.beginDate;
            for(integer i=0; i<=betDays; i++){
                Boolean skipDate = false;
                for(Date dt : holidayList){
                    if(dt == beginDate){
                        skipDate = true;
                    }
                }
                if(skipDate){
                    beginDate = beginDate+1;
                    continue;
                }
                T_PROVR_CLOSURE__c prc = new T_PROVR_CLOSURE__c();
                if(!exiRec.isEmpty()){
                    if(exiRec.containsKey(beginDate)){
                        exiRec.get(beginDate).IND_ACTIVE__c = true;
                        exiRec.get(beginDate).TXT_COMMENTS__c = provDe.comment;
                    }else{
                        prc.DTE_BEGIN_CLOSURE__c = beginDate;
                        prc.CDE_COUNTY__c = provDe.countyId;
                        prc.IDN_PROVIDER__c = provDe.proRecId;
                        prc.TXT_COMMENTS__c = provDe.comment;
                        prc.IND_ACTIVE__c = true;
                    }
                }else{
                    prc.DTE_BEGIN_CLOSURE__c = beginDate;
                    prc.CDE_COUNTY__c = provDe.countyId;
                    prc.IDN_PROVIDER__c = provDe.proRecId;
                    prc.TXT_COMMENTS__c = provDe.comment;
                    prc.IND_ACTIVE__c = true;
                }
                recordToInsert.add(prc);
                encumRecoToupdate.add(beginDate);
                beginDate = beginDate+1;
            }
            allDatesModified.addAll(encumRecoToupdate);
            fetchAuthEncumData(allDatesModified,provDe.proRecId,provDe.countyId);
            
            if(recordToInsert.size() > 0){
                updateAuthEncumRecord(encumRecoToupdate,provDe.proRecId,provDe.countyId);
            }
            sp = Database.setSavepoint();
            Database.insert(recordToInsert, false);
            if(!exiRec.equals(exiRec2)){
                Database.update(exiRec.values(), false);
            }
            if(recToInsert.size()>0){
                database.insert(recToInsert,false);
            }
            AuthorizationStatusController.insertATSRecords(authUpdateMap.values());
           // triggerCR213Corr(authUpdateMap.values());
            isSuccessful = true; 
            objectData.put('createError',false);
            objectData.put('authList',authUpdateMap.values());
            
        }catch(Exception e){
            isSuccessful = false;
            message = e.getMessage();
            objectData.put('createError',false);
            if(sp!=null){
	            Database.rollback(sp);                
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse updateData(string recordData,string provId,string countyId,string faId){
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message;  
        boolean needDel = true;
        set<date> encumRecoToupdate = new set<date>();
        set<date> encumRecoDeleted = new set<date>();
        set<date>allDatesModified = new set<date>();
        Savepoint sp;
        Map<date,T_PROVR_CLOSURE__c> exiRec = new Map<date,T_PROVR_CLOSURE__c>();
        try{
            List<T_PROVR_CLOSURE__c> listToInsert = new List<T_PROVR_CLOSURE__c>();
            List<ProvClosWrapp> provClos = (List<ProvClosWrapp>)System.JSON.deserialize(recordData,List<ProvClosWrapp>.class);  
            
            List<T_PROVR_CLOSURE__c> provList = [SELECT Id, Name, DTE_BEGIN_CLOSURE__c, CDE_COUNTY__c,
                                               		IDN_PROVIDER__c,TXT_COMMENTS__c,IND_ACTIVE__c  
                                               	 FROM T_PROVR_CLOSURE__c 
                                                 WHERE IDN_PROVIDER__c =:provId AND CDE_COUNTY__c =:countyId];
            if(provList.size()>0){
                for(T_PROVR_CLOSURE__c indProv : provList){
                    exiRec.put(indProv.DTE_BEGIN_CLOSURE__c,indProv);
                }                  
            } 
            Date beginDate;
            for(ProvClosWrapp indiProv : provClos){
                T_PROVR_CLOSURE__c toAdd = new T_PROVR_CLOSURE__c();
                beginDate = Date.valueof(indiProv.newbeginDate);
                if(!exiRec.isEmpty()) {
                    if(exiRec.containsKey(beginDate)){
                        if(indiProv.checked == false && exiRec.get(beginDate).IND_ACTIVE__c == true){
                            encumRecoDeleted.add(beginDate);
                        }
                        if(indiProv.checked == true && exiRec.get(beginDate).IND_ACTIVE__c == false){
                            encumRecoToupdate.add(beginDate);
                        }
                        exiRec.get(beginDate).IND_ACTIVE__c = indiProv.checked;
                        exiRec.get(beginDate).TXT_COMMENTS__c = indiProv.comment;
                    }
                    else{
                        toAdd.DTE_BEGIN_CLOSURE__c = beginDate;
                        toAdd.IDN_PROVIDER__c = provId;
                        toAdd.CDE_COUNTY__c = countyId;
                        toAdd.TXT_COMMENTS__c = indiProv.comment;
                        toAdd.IND_ACTIVE__c = indiProv.checked;
                        listToInsert.add(toAdd);
                        if(indiProv.checked == true){
                            encumRecoToupdate.add(beginDate);
                        }
                    }
                }
                else{                   
                    toAdd.DTE_BEGIN_CLOSURE__c = beginDate;
                    toAdd.IDN_PROVIDER__c = provId;
                    toAdd.CDE_COUNTY__c = countyId;
                    toAdd.TXT_COMMENTS__c = indiProv.comment;
                    toAdd.IND_ACTIVE__c = indiProv.checked;
                    listToInsert.add(toAdd);
                    if(indiProv.checked == true){
                        encumRecoToupdate.add(beginDate);
                    }
                }
            }
            allDatesModified.addAll(encumRecoToupdate);
            allDatesModified.addAll(encumRecoDeleted);
            fetchAuthEncumData(allDatesModified,provId,countyId); 
            
            if(encumRecoToupdate.size() > 0){
                updateAuthEncumRecord(encumRecoToupdate,provId,countyId);
            }
            if(encumRecoDeleted.size() > 0){
                updateEncumInactiv(encumRecoDeleted,provId,countyId);
            }
            sp = Database.setSavepoint();
            if(listToInsert != null && !listToInsert.isEmpty()){
                insert listToInsert;
            }
            Database.update(exiRec.values(), false);            
            if(recToInsert.size()>0){
                database.insert(recToInsert,false);
            }
            AuthorizationStatusController.insertATSRecords(authUpdateMap.values());
            //triggerCR213Corr(authUpdateMap.values());
            LightningServerResponse exist = ProviderCalendarApxCtrl.getInitData(faId);
            objectData.put('updatedProv', exist.objectData.get('provClosure'));
            objectData.put('authList',authUpdateMap.values());
            
            isSuccessful = true;
            message = 'success';
            objectData.put('createError',false);
        }catch(Exception e){
            isSuccessful = false;
            message = e.getMessage();
            objectData.put('createError',false);
            if(sp!=null){
	            Database.rollback(sp);                
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    public static void updateAuthEncumRecord(set<date> dateList,id provId,id countyId){
        Map<id, Map<date,T_AUTH_ENCUMBR__c>> response = new Map<id,Map<date,T_AUTH_ENCUMBR__c>>();
        Map<String,string> resultMap = new Map<String,string>();
        
        if(!authMap.isEmpty()){
            List<T_AUTH_ENCUMBR__c> encumList = [SELECT Id, IDN_AUTH__c,dte_care__c,cnt_hour_care__c,cde_status_encmbr__c, ind_0_36_months__c 
                                                   FROM T_AUTH_ENCUMBR__c WHERE IDN_AUTH__c in : authMap.keySet()];
            if(encumList.size()>0){
                for(T_AUTH_ENCUMBR__c indiEncum : encumList){
                    if(response.containsKey(indiEncum.IDN_AUTH__c)){
                        Map<date,T_AUTH_ENCUMBR__c> orgMap = response.get(indiEncum.IDN_AUTH__c);
                        orgMap.put(indiEncum.dte_care__c, indiEncum);
                        response.put(indiEncum.IDN_AUTH__c,orgMap);
                    }
                    else{
                        response.put(indiEncum.IDN_AUTH__c,new Map<date,T_AUTH_ENCUMBR__c>{indiEncum.dte_care__c=>indiEncum});
                    }
            	}
            }
            if(Test.isRunningTest()){
                batchsit_t_auth_encmbr__x statBtch = new batchsit_t_auth_encmbr__x(idn_auth__c =anyAuthId,dte_care__c =System.today(),cnt_Hour_Care__c =4,cde_status_encmbr__c='2',ind_0_36_months__c='N');
                listOfencumberance.add(statBtch);
            }
            List<encumbranceWrap> encumtoupdate = new List<encumbranceWrap>();
            if(listOfencumberance.size()>0){
                system.debug('dateList -->'+dateList);
                for(batchsit_t_auth_encmbr__x indiEncum : listOfencumberance){
                    system.debug('indiEncum.dte_care__c'+indiEncum.dte_care__c);
                    if(dateList.contains(indiEncum.dte_care__c)){
                        encumbranceWrap indiWrap=new encumbranceWrap();
                        //Salesforce ENCUM update
                        Map<date,T_AUTH_ENCUMBR__c> dtVsAuth = new Map<date,T_AUTH_ENCUMBR__c>();
                        dtVsAuth=response.get(indiEncum.idn_Auth__c);
                        if(dtVsAuth!=null && !dtVsAuth.isEmpty() && dtVsAuth.containsKey(indiEncum.dte_care__c)){
                            //no need to update
                        }else{
                            T_AUTH_ENCUMBR__c indiEncumbrance = new T_AUTH_ENCUMBR__c();
                            indiEncumbrance.IDN_AUTH__c = indiEncum.idn_Auth__c;
                            indiEncumbrance.dte_care__c = indiEncum.dte_care__c;
                            indiEncumbrance.cnt_hour_care__c = indiEncum.cnt_Hour_Care__c;
                            indiEncumbrance.cde_status_encmbr__c = indiEncum.cde_status_encmbr__c;
                            indiEncumbrance.ind_0_36_months__c = indiEncum.ind_0_36_months__c; //added for CCCAP-14174
                            recToInsert.add(indiEncumbrance);
                        }
                        indiWrap.cde_Status_Encmbr = '5';
                        //indi.cde_Status_Encmbrcde_Type_Unit_Care;
                        indiWrap.cnt_Hour_Care = '0';
                        indiWrap.lastmodifieddate = String.valueOf(system.now().format('yyyy-MM-dd HH:mm:ss')) ;
                        indiWrap.lastmodifiedbyid = Userinfo.getUserId();
                        indiWrap.idn_Encmbr_Auth = string.valueof(indiEncum.ExternalId);
                        encumtoupdate.add(indiWrap);
                        if(!authUpdateMap.containsKey(indiEncum.idn_Auth__c)){
                            authUpdateMap.put(indiEncum.idn_Auth__c,authMap.get(indiEncum.idn_Auth__c));
                        }
                    }
                }
                system.debug('serialize '+JSON.serialize(encumtoupdate));
                if(!Test.isRunningTest()){
                    resultMap = HerokuService.authEncumbranceUpdate(JSON.serialize(encumtoupdate));
                    if(HerokuService.isApiSuccess == false){
                        throw new AuraHandledException('There is an unknown problem. Please contact your administrator.');
                    }
                }
                system.debug('resultMap '+resultMap);
            }
        }       
    }
    public static void updateEncumInactiv(set<date> encumSet,id provId,id countyId){
        Map<id,Map<date,T_AUTH_ENCUMBR__c>> response = new Map<id,Map<date,T_AUTH_ENCUMBR__c>>();
        Map<String,string> resultMap = new Map<String,string>();
        if(!authMap.isEmpty()){
            if(Test.isRunningTest()){
                batchsit_t_auth_encmbr__x statBtch = new batchsit_t_auth_encmbr__x(idn_auth__c =anyAuthId,dte_care__c =system.today()+9,cnt_Hour_Care__c =4,cde_status_encmbr__c='2');
                listOfencumberance.add(statBtch);
            }
            List<T_AUTH_ENCUMBR__c> encumList = [select id, IDN_AUTH__c,dte_care__c,cnt_hour_care__c,cde_status_encmbr__c, ind_0_36_months__c 
                                                   from T_AUTH_ENCUMBR__c where IDN_AUTH__c in : authMap.keySet()];
            if(encumList.size()>0){
                for(T_AUTH_ENCUMBR__c indiEncum : encumList){
                    if(response.containsKey(indiEncum.IDN_AUTH__c)){
                        Map<date,T_AUTH_ENCUMBR__c> orgMap = response.get(indiEncum.IDN_AUTH__c);
                        orgMap.put(indiEncum.dte_care__c, indiEncum);
                        response.put(indiEncum.IDN_AUTH__c,orgMap);
                    }
                    else{
                        response.put(indiEncum.IDN_AUTH__c,new Map<date,T_AUTH_ENCUMBR__c>{indiEncum.dte_care__c=>indiEncum});
                    }
            	}
            }
            if(listOfencumberance.size()>0){                         
                List<encumbranceWrap> encumtoupdate = new List<encumbranceWrap>();
                system.debug('encumSet -- >'+encumSet);
                for(batchsit_t_auth_encmbr__x indiEncum : listOfencumberance){
                    system.debug('indiEncum.dte_care__c'+indiEncum.dte_care__c);
                    if(encumSet.contains(indiEncum.dte_care__c)){
                        encumbranceWrap indiWrap=new encumbranceWrap();
                        string originalStatus,originalHour;
                        Map<date,T_AUTH_ENCUMBR__c> dtVsAuth = new Map<date,T_AUTH_ENCUMBR__c>();
                        dtVsAuth=response.get(indiEncum.idn_Auth__c);
                        if(dtVsAuth != null && !dtVsAuth.isEmpty() && dtVsAuth.containsKey(indiEncum.dte_care__c)){
                            originalStatus = dtVsAuth.get(indiEncum.dte_care__c).cde_status_encmbr__c;
                            originalHour = String.valueOf(dtVsAuth.get(indiEncum.dte_care__c).cnt_hour_care__c);
                        }
                        
                        indiWrap.cde_Status_Encmbr = originalStatus==null? '2' : originalStatus;
                        indiWrap.cnt_Hour_Care = originalHour == null? '0' : originalHour;
                        indiWrap.lastmodifieddate = String.valueOf(system.now().format('yyyy-MM-dd HH:mm:ss')) ;
                        indiWrap.lastmodifiedbyid = Userinfo.getUserId();
                        indiWrap.idn_Encmbr_Auth = string.valueof(indiEncum.ExternalId);
                        encumtoupdate.add(indiWrap);                           
                        if(!authUpdateMap.containsKey(indiEncum.idn_Auth__c)){
                            authUpdateMap.put(indiEncum.idn_Auth__c,authMap.get(indiEncum.idn_Auth__c));
                        }
                    }
                }
                
                system.debug('serialize '+JSON.serialize(encumtoupdate));
                if(!Test.isRunningTest()){
                    resultMap = HerokuService.authEncumbranceUpdate(JSON.serialize(encumtoupdate));
                    if(HerokuService.isApiSuccess == false){
                        throw new AuraHandledException('There is an unknown problem. Please contact your administrator.');
                    }
                }
                system.debug('resultMap '+resultMap);
            }
        }        
    }
     @AuraEnabled
    public static void triggerCR213Corr(List<T_AUTH__c> authList){
        String CR213RsnCode = Label.CR0010;
        
        Map<string,string> keyParams;
        set<Id> recordKeys = new set<Id>();
        map<Id, String> rsnCodeMap = new map<Id, String>();
        map<Id, String> corspdnameMap = new map<Id, String>();
        map<Id, String> sendToMap = new map<Id, String>();
        map<Id, Integer> countyCodeMap = new map<Id, Integer>();
        Map<Id, map<string,string>> keyParamsMap = new Map<Id, map<string,string>>();
        for(T_AUTH__c auth : authList){
            keyParams = new Map<string, string>();
            keyParams.put('caseId', auth.IDN_CASE__r.Name);
            keyParams.put('providerId', auth.IDN_PROVR__r.Name);
            keyParams.put('authId', auth.Id);
            
            recordKeys.add(auth.Id);
            rsnCodeMap.put(auth.Id, CR213RsnCode);
            corspdnameMap.put(auth.Id, null);
            sendToMap.put(auth.Id, null);
            countyCodeMap.put(auth.Id, integer.valueOf(auth.CDE_COUNTY__r.CDE_COUNTY__c));
            keyParamsMap.put(auth.Id, keyParams);
        }
        
        if(!Test.isRunningTest() && recordKeys.size() > 0){
            CorspdTrigger.createCorspdRequestBulk(recordKeys, rsnCodeMap, corspdnameMap, sendToMap, countyCodeMap, keyParamsMap, null); 
        }
    }
    private static void fetchAuthEncumData(set<date> dateset,id provId,id countyId){
        for(T_AUTH__c indiAuth : [SELECT Id, Name, Authorization_Status__c, IDN_PROVR__c, Number_of_Drop_in_Days__c, IDN_CASE__r.Name, IDN_PROVR__r.Name, CDE_COUNTY__r.CDE_COUNTY__c, isFinishedFlow__c, IDN_EXTNL__c 
                                  FROM T_AUTH__c where Authorization_Status__c ='2' AND IDN_PROVR__c = :provId AND CDE_COUNTY__c =:countyId]){
                                      authMap.put(indiAuth.id, indiAuth);
                                      anyAuthId = indiAuth.id;
                                  }
        if(!authMap.isEmpty()){
            Herokuservice.careDateList = new Set<Date>();
            Herokuservice.careDateList = dateset;
            List<Id> authIds = new List<Id>();
            authIds.addAll(authMap.keyset());
            fetchedEncumberence = HerokuService.authEncumbrancefetchMult(authIds);
            if(HerokuService.isApiSuccess){
                for(List<batchsit_t_auth_encmbr__x> authEncumList : fetchedEncumberence.values()){
                    listOfencumberance.addAll(authEncumList);    
                }                
            }else{
                throw new AuraHandledException('There is an unknown problem. Please contact your administrator.');
            }
        }
    }
    
    @AuraEnabled
    public static LightningServerResponse checkAttendance(String provId, String fromDate, String toDate){
        return AttendanceSearchAPXCtrl.getAttendanceResults(provId, null, null , fromDate, toDate);
    } 
    public class ProvClosWrapp{
        @AuraEnabled
        public String proRecId {get;set;}
        @AuraEnabled
        public String countyId {get;set;}
        @AuraEnabled
        public Date beginDate {get;set;}
        @AuraEnabled
        public Date endDate {get;set;}
        @AuraEnabled
        public String comment {get;set;}
        @AuraEnabled
        public boolean checked {get;set;}
        @AuraEnabled
        public String newbeginDate {get;set;}
    }
    
    public class encumbranceWrap{
        public String cde_Status_Encmbr;
        public String cnt_Hour_Care;
        public String lastmodifieddate;
        public String lastmodifiedbyid;
        public String idn_Encmbr_Auth;
        public String ind_0_36_months; //added for CCCAP-14243
    }
    
}