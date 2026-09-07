// added for UFE by Shashank 08/09/24
@RestResource(urlMapping='/getClientInfo/*')
global with sharing class MS_FetchClientData {
    
    @HttpPost
    global static List<UFE_ResponseWrapper> getClientInfobyPost(){
        Map<String, Object> requestBody = (Map<String, Object>) JSON.deserializeUntyped(RestContext.request.requestBody.toString());
        String searchEmailId 	= (String)requestBody.get('email_id');
        String identifier 		= (String)requestBody.get('id');
        String appOrCase 		= (String)requestBody.get('iType');
        MS_FetchClientDataHelper.caseDataMap 		 	= new Map<Id,UFE_ResponseWrapper>();
        MS_FetchClientDataHelper.countyCodeVsName		= new map<String,String>();
        //. Query : to fetch all the County related information, 
        for(T_COUNTY__c county: [select Name,CDE_COUNTY__c  from T_COUNTY__c]){
            string countycode = county.CDE_COUNTY__c<10 ? '0'+county.CDE_COUNTY__c:county.CDE_COUNTY__c.toString();
            MS_FetchClientDataHelper.countyCodeVsName.put(countycode,county.Name);
        }
        // first Search based on Email, provide all the application/case level information where individual with provided email is associated
        if(searchEmailId!=null){
            MS_FetchClientDataHelper.getClientInfoByEmail(searchEmailId);
        }
        //Search based on Application Id to fetch specific case/app information by Id provided
        else if(appOrCase =='application'){
            MS_FetchClientDataHelper.getClientInfoByAppId(identifier,appOrCase);
        }//Search based on Case Id to fetch specific case/app information by Id provided
        else if(appOrCase =='case'){
            MS_FetchClientDataHelper.getClientInfoByCaseId(identifier,appOrCase);
        }
        return MS_FetchClientDataHelper.caseDataMap.values();
    }
}