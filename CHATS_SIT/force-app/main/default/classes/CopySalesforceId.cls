/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           01/19/2018                                                          
*  @description    copies salesforce Id to External Id                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 19-Jan-2018                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version   
*
*  * Change Log :
*  * Developer Name                     Date                    Description
*  * Shubham Khandelwal               5/14/2018             Adding null ande size check on line number 48 before DML operation
*
*********************************************************************************************/
public with sharing class CopySalesforceId {
    public static Map<string,sObject> stampSalesforceIdToExternalId(List<sObject> sobjectList, Boolean doUpdate) {
        Map<string,sObject> updateSobjectMap = new Map<string,sObject>();
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'CopySalesforceId','Method__c'=>'stampSalesforceIdToExternalId'};
     
       try {
        for(sObject objEach:sobjectList) {
            if(objEach.get('Id') != null && objEach.get('IDN_EXTNL__c')==null) {
                objEach.put('IDN_EXTNL__c',objEach.get('Id'));
                updateSobjectMap.put(string.valueOf(objEach.get('Id')),objEach);
            } 
        }
        if(doUpdate) {
            if(!updateSobjectMap.isEmpty() && updateSobjectMap != NULL ) {
                update updateSobjectMap.values();
            }
        }
        } catch(Exception ex) {
            system.debug(ex.getMessage());
            ExceptionLoggingServices.captureExceptionLog(ex,methodInfo);
        }
        return updateSobjectMap;
    }

}