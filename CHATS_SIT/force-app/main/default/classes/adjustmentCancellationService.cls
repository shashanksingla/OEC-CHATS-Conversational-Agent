/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           10/31/2022                                                          
*  @description    Handler class for Adjustment Cancellation Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 31-Oct-2022                                                             
*  * Author: Raina Yeole
*  * Description: CCCAP-7013
*********************************************************************************************/

public with sharing class adjustmentCancellationService {
    
    public static void validateCancellationNotes(List<T_ADJMT_CANCEL__c> newAdjustCancelList, Map<Id, T_ADJMT_CANCEL__c> newMap, List<T_ADJMT_CANCEL__c> oldAdjustCancelList, Map<Id, T_ADJMT_CANCEL__c> oldMap){
        Set<Id> adjId = new Set<Id>();
        
        if(newAdjustCancelList!= null && newAdjustCancelList.size()>0){
            for(T_ADJMT_CANCEL__c adjCancel: newAdjustCancelList){
                if(oldMap.get(adjCancel.Id).CDE_STATUS__c!=adjCancel.CDE_STATUS__c && 
                   (adjCancel.CDE_STATUS__c == '3' || adjCancel.CDE_STATUS__c == '4' || adjCancel.CDE_STATUS__c == '5')){
                       adjId.add(adjCancel.Id);
                   }
            }   
        }
        for(T_ADJMT_CANCEL__c adj: [select id ,(select id from Adjustment_Cancellation_Notes__r) from T_ADJMT_CANCEL__c where id IN:adjId ]){
            if(adj.Adjustment_Cancellation_Notes__r==null || adj.Adjustment_Cancellation_Notes__r.isEmpty()){
                newMap.get(adj.Id).addError('Please add Cancellation Notes before changing the Status'); 
            }
        }
    }     
}