public class IndividualInformationServices {
    /*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           1/8/2018                                                          
*  @description    Handler Class for Individual Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 8-JAN-2018                                                             
*  * Author: Nikunj Doshi                                                   
*  * Description: Initial version                                                 
*  * 

*  * Version: 2.0                                                                             
*  * Date: 19-Oct-2023                                                           
*  * Author: Diya Chaudhary
*  * Description: Duplicate citizenship record create based on case id and county and individual id


*********************************************************************************************/
    public static final string HEADSTART='HDS';
    public static set<Id> getIndividualsInformationBasedonType(List<T_SBSD_INDIV_INFO__c> indivInfoList) {
        set<Id> individualsIdsSet = new set<Id>();
        for(T_SBSD_INDIV_INFO__c indivInfoEach:indivInfoList) {
            if(indivInfoEach.CDE_TYPE_INFO_INDIV__c==HEADSTART) {
                individualsIdsSet.add(indivInfoEach.IDN_CLIENT__c);
            }
            
        }
        return individualsIdsSet;
    }
    
    // CCCAP-9208 Changes
    public static void checkDuplicateCitizenshipRecords(List<T_SBSD_INDIV_INFO__c> listIndivInfo){
        Set<Id> caseIDSet = new Set<Id>();
        Set<Id> clientIDSet = new Set<Id>();
        List<T_SBSD_INDIV_INFO__c> listIndivInfoCtzn = new List<T_SBSD_INDIV_INFO__c>();
        Map<String,T_SBSD_INDIV_INFO__c> indivInfoMap = new Map<String,T_SBSD_INDIV_INFO__c>();
        for(T_SBSD_INDIV_INFO__c IndivInfo : listIndivInfo ){
            if(IndivInfo.CDE_TYPE_INFO_INDIV__c=='CS'){
                listIndivInfoCtzn.add(IndivInfo);
                caseIDSet.add(IndivInfo.IDN_CASE__c);
                clientIDSet.add(IndivInfo.IDN_CLIENT__c);
            }
        }
        if(listIndivInfoCtzn!= null && listIndivInfoCtzn.size()>0){
            for(T_SBSD_INDIV_INFO__c infoObj :[Select id,IDN_CASE__c,IDN_CLIENT__c from T_SBSD_INDIV_INFO__c where IDN_CASE__c in: caseIDSet and IDN_CLIENT__c in:clientIDSet and id not in:listIndivInfoCtzn and CDE_TYPE_INFO_INDIV__c='CS']){
                String key = infoObj.IDN_CASE__c +' _ '+infoObj.IDN_CLIENT__c;
                indivInfoMap.put(key,infoObj);
            }  
        }
       for(T_SBSD_INDIV_INFO__c infoObj : listIndivInfoCtzn ){
           String key = infoObj.IDN_CASE__c +' _ '+infoObj.IDN_CLIENT__c;
           if(indivInfoMap.containsKey(key)){
               infoObj.addError('Citizenship already exists for an individual from the same case. Please review the information again.');
           }
       }
        
    }
    
}