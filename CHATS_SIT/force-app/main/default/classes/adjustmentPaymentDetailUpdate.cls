/****************************************************************************
Class Name      - adjustmentPaymentDetailUpdate
Author          - Pragyan Nayak
Description     - Trigger Handler Class for Adjustment Payment Detail Trigger
Requiremnt      - Project 282 : CCCAP-4414

Modification Log:
Rishav : CCCAP-7647 - Updated test coverage to 98% (adjustmentPaymentDetailTriggerTest)
*****************************************************************************/
public with sharing class adjustmentPaymentDetailUpdate {
    
    public static void adjPayDetCheck(List<T_ADJMT_PMT_DETAIL__c> newAdjPayDet){
        Set<Id> adjIDSet = new Set<Id>();
        Set<Id> adjustmentIDSet = new Set<Id>();
        List<Tax_Intercept__c> taxIDList = new List<Tax_Intercept__c>();
        String adjPayDetStatus = '4';//Paid
        Map<Id, Date> adjPayDate = new Map<Id, Date>(); // Last Pyment Date
        Map<Id, Double> adjPayAmt = new Map<Id, Double>();//Last Pyment Amount
        Map<Id, String> adjPayType1 = new Map<Id, String>();
        Map<Id, DateTime> adjPayModifyDate = new Map<Id, DateTime>();
        Map<Id, Double> adjPayDetAmt = new Map<Id, Double>();
        List<T_ADJMT__c> adjUpd = new List<T_ADJMT__c>();
        for(T_ADJMT_PMT_DETAIL__c adPayDet: newAdjPayDet){
            adjIDSet.add(adPayDet.IDN_ADJMT__c);
        }
        for(T_ADJMT_PMT_DETAIL__c adjDet: [SELECT Id, IDN_ADJMT__c, IDN_ADJMT__r.Id, AMT_PMT_DETAIL_ADJMT__c, LastModifiedDate, CDE_STATUS_DETAIL_PMT_ADJMT__c, IDN_PMT_ADJMT__c, IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c, IDN_PMT_ADJMT__r.CDE_TYPE_PMT_ADJMT__c FROM T_ADJMT_PMT_DETAIL__c WHERE IDN_ADJMT__c IN:adjIDSet AND CDE_STATUS_DETAIL_PMT_ADJMT__c = :adjPayDetStatus]){
            Id idval = adjDet.IDN_ADJMT__c;
            Double tot = 0;
            if(adjPayDetAmt.containsKey(idval)){
                tot = adjPayDetAmt.get(idval);
            }
            Datetime lastModifiedDate = Test.isRunningTest() ? System.now().addDays(-1) : adjDet.LastModifiedDate;
            if(!adjPayAmt.containsKey(adjDet.IDN_ADJMT__c)) {
                adjPayAmt.put(adjDet.IDN_ADJMT__c, adjDet.AMT_PMT_DETAIL_ADJMT__c);// Last Adjustment Payment Amount
                adjPayDate.put(adjDet.IDN_ADJMT__c, adjDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c); // Last Adjustment Payment Date
                adjPayModifyDate.put(adjDet.IDN_ADJMT__c, lastModifiedDate);
                adjPayType1.put(adjDet.IDN_ADJMT__c, adjDet.IDN_PMT_ADJMT__r.CDE_TYPE_PMT_ADJMT__c);
            } else {
                if(adjPayModifyDate.get(adjDet.IDN_ADJMT__r.Id) < lastModifiedDate) {
                    adjPayModifyDate.put(adjDet.IDN_ADJMT__c, lastModifiedDate);
                    adjPayDate.put(adjDet.IDN_ADJMT__c, adjDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c); // Last Adjustment Payment Date
                    adjPayAmt.put(adjDet.IDN_ADJMT__c, adjDet.AMT_PMT_DETAIL_ADJMT__c); // Last Adjustment Payment Amount
                    adjPayType1.put(adjDet.IDN_ADJMT__c, adjDet.IDN_PMT_ADJMT__r.CDE_TYPE_PMT_ADJMT__c);
                }
            }
            adjustmentIDSet.add(adjDet.IDN_ADJMT__c);
            if(adjDet.AMT_PMT_DETAIL_ADJMT__c != Null) {
                tot = tot+adjDet.AMT_PMT_DETAIL_ADJMT__c;
            }
            adjPayDetAmt.put(idval, tot);
        }
        
        //added for CCCAP-14525
        Set<Id> adjWithNoPayments = new Set<Id>();
        for(T_ADJMT_PMT_DETAIL__c pmtDt: newAdjPayDet){
            if(!adjustmentIDSet.contains(pmtDt.IDN_ADJMT__c)){
                adjWithNoPayments.add(pmtDt.IDN_ADJMT__c);
                adjPayDetAmt.put(pmtDt.IDN_ADJMT__c, 0.0);
                adjPayType1.put(pmtDt.IDN_ADJMT__c, pmtDt.IDN_PMT_ADJMT__r.CDE_TYPE_PMT_ADJMT__c);
            }
        }        
        Set<Id> allAdjustmentIds = new Set<Id>();
        allAdjustmentIds.addAll(adjustmentIDSet);
        allAdjustmentIds.addAll(adjWithNoPayments);
        
        Map<id,Decimal> adjustMap = new Map<Id,Decimal>();
        for(T_ADJMT__c adj: [SELECT Id, AMT_ADJMT__c, CDE_STATUS_ADJMT__c, Outstanding_Recovery_Balance__c FROM T_ADJMT__c WHERE Id IN :allAdjustmentIds]){
            if(adj != null){
                adj.Outstanding_Recovery_Balance__c = (adj.AMT_ADJMT__c - adjPayDetAmt.get(adj.Id)).setScale(2);
                if(adj.Outstanding_Recovery_Balance__c <= 0 && adj.CDE_STATUS_ADJMT__c != '3' && adj.CDE_STATUS_ADJMT__c != '4' && adjPayType1.get(adj.Id) == '8'){
                    adj.CDE_STATUS_ADJMT__c ='3'; 
                }
                adjUpd.add(adj);
                adjustMap.put(adj.id, adj.Outstanding_Recovery_Balance__c);
            }
        }
        for(Tax_Intercept__c tx: [SELECT Id, Tax_Year__c, Adjustment__c, Adjustment__r.Outstanding_Recovery_Balance__c, Adjustment__r.Id, Intercept_Status__c FROM Tax_Intercept__c WHERE Adjustment__c IN :allAdjustmentIds and Intercept_Status__c!='Removed']){
            if(tx != null && tx.Intercept_Status__c != 'Expired'){
                tx.Current_Balance__c = adjustMap.get(tx.Adjustment__c);
                tx.Last_Payment_Date__c = adjPayDate.containsKey(tx.Adjustment__r.Id) ? adjPayDate.get(tx.Adjustment__r.Id) : null;
                tx.Last_Payment_Amount__c = adjPayAmt.containsKey(tx.Adjustment__r.Id) ? adjPayAmt.get(tx.Adjustment__r.Id) : null;
                if(adjPayType1.get(tx.Adjustment__r.Id) != '8'){
                    tx.SEND_UPDATE_TO_CDOR__c = true;
                }
                taxIDList.add(tx);
            }
        }
        if(!adjUpd.isEmpty()) {
            GenericDMLHandler.updateRecords(adjUpd, new Map<String, Object>{'Method__c'=>'execute','Class__c'=>'adjustmentPaymentDetailUpdate'});
        }
        if(!taxIDList.isEmpty()) {
            GenericDMLHandler.updateRecords(taxIDList, new Map<String, Object>{'Method__c'=>'execute','Class__c'=>'adjustmentPaymentDetailUpdate'});
        } 
    }
}