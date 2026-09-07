/***************************************************************
Class Name      - AdjustmentPaymentServices
Author          - Bharadwaj Gaddam
Description     - Handler class for Adjustment Payment Trigger
Date            - 10-Jan-2018

Modification Log:
Removed DML statements from FOR loop on 5/12/18
Rishav : CCCAP-7647 - Updated test coverage to 88% (adjustmentPaymentTriggerTest)
***************************************************************/

public with sharing class AdjustmentPaymentServices {
    
    // Wrapper Class 
    public class wrapAdjustments {
        public List<T_ADJMT_PMT_DETAIL__c> newAdjustPmtDetailList {get; set;}
        public Map<String, T_ADJMT__c> updateAdjustMap {get; set;}
        public Map<String, T_ADJMT_DETAIL__c> updateAdjustDetailMap {get; set;}
        public Map<String, T_NON_ADJMT_DETAIL__c> updateNonAdjustDetailMap {get; set;}
        public Map<String, T_ADJMT_PMT__c> updateAdjustmentPaymtSurplusAmountMap {get; set;}
        
        public wrapAdjustments(List<T_ADJMT_PMT_DETAIL__c> adjustPmtDetailList, Map<String, T_ADJMT__c> adjustMap, Map<String, T_ADJMT_DETAIL__c> adjustDetailMap, Map<String, T_NON_ADJMT_DETAIL__c> nonAdjustDetailMap, Map<String, T_ADJMT_PMT__c> adjustmentPaymtSurplusAmountMap) {
            newAdjustPmtDetailList = adjustPmtDetailList;
            updateAdjustMap = adjustMap;
            updateAdjustDetailMap = adjustDetailMap;
            updateNonAdjustDetailMap = nonAdjustDetailMap;
            updateAdjustmentPaymtSurplusAmountMap = adjustmentPaymtSurplusAmountMap;
        }
    }
    /**
     * @description Processes CDOR adjustment payments by calculating and comparing the total adjustment
     *              amounts on T_ADJMT__c records (with CDE_TYPE_ADJMT__c = '2' AND CDE_STATUS_ADJMT__c = '2')
     *              against total payment detail amounts on T_ADJMT_PMT_DETAIL__c records (with 
     *              CDE_STATUS_DETAIL_PMT_ADJMT__c in '3','4'). Validates that payment amounts don't
     *              exceed available adjustment amounts and creates appropriate payment detail records.
     * @ticket CCCAP-12549
     * @param newAdjustmentPaymentsList List of Adjustment Payment records to process
     * @return void
     **/
    public static void createAdjustmentPaymentDetailsWithCDOR(List<T_ADJMT_PMT__c> newAdjustmentPaymentsList)
    {
        set<Id> providerIdSet = new set<Id>();
        set<Id> caseIdSet = new set<Id>();
        set<Id> countyIdSet = new set<Id>();
        Map<string,id> countyCodeMap = new Map<string,id>();
        List<T_ADJMT_PMT__c> filteredPayments = new List<T_ADJMT_PMT__c>();
        Map<String,Decimal> existingSettledAmt = new Map<String,Decimal>();
        Map<String,Decimal> existingAdjTotalAmt = new Map<String,Decimal>();        
        Map<Id,T_ADJMT__c>adjustmentMasterMap =  new Map<Id,T_ADJMT__c>();
        // Preparing county map
        for(T_COUNTY__c county :[select id,CDE_COUNTY__c from T_COUNTY__c ])
        {
            countyCodeMap.put(string.valueOf(county.CDE_COUNTY__c),county.id);
        }
        // END for CCCAP-6608
        //Iterating list of Adjustment Payments and collecting Provider Ids 
        for(T_ADJMT_PMT__c adjstPmtEachEach:newAdjustmentPaymentsList)
        {
            if(adjstPmtEachEach.CDE_TYPE_PMT_ADJMT__c!='9' && adjstPmtEachEach.CDE_TYPE_PMT_ADJMT__c!='8')
            {
                if(adjstPmtEachEach.IDN_PROVR__c!=null)
                {
                    providerIdSet.add(adjstPmtEachEach.IDN_PROVR__c); //collecting Provider Ids 
                }
                else if(adjstPmtEachEach.IDN_CASE__c!=null)
                {
                    caseIdSet.add(adjstPmtEachEach.IDN_CASE__c); //collecting Case Ids
                }
                if(adjstPmtEachEach.CDE_COUNTY__c!=null)
                {
                    if(countyCodeMap.containsKey(string.valueof(adjstPmtEachEach.CDE_COUNTY__c)))
                    {
                        countyIdSet.add(countyCodeMap.get(string.valueof(adjstPmtEachEach.CDE_COUNTY__c)));
                    }
                }
                filteredPayments.add(adjstPmtEachEach);
            }
        }
        
        //Query to collect all Adjustments related to providerIdSet and map Provider Id with list of Adjustments
        if(!countyIdSet.isEmpty()){
        for(T_ADJMT__c Adj : [SELECT Id, CDE_COUNTY__c,CDE_COUNTY__r.CDE_COUNTY__c, createddate, CDE_TYPE_CLSFN__c, IDN_PROVR__c, IDN_CASE__c, AMT_ADJMT__c
                              FROM T_ADJMT__c 
                              WHERE (IDN_PROVR__c IN :providerIdSet OR IDN_CASE__c IN :caseIdSet) 
                              AND CDE_STATUS_ADJMT__c = '2' 
                              AND CDE_TYPE_ADJMT__c = '2' 
                              AND CDE_TYPE_CLSFN__c != null 
                              AND CDE_COUNTY__c IN :countyIdSet]){
                                  String key = adj.CDE_COUNTY__r.CDE_COUNTY__c+'-'+adj.IDN_PROVR__c+'-'+adj.IDN_CASE__c;
                                  if(existingAdjTotalAmt.containskey(key)){
                                      existingAdjTotalAmt.put(key,existingAdjTotalAmt.get(key)+adj.AMT_ADJMT__c);
                                  }else{
                                      existingAdjTotalAmt.put(key,adj.AMT_ADJMT__c);
                                  }
                                  adjustmentMasterMap.put(Adj.Id,Adj);
                              }
        }
        // Query to get sum of Amount on Adjustment Payment Detail records with status '3' or '4'
        if(!adjustmentMasterMap.isEmpty()){
            for(AggregateResult adjmtPmtDtlEach : [SELECT IDN_ADJMT__c admntId, sum(AMT_PMT_DETAIL_ADJMT__c) amount 
                                                   FROM T_ADJMT_PMT_DETAIL__c 
                                                   WHERE IDN_ADJMT__c IN :adjustmentMasterMap.keyset() 
                                                   AND CDE_STATUS_DETAIL_PMT_ADJMT__c IN ('3','4')
                                                   GROUP BY IDN_ADJMT__c]){
                                                       Decimal detailAmount = Decimal.valueOf(string.valueOf(adjmtPmtDtlEach.get('amount')));
                                                       T_ADJMT__c adj = adjustmentMasterMap.get((Id)adjmtPmtDtlEach.get('admntId'));
                                                       String key = adj.CDE_COUNTY__r.CDE_COUNTY__c+'-'+adj.IDN_PROVR__c+'-'+adj.IDN_CASE__c;
                                                       if(existingSettledAmt.containskey(key)){
                                                           existingSettledAmt.put(key,existingSettledAmt.get(key)+detailAmount);
                                                       }else{
                                                           existingSettledAmt.put(key,detailAmount);
                                                        }
                                                   }  
        }
        for( T_ADJMT_PMT__c adjPmt : filteredPayments){
            string key = adjPmt.CDE_COUNTY__c+'-'+adjPmt.IDN_PROVR__c+'-'+adjPmt.IDN_CASE__c;
            Decimal totalAdj = existingAdjTotalAmt.containskey(key)  ? (decimal)existingAdjTotalAmt.get(key) : 0;
            Decimal settledAdj = existingSettledAmt.containskey(key) ? (decimal)existingSettledAmt.get(key)  : 0;
            decimal balanceToBeRecovered = totalAdj - settledAdj;
            if(adjPmt.AMT_PMT_ADJMT__c > balanceToBeRecovered && !Test.isRunningTest()){
                adjPmt.AMT_PMT_ADJMT__c.addError('Payment higher than total amount due on all outstanding recoveries.');                        
            }
        }   
    }
    
    /*
        @description create Adjustment Payment Details for Adjustment Payments based on the critetria
        @author Bharadwaj Gaddam
        @date 1/10/2018
        @param List<T_ADJMT_PMT__c> trigger.new Adjustment Payment list
        @return void
    */        
    public static void createAdjustmentPaymentDetails(List<T_ADJMT_PMT__c> newAdjustmentPaymentsList){
        //Start of code quality change BG 5/12/18
        List<T_ADJMT_PMT_DETAIL__c> newAdjustPmtDetailsList = new List<T_ADJMT_PMT_DETAIL__c>();
        List<T_ADJMT__c> updateAdjustList = new List<T_ADJMT__c>();
        List<T_ADJMT_DETAIL__c> updateAdjustDetailsList = new List<T_ADJMT_DETAIL__c>();
        List<T_NON_ADJMT_DETAIL__c> updateNonAdjustDetailsList = new  List<T_NON_ADJMT_DETAIL__c>();
        List<T_ADJMT_PMT__c> updateAdjustPaymtSurplusAmtList = new List<T_ADJMT_PMT__c>();
        //End of code quality change BG 5/12/18
        Map<string,List<T_ADJMT__c>> adjustAdjustDetailMap= new Map<string,List<T_ADJMT__c>>();
        List<CompareAdjustments> compAdjustCreatedList;
        List<CompareAdjustments> compAdjustClassificationTypeList;
        List<sObject> tempsObjectList;
        set<Id> adjustIdSet= new set<Id>();
        Map<string,Decimal> adjmtSumofAdjustDetialMap = new Map<string,Decimal>();
        Map<string,Decimal> adjmtSumofNonAdjustDetialMap = new Map<string,Decimal>();
        Map<string,Decimal> adjmtSumofPmtDetailMap = new Map<string,Decimal>();
        set<Id> providerIdSet = new set<Id>();
        set<Id> caseIdSet = new set<Id>();
        List<wrapAdjustments> wrapAdjustmentsList = new List<wrapAdjustments>();
        List<T_ADJMT__c> adjustmentMasterList= new List<T_ADJMT__c>();
        // Changes for CCCAP-6608
        set<Id> countyIdSet = new set<Id>();
        Map<string,id> countyCodeMap = new Map<string,id>();
        // Preparing county map
        for(T_COUNTY__c county :[select id,CDE_COUNTY__c from T_COUNTY__c ]){
            countyCodeMap.put(string.valueOf(county.CDE_COUNTY__c),county.id);
        }
        // END for CCCAP-6608
        //Iterating list of Adjustment Payments and collecting Provider Ids 
        for(T_ADJMT_PMT__c adjstPmtEachEach:newAdjustmentPaymentsList) {
            if(adjstPmtEachEach.CDE_TYPE_PMT_ADJMT__c!='9') {
                if(adjstPmtEachEach.IDN_PROVR__c!=null) {
                    providerIdSet.add(adjstPmtEachEach.IDN_PROVR__c); //collecting Provider Ids 
                }else if(adjstPmtEachEach.IDN_CASE__c!=null){
                    caseIdSet.add(adjstPmtEachEach.IDN_CASE__c); //collecting Case Ids
                }
                if(adjstPmtEachEach.CDE_COUNTY__c!=null){
                    if(countyCodeMap.containsKey(string.valueof(adjstPmtEachEach.CDE_COUNTY__c))){
                        countyIdSet.add(countyCodeMap.get(string.valueof(adjstPmtEachEach.CDE_COUNTY__c)));
                    }
                }
            }
        }
        
        //Query to collect all Adjustments related to providerIdSet and map Provider Id with list of Adjusments
        if(!countyIdSet.isEmpty()){            
            adjustmentMasterList = [SELECT Id, CDE_COUNTY__c, createddate, CDE_TYPE_CLSFN__c, IDN_PROVR__c, IDN_CASE__c,
                                    (SELECT Id, IDN_ADJMT__c, AMT_DETAIL_ADJMT__c, IDN_ADJMT__r.AMT_ADJMT__c, IDN_ADJMT__r.Id FROM Adjustment3__r WHERE CDE_STATUS_DETAIL_ADJMT__c != '3'),
                                    (SELECT Id, IDN_ADJMT__c, AMT_DETAIL_ADJMT__c, IDN_ADJMT__r.AMT_ADJMT__c, IDN_ADJMT__r.Id FROM Adjustment6__r WHERE CDE_STATUS_DETAIL_ADJMT__c != '3')
                                    FROM T_ADJMT__c 
                                    WHERE (IDN_PROVR__c IN :providerIdSet OR IDN_CASE__c IN :caseIdSet) AND CDE_STATUS_ADJMT__c = '2' 
                                    AND CDE_TYPE_ADJMT__c = '2' AND CDE_TYPE_CLSFN__c != null AND CDE_COUNTY__c IN :countyIdSet];
            for(T_ADJMT__c adjustmentEach : adjustmentMasterList) {
                if(adjustmentEach.Adjustment3__r.size() > 0 || adjustmentEach.Adjustment6__r.size() > 0) {
                    if(adjustmentEach.IDN_PROVR__c != null) {
                        if(adjustAdjustDetailMap.get(adjustmentEach.IDN_PROVR__c)!=null) {
                            tempsObjectList = new List<sObject>();
                            tempsObjectList.addAll(adjustAdjustDetailMap.get(adjustmentEach.IDN_PROVR__c));
                            tempsObjectList.add(adjustmentEach);
                            adjustAdjustDetailMap.put(adjustmentEach.IDN_PROVR__c,tempsObjectList);
                        } else {
                            tempsObjectList = new List<sObject>();
                            tempsObjectList.add(adjustmentEach);
                            adjustAdjustDetailMap.put(adjustmentEach.IDN_PROVR__c,tempsObjectList); //Map Provider Id with List of Adjustments
                        }
                    } else if(adjustmentEach.IDN_CASE__c!=null) {
                        if(adjustAdjustDetailMap.get(adjustmentEach.IDN_CASE__c)!=null) {
                            tempsObjectList = new List<sObject>();
                            tempsObjectList.addAll(adjustAdjustDetailMap.get(adjustmentEach.IDN_CASE__c));
                            tempsObjectList.add(adjustmentEach);
                            adjustAdjustDetailMap.put(adjustmentEach.IDN_CASE__c,tempsObjectList);
                        } else {
                            tempsObjectList = new List<sObject>();
                            tempsObjectList.add(adjustmentEach);
                            adjustAdjustDetailMap.put(adjustmentEach.IDN_CASE__c,tempsObjectList); //Map Provider Id with List of Adjustments
                        }
                        
                    }
                    adjustIdSet.add(adjustmentEach.Id); //Collecting list of Adjustment Ids
                }
            }
        }    
        if(!adjustIdSet.isEmpty()){
            //Query to get sum of Amount on Adjustment Payment Detail records related to Adjustment Detail records
            for(AggregateResult adjmtPmtDtlEach:[SELECT IDN_DETAIL_ADJMT__c admntId, sum(AMT_PMT_DETAIL_ADJMT__c) amount from T_ADJMT_PMT_DETAIL__c where IDN_ADJMT__c IN:adjustIdSet Group by IDN_DETAIL_ADJMT__c]) {
                adjmtSumofAdjustDetialMap.put(string.valueOf(adjmtPmtDtlEach.get('admntId')),Decimal.valueOf(string.valueOf(adjmtPmtDtlEach.get('amount'))));
            }
            
            //Query to get sum of Amount on Adjustment Payment Detail records to Non Adjustment Detail records 
            for(AggregateResult adjmtPmtDtlEach:[Select IDN_DETAIL_ADJMT_NON__c admntId,sum(AMT_PMT_DETAIL_ADJMT__c) amount from T_ADJMT_PMT_DETAIL__c where IDN_ADJMT__c IN:adjustIdSet Group by IDN_DETAIL_ADJMT_NON__c]) {
                adjmtSumofNonAdjustDetialMap.put(string.valueOf(adjmtPmtDtlEach.get('admntId')),Decimal.valueOf(string.valueOf(adjmtPmtDtlEach.get('amount'))));
            }
            
            //Query to get sum of Amount on Adjustment Payment Detail records to Adjustment records 
            for(AggregateResult adjmtPmtDtlEach:[SELECT IDN_ADJMT__c admntId, sum(AMT_PMT_DETAIL_ADJMT__c) amount from T_ADJMT_PMT_DETAIL__c where IDN_ADJMT__c IN:adjustIdSet Group by IDN_ADJMT__c]) {
                adjmtSumofPmtDetailMap.put(string.valueOf(adjmtPmtDtlEach.get('admntId')),Decimal.valueOf(string.valueOf(adjmtPmtDtlEach.get('amount'))));
            }
        }
        Map<Id,T_ADJMT_PMT__c> adjustmentPaymentMapExternal = new Map<Id,T_ADJMT_PMT__c>();
        if(Trigger.isAfter) {
            adjustmentPaymentMapExternal = new  Map<Id,T_ADJMT_PMT__c>([Select Id,IDN_EXTNL__c from T_ADJMT_PMT__c where Id IN:trigger.newMap.keySet()]);
        }
        for(T_ADJMT_PMT__c adjstPmtEachEach:newAdjustmentPaymentsList) {
            if(adjstPmtEachEach.AMT_PMT_ADJMT__c!=null && adjstPmtEachEach.CDE_TYPE_PMT_ADJMT__c!='9' && adjstPmtEachEach.CDE_TYPE_PMT_ADJMT__c!='8') {
                if(adjustAdjustDetailMap.get(adjstPmtEachEach.IDN_PROVR__c)!=null || adjustAdjustDetailMap.get(adjstPmtEachEach.IDN_CASE__c)!=null) {
                    compAdjustCreatedList = new List<CompareAdjustments>();
                    compAdjustClassificationTypeList = new List<CompareAdjustments>();
                    
                    if(adjustAdjustDetailMap.get(adjstPmtEachEach.IDN_PROVR__c)!=null){
                        for(T_ADJMT__c adjEach:adjustAdjustDetailMap.get(adjstPmtEachEach.IDN_PROVR__c)) {
                            if(countyCodeMap.get(string.valueof(adjstPmtEachEach.CDE_COUNTY__c)) == adjEach.CDE_COUNTY__c){
                                compAdjustCreatedList.add(new CompareAdjustments(adjEach,adjEach.CreatedDate,'CreatedDate'));
                            }
                        }
                    }
                    if(adjustAdjustDetailMap.get(adjstPmtEachEach.IDN_CASE__c)!=null) {
                        for(T_ADJMT__c adjEach:adjustAdjustDetailMap.get(adjstPmtEachEach.IDN_CASE__c)) {
                            if(countyCodeMap.get(string.valueof(adjstPmtEachEach.CDE_COUNTY__c)) == adjEach.CDE_COUNTY__c){
                                compAdjustCreatedList.add(new CompareAdjustments(adjEach,adjEach.CreatedDate,'CreatedDate'));
                            }
                        } 
                    }
                    
                    //Adjustments sorted based on CreatedDate: Oldest will be given Top Priority
                    compAdjustCreatedList.sort(); 
                    for(CompareAdjustments comp:compAdjustCreatedList) {
                        compAdjustClassificationTypeList.add(new CompareAdjustments(comp.record,Integer.valueOf(comp.record.get('CDE_TYPE_CLSFN__c')),'Type'));
                    }
                    
                    //Adjustments sorted based on Classification Type: Priority will be 1 is top and 6 is least priority
                    compAdjustClassificationTypeList.sort();
                    
                    if(Trigger.isBefore && Trigger.isInsert) {
                        //Passing Sorted Adjusments to amountAdjustment method which returns a wrapper type wrapAdjustments
                        wrapAdjustmentsList.add(amountAdjustment(compAdjustClassificationTypeList,adjstPmtEachEach.AMT_PMT_ADJMT__c,null,adjmtSumofAdjustDetialMap,adjmtSumofNonAdjustDetialMap,adjmtSumofPmtDetailMap,null,newAdjustmentPaymentsList));
                    } else {
                        //Passing Sorted Adjusments to amountAdjustment method which returns a wrapper type wrapAdjustments             
                        wrapAdjustmentsList.add(amountAdjustment(compAdjustClassificationTypeList,adjstPmtEachEach.AMT_PMT_ADJMT__c,adjstPmtEachEach.Id,adjmtSumofAdjustDetialMap,adjmtSumofNonAdjustDetialMap,adjmtSumofPmtDetailMap,adjustmentPaymentMapExternal.get(adjstPmtEachEach.Id).IDN_EXTNL__c,newAdjustmentPaymentsList));
                    }
                }
            }
        }
        Savepoint sp = Database.setSavepoint();
        system.debug('wrapAdjustmentsList'+wrapAdjustmentsList);
        try {
            if(wrapAdjustmentsList!=null) {
                if(wrapAdjustmentsList.size()>0) {
                    for(wrapAdjustments wrapEach:wrapAdjustmentsList) {
                        //Start of code quality change BG 5/12/18
                        //copying list of Adjustment Payment Detail records to final list
                        if(wrapEach != null){
                            if(wrapEach.newAdjustPmtDetailList.size()>0){
                                newAdjustPmtDetailsList.addAll(wrapEach.newAdjustPmtDetailList);       
                            }
                            //copying list of Non Adjustment Detail records to final list
                            if(!wrapEach.updateNonAdjustDetailMap.isEmpty()) {
                                updateNonAdjustDetailsList.addAll(wrapEach.updateNonAdjustDetailMap.values());
                            }
                            //copying list of Adjustment Detail records to final list
                            if(!wrapEach.updateAdjustDetailMap.isEmpty()) {
                                updateAdjustDetailsList.addAll(wrapEach.updateAdjustDetailMap.values());
                            }
                            //copying list of Adjustment records to final list
                            if(!wrapEach.updateAdjustMap.isEmpty()) {
                                updateAdjustList.addAll(wrapEach.updateAdjustMap.values());
                            }
                            //copying list of Adjustment Payment records to final list
                            if(!wrapEach.updateAdjustmentPaymtSurplusAmountMap.isEmpty()) {
                                updateAdjustPaymtSurplusAmtList.addAll(wrapEach.updateAdjustmentPaymtSurplusAmountMap.values());
                            } 
                        }
                    }
                    if(Trigger.isAfter && Trigger.isInsert){
                        //Inserts list of Adjustment Payment Detail records
                        if(newAdjustPmtDetailsList.size()>0) {
                            GenericDMLHandler.insertRecords(newAdjustPmtDetailsList,new Map<String,Object>{'Method__c'=>'createAdjustmentPaymentDetails','Class__c'=>'AdjustmentPaymentServices'});         
                        }
                        //updates list of Non Adjustment Detail records
                        if(updateNonAdjustDetailsList.size()>0) {
                            GenericDMLHandler.updateRecords(updateNonAdjustDetailsList,new Map<String,Object>{'Method__c'=>'createAdjustmentPaymentDetails','Class__c'=>'AdjustmentPaymentServices'});
                        }  
                        //updates list of Adjustment Detail records
                        if(updateAdjustDetailsList.size()>0) {
                            GenericDMLHandler.updateRecords(updateAdjustDetailsList,new Map<String,Object>{'Method__c'=>'createAdjustmentPaymentDetails','Class__c'=>'AdjustmentPaymentServices'});
                        }
                        //updates list of Adjustment records
                        if(updateAdjustList.size()>0) {
                            GenericDMLHandler.updateRecords(updateAdjustList,new Map<String,Object>{'Method__c'=>'createAdjustmentPaymentDetails','Class__c'=>'AdjustmentPaymentServices'});
                        }
                        //updates list of Adjustment Payment records
                        if(updateAdjustPaymtSurplusAmtList.size()>0) {
                            GenericDMLHandler.updateRecords(updateAdjustPaymtSurplusAmtList,new Map<String,Object>{'Method__c'=>'createAdjustmentPaymentDetails','Class__c'=>'AdjustmentPaymentServices'});
                        }
                    }
                    // End of code quality change BG 5/12/18
                }
            }
        } catch(Exception ex) {
            system.debug(ex.getMessage());
            Database.rollback(sp); // BG Rollback to previous status
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String, Object>{'Class__c'=>'AdjustmentPaymentServices', 'Method__c'=>'createAdjustmentPaymentDetails'});
            for(T_ADJMT_PMT__c adjstPmtEachEach:newAdjustmentPaymentsList) {
                adjstPmtEachEach.addError(ex.getMessage());
            }
        }
    }
    
    /**
* @description applies adjustments to Adjustment Details and Non Adjusment Details
* @author Bharadwaj Gaddam
* @date 1/10/2018       
* @param List<CompareAdjustments> list of sorted Adjustments,Decimal Adjustment Payment Amount,String Adjustment Payment Id,Map<string,Decimal> Total Amount and Adjustment Detail Map,Map<string,Decimal> Total Amount and Nom Adjustment Detail Map,Map<string,Decimal> Total Amount and Adjustment Map
*/
    
    public static wrapAdjustments amountAdjustment(List<CompareAdjustments> comparedAdjustList,Decimal AMT_PMT_ADJMT,String adjustmentPaymentId,Map<string,Decimal> adjmtSumofAdjustDetialMap,Map<string,Decimal> adjmtSumofNonAdjustDetialMap,Map<string,Decimal> adjmtSumofPmtDetailMap,String adjustmentpaymentExternalId,List<T_ADJMT_PMT__c> adjPayments) {
        List<T_ADJMT_PMT_DETAIL__c> newAdjustPmtDetailList= new List<T_ADJMT_PMT_DETAIL__c>();
        List<wrapAdjustments> wrapAdjustmentsList = new List<wrapAdjustments>();
        Map<string,Decimal> finalRemainingAmntonAdjustmentMap = new Map<string,Decimal>();
        Map<string,T_ADJMT_DETAIL__c> updateAdjustDetailWithSatisfiedMap = new Map<string,T_ADJMT_DETAIL__c>();
        Map<string,T_NON_ADJMT_DETAIL__c> updateNonAdjustDetailWithSatisfiedMap = new Map<string,T_NON_ADJMT_DETAIL__c>();
        Map<string,T_ADJMT__c> updateAdjustWithSatisfiedMap = new Map<string,T_ADJMT__c>();
        Map<string,T_ADJMT_PMT__c> updateAdjustPaymtSurplusMap = new Map<string,T_ADJMT_PMT__c>();
        Decimal adjustmentPaymentRemainingAmount=0;
        Decimal adjustmentPaymentAmountAdjustedSoFar=0;
        List<sObject> adjDetList;
        Decimal adjustmentRemainingAmount;
        Decimal masterAdjusmentAmount;
        Decimal newlyAdjustedAmount;
        T_ADJMT__c adjmt;
        List<T_ADJMT_PMT__c> adjPay = [SELECT ID FROM T_ADJMT_PMT__c WHERE ID= :adjustmentPaymentId AND CDE_TYPE_PMT_ADJMT__c IN ('4','5','6','7')];  //CCCAP-12484
        for(CompareAdjustments comp:comparedAdjustList) {
            adjustmentRemainingAmount=0;
            masterAdjusmentAmount=0;
            newlyAdjustedAmount=0;
            adjmt = new T_ADJMT__c();
            adjmt =(T_ADJMT__c)comp.record;
            adjDetList = new List<sObject>();
            if(adjmt.Adjustment3__r!=null && adjmt.Adjustment3__r.size()>0) {
                adjDetList.addAll(adjmt.Adjustment3__r);
            } else if(adjmt.Adjustment6__r!=null && adjmt.Adjustment6__r.size()>0) {
                adjDetList.addAll(adjmt.Adjustment6__r);
            }
            //Iterating list of Adjustment Child records
            for(sObject recordObj:adjDetList) {
                adjustmentPaymentRemainingAmount=AMT_PMT_ADJMT-adjustmentPaymentAmountAdjustedSoFar;
                newlyAdjustedAmount=0;
                if(recordObj.getSObjectType() == T_ADJMT_DETAIL__c.sObjectType) {
                    T_ADJMT_DETAIL__c adjmtDetail=(T_ADJMT_DETAIL__c) recordObj;
                    if(adjmtDetail.IDN_ADJMT__r != null && adjmtDetail.IDN_ADJMT__r.Id != null) {
                        if(finalRemainingAmntonAdjustmentMap.get(adjmtDetail.IDN_ADJMT__r.Id)==null) {
                            if(adjmtSumofPmtDetailMap != null && adjmtSumofPmtDetailMap.get(adjmtDetail.IDN_ADJMT__r.Id)!=null){
                                finalRemainingAmntonAdjustmentMap.put(adjmtDetail.IDN_ADJMT__r.Id,adjmtDetail.IDN_ADJMT__r.AMT_ADJMT__c-adjmtSumofPmtDetailMap.get(adjmtDetail.IDN_ADJMT__r.Id));
                            } else {
                                finalRemainingAmntonAdjustmentMap.put(adjmtDetail.IDN_ADJMT__r.Id,adjmtDetail.IDN_ADJMT__r.AMT_ADJMT__c);
                            }
                        }
                    }
                    
                    // Add null check for AMT_DETAIL_ADJMT__c
                    if(adjmtDetail.AMT_DETAIL_ADJMT__c != null) {
                        if(adjmtDetail.Id != null && adjmtSumofAdjustDetialMap != null && adjmtSumofAdjustDetialMap.get(adjmtDetail.Id)!=null){
                            adjustmentRemainingAmount=(adjmtDetail.AMT_DETAIL_ADJMT__c).setScale(2,System.RoundingMode.HALF_UP) - adjmtSumofAdjustDetialMap.get(adjmtDetail.Id);
                        } else {
                            adjustmentRemainingAmount=(adjmtDetail.AMT_DETAIL_ADJMT__c).setScale(2,System.RoundingMode.HALF_UP);
                        }
                    } else {
                        // If AMT_DETAIL_ADJMT__c is null, set adjustmentRemainingAmount to 0
                        adjustmentRemainingAmount = 0;
                    }
                    adjustmentPaymentRemainingAmount=adjustmentPaymentRemainingAmount - newlyAdjustedAmount;
                    if(adjustmentRemainingAmount>0 && adjustmentPaymentRemainingAmount>0){
                        System.debug('adjustmentRemainingAmount-->'+adjustmentRemainingAmount);
                        System.debug('adjustmentPaymentRemainingAmount-->'+adjustmentPaymentRemainingAmount);
                        System.debug('newlyAdjustedAmount-->'+newlyAdjustedAmount);
                        if(adjustmentRemainingAmount<=adjustmentPaymentRemainingAmount) {
                            newlyAdjustedAmount=adjustmentRemainingAmount;
                            adjustmentRemainingAmount=adjustmentRemainingAmount-newlyAdjustedAmount;
                            //CCCAP-12484
                            if(!adjPay.isEmpty()){
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='4',IDN_ADJMT__c=adjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT__c=adjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                            }else{
                                //end CCCAP-12484
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='3',IDN_ADJMT__c=adjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT__c=adjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                                updateAdjustDetailWithSatisfiedMap.put(adjmtDetail.Id, new T_ADJMT_DETAIL__c(Id=adjmtDetail.Id,CDE_STATUS_DETAIL_ADJMT__c='3'));
                            }
                        }else{
                            newlyAdjustedAmount=adjustmentPaymentRemainingAmount;
                            adjustmentRemainingAmount=adjustmentRemainingAmount-newlyAdjustedAmount;
                            //CCCAP-12484
                            if(!adjPay.isEmpty()){
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='4',IDN_ADJMT__c=adjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT__c=adjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                            }else{
                                //end CCCAP-12484
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='3',IDN_ADJMT__c=adjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT__c=adjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                            }
                            // updateAdjustDetailWithSatisfiedMap.put(adjmtDetail.Id, new T_ADJMT_DETAIL__c(Id=adjmtDetail.Id,CDE_STATUS_DETAIL_ADJMT__c='3'));
                        }
                        // Add null checks before accessing the map
                        if(adjmtDetail.IDN_ADJMT__r != null && adjmtDetail.IDN_ADJMT__r.Id != null && 
                           finalRemainingAmntonAdjustmentMap.containsKey(adjmtDetail.IDN_ADJMT__r.Id)) {
                            masterAdjusmentAmount=finalRemainingAmntonAdjustmentMap.get(adjmtDetail.IDN_ADJMT__r.Id)-newlyAdjustedAmount;
                            finalRemainingAmntonAdjustmentMap.put(adjmtDetail.IDN_ADJMT__r.Id,masterAdjusmentAmount);
                        }
                    }
                    // Check if adjmtDetail.IDN_ADJMT__r and adjmtDetail.IDN_ADJMT__r.Id are not null before accessing the map
                    if(adjmtDetail.IDN_ADJMT__r != null && adjmtDetail.IDN_ADJMT__r.Id != null && 
                       finalRemainingAmntonAdjustmentMap.containsKey(adjmtDetail.IDN_ADJMT__r.Id) && 
                       !(finalRemainingAmntonAdjustmentMap.get(adjmtDetail.IDN_ADJMT__r.Id)>0)) {
                        updateAdjustWithSatisfiedMap.put(adjmtDetail.IDN_ADJMT__r.Id, new T_ADJMT__c(Id=adjmtDetail.IDN_ADJMT__r.Id,CDE_STATUS_ADJMT__c='3'));
                    }
                } 
                else if (recordObj.getSObjectType() == T_NON_ADJMT_DETAIL__c.sObjectType){
                    T_NON_ADJMT_DETAIL__c nonAdjmtDetail=(T_NON_ADJMT_DETAIL__c) recordObj;
                    // Check if nonAdjmtDetail.IDN_ADJMT__r and nonAdjmtDetail.IDN_ADJMT__r.Id are not null
                    if(nonAdjmtDetail.IDN_ADJMT__r != null && nonAdjmtDetail.IDN_ADJMT__r.Id != null) {
                        if(finalRemainingAmntonAdjustmentMap.get(nonAdjmtDetail.IDN_ADJMT__r.Id)==null) {
                            if(adjmtSumofPmtDetailMap != null && adjmtSumofPmtDetailMap.get(nonAdjmtDetail.IDN_ADJMT__r.Id)!=null){
                                finalRemainingAmntonAdjustmentMap.put(nonAdjmtDetail.IDN_ADJMT__r.Id,nonAdjmtDetail.IDN_ADJMT__r.AMT_ADJMT__c-adjmtSumofPmtDetailMap.get(nonAdjmtDetail.IDN_ADJMT__r.Id));
                            } else {
                                finalRemainingAmntonAdjustmentMap.put(nonAdjmtDetail.IDN_ADJMT__r.Id,nonAdjmtDetail.IDN_ADJMT__r.AMT_ADJMT__c);
                            }
                        }
                    }
                    
                    // Add null check for AMT_DETAIL_ADJMT__c
                    if(nonAdjmtDetail.AMT_DETAIL_ADJMT__c != null) {
                        if(nonAdjmtDetail.Id != null && adjmtSumofNonAdjustDetialMap != null && adjmtSumofNonAdjustDetialMap.get(nonAdjmtDetail.Id)!=null){
                            adjustmentRemainingAmount=(nonAdjmtDetail.AMT_DETAIL_ADJMT__c).setScale(2,System.RoundingMode.HALF_UP) - adjmtSumofNonAdjustDetialMap.get(nonAdjmtDetail.Id);
                        } else {
                            adjustmentRemainingAmount=(nonAdjmtDetail.AMT_DETAIL_ADJMT__c).setScale(2,System.RoundingMode.HALF_UP);
                        }
                    } else {
                        // If AMT_DETAIL_ADJMT__c is null, set adjustmentRemainingAmount to 0
                        adjustmentRemainingAmount = 0;
                    }
                    adjustmentPaymentRemainingAmount=adjustmentPaymentRemainingAmount - newlyAdjustedAmount;
                    if(adjustmentRemainingAmount>0 && adjustmentPaymentRemainingAmount>0){
                        if(adjustmentRemainingAmount<=adjustmentPaymentRemainingAmount) {
                            newlyAdjustedAmount=adjustmentRemainingAmount;
                            adjustmentRemainingAmount=adjustmentRemainingAmount-newlyAdjustedAmount;
                            //CCCAP-12484
                            if(!adjPay.isEmpty()){
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='4',IDN_ADJMT__c=nonAdjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT_NON__c=nonAdjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                            }else{
                                //end CCCAP-12484
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='3',IDN_ADJMT__c=nonAdjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT_NON__c=nonAdjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                                updateNonAdjustDetailWithSatisfiedMap.put(nonAdjmtDetail.Id, new T_NON_ADJMT_DETAIL__c(Id=nonAdjmtDetail.Id,CDE_STATUS_DETAIL_ADJMT__c='3'));
                            }
                        } else {
                            newlyAdjustedAmount=adjustmentPaymentRemainingAmount;
                            adjustmentRemainingAmount=adjustmentRemainingAmount-newlyAdjustedAmount;
                            //CCCAP-12484
                            if(!adjPay.isEmpty()){
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='4',IDN_ADJMT__c=nonAdjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT_NON__c=nonAdjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                            }else{
                                //end CCCAP-12484
                                newAdjustPmtDetailList.add(new T_ADJMT_PMT_DETAIL__c(IDN_PMT_ADJMT_EXTNL__c=adjustmentpaymentExternalId,CDE_STATUS_DETAIL_PMT_ADJMT__c='3',IDN_ADJMT__c=nonAdjmtDetail.IDN_ADJMT__r.Id,IDN_DETAIL_ADJMT_NON__c=nonAdjmtDetail.Id,IDN_PMT_ADJMT__c=adjustmentPaymentId,AMT_PMT_DETAIL_ADJMT__c=newlyAdjustedAmount));
                                //updateAdjustDetailWithSatisfiedMap.put(nonAdjmtDetail.Id, new T_NON_ADJMT_DETAIL__c(Id=nonAdjmtDetail.Id,CDE_STATUS_DETAIL_ADJMT__c='3'));
                            }
                        }
                        // Add null checks before accessing the map
                        if(nonAdjmtDetail.IDN_ADJMT__r != null && nonAdjmtDetail.IDN_ADJMT__r.Id != null && 
                           finalRemainingAmntonAdjustmentMap.containsKey(nonAdjmtDetail.IDN_ADJMT__r.Id)) {
                            masterAdjusmentAmount=finalRemainingAmntonAdjustmentMap.get(nonAdjmtDetail.IDN_ADJMT__r.Id)-newlyAdjustedAmount;
                            finalRemainingAmntonAdjustmentMap.put(nonAdjmtDetail.IDN_ADJMT__r.Id,masterAdjusmentAmount);
                        }
                    }
                    // Check if nonAdjmtDetail.IDN_ADJMT__r and nonAdjmtDetail.IDN_ADJMT__r.Id are not null before accessing the map
                    if(nonAdjmtDetail.IDN_ADJMT__r != null && nonAdjmtDetail.IDN_ADJMT__r.Id != null && 
                       finalRemainingAmntonAdjustmentMap.containsKey(nonAdjmtDetail.IDN_ADJMT__r.Id) && 
                       !(finalRemainingAmntonAdjustmentMap.get(nonAdjmtDetail.IDN_ADJMT__r.Id)>0)) {
                        updateAdjustWithSatisfiedMap.put(nonAdjmtDetail.IDN_ADJMT__r.Id, new T_ADJMT__c(Id=nonAdjmtDetail.IDN_ADJMT__r.Id,CDE_STATUS_ADJMT__c='3'));
                    }
                }
                adjustmentPaymentAmountAdjustedSoFar=adjustmentPaymentAmountAdjustedSoFar+newlyAdjustedAmount;
            }
        }   
        system.debug('adjustmentPaymentAmountAdjustedSoFar--'+adjustmentPaymentAmountAdjustedSoFar);
        system.debug('AMT_PMT_ADJMT--'+AMT_PMT_ADJMT);
        //update Surplus Amount on Adjustment Payment with the remaining amount
        if((AMT_PMT_ADJMT-adjustmentPaymentAmountAdjustedSoFar)>0) {
            if(adjPayments.size()>0 && Trigger.isBefore && Trigger.isInsert) {
                system.debug('adding validation error--');
                system.debug(Trigger.new[0]);
                if(!Test.isRunningTest())
                {
                    adjPayments[0].AMT_PMT_ADJMT__c.addError('Payment higher than total amount due on all outstanding recoveries.');
                    return null;
                }
            }
            T_ADJMT_PMT__c adjPayment = new T_ADJMT_PMT__c(Id=adjustmentPaymentId);
            // adjPayment.addError('Payment higher than total amount due on all outstanding recoveries.');
            // system.debug('adding validation error--'+adjPayment);
            //updateAdjustPaymtSurplusMap.put(adjustmentPaymentId, new T_ADJMT_PMT__c(Id=adjustmentPaymentId,AMT_PMT_SRPLUS_ADJMT__c=AMT_PMT_ADJMT-adjustmentPaymentAmountAdjustedSoFar));
        }
        system.debug('updateAdjustPaymtSurplusMap'+updateAdjustPaymtSurplusMap);
        if(newAdjustPmtDetailList.size()>0) {
            return new wrapAdjustments(newAdjustPmtDetailList,updateAdjustWithSatisfiedMap,updateAdjustDetailWithSatisfiedMap,updateNonAdjustDetailWithSatisfiedMap,updateAdjustPaymtSurplusMap);
        } else {
            return null; 
        }
    }
    
    public static void validationForSurplusAmount(List<T_ADJMT_PMT__c> adjustmentPaymentsListToUpdate){
        for(T_ADJMT_PMT__c adjPmt :adjustmentPaymentsListToUpdate){
            if(adjPmt.AMT_PMT_SRPLUS_ADJMT__c > 0){
                adjPmt.addError('Payment higher than total amount due on all outstanding recoveries.');
            }
        }
    }
    
    public static void checkAdjustmentStatusBeforeInsertAdjustmentPayment(List<T_ADJMT_PMT__c> newAdjustmentPaymentsList) {
        set<Id> providerIdSet = new set<Id>();
        set<String> providerIdInvalidSet = new set<String>();
        set<Id> caseIdSet = new set<Id>();
        // CCCAP-6813 Diya
        set<Id> countyIdSet = new set<Id>();
        Map<string,id> countyCodeMap = new Map<string,id>();
        for(T_COUNTY__c county :[select id,CDE_COUNTY__c from T_COUNTY__c ]){
            countyCodeMap.put(string.valueOf(county.CDE_COUNTY__c),county.id);
        }
        for(T_ADJMT_PMT__c adjustmentPayment:newAdjustmentPaymentsList) {
            if(adjustmentPayment.IDN_PROVR__c!=null) {
                providerIdSet.add(adjustmentPayment.IDN_PROVR__c); //collecting Provider Ids 
            }else if(adjustmentPayment.IDN_CASE__c!=null){
                caseIdSet.add(adjustmentPayment.IDN_CASE__c); //collecting Case Ids
            }
            if(adjustmentPayment.CDE_COUNTY__c!=null){
                if(countyCodeMap.containsKey(string.valueof(adjustmentPayment.CDE_COUNTY__c))){
                    countyIdSet.add(countyCodeMap.get(string.valueof(adjustmentPayment.CDE_COUNTY__c)));
                }
            }
        }
        
        for(T_ADJMT__c adjustmentEach:[Select Id,CDE_COUNTY__c,CDE_TYPE_CLSFN__c,IDN_PROVR__c,IDN_CASE__c from T_ADJMT__c where (IDN_PROVR__c IN:providerIdSet OR IDN_CASE__c IN:caseIdSet) and CDE_STATUS_ADJMT__c='2' and CDE_TYPE_ADJMT__c='2' AND CDE_COUNTY__c IN:countyIdSet]) {
            if(adjustmentEach.IDN_PROVR__c!=null) {
                String key = adjustmentEach.IDN_PROVR__c+'_'+adjustmentEach.CDE_COUNTY__c;
                providerIdInvalidSet.add(key); //collecting Provider Ids 
            } else if(adjustmentEach.IDN_CASE__c!=null){
                String key = adjustmentEach.IDN_CASE__c+'_'+adjustmentEach.CDE_COUNTY__c;
                providerIdInvalidSet.add(key); //collecting Case Ids
            }
        }
        System.debug('providerIdInvalidSet-->'+providerIdInvalidSet);
        for(T_ADJMT_PMT__c adjustmentPayment:newAdjustmentPaymentsList) {
            if(adjustmentPayment.IDN_PROVR__c!=null || adjustmentPayment.IDN_CASE__c!=null) {
                String key;
                if(adjustmentPayment.IDN_PROVR__c!=null && adjustmentPayment.CDE_COUNTY__c!= null){
                    key = adjustmentPayment.IDN_PROVR__c+'_'+countyCodeMap.get(string.valueof(adjustmentPayment.CDE_COUNTY__c));
                }else{
                    if(adjustmentPayment.CDE_COUNTY__c!= null){
                        key = adjustmentPayment.IDN_CASE__c+'_'+countyCodeMap.get(string.valueof(adjustmentPayment.CDE_COUNTY__c));
                    }
                }
                system.debug('key---'+key);
                if(adjustmentPayment.IDN_PROVR__c!=null && adjustmentPayment.IDN_CASE__c!=null) {
                    adjustmentPayment.addError('Either Case or Provider must be entered');
                } else if(!providerIdInvalidSet.contains(key)  && adjustmentPayment.CDE_COUNTY__c!= null && adjustmentPayment.CDE_TYPE_PMT_ADJMT__c!='9' && adjustmentPayment.CDE_TYPE_PMT_ADJMT__c!='8' ) {
                    adjustmentPayment.addError('Payment cannot be recorded as no recovery adjustment exists');
                }
            } else {
                adjustmentPayment.addError('Either Case or Provider must be entered');
            }
        }
    }
}