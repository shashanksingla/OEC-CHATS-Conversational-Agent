/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/24/2022                                                         
*  @description    Child Enrollment batch class for datafix     currently 18868 open auths in PROD                         
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date:  22-Nov-2022                                                        
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class ProviderClosureRemovalBatch implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public String providerClsDataFixBegin = '2023-01-16';//System.Label.ProviderClosure_Begin_Date;
    public   Date providerClsDataFixBeginDate = Date.valueOf(providerClsDataFixBegin);
    // instance member to retain state across transactions
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String providerClsBegin = System.Label.ProviderClosure_Begin_Date;
        Date providerClsBeginDate = Date.valueOf(providerClsBegin);
        String lastModifiedUserId = system.UserInfo.getUserId();
        if(Test.isRunningTest()){
            providerClsBeginDate = system.today();
        }
        system.debug('providerClsBeginDate--'+providerClsBeginDate);
        return Database.getQueryLocator([select Id, Name, IDN_PROVIDER__c,IND_ACTIVE__c, IDN_PROVIDER__r.Name, CDE_COUNTY__c, CDE_COUNTY__r.Name, DTE_BEGIN_CLOSURE__c
                                         FROM T_PROVR_CLOSURE__c
                                         WHERE  DTE_BEGIN_CLOSURE__c=:providerClsBeginDate and CDE_COUNTY__c  !=null AND IND_ACTIVE__c=false and  lastModifiedById=:lastModifiedUserId]);
    }
    global void execute(Database.BatchableContext bc, List<T_PROVR_CLOSURE__c> providerClosureList){
        try{
            String providerClsBegin = System.Label.ProviderClosure_Begin_Date;  
            Map<string,set<date>> holidayMap = new  Map<string,set<date>> ();
            Date providerClsBeginDate = Date.valueOf(providerClsBegin);
            system.debug('providerClsBeginDate--'+providerClsBeginDate);
            Set<Id> providerSet = new Set<Id>();
            Set<Id> countySet = new Set<Id>();
            Set<Id> authIds = new Set<Id>();
            List<T_PROVR_CLOSURE__c> provrClosureList = new List<T_PROVR_CLOSURE__c>();
            Map<string,T_PROVR_CLOSURE__c> provrClosureMap= new Map<string,T_PROVR_CLOSURE__c>();
            Set<string> closureSet= new Set<string>();
            List<batchsit_t_auth_encmbr__x> encmbrToBeUpdated = new List<batchsit_t_auth_encmbr__x>();
            set<string> holidaySet = new set<string>();
            for(T_PROVR_CLOSURE__c eachProvrRec : providerClosureList){
                countySet.add(eachProvrRec.CDE_COUNTY__c);
            }
            // Holiday check
            List<T_COUNTY_RATE__c> crpList = [SELECT Id, PAYMENT_Q13_1__c,IDN_COUNTY__c, DTE_BEGIN_EFFV_RATE__c, DTE_END_EFFV_RATE__c 
                                              FROM T_COUNTY_RATE__c WHERE IDN_COUNTY__c in :countySet AND CDE_STATUS__c = 'APV'
                                              AND IND_RATE_PLAN_TEMPLT__c = false AND PAYMENT_Q13_1__c != null
                                              AND (DTE_END_EFFV_RATE__c >=: providerClsBeginDate OR DTE_END_EFFV_RATE__c = null)];
            
            for(T_COUNTY_RATE__c crp : crpList){
                if((crp.DTE_END_EFFV_RATE__c == null || crp.DTE_END_EFFV_RATE__c  >= providerClsBeginDate) && crp.DTE_BEGIN_EFFV_RATE__c <= providerClsBeginDate ){
                    holidaySet.addAll(crp.PAYMENT_Q13_1__c.split(';'));
                    // holidayMap.put(crp.IDN_COUNTY__c,holidaySet);
                }
            }
            
            set<date> holidayDates = new set<date>();
            Date holDt;
            if(Test.isRunningTest()){
                holidaySet.add('1');
                holidaySet.add('2');
                holidaySet.add('3');
            }
            system.debug('holidaySet--'+holidaySet);
            for(T_YEAR_HOL__c holiday : [SELECT DTE_HOL__c, DTE_OBSERVED_HOL__c, CDE_HOL__c FROM T_YEAR_HOL__c 
                                         WHERE CDE_HOL__c IN :holidaySet AND (DTE_HOL__c >=: providerClsBeginDate or DTE_OBSERVED_HOL__c>=:providerClsBeginDate)]){
                                             holDt = holiday.DTE_OBSERVED_HOL__c != null ? holiday.DTE_OBSERVED_HOL__c : holiday.DTE_HOL__c;
                                             for(T_COUNTY_RATE__c crp : crpList){
                                                 String crpHol = crp.PAYMENT_Q13_1__c+';';
                                                 if(crp.DTE_BEGIN_EFFV_RATE__c <= holDt && (crp.DTE_END_EFFV_RATE__c >= holDt || crp.DTE_END_EFFV_RATE__c == null)
                                                    && crpHol.contains(holiday.CDE_HOL__c+';')){
                                                        holidayDates.add(holDt);
                                                        if(holidayMap.containsKey(crp.IDN_COUNTY__c)){
                                                            set<date> holidayDates2 = holidayMap.get(crp.IDN_COUNTY__c);
                                                            holidayDates2.add(holDt);
                                                            if(holiday.DTE_HOL__c != null && holiday.DTE_OBSERVED_HOL__c != null){
                                                                holidayDates2.add(holiday.DTE_HOL__c);
                                                            }
                                                            holidayMap.put(crp.IDN_COUNTY__c,holidayDates2);
                                                        }else{
                                                            set<date> holidayDates1 = new set<date>();
                                                            holidayDates1.add(holDt);
                                                            if(holiday.DTE_HOL__c != null && holiday.DTE_OBSERVED_HOL__c != null){
                                                                holidayDates1.add(holiday.DTE_HOL__c);
                                                            }
                                                            holidayMap.put(crp.IDN_COUNTY__c,holidayDates1);
                                                        }
                                                    }                              
                                             }  
                                         }
            // end
            countySet = new Set<ID>();
            for(T_PROVR_CLOSURE__c eachProvrRec : providerClosureList){
                if(Test.isRunningTest()){
                    providerClsBeginDate = system.today();
                    holidayMap.put(eachProvrRec.CDE_COUNTY__c, new Set<Date>{providerClsBeginDate});
                }
                if(holidayMap.containsKey(String.valueOf(eachProvrRec.CDE_COUNTY__c))){
                    set<date> holidayDatesTemp = holidayMap.get(eachProvrRec.CDE_COUNTY__c);
                    system.debug('holidayDatesTemp--'+holidayDatesTemp);
                    if(holidayDatesTemp.contains(providerClsBeginDate)){
                        List<T_PROVR_CLOSURE__c> tempList = new List<T_PROVR_CLOSURE__c>();
                        closureSet.add(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c);
                        if(provrClosureMap.containsKey(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c+'_'+eachProvrRec.DTE_BEGIN_CLOSURE__c)){
                            provrClosureMap.put(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c+'_'+string.valueOf(eachProvrRec.DTE_BEGIN_CLOSURE__c),eachProvrRec);                                           
                        }else {
                            provrClosureMap.put(eachProvrRec.IDN_PROVIDER__c + '_' +eachProvrRec.CDE_COUNTY__c+'_'+string.valueOf(eachProvrRec.DTE_BEGIN_CLOSURE__c),eachProvrRec);
                        }
                        providerSet.add(eachProvrRec.IDN_PROVIDER__c);
                        countySet.add(eachProvrRec.CDE_COUNTY__c);
                        //eachProvrRec.IND_ACTIVE__c=false;
                        // providerClsToBeUpdated.add(eachProvrRec);
                        
                    }
                }
                
            }
            
            system.debug('holidayMap--'+holidayMap);
            system.debug('providerSet--'+providerSet);
            system.debug('countySet--'+countySet);
            List<T_AUTH__c> authList = [SELECT  Id, Name, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,
                                        IDN_PROVR__c, IDN_PROVR__r.Name, CDE_COUNTY__c, CDE_COUNTY__r.Name 
                                        FROM T_AUTH__c 
                                        where DTE_BEGIN_EFFV_AUTH__c <=: providerClsBeginDate and DTE_END_EFFV_AUTH__c >=:providerClsBeginDate
                                        AND IDN_PROVR__c in:providerSet and CDE_COUNTY__c in:countySet 
                                        order by Name ASC];
            Map<String,T_AUTH_ENCUMBR__c> copyAuthMap= new Map<String,T_AUTH_ENCUMBR__c>();
            Map<String,T_PROVR_CLOSURE__c> providerClsMap= new Map<String,T_PROVR_CLOSURE__c>();
            for(T_AUTH__c au:authList){
                authIds.add(au.id);  
            }
            for( T_PROVR_CLOSURE__c clsObj:[select Id, Name, IDN_PROVIDER__c,IND_ACTIVE__c, IDN_PROVIDER__r.Name, CDE_COUNTY__c, CDE_COUNTY__r.Name, DTE_BEGIN_CLOSURE__c
                                            FROM T_PROVR_CLOSURE__c where IDN_PROVIDER__c in:providerSet and DTE_BEGIN_CLOSURE__c>=:providerClsDataFixBeginDate and
                                            DTE_BEGIN_CLOSURE__c !=:providerClsBeginDate and CDE_COUNTY__c in:countySet and IND_ACTIVE__c=true]){
                                                //String keyStr = clsObj.IDN_PROVIDER__c+'_'+clsObj.CDE_COUNTY__c+'_'+clsObj.DTE_BEGIN_CLOSURE__c;
                                                String monthStr = String.valueOf(clsObj.DTE_BEGIN_CLOSURE__c.month());
                                                String dayStr = String.valueOf(clsObj.DTE_BEGIN_CLOSURE__c.day());
                                                if(clsObj.DTE_BEGIN_CLOSURE__c.month()<10){
                                                    monthStr = '0'+monthStr;
                                                }
                                                if(clsObj.DTE_BEGIN_CLOSURE__c.day()<10){
                                                    dayStr = '0'+dayStr;
                                                }
                                                String keyVal =clsObj.IDN_PROVIDER__c+'_'+clsObj.CDE_COUNTY__c+'_'+(clsObj.DTE_BEGIN_CLOSURE__c).year()+'-'+monthStr+'-'+dayStr;
                                                providerClsMap.put(keyVal,clsObj);
                                            }
            system.debug('authIds--'+authIds);
            system.debug('copyAuthMap--'+copyAuthMap);
            system.debug('providerClsMap---'+providerClsMap);
            List<T_AUTH_ENCUMBR__c> recToInsert = new List<T_AUTH_ENCUMBR__c>();
            for(T_AUTH__c eachAuth: authList){
                //for each AUTH record get the list of Provider Closures - for that Provider-county
                List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
                if(!Test.isRunningTest()){
                    fetchedEncumberence = HerokuService.authEncumbrancefetch(eachAuth.Id);
                }else{
                    fetchedEncumberence.add(new batchsit_t_auth_encmbr__x(dte_care__c =system.today(),idn_auth__c =eachAuth.Id,cde_status_encmbr__c='5',cnt_hour_care__c=12,cde_type_unit_care__c='Reg',ExternalId=eachAuth.Id,cnt_hour_attnd_actual__c=0));
                }
                for(batchsit_t_auth_encmbr__x ew : fetchedEncumberence){
                    //system.debug('key--'+eachAuth.id + '_'+string.valueOf(ew.dte_Care__c));
                    //system.debug('backup record--'+copyAuthMap.get(eachAuth.id + '_'+string.valueOf(ew.dte_Care__c)));
                    //  if(!copyAuthMap.containsKey(eachAuth.id + '_'+string.valueOf(ew.dte_Care__c))){
                    //system.debug('inside first if condition');
                    string keyStr = eachAuth.IDN_PROVR__c + '_' +eachAuth.CDE_COUNTY__c+'_'+string.valueOf(ew.dte_Care__c);
                    system.debug('keyStr---'+keyStr);
                    if(providerClsMap.containsKey(keyStr)){
                        T_AUTH_ENCUMBR__c indiObj = new T_AUTH_ENCUMBR__c();
                        system.debug('ew--'+ew);
                        if(ew.cnt_hour_attnd_actual__c<=0 && ew.cde_Status_Encmbr__c !='5' && ew.cde_Status_Encmbr__c =='2' && ew.dte_Care__c >= providerClsDataFixBeginDate ){
                            system.debug('meet condition--'+ew);
                            if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.cde_status_encmbr__c.isCreateable()){
                                indiObj.cde_status_encmbr__c = ew.cde_Status_Encmbr__c;
                            }
                            if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.cnt_hour_care__c.isCreateable()){
                                indiObj.cnt_hour_care__c = Integer.valueof(ew.cnt_Hour_Care__c);
                            }
                            if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.dte_care__c.isCreateable()){
                                indiObj.dte_care__c = Date.valueof(ew.dte_Care__c);
                            }
                            if(Schema.sObjectType.T_AUTH_ENCUMBR__c.fields.IDN_AUTH__c.isCreateable()){
                                indiObj.IDN_AUTH__c = ew.idn_Auth__c;
                            }
                            recToInsert.add(indiObj);
                            ew.cde_Status_Encmbr__c = '5';
                            ew.cnt_Hour_Care__c = 0;
                            system.debug('The Encumbrance Update Value' + ew);
                            //add to the list of Encumbrance Update
                            encmbrToBeUpdated.add(ew);
                        }
                    }
                    // }
                }  
            }
            if(!recToInsert.isEmpty()){
                //system.debug('The Encmbr to be Updated 77 '+recToInsert.size());
                database.insert(recToInsert);
            }
            //provider note creation
            //provider closure update to make them inactive
            if(!encmbrToBeUpdated.isEmpty()){
                system.debug('The Encmbr to be Updated '+encmbrToBeUpdated.size());
                database.updateAsync(encmbrToBeUpdated);
            }
            
        }
        catch(Exception e) {
            system.debug('exception--'+e.getMessage());
        }
    }    
    global void finish(Database.BatchableContext bc){
        
    }    
    
    
}