/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/23/2017                                                          
*  @description    EmploymentVerificationApxCtrl
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 23-Nov-2017                                                             
*  * Author: Shubham Jain                                                      
*  * Description: Initial version                                                 
*  * JIRA Ticket: CHAT-1187
*                                                                                 
*********************************************************************************************/
public with sharing class EmploymentVerificationApxCtrl {
    @AuraEnabled
    public static LightningServerResponse getInitData(String employmentId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        Date todayDate = system.today();
       // String profileName = [Select Name from Profile where Id =: UserInfo.getProfileId() Limit 1].Name;   Commenting as part of CCCAP-14993 since using custom permission
        Boolean isReadOnlyUser =false;
        //Replacing with custom permission CCCAP-14993
        if(FeatureManagement.checkPermission('Read_Only_User')){
                isReadOnlyUser=true;
            }
            objectData.put('isReadOnlyUser',isReadOnlyUser);
        List<T_SBSD_INDIV_EMPLMT__c> employments = [SELECT Id, IDN_CLIENT__r.NAM_LAST__c, IDN_CLIENT__r.NAM_FIRST__c, NAM_BUSNS__c, 
                                                    (SELECT Id, CDE_TYPE_VERIF__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c FROM Employment_Information__r WHERE CDE_TYPE_INFO_EMPLMT__c != 'EIW' and DTE_BEGIN_EFFV__c <=:todayDate and (DTE_END_EFFV__c >=:todayDate or  DTE_END_EFFV__c = null)),
                                                    (SELECT Id, CDE_TYPE_VERIF__c FROM Employment_Verifications__r)
                                                    FROM T_SBSD_INDIV_EMPLMT__c WHERE Id = :employmentId WITH SECURITY_ENFORCED];
        if(!employments.isEmpty()){
            objectData.put('data',employments.get(0));
        }else{
            isSuccessful = false;
        }
        isSuccessful = true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
}