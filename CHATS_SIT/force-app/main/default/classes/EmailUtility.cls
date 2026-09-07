public with sharing class EmailUtility {
    
    public static Id getOrgWideEmailIdByLabel(String customLabel){
        
        if(!String.isBlank(customLabel)) {
            OrgWideEmailAddress[] owEmailAddress = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :customLabel Limit 1];
            
            if(!owEmailAddress.isEmpty()) {
            return owEmailAddress[0].Id;
            }
        }
        return null; 
    }

}