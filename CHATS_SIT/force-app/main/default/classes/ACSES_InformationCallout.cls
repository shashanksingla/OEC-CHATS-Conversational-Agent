/**
* @Component Name   : ACSES_InformationCallout
* @Developed By     : Gaurav Trivedi
* @Created Date     : May 14, 2018
* @Description      : Webservice call from TRAILS database
* @Test Class		: ACSES_InformationCalloutTest
* ***************************************************************************************************
*										Modification Log
* ***************************************************************************************************
* 	Name				|	Version		|		Date		|					Discription
* ***************************************************************************************************
*						|				|					|	
*
*/
global with sharing class ACSES_InformationCallout {
    /**
    * @function     :   parentStateIdToNameMap
    * @description  :   Generate map of Parent state Id to Parent Name and pass it to Lightning page
    * @parm         :   {String} caseId
    * @return       :  	String 
    */
    @AuraEnabled
    public static String parentStateIdToNameMap(String caseId){
        Set<Id> individualSet = new Set<Id>();
        Map<Id, T_SBSD_CASE_INDIV__c> caseIntividualMap = new Map<id,T_SBSD_CASE_INDIV__c>();
        List<T_SBSD_CASE_INDIV__c> plist = new List<T_SBSD_CASE_INDIV__c>();
        Set<String> careTakerRelationships = new Set<String>{'F', 'M', 'CLH', 'CLW', 'W', 'H', 'LIC'};
        try{
            for(T_SBSD_CASE_INDIV__c caseIndiv : [SELECT Name, IDN_CLIENT__c, IDN_STATE__c, NAM_INDIV__c, DTE_END_EFFV__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CASE__c = : caseId AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c > TODAY)]){
                caseIntividualMap.put(caseIndiv.IDN_CLIENT__c, caseIndiv);
            }
            if(!caseIntividualMap.isEmpty()){
                for(T_SBSD_INDIV__c indiv:[SELECT Id, NAM_FIRST__c, NAM_LAST__c, Age__c, IDN_STATE__c, (SELECT Id FROM Relationship__r WHERE CDE_TYPE_REL_INDIV__c IN:careTakerRelationships), (SELECT Id FROM Case_Individual__r WHERE IND_CRTKR__c=true) FROM T_SBSD_INDIV__c WHERE Id IN:caseIntividualMap.keySet()]){
                    if(!indiv.Case_Individual__r.isEmpty() || indiv.Age__c>18 || !indiv.Relationship__r.isEmpty()){
                        individualSet.add(indiv.Id);
                    }
                }
                for(Id indv: individualSet){
                    plist.add(caseIntividualMap.get(indv));
                }
            }
        }catch(Exception e) {
            throw new AuraHandledException('Oops! Something went wrong: '+ e.getMessage());
        }
        return JSON.serialize(plist);
    }

    /**
    * @function     :   domProcessing
    * @description  :   Process Request and response
    * @parm         :   {String} supportType,{String} parentId, {String} endDate
    * @return       :   DomDocument
    */
    @AuraEnabled
    public static String callACSES(String supportType,String parentId, String endDate){
        String returnResult;
        try {
            ACSES_Trails_WebService.trails_webservicesSOAP call = new ACSES_Trails_WebService.trails_webservicesSOAP();
            ACSES_Trails_WebService_Fiscal.NonCustodialParentFiscalDataType ncpFiscalData = new ACSES_Trails_WebService_Fiscal.NonCustodialParentFiscalDataType();
            List<ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType> cpFiscalData = new List<ACSES_Trails_WebService_Fiscal.CustodialParentFiscalDataType>();
            Date beginningDate = String.isNotBlank(endDate) ? Date.valueOf(endDate).addMonths(-12) : System.today().addMonths(-12);
            Date endingDate = String.isNotBlank(endDate) ? Date.valueOf(endDate) : System.today();
            String childStateID = null;
            if (String.isNotBlank(parentId)) {
                if (supportType.equalsIgnoreCase('Expense')) {
                    ncpFiscalData = call.GetNCPFiscalData(parentId, beginningDate, endingDate);
                    returnResult = JSON.serializePretty(ncpFiscalData);
                } else {
                    cpFiscalData = call.GetCPFiscalData(parentId, childStateID, beginningDate, endingDate);
                    returnResult =  JSON.serializePretty(cpFiscalData);
                }
            }
        }catch(Exception e){
            returnResult = 'Oops! Something went wrong: '+e.getMessage();
            throw new AuraHandledException(returnResult);
        }
        return returnResult;
    }
}