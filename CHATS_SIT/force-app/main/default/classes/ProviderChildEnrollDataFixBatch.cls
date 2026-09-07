/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           5/24/2022                                                         
*  @description    Child Enrollment batch class for datafix     currently 18868 open auths in PROD                         
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 244-May-2022                                                             
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
global with sharing class ProviderChildEnrollDataFixBatch implements 
Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public Set<Id> providerId = new Set<Id>();
    public Map<String,Date> enrollMap = new Map<String,Date>();
    public static Date weekDate = system.today()-16;
    public Map<String,T_CHATS_CHILD_ENROLLMENT__c> enrollToBeInsertedMap = new Map<String,T_CHATS_CHILD_ENROLLMENT__c>();
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = system.today(); // this is referred in below dynamic query
        // this is referred in below dynamic query
        String status ='2';
        Datetime currentYear = Datetime.newInstance(2022, 01,01,0,0,0);
        system.debug('currentYear--'+currentYear);
        String authId='a0s8B000000te7fQAA';
        //String queryStr ='SELECT ID,Name,isFinishedFlow__c,IDN_CASE__c,IDN_CLIENT__c,IDN_PROVR__c,Authorization_Status__c,Number_of_Drop_in_Days__c, DTE_BEGIN_EFFV_AUTH__c,CreatedById, DTE_END_EFFV_AUTH__c, IDN_EXTNL__c FROM T_AUTH__c Where  ( DTE_END_EFFV_AUTH__c >=:weekDate)  order by DTE_BEGIN_EFFV_AUTH__c asc';//+todayDate; Updated as of CHATS-6644
        String queryStr ='SELECT ID,Name,isFinishedFlow__c,IDN_CASE__c,IDN_CLIENT__c,IDN_PROVR__c,Authorization_Status__c,Number_of_Drop_in_Days__c, DTE_BEGIN_EFFV_AUTH__c,CreatedById, DTE_END_EFFV_AUTH__c, IDN_EXTNL__c FROM T_AUTH__c Where   Child_Enrollment_Datafix_Flag__c= true  order by DTE_BEGIN_EFFV_AUTH__c asc';//+todayDate; Updated as of CHATS-6644
        system.debug('queryStr--'+queryStr);
        return Database.getQueryLocator(queryStr);
    }

    global void execute(Database.BatchableContext bc, List<T_Auth__c> newAuthorizations){
        try {
            Set<Id> caseIDSet = new Set<Id>();
            Set<Id> clientIDSet = new Set<Id>();
            Set<Id> providerIDSet = new Set<Id>();
            List<T_AUTH__c> authUpdatelist = new List<T_AUTH__C>();
            Date todayDate = System.today();
            Date authBeginDateMin = todayDate.addDays(-9);
            List<T_CHATS_CHILD_ENROLLMENT__c> childEnrollToBeInserted = new List<T_CHATS_CHILD_ENROLLMENT__c>();
            List<T_CHATS_CHILD_ENROLLMENT__c> childEnrollToBeOldList = new List<T_CHATS_CHILD_ENROLLMENT__c>();
            Map<string,List<T_CHATS_CHILD_ENROLLMENT__c> > childEnrollToBeOldMap = new Map<string,List<T_CHATS_CHILD_ENROLLMENT__c> >();
            Boolean isFutureAuthorization = false;
            T_CHATS_CHILD_ENROLLMENT__c enroll;
            for(T_Auth__c authorization: newAuthorizations){
                clientIDSet.add(authorization.IDN_CLIENT__c);
                providerIDSet.add(authorization.IDN_PROVR__c);
            }
            system.debug('clientIDSet--'+clientIDSet);
            system.debug('providerIDSet--'+providerIDSet);
            List<T_Auth__c> existAuthorizations = new List<T_Auth__c>();
            existAuthorizations=[select id,DTE_BEGIN_EFFV_AUTH__c,IDN_CASE__c,IDN_CASE__r.Name,IDN_CLIENT__r.IDN_STATE__c,IDN_PROVR__r.Name,DTE_END_EFFV_AUTH__c,IDN_CLIENT__c,IDN_PROVR__c,IDN_PROVR__r.CDE_ATS_WAIVER__c,IDN_PROVR__r.CDE_ELV_WAIVER__c from T_Auth__c where id in:newAuthorizations];
            // Need to add some date filter to restrict the records count
            system.debug('existAuthorizations--'+existAuthorizations);
            for(T_CHATS_CHILD_ENROLLMENT__c enrollObj :[select id,DTE_BEGIN_EFFV__c,IDN_PROVR__c,IDN_CLIENT__c from T_CHATS_CHILD_ENROLLMENT__c where IDN_CLIENT__c in:clientIDSet and IDN_PROVR__c in:providerIDSet and (DTE_END_EFFV__c>=: authBeginDateMin or DTE_END_EFFV__c= null)]){
                string key = enrollObj.IDN_PROVR__c +'_'+enrollObj.IDN_CLIENT__c;
                if(enrollToBeInsertedMap.containsKey(key)){
                    T_CHATS_CHILD_ENROLLMENT__c temp = enrollToBeInsertedMap.get(key);
                    if(enrollObj.DTE_BEGIN_EFFV__c != null && temp.DTE_BEGIN_EFFV__c > enrollObj.DTE_BEGIN_EFFV__c){
                        enrollToBeInsertedMap.put(key,enrollObj);
                        enrollMap.put(key, enrollObj.DTE_BEGIN_EFFV__c);
                    }
                }else{
                    enrollToBeInsertedMap.put(key,enrollObj);
                    enrollMap.put(key, enrollObj.DTE_BEGIN_EFFV__c);
                }
                childEnrollToBeOldList.add(enrollObj);
            }
            system.debug('existing enrollToBeInsertedMap--'+enrollToBeInsertedMap);
            
            for(T_Auth__c authorization: existAuthorizations){
                List<batchsit_t_auth_encmbr__x> fetchedEncumberence = new List<batchsit_t_auth_encmbr__x>();
                fetchedEncumberence = HerokuService.authEncumbrancefetch(authorization.Id);
                string key = authorization.IDN_PROVR__c +'_'+authorization.IDN_CLIENT__c;
                Boolean validEnrollRecExist = false;
                Date childFirstCheckIn;
                system.debug('authorization--'+authorization);
                // checking for attendance
                for(batchsit_t_auth_encmbr__x ew : fetchedEncumberence){
                    if((ew.cnt_hour_attnd_actual__c >0 ) && ew.cde_Status_Encmbr__c !='5' ){

                        if(childFirstCheckIn == null){
                            childFirstCheckIn = ew.dte_care__c;
                            system.debug('childFirstCheckIn---1-'+childFirstCheckIn+' and auth id --'+authorization.id);
                        }
                        if(childFirstCheckIn != null && childFirstCheckIn >ew.dte_care__c){
                            childFirstCheckIn = ew.dte_care__c;
                            system.debug('childFirstCheckIn---2-'+childFirstCheckIn+' and auth id --'+authorization.id);
                        }
                    }
                }
                if(childFirstCheckIn == null){
                    // Get the attendance records from transactions
                    Date fromDate = weekDate;
                    Date fromDateEntered = Date.valueOf(fromDate);
                    Date toDateEntered = system.today();
                    LightningServerResponse lstResp= AttendanceSearchApxCtrl.getAttendanceResults(string.valueOf(authorization.IDN_PROVR__r.Name),string.valueOf(authorization.IDN_CASE__r.Name), string.valueOf(authorization.IDN_CLIENT__r.IDN_STATE__c), string.valueOf(fromDateEntered), string.valueOf(toDateEntered));
                    system.debug('lstResp--'+lstResp); 
                    Map<String, String> transactionTypeMap;
                    List<Transaction_c__x> lstTransaction = new List<Transaction_c__x>();
                    if(lstResp != null && lstResp.objectData != null){
                        map<String, Object> objectData =lstResp.objectData;
                        if(objectData.get('transactionTypeMap') != null){
                            transactionTypeMap=(Map<String, String>)objectData.get('transactionTypeMap');
                        }
                        system.debug('objectData--'+objectData);
                        if(objectData != null && objectData.get('lstTransaction1') != null){
                            system.debug('lstTransaction1 value--'+objectData.get('lstTransaction1'));
                            List<Transaction_c__x> lstTransaction1 = (List<Transaction_c__x>)objectData.get('lstTransaction1');
                            if(lstTransaction1 != null && lstTransaction1.size()>0){
                                lstTransaction.addAll(lstTransaction1);
                            }
                        }
                        if(objectData != null && objectData.get('lstTransaction2') != null){
                            system.debug('lstTransaction2 value--'+objectData.get('lstTransaction2'));
                            List<Object> lstTransaction2 = (List<Object>)objectData.get('lstTransaction2');
                            for(Object obj :lstTransaction2){
                                Transaction_c__x tran = (Transaction_c__x)obj; 
                                if(tran != null){
                                    lstTransaction.add(tran);
                                }
                            }
                        }
                        system.debug('lstTransaction--'+lstTransaction);
                        for(Transaction_c__x tran :lstTransaction){
                            if(transactionTypeMap.get(string.valueOf(tran.Reporting_Transaction_Type_c__c)) =='Check In' && tran.CI_Transaction_Time_c__c != null){
                                if(childFirstCheckIn != null && childFirstCheckIn >tran.CI_Transaction_Time_c__c){
                                    childFirstCheckIn = Date.valueOf(tran.CI_Transaction_Time_c__c);
                                }
                                else if(childFirstCheckIn == null ){
                                    childFirstCheckIn = Date.valueOf(tran.CI_Transaction_Time_c__c);
                                }
                            }
                        } 
                        
                    }
                    system.debug('childFirstCheckIn--after-'+childFirstCheckIn);  
                }
                system.debug('childFirstCheckIn--'+childFirstCheckIn+' and auth id --'+authorization.id);
                if(childFirstCheckIn!= null){
                    if(!enrollToBeInsertedMap.containsKey(key) ){
                        system.debug('childFirstCheckIn-3-'+childFirstCheckIn+' and auth id --'+authorization.id);
                        /*if(enrollMap.containsKey(key)){
                            // Update the enrollment list
                            if(enrollMap.get(key) > childFirstCheckIn){
                                T_CHATS_CHILD_ENROLLMENT__c enObj = enrollToBeInsertedMap.get(key);
                                enObj.DTE_BEGIN_EFFV__c = childFirstCheckIn;
                                enrollToBeInsertedMap.put(key, enObj);
                                enrollMap.put(key, childFirstCheckIn);
                            }
                        }else{*/
                        if(authorization.IDN_PROVR__r.CDE_ATS_WAIVER__c || authorization.IDN_PROVR__r.CDE_ELV_WAIVER__c){
                            enroll = new T_CHATS_CHILD_ENROLLMENT__c();
                            enroll.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
                            enroll.IDN_PROVR__c = authorization.IDN_PROVR__c;
                            enroll.Enroll_Flag__c='Enrolled';
                            enroll.IsWavierProvider__c = true;
                            enroll.DTE_BEGIN_EFFV__c=childFirstCheckIn;
                        }else{
                            enroll = new T_CHATS_CHILD_ENROLLMENT__c();
                            enroll.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
                            enroll.IDN_PROVR__c = authorization.IDN_PROVR__c;
                            enroll.DTE_BEGIN_EFFV__c=childFirstCheckIn;
                            enroll.Enroll_Flag__c='Enrolled';
                        }
                        if(enroll != null){
                            childEnrollToBeInserted.add(enroll);
                            enrollToBeInsertedMap.put(key, enroll);
                            enrollMap.put(key, childFirstCheckIn);
                        }
                    }else{
                        system.debug('else condition--'+enrollToBeInsertedMap.get(key));
                        if(enrollMap.containsKey(key) && enrollToBeInsertedMap.containsKey(key) ){
                            // Update the enrollment list
                            if(enrollMap.get(key) != null){
                                if(enrollMap.get(key) > childFirstCheckIn){
                                    T_CHATS_CHILD_ENROLLMENT__c enObj = enrollToBeInsertedMap.get(key);
                                    enObj.DTE_BEGIN_EFFV__c = childFirstCheckIn;
                                    enrollToBeInsertedMap.put(key, enObj);
                                    enrollMap.put(key, childFirstCheckIn);
                                }  
                            }else{
                                T_CHATS_CHILD_ENROLLMENT__c enObj = enrollToBeInsertedMap.get(key);
                                enObj.DTE_BEGIN_EFFV__c = childFirstCheckIn;
                                enrollToBeInsertedMap.put(key, enObj);
                                enrollMap.put(key, childFirstCheckIn);
                            }
                            
                        }
                        system.debug('else childFirstCheckIn--'+childFirstCheckIn);
                    } 
                } else {
                    if(!enrollToBeInsertedMap.containsKey(key)){
                        if(authorization.IDN_PROVR__r.CDE_ATS_WAIVER__c || authorization.IDN_PROVR__r.CDE_ELV_WAIVER__c){
                            enroll = new T_CHATS_CHILD_ENROLLMENT__c();
                            enroll.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
                            enroll.IDN_PROVR__c = authorization.IDN_PROVR__c;
                            enroll.DTE_BEGIN_EFFV__c=authorization.DTE_BEGIN_EFFV_AUTH__c;
                            enroll.IsWavierProvider__c = true;
                            enroll.Enroll_Flag__c='Enrolled';
                            childEnrollToBeInserted.add(enroll);
                            enrollToBeInsertedMap.put(key, enroll);
                            enrollMap.put(key, authorization.DTE_BEGIN_EFFV_AUTH__c);
                        }else{
                            enroll = new T_CHATS_CHILD_ENROLLMENT__c();
                            enroll.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
                            enroll.IDN_PROVR__c = authorization.IDN_PROVR__c;
                            enroll.Enroll_Flag__c='Neutral';
                            childEnrollToBeInserted.add(enroll);
                            enrollToBeInsertedMap.put(key, enroll);
                            enrollMap.put(key, childFirstCheckIn);
                        }
                    }else{
                        if(enrollMap.containsKey(key)){
                            // Update the enrollment list
                            if(authorization.IDN_PROVR__r.CDE_ATS_WAIVER__c){
                                if(enrollMap.get(key) > authorization.DTE_BEGIN_EFFV_AUTH__c){
                                    T_CHATS_CHILD_ENROLLMENT__c enObj = enrollToBeInsertedMap.get(key);
                                    enObj.DTE_BEGIN_EFFV__c = authorization.DTE_BEGIN_EFFV_AUTH__c;
                                    childEnrollToBeInserted.add(enroll);
                                    enrollToBeInsertedMap.put(key, enroll);
                                    enrollMap.put(key, authorization.DTE_BEGIN_EFFV_AUTH__c);
                                }
                            }
                        }
                    }
                    if(enroll != null){
                        
                    }
                }
                // uncheck the flag, once the auth is picked and processed
                T_AUTH__c tempAUth = new T_AUTH__c();
                tempAUth.Id = authorization.Id;
                tempAUth.Child_Enrollment_Datafix_Flag__c = false;
                authUpdatelist.add(tempAUth);
            }
            if(!authUpdatelist.isEmpty()){
                Database.update(authUpdatelist);
            }
            system.debug('enrollToBeInsertedMap--'+enrollToBeInsertedMap);
            if(enrollToBeInsertedMap.size()>0){
                system.debug('enrollToBeInsertedMap-size-'+enrollToBeInsertedMap.values().size());
                Database.upsert(enrollToBeInsertedMap.values());
            }
        }
        catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'ProviderChildEnrollDataFixBatch';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'ProviderChildEnrollDataFixBatch  for adjustment'+e.getMessage();
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }

    global void finish(Database.BatchableContext bc){
        system.debug('enrollToBeInsertedMap----finish method--'+enrollToBeInsertedMap);
    }
    
}