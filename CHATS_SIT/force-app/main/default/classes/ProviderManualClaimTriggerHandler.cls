public with sharing class ProviderManualClaimTriggerHandler {
    
    public static void handleBeforeUpdateOps(List<Provider_Manual_Claim__c> newClaims , Map<Id,Provider_Manual_Claim__c> oldClaims){
        Map<Decimal,Id> countyCodevsId = new Map<Decimal,Id>();
        Set<Id> adjIdSet = new Set<Id>(); 
        for(Provider_Manual_Claim__c claim: newClaims){
            if(claim.County_Code__c!=null){
                countyCodevsId.put(integer.valueOf(claim.County_Code__c),null);
            }
            
            if(claim.Claim_Status__c != oldClaims.get(claim.id).Claim_Status__c){
                if(claim.Claim_Status__c == 'Denied' && claim.Adjustment__c!=null){
                    claim.addError('Denied record cannot have an Adjustment ID.');
                }
            }
            if(claim.Adjustment__c!=null && claim.Adjustment__c!=oldClaims.get(claim.id).Adjustment__c){
                adjIdSet.add(claim.Adjustment__c);
            }            
        }
        for(T_County__c county: [select id,CDE_COUNTY__C from T_COUNTY__C where CDE_COUNTY__C IN : countyCodevsId.keyset()]){
            countyCodevsId.put(county.CDE_COUNTY__C,county.Id);
        }
        Map<Id,Boolean>countyMatch = CHATSUtility.checkCountyWithUserCountyBulk(new Set<Id>(countyCodevsId.values()));
        
        Map<Id,T_ADJMT__c> adjMap = new Map<Id,T_ADJMT__c>([select id,CDE_STATUS_ADJMT__c from T_ADJMT__c where id IN: adjIdSet and CDE_STATUS_ADJMT__c='4']);
        for(Provider_Manual_Claim__c  claim: newClaims){
            if(adjMap.containsKey(claim.Adjustment__c) && claim.Claim_Status__c!= '4'){
                claim.Claim_Status__c ='Paid';
            }
            if(claim.Claim_Status__c != oldClaims.get(claim.id).Claim_Status__c){
                if(claim.Status_Updated_Date__c == oldClaims.get(claim.id).Status_Updated_Date__c){
                    claim.Status_Updated_Date__c = Date.Today();
                    claim.Last_Modified_By__c = UserInfo.getName();
                }
            }
            Integer countyCode = Integer.valueOf(claim.County_Code__c);
            if(countyCode!=null && countyCodevsId.containsKey(countyCode)){
                Id countyId = countyCodevsId.get(countyCode);
                if(countyMatch.containsKey(countyId) && countyMatch.get(countyId) == false){
                    claim.addError('The county of the Provider Manual Claim does not match your assigned county(ies).');
                }
            }
        }
    }
    public static void handleAfterUpdateOps(List<Provider_Manual_Claim__c> newClaims , Map<Id,Provider_Manual_Claim__c> oldClaims){
        Set<Id> recordIds = new Set<Id>(); 
        for(Provider_Manual_Claim__c claim: newClaims){
            if(claim.Claim_Status__c != oldClaims.get(claim.id).Claim_Status__c){
                recordIds.add(claim.Id);
            }
        }
        if(!recordIds.isEmpty()){
            system.enqueueJob(new CallAtsAPIJob(JSON.serialize(recordIds)));
        }
    }
}