/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/03/2017                                                          
*  @description    Handler class for County Rate Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 03-Nov-2017                                                             
*  * Author: Vineet Srivastava                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
public with sharing class AuthorizationServices {
    
    /**
* @description Check for Duplicate records before insertion
* @author Vineet Srivastava
* @date 11/03/2017
* @param List<T_AUTH__c> trigger.new Authorizations list
* @return void
*/
    
     public static void duplicateCheck(List<T_Auth__c> newAuthorizations){
        Set<Id> caseIDSet = new Set<Id>();
        Set<Id> clientIDSet = new Set<Id>();
        Set<Id> providerIDSet = new Set<Id>();
        Date todayDate = System.today();
        Map<ID,List<T_INDIV_CUST__c>> childCustdyMap = new Map<ID,List<T_INDIV_CUST__c>>();
        Boolean isFutureAuthorization = false;
        for(T_Auth__c authorization: newAuthorizations){
            caseIDSet.add(authorization.IDN_CASE__c);
            clientIDSet.add(authorization.IDN_CLIENT__c);
            providerIDSet.add(authorization.IDN_PROVR__c);
        }
         List<T_Auth__c> authList =[Select Id, IDN_CASE__c,IDN_CLIENT__c, IDN_PROVR__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c from T_AUTH__c where IDN_CASE__c in :caseIDSet and IDN_CLIENT__c in :clientIDSet and IDN_PROVR__c in :providerIDSet  ];
         List<T_Auth__c> ExistingAuthList =[Select Id, IDN_CASE__c,IDN_CLIENT__c, IDN_PROVR__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c from T_AUTH__c where  IDN_CLIENT__c in :clientIDSet and IDN_CASE__c NOT in :caseIDSet  ];
         for(T_INDIV_CUST__c custInv :[select id,IDN_CLIENT__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from T_INDIV_CUST__c where IDN_CLIENT__c in :clientIDSet and DTE_BEGIN_EFFV__c <= today and (DTE_END_EFFV__c > today or DTE_END_EFFV__c =null)  ]){
                                           if(childCustdyMap.containsKey(custInv.IDN_CLIENT__c)){
                                               List<T_INDIV_CUST__c> cust = childCustdyMap.get(custInv.IDN_CLIENT__c);
                                               cust.add(custInv);
                                               childCustdyMap.put(custInv.IDN_CLIENT__c,cust);
                                           }else{
                                               List<T_INDIV_CUST__c> cust = new List<T_INDIV_CUST__c>();
                                               cust.add(custInv);
                                               childCustdyMap.put(custInv.IDN_CLIENT__c,cust);
                                           }
             
         }
         for(T_Auth__c authorization: newAuthorizations){
             for (T_Auth__c existingAuth: authList)
             {
                 If(((authorization.DTE_BEGIN_EFFV_AUTH__c >= existingAuth.DTE_BEGIN_EFFV_AUTH__c && authorization.DTE_BEGIN_EFFV_AUTH__c <= existingAuth.DTE_END_EFFV_AUTH__c)
                     && (authorization.DTE_END_EFFV_AUTH__c >= existingAuth.DTE_BEGIN_EFFV_AUTH__c && authorization.DTE_END_EFFV_AUTH__c <= existingAuth.DTE_END_EFFV_AUTH__c ))
                    ||((authorization.DTE_BEGIN_EFFV_AUTH__c >= existingAuth.DTE_BEGIN_EFFV_AUTH__c && authorization.DTE_BEGIN_EFFV_AUTH__c <= existingAuth.DTE_END_EFFV_AUTH__c))
                    ||((authorization.DTE_END_EFFV_AUTH__c >= existingAuth.DTE_BEGIN_EFFV_AUTH__c && authorization.DTE_END_EFFV_AUTH__c <= existingAuth.DTE_END_EFFV_AUTH__c ))&& authorization.IDN_CASE__c == existingAuth.IDN_CASE__c && authorization.IDN_CLIENT__c == existingAuth.IDN_CLIENT__c&& authorization.IDN_PROVR__c == existingAuth.IDN_PROVR__c)
                {
                    authorization.addError(Label.DuplicateAuthorization);
                }
               else if((existingAuth.DTE_BEGIN_EFFV_AUTH__c > authorization.DTE_BEGIN_EFFV_AUTH__c) && authorization.IDN_CASE__c == existingAuth.IDN_CASE__c
                    && authorization.IDN_CLIENT__c == existingAuth.IDN_CLIENT__c
                    && authorization.IDN_PROVR__c == existingAuth.IDN_PROVR__c) {
                        authorization.addError('Cannot create more than one future active authorization for the same individual and provider on this case');
                }
               else if((existingAuth.DTE_BEGIN_EFFV_AUTH__c <= authorization.DTE_BEGIN_EFFV_AUTH__c && existingAuth.DTE_END_EFFV_AUTH__c >= authorization.DTE_END_EFFV_AUTH__c) && authorization.IDN_CASE__c == existingAuth.IDN_CASE__c && authorization.IDN_CLIENT__c == existingAuth.IDN_CLIENT__c && authorization.IDN_PROVR__c == existingAuth.IDN_PROVR__c){
                        authorization.addError('Cannot create more than one current active authorization for the same individual and provider on this case');
                    
                }
            }
         } 
         for(T_Auth__c newAuth: newAuthorizations){
             for (T_Auth__c existingAuth: ExistingAuthList){
                 if(newAuth.IDN_CLIENT__c ==existingAuth.IDN_CLIENT__c && newAuth.IDN_CASE__c !=existingAuth.IDN_CASE__c &&
                    (existingAuth.DTE_BEGIN_EFFV_AUTH__c <= todayDate && (existingAuth.DTE_END_EFFV_AUTH__c >= todayDate || existingAuth.DTE_END_EFFV_AUTH__c == null)) ){
                        if(!childCustdyMap.containsKey(newAuth.IDN_CLIENT__c)){
                            newAuth.addError('Child is already authorized on another case and is not in joint custody');
                        }
                 }
             }
         }
    }  
    //Added By Diya
    public static void fiscalActiveCheck(List<T_Auth__c> newAuthorizations){
        Set<Id> caseIDSet = new Set<Id>();
        Set<Id> clientIDSet = new Set<Id>();
        Set<Id> providerIDSet = new Set<Id>();
        Set<Id> countyIdSet = new Set<Id>();
        Map<String,String> caseMap = new Map<String,String>();
        //Removed unused variable on 5/13/2018 BG  
        for(T_Auth__c authorization: newAuthorizations){
            caseIDSet.add(authorization.IDN_CASE__c);
            clientIDSet.add(authorization.IDN_CLIENT__c);
            providerIDSet.add(authorization.IDN_PROVR__c);
            countyIdSet.add(authorization.CDE_COUNTY__c);
        }
        for(T_SBSD_CASE__c cse :[Select id,CDE_COUNTY__c from T_SBSD_CASE__c where id IN:caseIDSet  ]){
            caseMap.put(cse.Id,cse.CDE_COUNTY__c);
        }
        List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreeList =[Select Id, ID_SERVICE__c,CDE_COUNTY__c, DTE_BEGIN_AGRMT__c, DTE_END_AGRMT__c from T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__c in :providerIDSet and
                                                           CDE_COUNTY__c in :countyIdSet and (DTE_END_AGRMT__c >= today or DTE_END_AGRMT__c = null)  ];
         Boolean isValidAuth;
        for(T_Auth__c authorization: newAuthorizations){
            isValidAuth = false;
            for (T_PROVR_FISCAL_AGREMENT__c existingAuth: fiscalAgreeList)
            {
                if((existingAuth.CDE_COUNTY__c == authorization.CDE_COUNTY__c) && (existingAuth.ID_SERVICE__c == authorization.IDN_PROVR__c)){
                    isValidAuth = true;
                    break;
                }
            }
            if(!isValidAuth){
                authorization.addError('Authorization has no active fiscal agreements');
            }
        } 
        
    } 
     public static void updateRecurrence(List<Auth_Schedule_Recurrence__c> recurrenceLst,Map<id,Auth_Schedule_Recurrence__c> oldAuthRecurrence){
        Date todayDate = system.today();
        for(Auth_Schedule_Recurrence__c recurr : recurrenceLst){
             Auth_Schedule_Recurrence__c oldRecurr = oldAuthRecurrence.get(recurr.Id);
            if(oldRecurr.DTE_End_Date__c<= todayDate){
                recurr.addError('Recurrence patterns with dates in the past may not be edited.');
            }else{
                String daysString='';
                Boolean isFirstDay =false;
                if(recurr.Sun__c){
                    if(!isFirstDay){
                        isFirstDay=true;
                        daysString=daysString+'Sun';
                    }else{
                        daysString=daysString+'Sun';  
                    }
                    
                }
                if(recurr.Mon__c){
                    if(!isFirstDay){
                        isFirstDay=true;
                        daysString=daysString+'Mon';
                    }else{
                        daysString=daysString+',Mon';
                    }
                }
                
                if(recurr.Tue__c){
                    if(!isFirstDay){
                        isFirstDay=true;
                        daysString=daysString+'Tue';
                    }else{
                        daysString=daysString+',Tue';
                    }
                }
                if(recurr.Wed__c){
                    if(!isFirstDay){
                        isFirstDay=true;
                        daysString=daysString+'Wed';
                    }else{
                        daysString=daysString+',Wed';
                    }
                }
                if(recurr.Thur__c){
                    if(!isFirstDay){
                        isFirstDay=true;
                        daysString=daysString+'Thu';
                    }else{
                        daysString=daysString+',Thu';
                    }
                }
                if(recurr.Fri__c){
                    if(!isFirstDay){
                        isFirstDay=true;
                        daysString=daysString+'Fri';
                    }else{
                        daysString=daysString+',Fri';
                    }
                }
                if(recurr.Sat__c){
                    if(!isFirstDay){
                        isFirstDay=true;
                        daysString=daysString+'Sat';
                    }else{
                        daysString=daysString+',Sat';
                    }
                }
                recurr.WeekDays__c =daysString;  
            }
            
        }
    }
    public static void duplicateRecurrenceCheck(List<Auth_Schedule_Recurrence__c> recurrenceLst,Map<id,Auth_Schedule_Recurrence__c> oldAuthRecurrence){
        Map<String,T_AUTH__c> authMap = new Map<String,T_AUTH__c>();
        Set<Id> recurrIds = new Set<Id>();
         Set<Id> recurrNewIds = new Set<Id>();
        Date todayDate = system.today();
        for(Auth_Schedule_Recurrence__c  recurr : recurrenceLst){
            recurrIds.add(recurr.IDN_AUTH__c);
            recurrNewIds.add(recurr.IDN_AUTH__c);
        }
        for(T_AUTH__c auth:[Select id,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c from T_AUTH__c where ID  IN:recurrIds  ]){
           authMap.put(auth.id, auth);
        }
        List<Auth_Schedule_Recurrence__c> oldRecurrList = [Select id,DTE_Begin_Date__c,IDN_AUTH__c,DTE_End_Date__c from Auth_Schedule_Recurrence__c where IDN_AUTH__c IN:recurrIds and ID NOT IN:recurrenceLst  ];
        for(Auth_Schedule_Recurrence__c  newRecurr : recurrenceLst){
            T_AUTH__c authRecord = authMap.get(newRecurr.IDN_AUTH__c);
                if(newRecurr.DTE_Begin_Date__c != null && newRecurr.DTE_End_Date__c != null && newRecurr.DTE_End_Date__c < newRecurr.DTE_Begin_Date__c){
                    newRecurr.addError('Begin Date can not be greater than End Date.');   
                } else if( newRecurr.DTE_End_Date__c <= todayDate || ( newRecurr.DTE_Begin_Date__c <= todayDate &&  newRecurr.DTE_End_Date__c <= todayDate)){
                    newRecurr.addError('Recurrence patterns with dates in the past may not be edited.');  
                } else if(newRecurr.DTE_Begin_Date__c != null && authRecord !=NULL && newRecurr.DTE_Begin_Date__c < authRecord.DTE_BEGIN_EFFV_AUTH__c){
                    Date beginDate =  authRecord.DTE_BEGIN_EFFV_AUTH__c;
                    String beginDateStr =  beginDate.month() +'/'+beginDate.day() +'/'+ beginDate.year() ;
                    String beginDateErrMsg = 'Begin date cannot be less than authorization begin date, '+beginDateStr;
                    newRecurr.addError(beginDateErrMsg);   
                } else if(newRecurr.DTE_End_Date__c != null && authRecord !=NULL && newRecurr.DTE_End_Date__c > authRecord.DTE_END_EFFV_AUTH__c){
                    Date endDate =  authRecord.DTE_END_EFFV_AUTH__c;
                    String EndDateStr =  endDate.month() +'/'+endDate.day() +'/'+ endDate.year() ;
                    String endDateErrMsg = 'End date cannot be greater than authorization end date, '+EndDateStr;
                    newRecurr.addError(endDateErrMsg);   
                }else {
                    for(Auth_Schedule_Recurrence__c  oldRecurr : oldRecurrList){
                        if(((oldRecurr.DTE_Begin_Date__c <= newRecurr.DTE_Begin_Date__c) 
                            && (oldRecurr.DTE_End_Date__c >= newRecurr.DTE_End_Date__c) 
                            && oldRecurr.IDN_AUTH__c == newRecurr.IDN_AUTH__c)
                           || ((oldRecurr.DTE_Begin_Date__c >= newRecurr.DTE_Begin_Date__c) 
                               && (oldRecurr.DTE_End_Date__c <= newRecurr.DTE_End_Date__c)
                               && oldRecurr.IDN_AUTH__c == newRecurr.IDN_AUTH__c)
                           || ((oldRecurr.DTE_Begin_Date__c >= newRecurr.DTE_Begin_Date__c) 
                               && (oldRecurr.DTE_End_Date__c >= newRecurr.DTE_End_Date__c)
                               && (oldRecurr.DTE_Begin_Date__c <= newRecurr.DTE_End_Date__c)
                               && oldRecurr.IDN_AUTH__c == newRecurr.IDN_AUTH__c)
                           || ((oldRecurr.DTE_Begin_Date__c <= newRecurr.DTE_Begin_Date__c) 
                               && (oldRecurr.DTE_End_Date__c >= newRecurr.DTE_Begin_Date__c)
                               && oldRecurr.IDN_AUTH__c == newRecurr.IDN_AUTH__c)) {
                                   newRecurr.addError('A reoccurrence pattern already exists for the date/s entered.');    
                               }   
                        
                    }
                }
            }
        
    }
    public static void createChildEnrollmentRecord(List<T_Auth__c> newAuthorizations){
        Set<Id> caseIDSet = new Set<Id>();
        Set<Id> clientIDSet = new Set<Id>();
        Set<Id> providerIDSet = new Set<Id>();
        Date todayDate = System.today();
        Date authBeginDateMin = todayDate.addDays(-9);
        List<T_CHATS_CHILD_ENROLLMENT__c> childEnrollToBeInserted = new List<T_CHATS_CHILD_ENROLLMENT__c>();
        List<T_CHATS_CHILD_ENROLLMENT__c> childEnrollToBeUpdated = new List<T_CHATS_CHILD_ENROLLMENT__c>();
        List<T_CHATS_CHILD_ENROLLMENT__c> childEnrollToBeOldList = new List<T_CHATS_CHILD_ENROLLMENT__c>();
        Map<string,List<T_CHATS_CHILD_ENROLLMENT__c> > childEnrollToBeOldMap = new Map<string,List<T_CHATS_CHILD_ENROLLMENT__c> >();
        Boolean isFutureAuthorization = false;
        T_CHATS_CHILD_ENROLLMENT__c enroll;
        for(T_Auth__c authorization: newAuthorizations){
            clientIDSet.add(authorization.IDN_CLIENT__c);
            providerIDSet.add(authorization.IDN_PROVR__c);
        }
        List<T_Auth__c> existAuthorizations = new List<T_Auth__c>();
        existAuthorizations=[select id,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c,IDN_CLIENT__c,IDN_PROVR__c,IDN_PROVR__r.CDE_ATS_WAIVER__c,IDN_PROVR__r.CDE_ELV_WAIVER__c from T_Auth__c where id in:newAuthorizations];
        // Need to add some date filter to restrict the records count
        for(T_CHATS_CHILD_ENROLLMENT__c enrollObj :[select id,name,isActive__c,IDN_PROVR__c,Enroll_Flag__c,Previous_Flag__c,Previous_Enroll_End_Date__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,IDN_CLIENT__c from T_CHATS_CHILD_ENROLLMENT__c where IDN_CLIENT__c in:clientIDSet and IDN_PROVR__c in:providerIDSet and isActive__c=true	]){
            string key = enrollObj.IDN_PROVR__c +'_'+enrollObj.IDN_CLIENT__c;
            if(childEnrollToBeOldMap.containsKey(key)){
                List<T_CHATS_CHILD_ENROLLMENT__c> temp = childEnrollToBeOldMap.get(key);
                temp.add(enrollObj);
                childEnrollToBeOldMap.put(key,temp);                    
            }else{
                childEnrollToBeOldMap.put(key,new List<T_CHATS_CHILD_ENROLLMENT__c>{enrollObj});
            }
            childEnrollToBeOldList.add(enrollObj);
        }
        for(T_Auth__c authorization: existAuthorizations){
            string key = authorization.IDN_PROVR__c +'_'+authorization.IDN_CLIENT__c;
            Boolean validEnrollRecExist = false;
            if(!childEnrollToBeOldMap.containsKey(key)){
                if(authorization.IDN_PROVR__r.CDE_ATS_WAIVER__c || authorization.IDN_PROVR__r.CDE_ELV_WAIVER__c){
                    enroll = new T_CHATS_CHILD_ENROLLMENT__c();
                    enroll.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
                    enroll.IDN_PROVR__c = authorization.IDN_PROVR__c;
                    enroll.Enroll_Flag__c='Enrolled';
                    enroll.Previous_Flag__c='Enrolled';
                    enroll.IsWavierProvider__c = true;
                    enroll.DTE_BEGIN_EFFV__c=authorization.DTE_BEGIN_EFFV_AUTH__c;
                    enroll.Enrollment_Reason__c ='Child confirmed attending';
                    enroll.isActive__c=true;
                }else{
                    enroll = new T_CHATS_CHILD_ENROLLMENT__c();
                    enroll.IDN_CLIENT__c = authorization.IDN_CLIENT__c;
                    enroll.IDN_PROVR__c = authorization.IDN_PROVR__c;
                    enroll.Enroll_Flag__c='Neutral';
                    enroll.Previous_Flag__c='Neutral';
                    enroll.isActive__c=true;
                }
                childEnrollToBeInserted.add(enroll);
            }else{
                T_CHATS_CHILD_ENROLLMENT__c enrollObj = childEnrollToBeOldMap.get(key)[0];
                if(enrollObj.Enroll_Flag__c =='Enrolled' &&  enrollObj.DTE_END_EFFV__c!= null){
                    if(enrollObj.Previous_Enroll_End_Date__c < authorization.DTE_BEGIN_EFFV_AUTH__c || ( enrollObj.Previous_Enroll_End_Date__c == null)){
                        enrollObj.Previous_Enroll_End_Date__c =enrollObj.DTE_END_EFFV__c;
                    }else{
                        enrollObj.Previous_Enroll_End_Date__c =null;
                    }
                     enrollObj.DTE_END_EFFV__c =null;
                     enrollObj.Previous_Flag__c ='Declined';
                     enrollObj.Enroll_Flag__c='Enrolled';
                     enrollObj.DTE_BEGIN_EFFV__c=authorization.DTE_BEGIN_EFFV_AUTH__c;
                     enrollObj.Enrollment_Reason__c ='Child confirmed attending';
                     childEnrollToBeUpdated.add(enrollObj);
                 }else if(enrollObj.Enroll_Flag__c =='Declined'){
                    if(enrollObj.Previous_Enroll_End_Date__c < authorization.DTE_BEGIN_EFFV_AUTH__c || ( enrollObj.Previous_Enroll_End_Date__c == null)){
                        enrollObj.Previous_Enroll_End_Date__c =enrollObj.DTE_END_EFFV__c;
                    }else{
                        enrollObj.Previous_Enroll_End_Date__c =null;
                    }
                     enrollObj.DTE_END_EFFV__c =null;
                     enrollObj.Previous_Flag__c ='Declined';
                     enrollObj.Enroll_Flag__c='Enrolled';
                     enrollObj.DTE_BEGIN_EFFV__c=authorization.DTE_BEGIN_EFFV_AUTH__c;
                     enrollObj.Enrollment_Reason__c ='Child confirmed attending';
                     childEnrollToBeUpdated.add(enrollObj);
                 }
            }
        }
        
        if(childEnrollToBeInserted.size()>0){
            GenericDMLHandler.insertRecords(
                childEnrollToBeInserted,
                new Map<String,Object>{'Method__c'=>'createChildEnrollmentRecord','Class__c'=>'AuthorizationServices'},
                new List<String>{'IDN_CLIENT__c','IDN_PROVR__c','Enroll_Flag__c','Previous_Flag__c','IsWavierProvider__c','DTE_BEGIN_EFFV__c','Enrollment_Reason__c','isActive__c'}
            );
        }
        if(childEnrollToBeUpdated.size()>0){
            GenericDMLHandler.updateRecords(
                childEnrollToBeUpdated,
                new Map<String,Object>{'Method__c'=>'createChildEnrollmentRecord','Class__c'=>'AuthorizationServices'},
                new List<String>{'IDN_CLIENT__c','IDN_PROVR__c','Enroll_Flag__c','Previous_Flag__c','Previous_Enroll_End_Date__c','DTE_END_EFFV__c','DTE_BEGIN_EFFV__c','Enrollment_Reason__c'}
            );
            ChildEnrollmentServices.insertATSRecords(childEnrollToBeUpdated);
        }
    }   
    // added for CCCAP-10162 by Shashank ,  CHATS Reverse mapping
    public static void markReverseRefOnAuthCase(Map<Id,T_AUTH__c>newAuthMap){
        List<T_SBSD_CASE__c> cases = new list<T_SBSD_CASE__c>();
        List<T_AUTH__c> authsToUpdate = new List<T_AUTH__c>();
        Map<Id,Id> authVsCase = new Map<Id,Id>();
        Map<Id,T_SBSD_CASE__c> caseMap = new Map<Id,T_SBSD_CASE__c>();
        for(T_AUTH__c auth : newAuthMap.values()){
            authVsCase.put(auth.Id,auth.IDN_CASE__c);
        }
        for(T_SBSD_CASE__c chatsCase : [select id,CHATS_Reverse_Refer_Mode__c,Program_Type__c
                                        from T_SBSD_CASE__c where id in:authVsCase.values() and CHATS_Reverse_Refer_Mode__c excludes('Auth Creation') and Program_Type__c in ('TF','LI')]){
                                        caseMap.put(chatsCase.Id,chatsCase);
        }
        for(T_AUTH__c auth : newAuthMap.values()){
            if(caseMap.containsKey(auth.IDN_CASE__c)){
                T_SBSD_CASE__c chatsC = caseMap.get(auth.IDN_CASE__c);
                chatsC.CHATS_Reverse_Refer_Mode__c = chatsC.CHATS_Reverse_Refer_Mode__c!=null?chatsC.CHATS_Reverse_Refer_Mode__c+';Auth Creation' :'Auth Creation';
                chatsC.Case_Reverse_Refer_Track__c = true;
                cases.add(chatsC);
                T_AUTH__c auth1 = new T_AUTH__c(Id=auth.Id,Auth_Reverse_Refer_Track__c=true);
                authsToUpdate.add(auth1);
            }
        }
        if(!cases.isEmpty()){
            GenericDMLHandler.updateRecords(cases, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_SBSD_Case__c'},'Class__c'=>'AuthorizationServices','Method__c'=>'markReverseRefOnAuthCase'});
        }
        if(!authsToUpdate.isEmpty()){
            GenericDMLHandler.updateRecords(authsToUpdate, new Map<String,Object>{'byPassObjects'=>new Set<String>{'T_AUTH__c'},'Class__c'=>'AuthorizationServices','Method__c'=>'markReverseRefOnAuthCase'});
        }
    }

    /*
    * CCCAP-15329 - Clears UPK fields when 'Is this Child Dually Enrolled in UPK?' is changed to anything except 'Yes'
    */
    public static void handleUPKFieldsOnEnrollmentChange(List<T_AUTH__c> newAuthorizations, Map<Id, T_AUTH__c> oldAuthorizationMap) {
        for (T_AUTH__c auth : newAuthorizations) {            
            if (Trigger.isInsert || (Trigger.isUpdate && oldAuthorizationMap.get(auth.Id).CDE_CHILD_ENROLLED_IN_UPK__c != auth.CDE_CHILD_ENROLLED_IN_UPK__c)) {
                if (auth.CDE_CHILD_ENROLLED_IN_UPK__c == 'Yes') {
                    auth.UPK_Last_Updated_date__c = Date.today();
                } else {
                    auth.UPK_Awarded_Hours__c = null;
                    auth.UPK_Start_date__c = null;
                    auth.Is_UPK_Stacked__c = 'No';
                    auth.UPK_Last_Updated_date__c = null;
                }
            }
        }
    }

    /*
    * CCCAP-15329 - Creates Task T122 when 'Is this Child Dually Enrolled in UPK?' is set to 'Yes' or when UPK Awarded Hours are updated to a value greater than 0
    */
    public static void createTaskT122(Set<Id> qualifyingAuthIds){
        if (qualifyingAuthIds == null || qualifyingAuthIds.isEmpty()) {
            return;
        }
        List<Task> tasksToInsert = new List<Task>();
        Map<Id, T_AUTH__c> authWithCaseOwnerMap = new Map<Id, T_AUTH__c>([
            SELECT Id, IDN_CASE__r.OwnerId FROM T_AUTH__c WHERE Id IN :qualifyingAuthIds]);

        for (Id authId : qualifyingAuthIds) {
            T_AUTH__c authWithOwner = authWithCaseOwnerMap.get(authId);
            if (authWithOwner == null || authWithOwner.IDN_CASE__r.OwnerId == null){
                continue;
            }
            Task t = new Task();
            t.Subject = Label.Task_T122_Subject;
            t.Description = Label.Task_T122_Description;
            t.Status = 'New';
            t.Priority = 'Normal';
            t.WhatId = authId;
            t.OwnerId = authWithOwner.IDN_CASE__r.OwnerId;
            tasksToInsert.add(t);
        }
        if (!tasksToInsert.isEmpty()) {
            GenericDMLHandler.insertRecords(tasksToInsert,
                new Map<String,Object>{'Method__c'=>'createTaskT122','Class__c'=>'AuthorizationServices'},
                new List<String>{'Subject','Description','WhatId','OwnerId','Status','Priority'}
            );
        }
    }
}