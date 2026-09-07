/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           04/05/2018                                                          
*  @description    APEX CLASS for Attendance Search                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 05-Apr-2018                                                             
*  * Author: Vineet Srivastava                                                    
*  * Description: Initial version
*  * Version: 2.0                                                                             
*  * Date: 31-July-2018                                                             
*  * Author: Azhar
*  * Description: updated the logic to take end date till today EOD by adding +1 and replacing <= with < in the query
*  * Version: 3.0                                                                             
*  * Date: 20-Aug-2018                                                             
*  * Author: Azhar
*  * Description: CHAT-6249 : Attendance Search Screen should display transaction records with SUBTYPE CCCAP, CCCAP Not authorized and DropIn.
*  * Version: 4.0                                                                             
*  * Date: 05-Dec-2018                                                             
*  * Author: Bharadwaj Gaddam                                                    
*  * Description: CHATS-7133 : Added Web Service callout to fetch Transaction records from external system
*  * Version: 5.0                                                                             
*  * Date: 11-Apr-2019                                                             
*  * Author: Erik Sells                                                    
*  * Description: CHATS-5149 : Convert fromDate and toDate to GMT datetime variables rather than local datetime.  
*  *                           Original Search is retrieving records one day before fromDate.
*  * Version: 6.0                                                                             
*  * Date: 23-May-2019                                                              
*  * Author: Erik Sells                                                    
*  * Description: CHATS-5149 : Update Version 5.0 to fix remaining situations where search is still retrieving
*  *                           records one day earlier.
*  * Version: 7.0                                                                             
*  * Date: 28-Jun-2019                                                              
*  * Author: Erik Sells                                                    
*  * Description: CHATS-5149 : Update Version 6.0 to fix remaining situations where search is still retrieving
*  *                           records one day earlier.
*  * Version: 8.0                                                                             
*  * Date: 29-Jul-2019                                                              
*  * Author: Erik Sells                                                    
*  * Description: CHATS-5149 : Update Version 7.0 to fix searches showing one day in the future of toDate.
*  * 
*  * Version: 9.0                                                                             
*  * Date: 6-Sep-2019                                                              
*  * Author: Erik Sells                                                    
*  * Description: CHATS-5149 : Finally figured out where the problem was.  fromDate and toDate needed to be
*  *                           fixed in the web service call for wsReturnedTransList, 
*  *                           in addition to the query string for the Database.query call.  I had previously
*  *                           focused exclusively on the query string and database call.
*  * 
*  * Version: 10.0                                                                             
*  * Date: 16-May-2022                                                              
*  * Author: Rishav Maji                                                    
*  * Description: CCCAP-5186 : Updated sorting order in 'getAttendanceResults' and 'getAttendanceResultsFor803Report' methods.
*  *                           Added 'isPending' filter in 'getAttendanceResultsFor803Report'.
*  *                           API upgrade from 42 to 54.
*  * 
*********************************************************************************************/
public with sharing class AttendanceSearchApxCtrl {  
    
    public static final String SUB_TYPE = System.Label.PRIVATE_PAY;
    public static final String CONFIRMATION = System.Label.ATSRecordTypeConfirmation;
    
    /**
* @description get Attendance Information 
* @author Vineet Srivasatava
* @date 04/05/2018   
* @param providerId, CaseId, stateId, fromDate,toDate
* @return LightningServerResponse  
*/ 
    @auraEnabled
    public static LightningServerResponse getAttendanceResults(String providerId, String caseId, String stateId, String fromDate, String toDate){
        try{
            Map<String, Object> objectData = new map<String, Object>();
            Map<String, String> transactionTypeMap = DynamicExternalDetailPageController.getPickListValue('Field_Utility__c','Attendance_Transaction_Type__c');
            Map<String, String> transactionStatusMap = DynamicExternalDetailPageController.getPickListValue('Field_Utility__c','Attendance_Transaction_Status__c');
            List<Object> transList = new List<Object>();
            Map<Object, Map<String,Object>> transMap = new Map<Object, Map<String,Object>>();
            List<Object> wsReturnedTransList= new List<Object>(); 
            Boolean isSuccessful;
            String message;
            Date fromDateEntered = Date.valueOf(fromDate);
            Datetime fromDateTime = datetime.newInstance(fromDateEntered.year(), fromDateEntered.month(), fromDateEntered.day(), 0, 0, 0);          
            String fromDateTimeFormattedGMT = fromDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'', 'GMT');            
            Datetime fromDateTimeGMT = datetime.newInstanceGMT(fromDateEntered.year(), fromDateEntered.month(), fromDateEntered.day());
            Date toDateEntered = Date.valueOf(toDate);
            toDateEntered = toDateEntered.addDays(1);
            Datetime toDateTime = datetime.newInstance(toDateEntered.year(), toDateEntered.month(), toDateEntered.day());
            String toDateTimeFormattedGMT = toDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'', 'GMT');  
            Datetime toDateTimeGMT = datetime.newInstanceGMT(toDateEntered.year(), toDateEntered.month(), toDateEntered.day());
            String query ='Select Reporting_Parent_Caretaker_Name_c__c, Id,Reporting_Transaction_Type_c__c, Reporting_Authorization_Id_c__c,CI_Transaction_ID_c__c,' 
                +'Reporting_Card_Number_c__c, Reporting_Case_Id_c__c, Reporting_Child_Name_c__c,Reporting_Child_Number_c__c, Reporting_Client_Id_c__c,'
                +'Reporting_Denial_Reason_Code_c__c,CreatedDate__c, Reporting_Error_Description_c__c, Reporting_Provider_Id_c__c,CI_Entry_Time_c__c,' 
                +'Reporting_SAF_Indicator_c__c, Reporting_State_Id_c__c, Reporting_Transaction_Result_c__c, Name__c, CI_Transaction_Time_c__c,ExternalId from Transaction_c__x where Sub_Type_c__c !=\''+ String.escapeSingleQuotes(SUB_TYPE)+'\''
                +' and Reporting_Provider_Id_c__c=' + Decimal.valueOf(String.escapeSingleQuotes(providerId))
                +' and RecordTypeId__c !=\'' + String.escapeSingleQuotes(CONFIRMATION) + '\''
                +' and CI_Transaction_Time_c__c >=' + fromDateTimeFormattedGMT
                +' and CI_Transaction_Time_c__c <=' + toDateTimeFormattedGMT;
            if(caseId != null && caseId != ''){
                query += ' and Reporting_Case_Id_c__c=' + Decimal.valueOf(String.escapeSingleQuotes(caseId));
            }
            if(stateId != null && stateId != ''){
                query += ' and Reporting_State_Id_c__c=\'' + String.escapeSingleQuotes(stateId) + '\'' ;
            }
            query += ' ORDER BY Reporting_Child_Name_c__c, CI_Transaction_Time_c__c ASC NULLS LAST';
            List<Transaction_c__x> lstTransaction = new List<Transaction_c__x>();
            lstTransaction = Database.query(query);
            wsReturnedTransList= getCalloutResponseContents(providerId, caseId, stateId, fromDateTimeGMT, toDateTimeGMT);
            for(Object obj:wsReturnedTransList) {
                Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
                if(mp_StrObj.get('id')!=null) {
                    transMap.put(mp_StrObj.get('id'), mp_StrObj);
                }
            }
            for(Transaction_c__x tran:lstTransaction) {
                if(transMap.keySet().contains(tran.ExternalId )) {
                    transMap.remove(tran.ExternalId);
                }
            } 
            if(!transMap.isEmpty()) {
                system.debug('testing'+transMap.values());
                transList.addAll((List<Object>)transMap.values());
            }  
            if(transList.size()>0 || lstTransaction.size()>0) {
                if(lstTransaction.size()>0) {
                    objectData.put('lstTransaction1',lstTransaction);
                }
                if(transList.size()>0) {
                    objectData.put('lstTransaction2',transList);
                }
                objectData.put('transactionTypeMap',transactionTypeMap);
                objectData.put('transactionStatusMap',transactionStatusMap);
                isSuccessful=true;
            } else {
                isSuccessful= false;
                message=Label.No_Records_Found;
            }
            return new LightningServerResponse(isSuccessful,message,objectData); 
        } Catch(CallOutException ce) {
            return new LightningServerResponse(false,'Problem Connecting to external system. '+ce.getMessage(),null);  
        } Catch(Exception e) {
            Map<String,Object> exceptionMap = new Map<String,Object>();
            exceptionMap.put('Class__c','AttendanceSearchApxCtrl');    
            exceptionMap.put('Method__c','getAttendanceResults');            
            ExceptionLoggingServices.captureExceptionLog(e, exceptionMap);
            return new LightningServerResponse(false,e.getMessage(),null);
        }
    }
    
    /**
* @description Web Service Callout
* @author Bharadwaj Gaddam
* @date 12/5/2018 
* @param String providerId, String caseId, String stateId, Datetime fromDate, Datetime toDate
* @return List<Object>
*/           
    public static List<Object> getCalloutResponseContents(String providerId, String caseId, String stateId, Datetime fromDate, Datetime toDate) {
        try {
            // Instantiate a new http object
            Http h = new Http();
            // Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            req.setTimeout(Integer.valueOf(system.Label.AttendanceSearchTimeOut));  //Added time out based on CHATS-7275
            req.setEndpoint(Label.ATSSearch);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            string bodystr='{ "caseId":';
            if(String.isEmpty(caseId)) {
                bodystr+=null+',';
            } else {
                bodystr+='"'+caseId+'", ';
            }
            bodystr+='"stateId":';
            if(String.isEmpty(stateId)) {
                bodystr+=null+',';
            } else {
                bodystr+='"'+stateId+'", ';
            }
            bodystr+='"providerId":"'+providerId+'", "fromDate":"'+fromDate+'", "toDate":"'+toDate+'" }';
            system.debug('bodystr'+bodystr);
            req.setBody(bodystr);
            if(!Test.isRunningTest()) {
                // Send the request, and return a response
                res = h.send(req);
            }
            // return res.getBody();
            if (res.getStatusCode() != 200) {
                System.debug('The status code returned was not expected: ' + res.getStatusCode() + ' ' + res.getStatus()+' '+res.getBody());
                ExceptionLoggingServices.captureExceptionLog(res, req, new Map<String,Object>{'Class__c'=>'AttendanceSearchApxCtrl','Method__c'=>'getCalloutResponseContents'});             
                return new List<Object>();
            } else {
                return (List<Object>) JSON.deserializeUntyped(res.getBody());
            }
        } catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'AttendanceSearchApxCtrl','Method__c'=>'getCalloutResponseContents'});             
            return new List<Object>{};
        }
    }
    
    public static Map<String, Object> getAttendanceResultsFor803Report(String providerId, String caseId, String stateId, String fromDate, String toDate, String isPending){
        system.debug('REACHED getAttendanceResultsForReport');            
        system.debug('providerId-->' + providerId);
        system.debug('caseId-->' + caseId);
        system.debug('stateId-->' + stateId);
        system.debug('toDate-->' + toDate);
        system.debug('fromDate-->' + fromDate);
        system.debug('isPending-->' + isPending);
        Map<String, Object> objectData = new map<String, Object>();
        Map<String, String> transactionTypeMap = DynamicExternalDetailPageController.getPickListValue('Field_Utility__c','Attendance_Transaction_Type__c');
        Map<String, String> transactionStatusMap = DynamicExternalDetailPageController.getPickListValue('Field_Utility__c','Attendance_Transaction_Status__c');
        List<Object> transList = new List<Object>();
        Map<Object, Map<String,Object>> transMap = new Map<Object, Map<String,Object>>();
        List<Object> wsReturnedTransList= new List<Object>();
        Boolean isSuccessful;
        String message;
        Date fromDateEntered = Date.valueOf(fromDate);
        Datetime fromDateTime = datetime.newInstance(fromDateEntered.year(), fromDateEntered.month(), fromDateEntered.day(), 0, 0, 0);          
        String fromDateTimeFormattedGMT = fromDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'', 'GMT');            
        Date toDateEntered = Date.valueOf(toDate);
        Datetime toDateTime = datetime.newInstance(toDateEntered.year(), toDateEntered.month(), toDateEntered.day(), 23, 59, 59);
        String toDateTimeFormattedGMT = toDateTime.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'', 'GMT');                    
        String query ='Select Reporting_Parent_Caretaker_Name_c__c, Id,Reporting_Transaction_Type_c__c, Reporting_Authorization_Id_c__c,CI_Transaction_ID_c__c,Creation_Source_c__c,Status_c__c,API_Flag_c__c,CI_Provider_ID_c__c,' 
            +'Reporting_Card_Number_c__c, Reporting_Case_Id_c__c, Reporting_Child_Name_c__c,Reporting_Child_Number_c__c, Reporting_Client_Id_c__c,CI_Transaction_Result_c__c,LastModifiedDate__c,Record_Type_Name_c__c,Provider_Number_c__c,'
            +'Reporting_Denial_Reason_Code_c__c,CreatedDate__c, Reporting_Error_Description_c__c, Reporting_Provider_Id_c__c,CI_Entry_Time_c__c,CI_Transaction_Type_c__c, Transaction_Created_By_Name__c ,' 
            +'Reporting_SAF_Indicator_c__c, Reporting_State_Id_c__c, Reporting_Transaction_Result_c__c, Name__c, CI_Transaction_Time_c__c,ExternalId from Transaction_c__x where Sub_Type_c__c !=\''+ String.escapeSingleQuotes(SUB_TYPE)+'\''
            +' and RecordTypeId__c !=\'' + String.escapeSingleQuotes(CONFIRMATION) + '\''
            +' and CI_Transaction_Time_c__c >=' + fromDateTimeFormattedGMT
            +' and CI_Transaction_Time_c__c <=' + toDateTimeFormattedGMT;
        if(providerId != null && providerId !='' ) {
            query += ' and Reporting_Provider_Id_c__c=' + Decimal.valueOf(String.escapeSingleQuotes(providerId));
        }
        if(caseId != null && caseId != ''){
            query += ' and Reporting_Case_Id_c__c=' + Decimal.valueOf(caseId);
        }
        if(isPending == 'true'){ // Added by Rishav for CCCAP-5186
            query += ' and Status_c__c = \'PARENT_PENDING\' and Creation_Source_c__c != \'Parent\'';
        }
        if(stateId != null && stateId != ''){
            query += ' and Reporting_State_Id_c__c=\'' + String.escapeSingleQuotes(stateId) + '\'' ;
        }
        query += ' ORDER BY Reporting_Child_Name_c__c, CI_Transaction_Time_c__c ASC NULLS LAST';
        System.debug('query-->'+query);
        List<Transaction_c__x> lstTransaction = new List<Transaction_c__x>();
        List<Transaction_c__x> lstTransaction2 = new List<Transaction_c__x>();
        lstTransaction2 = Database.query(query);
        system.debug('lstTransaction2.size()::' + lstTransaction2.size());
        System.debug('========== (0) getAttendanceResultsFor803Report: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
        // CCCAP-5270
        // Heap size exceeds if the response body is more than 5.5MB
        // The callout data is not used anywhere in the code. So commenting the callout                   
        //wsReturnedTransList= getCalloutResponseContents(providerId, caseId, stateId, fromDateTime, toDateTime);
        for(Transaction_c__x tran:lstTransaction2) {
            Datetime fromDatetime2 = datetime.newInstance(tran.CI_Transaction_Time_c__c.year(), tran.CI_Transaction_Time_c__c.month(), tran.CI_Transaction_Time_c__c.day(), tran.CI_Transaction_Time_c__c.hour(), tran.CI_Transaction_Time_c__c.minute(), tran.CI_Transaction_Time_c__c.second());
            Datetime toDatetime2 = datetime.newInstance(tran.CI_Transaction_Time_c__c.year(), tran.CI_Transaction_Time_c__c.month(), tran.CI_Transaction_Time_c__c.day(), tran.CI_Transaction_Time_c__c.hour(), tran.CI_Transaction_Time_c__c.minute(), tran.CI_Transaction_Time_c__c.second()); 
            Date fromDateEntered2 = Date.newInstance(fromDatetime2.year(), fromDatetime2.month(), fromDatetime2.day());
            Date toDateEntered2 = Date.newInstance(toDatetime2.year(), toDatetime2.month(), toDatetime2.day());
            if (fromDateEntered2 >= fromDateEntered && toDateEntered2 <= toDateEntered)
                lstTransaction.add(tran);              
        }                   
        for(Object obj:wsReturnedTransList) {
            Map<String,Object> mp_StrObj = (Map<string,Object>)obj;
            if(mp_StrObj.get('id')!=null) {
                transMap.put(mp_StrObj.get('id'), mp_StrObj);
            }
        }
        for(Transaction_c__x tran:lstTransaction) {
            if(transMap.keySet().contains(tran.ExternalId )) {
                transMap.remove(tran.ExternalId);
            }
        } 
        if(!transMap.isEmpty()) {
            system.debug('testing'+transMap.values());
            transList.addAll((List<Object>)transMap.values());
        }  
        system.debug('lstTransaction.size()::' + lstTransaction.size());
        system.debug('transList.size()::' + transList.size());
        if(transList.size()>0 || lstTransaction.size()>0) {
            if(lstTransaction.size()>0) {
                objectData.put('lstTransaction1',lstTransaction);
            }
            if(transList.size()>0) {
                //objectData.put('lstTransaction2',transList);
            }
            objectData.put('transactionTypeMap',transactionTypeMap);
            objectData.put('transactionStatusMap',transactionStatusMap);
            isSuccessful=true;
        } else {
            isSuccessful= false;
            message=Label.No_Records_Found;
        }
        System.debug('========== (1) getAttendanceResultsFor803Report: <<Heap>> Used : ' + Limits.getHeapSize() + ' , Available : ' + (Limits.getLimitHeapSize()-Limits.getHeapSize()) );
        if(isSuccessful) {
            return objectData;  
        } else {
            return null;
        }
    }
}