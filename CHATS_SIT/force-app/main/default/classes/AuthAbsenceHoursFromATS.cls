global with sharing class AuthAbsenceHoursFromATS implements Database.Batchable<sObject>{
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        Date dateToday =  System.today() ;
        return Database.getQueryLocator('SELECT Id,Name,isFinishedFlow__c,Authorization_Status__c, DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c, IDN_EXTNL__c, IDN_PROVR__c, CDE_COUNTY__c FROM T_AUTH__c Where DTE_BEGIN_EFFV_AUTH__c <=:dateToday and (DTE_END_EFFV_AUTH__c = null or DTE_END_EFFV_AUTH__c >=: dateToday)');   
        
    }
    
    
    global void execute(Database.BatchableContext BC, List<T_AUTH__c> scope){
        
        Map<date,T_YEAR_HOL__c> holidayMapForCurrentYear = new Map<date,T_YEAR_HOL__c>();
        Map<string,date> holidayMapFromCodeToDate = new Map<string, date>();
        Map<date,string> holidayMapFromDateToCode = new Map<date, string>();
        
        Map<decimal, List<Schedule_c__x>> mapAuthIdToScheduleList = new Map<decimal, List<Schedule_c__x>>();
        Map<string, decimal> mapAuthSfidToAbsenceHours = new Map<string,decimal>();
        List<T_AUTH_ABSENCE__c> ListOfStagingRecordsToBeUpdtd = new List<T_AUTH_ABSENCE__c>();
        Map<decimal,string> authIdToSfid = new Map<decimal,string>();
        integer currentYear = system.today().year();
        Date todayMinusNineDays = system.today() - 9;
        
        set<string> provrSfidsFromAuth = new set<string>();
        set<string> countySfidsFromAuth = new set<string>();
        Map<string, string> provrSfidToType = new Map<string, string>();
        Map<string, string> countySfidToCRPHolidays = new Map<string, string>();
        Map<decimal,string> mapAuthIdToProvrType = new Map<decimal, string>();
        Map<decimal,list<string>> mapAuthIdToCRPHolidays = new Map<decimal,list<string>>();
        Map<decimal,set<string>> mapAuthIdToCRPHolidaysSet = new Map<decimal,set<string>>();
        Map<decimal,string> mapAuthIdToCRPHolidaysString = new Map<decimal,string>();
        
        
        for(T_AUTH__C eachAuth : scope){
            provrSfidsFromAuth.add(eachAuth.IDN_PROVR__c);
            countySfidsFromAuth.add(eachAuth.CDE_COUNTY__c);
        }
        
        
        for(T_YEAR_HOL__c eachHoliday : [SELECT Id, Name, CDE_HOL__c, CDE_YEAR__c, DTE_HOL__c FROM T_YEAR_HOL__c where DTE_HOL__c = LAST_N_DAYS:9 WITH SECURITY_ENFORCED]){
            holidayMapForCurrentYear.put(eachHoliday.DTE_HOL__c,eachHoliday);
            holidayMapFromCodeToDate.put(eachHoliday.CDE_HOL__c,eachHoliday.DTE_HOL__c);
            holidayMapFromDateToCode.put(eachHoliday.DTE_HOL__c,eachHoliday.CDE_HOL__c);
        }
        
        for(T_CHATS_PROVR_STATUS__c eachProvr : [SELECT Id, Name, CDE_TYPE_PROVR__c FROM T_CHATS_PROVR_STATUS__c where Id in:provrSfidsFromAuth WITH SECURITY_ENFORCED]){
            provrSfidToType.put(eachProvr.Id, eachProvr.CDE_TYPE_PROVR__c);
        }
        
        for(T_COUNTY_RATE__c eachCRP : [SELECT  Id, IDN_COUNTY__c, PAYMENT_Q13_1__c
                                        FROM T_COUNTY_RATE__c 
                                        WHERE IDN_COUNTY__c in:countySfidsFromAuth
                                        AND DTE_BEGIN_EFFV_RATE__c<=:system.today()
                                        AND (DTE_END_EFFV_RATE__c>=:system.today() OR DTE_END_EFFV_RATE__c=null)
                                        AND CDE_STATUS__c = 'APV'
                                        AND IND_RATE_PLAN_TEMPLT__c = false WITH SECURITY_ENFORCED]){
                                            
                                            countySfidToCRPHolidays.put(eachCRP.IDN_COUNTY__c, eachCRP.PAYMENT_Q13_1__c);  
                                            
                                        }
        
        for(T_AUTH__C eachAuth : scope){
            authIdToSfid.put(decimal.valueOf(eachAuth.Name), eachAuth.Id);
            mapAuthIdToProvrType.put(decimal.valueOf(eachAuth.Name), provrSfidToType.get(eachAuth.IDN_PROVR__c));
            
            if(countySfidToCRPHolidays.containsKey(eachAuth.CDE_COUNTY__c)){
                if(countySfidToCRPHolidays.get(eachAuth.CDE_COUNTY__c) != null){
                    List<string> listOfHolidaysPerAuthPerCRP = countySfidToCRPHolidays.get(eachAuth.CDE_COUNTY__c).split(';');
                    set<string> setOfHolidaysPerAuthPerCRP = new set<string>();
                    setOfHolidaysPerAuthPerCRP.addAll(listOfHolidaysPerAuthPerCRP);
                	mapAuthIdToCRPHolidays.put(decimal.valueOf(eachAuth.Name), countySfidToCRPHolidays.get(eachAuth.CDE_COUNTY__c).split(';')); 
                    mapAuthIdToCRPHolidaysSet.put(decimal.valueOf(eachAuth.Name), setOfHolidaysPerAuthPerCRP); 
                }
                mapAuthIdToCRPHolidaysString.put(decimal.valueOf(eachAuth.Name), countySfidToCRPHolidays.get(eachAuth.CDE_COUNTY__c));
            }
        }
        
        if(!authIdToSfid.isEmpty()){
            for(Schedule_c__x eachSchedule : [select CI_Authorization_Id_c__c, CI_Authorization_Hours_c__c, Hours_c__c, Type_c__c, Attended_c__c, CI_Authorization_Date_c__c
                                              FROM Schedule_c__x
                                              WHERE CI_Authorization_Date_c__c >=: todayMinusNineDays
                                              AND CI_Authorization_Date_c__c <: system.today()
                                              AND CI_Authorization_Id_c__c in:authIdToSfid.keySet()
                                              AND CI_Authorization_Hours_c__c > 0 WITH SECURITY_ENFORCED]){
                                                  
                                                  if(mapAuthIdToScheduleList.containsKey(eachSchedule.CI_Authorization_Id_c__c)) {
                                                      List<Schedule_c__x> existingScheduleList = mapAuthIdToScheduleList.get(eachSchedule.CI_Authorization_Id_c__c);
                                                      existingScheduleList.add(eachSchedule);
                                                      mapAuthIdToScheduleList.put(eachSchedule.CI_Authorization_Id_c__c, existingScheduleList);
                                                  } else {
                                                      List<Schedule_c__x> newScheduleList = new List<Schedule_c__x>();
                                                      newScheduleList.add(eachSchedule);
                                                      mapAuthIdToScheduleList.put(eachSchedule.CI_Authorization_Id_c__c, newScheduleList);
                                                  }
                                                  
                                              }
            
            for(decimal eachAuthId : authIdToSfid.keySet()){
                decimal numberofAbsences = 0;
                if(mapAuthIdToScheduleList.containsKey(eachAuthId)){
                    if(mapAuthIdToProvrType.containsKey(eachAuthId) && mapAuthIdToProvrType.get(eachAUthId) == 'EFACH'){
                        for(Schedule_c__x eachOfCompleteScheduleListForAuth : mapAuthIdToScheduleList.get(eachAuthId)){
                            if(	(eachOfCompleteScheduleListForAuth.Hours_c__c == null && eachOfCompleteScheduleListForAuth.Type_c__c == 'CCCAP_AUTHORIZED') || 
                               (eachOfCompleteScheduleListForAuth.Hours_c__c == 0.00 && eachOfCompleteScheduleListForAuth.Type_c__c == 'CCCAP_AUTHORIZED' && eachOfCompleteScheduleListForAuth.Attended_c__c == false)
                              ){
                                  numberofAbsences++;
                              }
                        }
                    }else if(mapAuthIdToCRPHolidaysString.containsKey(eachAuthId)){
                        for(Schedule_c__x eachOfCompleteScheduleListForAuth : mapAuthIdToScheduleList.get(eachAuthId)){
                            if(	(eachOfCompleteScheduleListForAuth.Hours_c__c == null && eachOfCompleteScheduleListForAuth.Type_c__c == 'CCCAP_AUTHORIZED') || 
                               (eachOfCompleteScheduleListForAuth.Hours_c__c == 0.00 && eachOfCompleteScheduleListForAuth.Type_c__c == 'CCCAP_AUTHORIZED' && eachOfCompleteScheduleListForAuth.Attended_c__c == false)
                              ){
                                  if(holidayMapFromDateToCode.containsKey(eachOfCompleteScheduleListForAuth.CI_Authorization_Date_c__c)){
                                      if(mapAuthIdToCRPHolidaysString.get(eachAuthId) != null){ 
                                          if(mapAuthIdToCRPHolidaysSet.get(eachAuthId).contains(holidayMapFromDateToCode.get(eachOfCompleteScheduleListForAuth.CI_Authorization_Date_c__c))){
                                              
                                          }else{
                                              numberofAbsences++;
                                          } 
                                      } else {
                                      	numberofAbsences++;    
                                      }
                                  }else {
                                      numberofAbsences++;
                                  }
                              }
                        }
                    }
                    mapAuthSfidToAbsenceHours.put(authIdToSfid.get(eachAuthId), numberofAbsences);
                }                                     
            }
            
            // Using the map<authSfid,numberOfAbsences>, get the list of Staging table records that needs to be updated.
            
            if(!mapAuthSfidToAbsenceHours.isEmpty()){
                for(T_AUTH_ABSENCE__c eachAuthAbsenceRecord : [select Id, IDN_AUTH__c, Number_of_Absences_From_ATS__c FROM T_AUTH_ABSENCE__c WHERE IDN_AUTH__C in:mapAuthSfidToAbsenceHours.keySet() WITH SECURITY_ENFORCED]){
                    if(mapAuthSfidToAbsenceHours.containsKey(eachAuthAbsenceRecord.IDN_AUTH__c)){
                        T_AUTH_ABSENCE__c stagingRecordToBeUpdtd = new T_AUTH_ABSENCE__c();
                        stagingRecordToBeUpdtd.Id = eachAuthAbsenceRecord.Id;
                        stagingRecordToBeUpdtd.Number_of_Absences_From_ATS__c = mapAuthSfidToAbsenceHours.get(eachAuthAbsenceRecord.IDN_AUTH__c);
                        ListOfStagingRecordsToBeUpdtd.add(stagingRecordToBeUpdtd);
                    }
                    
                }
            }
            
            if(!ListOfStagingRecordsToBeUpdtd.isEmpty()){
                GenericDMLHandler.updateRecords(ListOfStagingRecordsToBeUpdtd, false,new Map<String,Object>{'Class__c'=>'AuthAbsenceHoursFromATS','Method__c'=>'execute'});
            }
        }
    }
    
    global void finish(Database.BatchableContext BC){
        
        
    }
}