/*************************************************************
Class Name	    - TaxInterceptCreationBatch
Test Class	    - TaxInterceptCreationBatch_Test
Scheduler Class	- TaxInterceptBatchSchedulable
Description     - Batch to create Tax Intercepts from Adjustment records
Author          - Pragyan Nayak, Rishav Maji
Requiremnt		- Project 282 : CCCAP-4414
**************************************************************/
global with sharing class TaxInterceptCreationBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    public Exception_Log__c[] errors = new Exception_Log__c[0];
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String adjType = '2'; // Recovery
        String adjStatus = '2'; // Calculation Complete
        Date todayDate = System.today();
        String queryStr ='SELECT Id, Name, DTE_END_ADJMT__c, IDN_CASE__r.Id, IDN_PROVR__c, IDN_PROVR__r.NAM_FACILITY__c, CDE_COUNTY__c, IDN_CASE__c, DTE_START_ADJMT__c, ';
        queryStr += 'CDE_STATUS_ADJMT__c, AMT_ADJMT__c, CDE_TYPE_CLSFN__c, CDE_REASON__c, IDN_PROVR__r.NBR_FEIN__c, IDN_PROVR__r.NBR_SSN__c, CreatedDate ';
        queryStr += 'FROM T_ADJMT__c WHERE CDE_TYPE_ADJMT__c =: adjType AND CDE_STATUS_ADJMT__c =: adjStatus';
        return Database.getQueryLocator(queryStr);
    }
    
    global void execute(Database.BatchableContext bc, List<T_ADJMT__c> scope) {
        List<Tax_Intercept__c> finalListToInsert = new List<Tax_Intercept__c>();
        String adjPayDetStatus = '4';//Paid
        Map<Id, Date> adjPayDate = new Map<Id, Date>(); // Final Tax Tntercepts to be inserted
        Map<Id, Double> adjPayAmt = new Map<Id, Double>();
        Map<Id, DateTime> adjPayCreateDate = new Map<Id, DateTime>();
        Map<Id, List<Double>> sumOfAuthPayDetAmt = new Map<Id, List<Double>>();
        Map<Id, Double> adjPayDetAmt = new Map<Id, Double>();
        Map<Id, List<T_ADJMT_RESPBL_PARTY__c>> respParties = new Map<Id, List<T_ADJMT_RESPBL_PARTY__c>>();
        List<Id> caseList = new List<Id>();
        Map<Id, String> caseStatus = new Map<Id, String>();
        Date todayDate = System.today();
        try {
            // Seperating Provider and Case type Adjustments
            List<T_ADJMT__c> providerAdj = new List<T_ADJMT__c>();
            List<T_ADJMT__c> caseAdj = new List<T_ADJMT__c>();
            for(T_ADJMT__c adj : scope) {
                if(adj.IDN_PROVR__c != Null) {
                    providerAdj.add(adj);
                }
                if(adj.IDN_CASE__c != Null) {
                    caseAdj.add(adj);
                }
            }
            
            /* Processing Provider type Adjustments */
            
            // Adding the adjustment Payment date and Amount to a Map having Adjustment Id as the key and Payment Date and Amount as the value.
            for(T_ADJMT_PMT_DETAIL__c adPayDet : [SELECT Id, Name, IDN_PMT_ADJMT__c, IDN_ADJMT__c, AMT_PMT_DETAIL_ADJMT__c, CreatedDate, IDN_PMT_ADJMT__r.CreatedDate, IDN_ADJMT__r.Name, IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c
                                                  FROM T_ADJMT_PMT_DETAIL__c 
                                                  WHERE IDN_ADJMT__c IN: providerAdj AND IDN_PMT_ADJMT__c != null AND IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c != null
                                                  WITH SECURITY_ENFORCED ORDER BY IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c DESC,IDN_PMT_ADJMT__r.CreatedDate DESC]) {
                                                      if(!adjPayDate.containsKey(adPayDet.IDN_ADJMT__c)) {
                                                          adjPayDate.put(adPayDet.IDN_ADJMT__c, adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c);
                                                          adjPayAmt.put(adPayDet.IDN_ADJMT__c, adPayDet.AMT_PMT_DETAIL_ADJMT__c);
                                                          adjPayCreateDate.put(adPayDet.IDN_ADJMT__c, adPayDet.CreatedDate); // Last Adjustment Payment Date
                                                      } else {
                                                          if((adjPayDate.get(adPayDet.IDN_ADJMT__c) < adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c) || (adjPayDate.get(adPayDet.IDN_ADJMT__c) == adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c && adjPayCreateDate.get(adPayDet.IDN_ADJMT__c) < adPayDet.CreatedDate)) {
                                                              adjPayDate.put(adPayDet.IDN_ADJMT__c, adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c); // Last Adjustment Payment Date
                                                              adjPayAmt.put(adPayDet.IDN_ADJMT__c, adPayDet.AMT_PMT_DETAIL_ADJMT__c);
                                                          }
                                                      }
                                                  }
            // Adding all the Adjustment Payment Detail amount in a Map for a particular Adjustment.This calculation is related to "Outstanding Recovery Balance".
            // Note: Calculation for "Outstanding Recovery Balance" = "Amount" field of Adjustemnt - Sum of amount of Adjustment Payment Detail records related to the particular adjustment.
            for(T_ADJMT_PMT_DETAIL__c adPayDet : [SELECT Id, Name, IDN_ADJMT__c, CDE_STATUS_DETAIL_PMT_ADJMT__c, AMT_PMT_DETAIL_ADJMT__c FROM T_ADJMT_PMT_DETAIL__c WHERE IDN_ADJMT__c IN:providerAdj AND CDE_STATUS_DETAIL_PMT_ADJMT__c =:adjPayDetStatus WITH SECURITY_ENFORCED]) {
                if(!sumOfAuthPayDetAmt.containsKey(adPayDet.IDN_ADJMT__c)) { 
                    sumOfAuthPayDetAmt.put(adPayDet.IDN_ADJMT__c, new List<Double>());
                }
                sumOfAuthPayDetAmt.get(adPayDet.IDN_ADJMT__c).add(adPayDet.AMT_PMT_DETAIL_ADJMT__c);
            }
            // Summing up all the Adjustment Payment Detail amount and putting it with a particular Adjustment. This calculation is related to "Outstanding Recovery Balance"
            for(Id idVal : sumOfAuthPayDetAmt.keySet()) {
                if(idVal != null && sumOfAuthPayDetAmt.get(idVal) != null) {
                    Double tot = 0;
                    for(Double amt : sumOfAuthPayDetAmt.get(idVal)) {
                        if(amt != null) {
                            tot = tot + amt;
                        }
                    }
                    if(!adjPayDetAmt.containsKey(idVal)) {
                        adjPayDetAmt.put(idVal, tot);
                    }
                }
            }
            // Preparing final list for Provider type Tax Intercepts
            for(T_ADJMT__c provAdj : providerAdj) {
                if(hasCRUDPermission() && ((adjPayDetAmt.containsKey(provAdj.Id)) && provAdj.AMT_ADJMT__c - adjPayDetAmt.get(provAdj.Id) > 25.0)
                   && (!String.isBlank(provAdj.IDN_PROVR__r.NBR_FEIN__c) || !String.isBlank(provAdj.IDN_PROVR__r.NBR_SSN__c))
                   && adjPayDate.get(provAdj.Id) != null && (adjPayDate.get(provAdj.Id)).daysBetween(todayDate) > 90) {
                       Tax_Intercept__c tx = new Tax_Intercept__c();
                       tx.Adjustment__c = Schema.sObjectType.Tax_Intercept__c.fields.Adjustment__c.isCreateable() ? provAdj.Id : null;
                       tx.County__c = Schema.sObjectType.Tax_Intercept__c.fields.County__c.isCreateable() ? provAdj.CDE_COUNTY__c : null;
                       tx.Provider__c = Schema.sObjectType.Tax_Intercept__c.fields.Provider__c.isCreateable() ? provAdj.IDN_PROVR__c : null;
                       tx.Name__c = Schema.sObjectType.Tax_Intercept__c.fields.Name__c.isCreateable() ? provAdj.IDN_PROVR__r.NAM_FACILITY__c : null;
                       tx.NAM_FIRST__c = Schema.sObjectType.Tax_Intercept__c.fields.NAM_FIRST__c.isCreateable() ? provAdj.IDN_PROVR__r.NAM_FACILITY__c : null;
                       tx.SSN__c = (!String.isBlank(provAdj.IDN_PROVR__r.NBR_SSN__c) && Schema.sObjectType.Tax_Intercept__c.fields.SSN__c.isCreateable()) ? provAdj.IDN_PROVR__r.NBR_SSN__c : null;
                       tx.Amount_Due__c = Schema.sObjectType.Tax_Intercept__c.fields.Amount_Due__c.isCreateable() ? provAdj.AMT_ADJMT__c : null; // Original Recovery Amount
                       tx.Current_Balance__c = Schema.sObjectType.Tax_Intercept__c.fields.Current_Balance__c.isCreateable() ? (provAdj.AMT_ADJMT__c - adjPayDetAmt.get(provAdj.Id)).setScale(2) : null; // Outstanding Recovery Balance
                       tx.Classification__c = Schema.sObjectType.Tax_Intercept__c.fields.Classification__c.isCreateable() ? provAdj.CDE_TYPE_CLSFN__c : null;
                       tx.Recovery_Reason__c = Schema.sObjectType.Tax_Intercept__c.fields.Recovery_Reason__c.isCreateable() ? provAdj.CDE_REASON__c : null;
                       tx.Last_Payment_Date__c = Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Date__c.isCreateable() ? adjPayDate.get(provAdj.Id) : null;
                       tx.Last_Payment_Amount__c = Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Amount__c.isCreateable() ? adjPayAmt.get(provAdj.Id) : null;
                       tx.Reinstate__c = Schema.sObjectType.Tax_Intercept__c.fields.Reinstate__c.isCreateable() ? 'N' : null;
                       tx.Sent_to_CDOR__c = Schema.sObjectType.Tax_Intercept__c.fields.Sent_to_CDOR__c.isCreateable() ? null : null;
                       tx.Type__c = Schema.sObjectType.Tax_Intercept__c.fields.Type__c.isCreateable() ? 'Provider' : null;
                       finalListToInsert.add(tx);
                   } else if(hasCRUDPermission() && !(adjPayDetAmt.containsKey(provAdj.Id)) 
                             && provAdj.AMT_ADJMT__c > 25.0 
                             && (!String.isBlank(provAdj.IDN_PROVR__r.NBR_FEIN__c) || !String.isBlank(provAdj.IDN_PROVR__r.NBR_SSN__c)) 
                             && ((provAdj.CreatedDate).date()).daysBetween(todayDate) > 90) 
                   {
                       Tax_Intercept__c txtwo = new Tax_Intercept__c();
                       txtwo.Adjustment__c = Schema.sObjectType.Tax_Intercept__c.fields.Adjustment__c.isCreateable() ? provAdj.Id : null;
                       txtwo.County__c = Schema.sObjectType.Tax_Intercept__c.fields.County__c.isCreateable() ? provAdj.CDE_COUNTY__c : null;
                       txtwo.Provider__c = Schema.sObjectType.Tax_Intercept__c.fields.Provider__c.isCreateable() ? provAdj.IDN_PROVR__c : null;
                       txtwo.Name__c = Schema.sObjectType.Tax_Intercept__c.fields.Name__c.isCreateable() ? provAdj.IDN_PROVR__r.NAM_FACILITY__c : null;
                       txtwo.SSN__c = (!String.isBlank(provAdj.IDN_PROVR__r.NBR_SSN__c) && Schema.sObjectType.Tax_Intercept__c.fields.SSN__c.isCreateable()) ? provAdj.IDN_PROVR__r.NBR_SSN__c : null;
                       txtwo.Amount_Due__c = Schema.sObjectType.Tax_Intercept__c.fields.Amount_Due__c.isCreateable() ? provAdj.AMT_ADJMT__c : null; // Original Recovery Amount
                       txtwo.Current_Balance__c = Schema.sObjectType.Tax_Intercept__c.fields.Amount_Due__c.isCreateable() ? provAdj.AMT_ADJMT__c : null; // Outstanding Recovery Balance
                       txtwo.Classification__c = Schema.sObjectType.Tax_Intercept__c.fields.Classification__c.isCreateable() ? provAdj.CDE_TYPE_CLSFN__c : null;
                       txtwo.Recovery_Reason__c = Schema.sObjectType.Tax_Intercept__c.fields.Recovery_Reason__c.isCreateable() ? provAdj.CDE_REASON__c : null;
                       txtwo.Last_Payment_Amount__c = Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Amount__c.isCreateable() ? 0.0 : null;
                       txtwo.Reinstate__c = Schema.sObjectType.Tax_Intercept__c.fields.Reinstate__c.isCreateable() ? 'N' : null;
                       txtwo.Sent_to_CDOR__c = Schema.sObjectType.Tax_Intercept__c.fields.Sent_to_CDOR__c.isCreateable() ? null : null;
                       txtwo.Type__c = Schema.sObjectType.Tax_Intercept__c.fields.Type__c.isCreateable() ? 'Provider' : null;
                       finalListToInsert.add(txtwo);
                   }
            }
            
            /* Processing Case type Adjustments */
            
            // Adding the adjustment Payment date and Amount to a Map having Adjustment Id as the key and Payment Date and Amount as the value.
            for(T_ADJMT_PMT_DETAIL__c adPayDet : [SELECT Id, Name, IDN_PMT_ADJMT__c, IDN_ADJMT__c, AMT_PMT_DETAIL_ADJMT__c, IDN_PMT_ADJMT__r.CreatedDate, IDN_ADJMT__r.Name, IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c, CreatedDate
                                                  FROM T_ADJMT_PMT_DETAIL__c
                                                  WHERE IDN_ADJMT__c IN: caseAdj AND IDN_PMT_ADJMT__c != null AND IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c != null
                                                  WITH SECURITY_ENFORCED ORDER BY IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c DESC, IDN_PMT_ADJMT__r.CreatedDate DESC]) {
                                                      if(!adjPayDate.containsKey(adPayDet.IDN_ADJMT__c)) {
                                                          adjPayDate.put(adPayDet.IDN_ADJMT__c, adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c); // Last Adjustment Payment Date
                                                          adjPayAmt.put(adPayDet.IDN_ADJMT__c, adPayDet.AMT_PMT_DETAIL_ADJMT__c); // Last Adjustment Payment Amount
                                                          adjPayCreateDate.put(adPayDet.IDN_ADJMT__c, adPayDet.CreatedDate);
                                                      } else {
                                                          if(adjPayDate.get(adPayDet.IDN_ADJMT__c) < adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c || (adjPayDate.get(adPayDet.IDN_ADJMT__c) == adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c && adjPayCreateDate.get(adPayDet.IDN_ADJMT__c) < adPayDet.CreatedDate)) {
                                                              adjPayDate.put(adPayDet.IDN_ADJMT__c, adPayDet.IDN_PMT_ADJMT__r.DTE_PMT_ADJMT__c); // Last Adjustment Payment Date
                                                              adjPayAmt.put(adPayDet.IDN_ADJMT__c, adPayDet.AMT_PMT_DETAIL_ADJMT__c); // Last Adjustment Payment Amount
                                                          }
                                                      }
                                                  }
            // Adding all the Adjustment Payment Detail amount in a Map for a particular Adjustment.This calculation is related to "Outstanding Recovery Balance".
            // Note: Calculation for "Outstanding Recovery Balance"= Amount field of Adjustemnt - Sum of amount of Adjustment Payment Detail records related to the particular adjustment.
            for(T_ADJMT_PMT_DETAIL__c adPayDet : [SELECT Id, Name, CDE_STATUS_DETAIL_PMT_ADJMT__c, IDN_ADJMT__c, AMT_PMT_DETAIL_ADJMT__c FROM T_ADJMT_PMT_DETAIL__c WHERE IDN_ADJMT__c IN: caseAdj AND CDE_STATUS_DETAIL_PMT_ADJMT__c =:adjPayDetStatus WITH SECURITY_ENFORCED]) {
                if(!sumOfAuthPayDetAmt.containsKey(adPayDet.IDN_ADJMT__c)) { 
                    sumOfAuthPayDetAmt.put(adPayDet.IDN_ADJMT__c, new List<Double>());
                }
                sumOfAuthPayDetAmt.get(adPayDet.IDN_ADJMT__c).add(adPayDet.AMT_PMT_DETAIL_ADJMT__c);
            }
            // Summing up all the Adjustment Payment Detail amount and putting it with a particular Adjustment. This calculation is related to "Outstanding Recovery Balance".
            for(Id idVal : sumOfAuthPayDetAmt.keySet()) {
                if(idVal != null && sumOfAuthPayDetAmt.get(idVal) != null) {
                    Double tot = 0;
                    for(Double amt : sumOfAuthPayDetAmt.get(idVal)) {
                        if(amt != Null) {
                            tot = tot+amt;
                        }
                    }
                    if(!adjPayDetAmt.containsKey(idVal)) {
                        adjPayDetAmt.put(idVal, tot);
                    }
                }
            }
            // Fetching list of Cases from Case Adjustment
            for(T_ADJMT__c casAdj : caseAdj) {
                caseList.add(casAdj.IDN_CASE__c);
            }
            // Fetching the case status from the list of Cases fetched from above adjustment.
            for(T_SBSD_CASE_STATUS_MODE__c casStatus : [SELECT Id, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c, CDE_STATUS_CASE__c, IDN_CASE__c
                                                        FROM T_SBSD_CASE_STATUS_MODE__c
                                                        WHERE IDN_CASE__c IN: caseList AND DTE_BEGIN_EFFV__c <=: todayDate AND (DTE_END_EFFV__c >=: todayDate OR DTE_END_EFFV__c = null) WITH SECURITY_ENFORCED]) {
                                                            if(!caseStatus.containsKey(casStatus.IDN_CASE__c)) {
                                                                caseStatus.put(casStatus.IDN_CASE__c, casStatus.CDE_STATUS_CASE__c);
                                                            }
                                                        }
            // Fetching all resp parties of particular adjustment
            for(T_ADJMT_RESPBL_PARTY__c rParty : [SELECT Id, IDN_CLIENT__c, IDN_CLIENT__r.NBR_SSN__c, IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c, IDN_ADJMT__c, IDN_CLIENT__r.NAM_MI__c, IDN_CLIENT__r.DTE_DOB__c
                                                  FROM T_ADJMT_RESPBL_PARTY__c
                                                  WHERE IDN_ADJMT__c IN:caseAdj WITH SECURITY_ENFORCED]) {
                                                      if(!respParties.containsKey(rParty.IDN_ADJMT__c)) {
                                                          respParties.put(rParty.IDN_ADJMT__c, new List<T_ADJMT_RESPBL_PARTY__c>());
                                                      }
                                                      respParties.get(rParty.IDN_ADJMT__c).add(rParty);
                                                  }
            // Preparing final list for Case type Tax Intercepts
            for(T_ADJMT__c casAdj : caseAdj) {
                if(respParties.get(casAdj.Id) != null) {
                    for(T_ADJMT_RESPBL_PARTY__c resPar : respParties.get(casAdj.Id)) {
                        if(((adjPayDetAmt.containsKey(casAdj.Id)) && ((casAdj.AMT_ADJMT__c - adjPayDetAmt.get(casAdj.Id)) > 25.0))
                           && (!String.isBlank(resPar.IDN_CLIENT__r.NBR_SSN__c)) && adjPayDate.get(casAdj.Id) != null 
                           && ((adjPayDate.get(casAdj.Id)).daysBetween(todayDate)>90) && hasCRUDPermission()) {
                               Tax_Intercept__c txone = new Tax_Intercept__c();
                               txone.Adjustment__c = Schema.sObjectType.Tax_Intercept__c.fields.Adjustment__c.isCreateable() ? casAdj.Id : null;
                               txone.County__c = Schema.sObjectType.Tax_Intercept__c.fields.County__c.isCreateable() ? casAdj.CDE_COUNTY__c : null;
                               txone.Case__c = Schema.sObjectType.Tax_Intercept__c.fields.Case__c.isCreateable() ? casAdj.IDN_CASE__c : null;
                               txone.Case_Status__c = Schema.sObjectType.Tax_Intercept__c.fields.Case_Status__c.isCreateable() ? caseStatus.get(casAdj.IDN_CASE__r.Id) : null;
                               if(Schema.sObjectType.Tax_Intercept__c.fields.Name__c.isCreateable())
                                   txone.Name__c = String.isBlank(resPar.IDN_CLIENT__r.NAM_MI__c) ? resPar.IDN_CLIENT__r.NAM_FIRST__c+' '+resPar.IDN_CLIENT__r.NAM_LAST__c : resPar.IDN_CLIENT__r.NAM_FIRST__c+' '+resPar.IDN_CLIENT__r.NAM_MI__c+' '+resPar.IDN_CLIENT__r.NAM_LAST__c;
                               txone.NAM_FIRST__c = Schema.sObjectType.Tax_Intercept__c.fields.NAM_FIRST__c.isCreateable() ? resPar.IDN_CLIENT__r.NAM_FIRST__c : null;
                               txone.NAM_LAST__c = Schema.sObjectType.Tax_Intercept__c.fields.NAM_LAST__c.isCreateable() ? resPar.IDN_CLIENT__r.NAM_LAST__c : null;
                               txone.NAM_MI__c = (!String.isBlank(resPar.IDN_CLIENT__r.NAM_MI__c) && Schema.sObjectType.Tax_Intercept__c.fields.NAM_MI__c.isCreateable()) ? resPar.IDN_CLIENT__r.NAM_MI__c : null;
                               txone.DTE_DOB__c = Schema.sObjectType.Tax_Intercept__c.fields.DTE_DOB__c.isCreateable() ? resPar.IDN_CLIENT__r.DTE_DOB__c : null;
                               txone.SSN__c = Schema.sObjectType.Tax_Intercept__c.fields.SSN__c.isCreateable() ? resPar.IDN_CLIENT__r.NBR_SSN__c : null;
                               txone.Amount_Due__c = Schema.sObjectType.Tax_Intercept__c.fields.Amount_Due__c.isCreateable() ? casAdj.AMT_ADJMT__c : null; // Original Recovery Amount
                               txone.Current_Balance__c = Schema.sObjectType.Tax_Intercept__c.fields.Current_Balance__c.isCreateable() ? (casAdj.AMT_ADJMT__c - adjPayDetAmt.get(casAdj.Id)).setScale(2) : null; // Outstanding Recovery Balance
                               txone.Classification__c = Schema.sObjectType.Tax_Intercept__c.fields.Classification__c.isCreateable() ? casAdj.CDE_TYPE_CLSFN__c : null;
                                txone.Recovery_Reason__c = Schema.sObjectType.Tax_Intercept__c.fields.Recovery_Reason__c.isCreateable() ? casAdj.CDE_REASON__c : null;
                               txone.Last_Payment_Date__c = Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Date__c.isCreateable() ? adjPayDate.get(casAdj.Id) : null;
                               txone.Last_Payment_Amount__c = Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Amount__c.isCreateable() ? adjPayAmt.get(casAdj.Id) : null;
                               txone.Reinstate__c = Schema.sObjectType.Tax_Intercept__c.fields.Reinstate__c.isCreateable() ? 'N' : null;
                               txone.Sent_to_CDOR__c = Schema.sObjectType.Tax_Intercept__c.fields.Sent_to_CDOR__c.isCreateable() ? null : null;
                               txone.Type__c = Schema.sObjectType.Tax_Intercept__c.fields.Type__c.isCreateable() ? 'Case' : null;
                               txone.Responsible_Party_Id__c = resPar.Id; // added for CCCAP-12508
                               finalListToInsert.add(txone);
                           } else if(hasCRUDPermission() && !(adjPayDetAmt.containsKey(casAdj.Id))
                                     && casAdj.AMT_ADJMT__c > 25.0 
                                     && (!String.isBlank(resPar.IDN_CLIENT__r.NBR_SSN__c)) 
                                     && ((casAdj.CreatedDate).date()).daysBetween(todayDate) > 90) 
                           {
                               Tax_Intercept__c txthr = new Tax_Intercept__c();
                               txthr.Adjustment__c = Schema.sObjectType.Tax_Intercept__c.fields.Adjustment__c.isCreateable() ? casAdj.Id : null;
                               txthr.County__c = Schema.sObjectType.Tax_Intercept__c.fields.County__c.isCreateable() ? casAdj.CDE_COUNTY__c : null;
                               txthr.Case__c = Schema.sObjectType.Tax_Intercept__c.fields.Case__c.isCreateable() ? casAdj.IDN_CASE__c : null;
                               txthr.Case_Status__c = Schema.sObjectType.Tax_Intercept__c.fields.Case_Status__c.isCreateable() ? caseStatus.get(casAdj.IDN_CASE__r.Id) : null;
                               if(Schema.sObjectType.Tax_Intercept__c.fields.Name__c.isCreateable())
                                   txthr.Name__c = String.isBlank(resPar.IDN_CLIENT__r.NAM_MI__c) ? resPar.IDN_CLIENT__r.NAM_FIRST__c+' '+resPar.IDN_CLIENT__r.NAM_LAST__c : resPar.IDN_CLIENT__r.NAM_FIRST__c+' '+resPar.IDN_CLIENT__r.NAM_MI__c+' '+resPar.IDN_CLIENT__r.NAM_LAST__c;
                               txthr.NAM_FIRST__c = Schema.sObjectType.Tax_Intercept__c.fields.NAM_FIRST__c.isCreateable() ? resPar.IDN_CLIENT__r.NAM_FIRST__c : null;
                               txthr.NAM_LAST__c = Schema.sObjectType.Tax_Intercept__c.fields.NAM_LAST__c.isCreateable() ? resPar.IDN_CLIENT__r.NAM_LAST__c : null;
                               txthr.NAM_MI__c = (!String.isBlank(resPar.IDN_CLIENT__r.NAM_MI__c) && Schema.sObjectType.Tax_Intercept__c.fields.NAM_MI__c.isCreateable()) ? resPar.IDN_CLIENT__r.NAM_MI__c : null;
                               txthr.DTE_DOB__c = Schema.sObjectType.Tax_Intercept__c.fields.DTE_DOB__c.isCreateable() ? resPar.IDN_CLIENT__r.DTE_DOB__c : null;
                               txthr.SSN__c = Schema.sObjectType.Tax_Intercept__c.fields.SSN__c.isCreateable() ? resPar.IDN_CLIENT__r.NBR_SSN__c : null;
                               txthr.Amount_Due__c = Schema.sObjectType.Tax_Intercept__c.fields.Amount_Due__c.isCreateable() ? casAdj.AMT_ADJMT__c : null; // Original Recovery Amount
                               txthr.Current_Balance__c = Schema.sObjectType.Tax_Intercept__c.fields.Current_Balance__c.isCreateable() ? casAdj.AMT_ADJMT__c : null; // Outstanding Recovery Balance
                               txthr.Classification__c = Schema.sObjectType.Tax_Intercept__c.fields.Classification__c.isCreateable() ? casAdj.CDE_TYPE_CLSFN__c : null;
                                txthr.Recovery_Reason__c = Schema.sObjectType.Tax_Intercept__c.fields.Recovery_Reason__c.isCreateable() ? casAdj.CDE_REASON__c : null;
                               txthr.Last_Payment_Amount__c = Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Amount__c.isCreateable() ? 0.0 : null;
                               txthr.Reinstate__c = Schema.sObjectType.Tax_Intercept__c.fields.Reinstate__c.isCreateable() ? 'N' : null;
                               txthr.Sent_to_CDOR__c = Schema.sObjectType.Tax_Intercept__c.fields.Sent_to_CDOR__c.isCreateable() ? null : null;
                               txthr.Type__c = Schema.sObjectType.Tax_Intercept__c.fields.Type__c.isCreateable() ? 'Case' : null;
                               txthr.Responsible_Party_Id__c = resPar.Id; // added for CCCAP-12508
                               finalListToInsert.add(txthr);
                           }
                    }
                }
            }
            
            /* Inserting final processed Tax Intercept records */
            if(!finalListToInsert.isEmpty()) {
                GenericDMLHandler.insertRecords(finalListToInsert, new Map<String, Object>{'Method__c'=>'execute','Class__c'=>'TaxInterceptCreationBatch'});
            }
        } catch(Exception e) {
            errors.add(new Exception_Log__c(Class__c = 'TaxInterceptCreationBatch', Method__c = 'execute', Exception_Message__c = e.getMessage(), Exception_Type__c = 'Error'));
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        database.executebatch(new T215TaskCreationBatch()); // Added by Rishav for CCCAP-4373
        if(errors.size() > 0) {
            GenericDMLHandler.insertRecords(errors, new Map<String, Object>{'Method__c'=>'finish','Class__c'=>'TaxInterceptCreationBatch'});
        }
    }
    
    private boolean hasCRUDPermission(){
        return Schema.sObjectType.Tax_Intercept__c.isCreateable() 
            && Schema.sObjectType.Tax_Intercept__c.fields.Adjustment__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.County__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.Provider__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.Name__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.NAM_FIRST__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.SSN__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.Amount_Due__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.Current_Balance__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.Classification__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.Recovery_Reason__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Date__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.Last_Payment_Amount__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.Reinstate__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.Sent_to_CDOR__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.Type__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.Case__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.Case_Status__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.NAM_LAST__c.isCreateable()
            && Schema.sObjectType.Tax_Intercept__c.fields.NAM_MI__c.isCreateable() && Schema.sObjectType.Tax_Intercept__c.fields.DTE_DOB__c.isCreateable();
    }
}