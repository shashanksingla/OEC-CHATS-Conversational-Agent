global with sharing class AuthorizationBatchApxCtrl implements 
    Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    public List<T_AUTH__c> authNameList = new List<T_AUTH__c>();
    public Set<Id> authTerminate = new Set<Id>();
     public Exception_Log__c[] errors = new Exception_Log__c[0];
    // instance member to retain state across transactions
    global Integer recordsProcessed = 0;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date todayDate = system.today(); // this is referred in below dynamic query
        Date weekDate = system.today()-7; // this is referred in below dynamic query
        //String queryStr ='SELECT ID,Name,isFinishedFlow__c, DTE_BEGIN_EFFV_AUTH__c,CreatedById, DTE_END_EFFV_AUTH__c, IDN_EXTNL__c FROM T_AUTH__c Where DTE_END_EFFV_AUTH__c <=:todayDate ';//+todayDate;
        // Query Authorization for last one week and end date less than today.
        String queryStr ='SELECT ID,Name,isFinishedFlow__c,Authorization_Status__c,Number_of_Drop_in_Days__c, DTE_BEGIN_EFFV_AUTH__c,CreatedById, DTE_END_EFFV_AUTH__c, IDN_EXTNL__c FROM T_AUTH__c Where DTE_END_EFFV_AUTH__c <=:todayDate and DTE_END_EFFV_AUTH__c >= :weekDate';//+todayDate; Updated as of CHATS-6644
        
        return Database.getQueryLocator(queryStr);
    }
    global void execute(Database.BatchableContext bc, List<T_AUTH__c> authList){
    	try{
    		        Set<String> authExternalId = new Set<String>();
        String authIdTest;
        Map<String,batchsit_t_auth_status__x> authMap = new Map<String,batchsit_t_auth_status__x>();
          //Removed unused variable on 5/13/2018 BG         
        for(T_AUTH__c auth :authList){
            authIdTest =auth.IDN_EXTNL__c;
            authExternalId.add(auth.IDN_EXTNL__c);
            if(auth.DTE_END_EFFV_AUTH__c <= system.today() && auth.Authorization_Status__c == '2'){
                authTerminate.add(auth.Id);
            }
        }      
        if(authExternalId.size()>0){
            List<batchsit_t_auth_status__x> authStatList = new  List<batchsit_t_auth_status__x>();
            if(Test.isRunningTest()){
                batchsit_t_auth_status__x stat2 = new batchsit_t_auth_status__x(cde_status_auth__c ='4',idn_auth__c= authIdTest);
                batchsit_t_auth_status__x stat3 = new batchsit_t_auth_status__x(cde_status_auth__c ='2');
                authStatList.add(stat3);
                authStatList.add(stat2);
            }else{
                authStatList =[Select id,idn_auth__c,cde_status_auth__c from batchsit_t_auth_status__x where  idn_auth__c IN: authExternalId];
            }
            for(batchsit_t_auth_status__x authStat :authStatList)
            {
                if(authMap.containsKey(authStat.idn_auth__c)){
                    if(authStat.cde_status_auth__c == '4'){
                        authMap.remove(authStat.idn_auth__c);
                    }
                    if(authStat.cde_status_auth__c == '2'){
                      authMap.put(authStat.idn_auth__c, authStat);  
                    }
                }else{
                    if(authStat.cde_status_auth__c != '4'){
                        authMap.put(authStat.idn_auth__c, authStat);
                    }
                }
            }
        }
        for(T_AUTH__c authObj: authList){
            if(Test.isRunningTest()){authMap.put(authObj.IDN_EXTNL__c, new batchsit_t_auth_status__x(cde_status_auth__c='3'));}
            if(authMap.containsKey(authObj.IDN_EXTNL__c)){
                batchsit_t_auth_status__x statObj = authMap.get(authObj.IDN_EXTNL__c);
                if(statObj.cde_status_auth__c != '4'){
                    if(authObj.isFinishedFlow__c){
                        authNameList.add(authObj);
                    }
                    batchsit_t_auth_status__x stat = new batchsit_t_auth_status__x();
                    String authId ='';
                    stat.idn_auth__c =authObj.IDN_EXTNL__c;
                    stat.cde_status_auth__c ='4';
                    stat.createdbyid__c = authObj.CreatedById;
                    stat.lastmodifiedbyid__c =authObj.CreatedById;
                    stat.dte_begin_effv__c = (authObj.DTE_END_EFFV_AUTH__c).addDays(1);
                    stat.createddate__c =System.today();
                    stat.lastmodifieddate__c = System.today();
                    stat.cde_reason_change_auth__c ='6';
                    authId = authObj.Id;
                    AuthorizationStatusController.upsertAuthStatus(stat,true,false,authId,true);   
                }
                
            }
            
        }
    	}catch(Exception e) {
            Exception_Log__c xLog = new Exception_Log__c();
            xLog.Class__c = 'AuthorizationBatchApxCtrl';
            xLog.Method__c = 'executeMethod';
            xLog.Exception_Message__c = 'Authorization Batch for auth'+e.getMessage().left(200);
            xLog.Exception_Type__c = 'Error';
            errors.add(xLog);
        }
    }    
        global void finish(Database.BatchableContext bc){
            if((!authNameList.isEmpty()) && authNameList.size() >0){
                AuthorizationStatusController.insertATSRecords(authNameList);
            }
            if(errors.size()>0){
                GenericDMLHandler.insertRecords(errors,new Map<String,Object>{'Method__c'=>'authTerminate','Class__c'=>'AuthorizationBatchApxCtrl'});
            //insert errors;
      		  }
            // below method to set Auth status field  T_AUTH__c.Authorization_Status__c = '4'; Below code added as part of Jira ticket CHATS-6981
            if(authTerminate.size()>0){
                AuthorizationStatusController.authTerminate(authTerminate);
            }
            
        }    
    }