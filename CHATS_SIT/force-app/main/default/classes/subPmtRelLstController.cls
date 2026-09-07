public with sharing class subPmtRelLstController {
    
    @auraEnabled
    public Static List<batchsit_t_sub_pmt__x> getSubPmtRecords(String pmtId) {
		// Added 'DTE_BEGIN_EFFV_Formatted__c' & 'DTE_END_EFFV_Formatted__c' in the query by Rishav for CCCAP-2556
        List<batchsit_t_sub_pmt__x> sbPmtLst = [select id, idn_pmt_sub__c, amt_copay_pmt_sub__c, amt_rate_pmt_sub__c, idn_pmt__c, idn_period_serv__c, idn_period_serv__r.Name, idn_auth__c, 
                                                	   idn_auth__r.NAM_LAST__c, idn_auth__r.NAM_FIRST__c, amt_total_pmt_sub__c, amt_slot_pmt_sub__c, idn_auth__r.Id, idn_auth__r.IDN_CASE__c, 
                                                	   idn_auth__r.IDN_CASE__r.IDN_EXTNL__c, idn_auth__r.IDN_CASE__r.Name, idn_period_serv__r.DTE_BEGIN_EFFV_Formatted__c, 
                                                	   idn_period_serv__r.DTE_END_EFFV_Formatted__c, idn_slot_contract__c, idn_slot_contract__r.idn_auth__c
                                                 from batchsit_t_sub_pmt__x where idn_pmt__r.Id = :pmtId
                                                  AND (idn_slot_contract__c = null OR idn_slot_contract__r.idn_auth__c != null)];
        if(sbPmtLst!=null && !sbPmtLst.isEmpty()) {
        	return sbPmtLst;
        } else {
        	return null;
        }
    }
    
    @auraEnabled
    public Static List<batchsit_t_sub_pmt__x> getVacantSlotSubPmtRecords(String pmtId) {
		List<batchsit_t_sub_pmt__x> sbPmtLst = [select id, idn_pmt_sub__c, amt_slot_pmt_sub__c, idn_slot_contract__c, idn_slot_contract__r.idn_auth__c,
                                                	idn_slot_contract__r.Name, toLabel(idn_slot_contract__r.CDE_CARE_LEVEL__c), toLabel(idn_slot_contract__r.CDE_CARE_UNIT__c), 
                                                	toLabel(idn_slot_contract__r.CDE_RATE_TYPE__c), idn_slot_contract__r.DTE_BEGIN_SLOT__c,
                                                    (SELECT dte_care__c FROM batchsit_t_sub_pmt_detail__r ORDER BY dte_care__c asc)
                                                 from batchsit_t_sub_pmt__x where idn_pmt__r.Id = :pmtId
                                                  AND idn_slot_contract__c != null AND idn_slot_contract__r.idn_auth__c = null];
        if(sbPmtLst != null && !sbPmtLst.isEmpty()) {
            for(batchsit_t_sub_pmt__x sp : sbPmtLst){
                for(batchsit_t_sub_pmt_detail__x obj : sp.batchsit_t_sub_pmt_detail__r){
                    sp.idn_slot_contract__r.DTE_BEGIN_SLOT__c = obj.dte_care__c;
                }
            }
        	return sbPmtLst;
        } else {
        	return null;
        }
    }
}