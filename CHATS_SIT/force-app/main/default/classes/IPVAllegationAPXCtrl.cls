/************************************************************
*  Author:         Deloitte Consulting LLP.
*  Date:           06/16/2021
*  Description:    Controller class for IPV_DisqualificationScreen flow
*  Test class:     IPVAllegationAPXCtrl_Test
*
*  Modification Log:
*  * Version: 1.0
*  * Date: 06/16/2021
*  * Author: Vineet Srivastava
*  * Description: Initial version
*
*  * Version: 1.1
*  * Date: 03/03/2023
*  * Author: Rishav Maji
*  * Description: API Upgrade, Code cleanup, CheckMarx fix
************************************************************/
public with sharing class IPVAllegationAPXCtrl {
    
    public static String getDomainURL(){
        String domainURL = URL.getOrgDomainUrl().toExternalForm();
        return domainURL;
    }
    
    public static IPV_Information__c getIPVInformation(){
        IPV_Information__c ipvInfoRec = new IPV_Information__c();
        Id ipvInformationId = String.escapeSingleQuotes(apexpages.currentpage().getparameters().get('ipvInformationId'));
        ipvInfoRec = [SELECT Id, Name, Name__c FROM IPV_Information__c WHERE Id = :ipvInformationId WITH SECURITY_ENFORCED];
        return ipvInfoRec;
    }
    
    public static List<Allegation_Note__c> getAllegationNotes(){
        Id ipvInformationId = String.escapeSingleQuotes(apexpages.currentpage().getparameters().get('ipvInformationId'));
        List<Allegation_Note__c> lstAllegationNotes = [SELECT Id, Note_Type__c, name, Body__c, Subject__c, CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate FROM Allegation_Note__c WHERE IPV_Information__c = :ipvInformationId WITH SECURITY_ENFORCED ORDER BY CreatedDate ASC];
        return lstAllegationNotes;
    }
    
    @AuraEnabled
    public static LightningServerResponse getDisqualificationInitData(String recordId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        Date lastOccurenceEndDate;
        String message;
        Integer occurences = 0;
        
        List<IPV_Information__c> lstIPVInfo = [SELECT Id, Individual_Id__c FROM IPV_Information__c WHERE id=: String.escapeSingleQuotes(recordId) WITH SECURITY_ENFORCED];
        for (IPV_Information__c ipvRec : [SELECT Id, Number_of_occurrences__c, Disqualification_End_Date__c FROM IPV_Information__c WHERE Individual_Id__c = :lstIPVInfo[0].Individual_Id__c and Id != :String.escapeSingleQuotes(recordId) and Reversal_Created__c = false WITH SECURITY_ENFORCED ORDER BY Number_of_occurrences__c DESC LIMIT 1 ]){
            if(ipvRec.Number_of_occurrences__c != null && ipvRec.Number_of_occurrences__c != ''){
                occurences = Integer.valueOf(ipvRec.Number_of_occurrences__c);
                lastOccurenceEndDate = ipvRec.Disqualification_End_Date__c;
            }
        }
        objectData.put('occurences', ++occurences);
        objectData.put('lastOccurenceEndDate', lastOccurenceEndDate);
        isSuccessful = true;
        LightningServerResponse lsr = getInvestigatoryFindings(String.escapeSingleQuotes(recordId));
        if(lsr.isSuccessful){
            objectData.put('lstInvestigatoryFindings', lsr.objectData.get('lstInvestigatoryFindings')); 
        }
        Map<String, String> mapInvInfoValuetoLabel = CHATSUtility.getPicklistValuesToLabelMap(Investigatory_Finding__c.Investigatory_Finding__c.getDescribe());
        if(mapInvInfoValuetoLabel!= null){
            objectData.put('mapInvInfoValuetoLabel', mapInvInfoValuetoLabel);
        }
        Map<String, String> mapOccurredValuetoLabel = CHATSUtility.getPicklistValuesToLabelMap(Investigatory_Finding__c.Occurred__c.getDescribe());
        if(mapOccurredValuetoLabel!= null){
            objectData.put('mapOccurredValuetoLabel', mapOccurredValuetoLabel);
        }
        Map<String, String> mapInvInfoLabelToValue = CHATSUtility.getPicklistLabelToValueMap(Investigatory_Finding__c.Investigatory_Finding__c.getDescribe());
        if(mapInvInfoLabelToValue!= null){
            objectData.put('mapInvInfoLabelToValue', mapInvInfoLabelToValue);
        }
        Map<String, String> mapOccurredLabelToValue = CHATSUtility.getPicklistLabelToValueMap(Investigatory_Finding__c.Occurred__c.getDescribe());
        if(mapOccurredLabelToValue!= null){
            objectData.put('mapOccurredLabelToValue', mapOccurredLabelToValue);
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
    
    @AuraEnabled
    public static String getLatestIPVRecord(String individualId){
        String ipvRecordId;
        for(IPV_Information__c ipv : [SELECT Id FROM IPV_Information__c WHERE Individual_ID__c = :String.escapeSingleQuotes(individualId) WITH SECURITY_ENFORCED ORDER BY lastModifiedDate DESC LIMIT 1]){
            ipvRecordId = ipv.Id;
        }
        return ipvRecordId;
    }
    
    @AuraEnabled
    public static LightningServerResponse getInvestigatoryFindings(String ipvId){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = false;
        Date lastOccurenceEndDate;
        String message;
        List<Investigatory_Finding__c> lstInvestigatoryFindings = new List<Investigatory_Finding__c>();
        for(Investigatory_Finding__c investigatoryFinding : [SELECT Id, toLabel(Occurred__c), Date__c, IPV_Information__c, toLabel(Investigatory_Finding__c) FROM Investigatory_Finding__c WHERE IPV_Information__c = :String.escapeSingleQuotes(ipvId) WITH SECURITY_ENFORCED ORDER BY CreatedDate ASC]){
            lstInvestigatoryFindings.add(investigatoryFinding);
        }
        if(lstInvestigatoryFindings.size() > 0){
            objectData.put('lstInvestigatoryFindings', lstInvestigatoryFindings);
            isSuccessful=true;
        }
        return new LightningServerResponse(isSuccessful, message, objectData);
    }
}