public with sharing class SubPaymentSearchApxCtrl{
    public class My1Exception extends Exception {} 
    private static requestParams req{get;set;}
    public static boolean throwException{get;set;}
    public static boolean adjustmentEntrySearchFlag = true; //BG 7/30/2018 CHATS-5997 To avoid County check on Payment Object from Adjustment Entry Screen
    
    public static List<subpaymentWrapper> doSubPaymentSearch(String paymentId, String providerId, String caseId, String countyId, String servicePeriodId, String stateId, String childFirstName, String childLastName, String selectedAuthId) {
        List<String> subPmtIds = new List<String>();
        List<String> servicePeriodIds = new List<String>();
        List<String> servicePeriodExtIds = new List<String>();
        req = new requestParams();
        req.adjCountySFID = countyId;
        req.providerSfid = providerId; // added for CCCAP-9465 by Shashank
        req.isSearchByVacantSlotContractId  = 'false';
        if(String.isNotEmpty(servicePeriodId)) {
            servicePeriodIds.add(servicePeriodId);
            List<T_SERV_PERIOD__c> servicePeriods = [SELECT IDN_EXTNL__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c FROM T_SERV_PERIOD__c WHERE Id = :servicePeriodId];
            if(!servicePeriods.isEmpty()) {
                servicePeriodExtIds.add(servicePeriods.get(0).IDN_EXTNL__c);
                req.beginDate = String.valueOf(servicePeriods.get(0).DTE_BEGIN_EFFV__c);
                req.endDate = String.valueOf(servicePeriods.get(0).DTE_END_EFFV__c);
            }
        }
        if(String.isNotEmpty(caseId) || String.isNotEmpty(stateId) || String.isNotEmpty(childFirstName) || String.isNotEmpty(childLastName)) {
            if(String.isNotEmpty(paymentId) || String.isNotEmpty(providerId)) {
                List<String> providerIds = getSubPmtOrPrvdrExtIdsBasedOnAuth(providerId, caseId, countyId, stateId, childFirstName, childLastName, servicePeriodExtIds, true, selectedAuthId);   
                if(Test.isRunningTest()) {
                    providerIds.add('123');
                }
                if(providerIds == null || providerIds.isEmpty()) {
                    return new List<subpaymentWrapper>();
                }
                subPmtIds = getPrvdrExtIds(paymentId, providerId, caseId, countyId, servicePeriodIds, stateId, childFirstName, childLastName, providerIds, false);
            } else {
                subPmtIds = getSubPmtOrPrvdrExtIdsBasedOnAuth(providerId, caseId, countyId, stateId, childFirstName, childLastName, servicePeriodExtIds, false, selectedAuthId);   
            }
        } else {
            subPmtIds = getPrvdrExtIds(paymentId, providerId, caseId, countyId, servicePeriodIds, stateId, childFirstName, childLastName, new List<String>(), false);
        }
        req.subPymtIds = subPmtIds;
        if(req.subPymtIds!=null && req.subPymtIds.size()>0){
            return hitSubpaymentWebService();
        }else{
            return new List<subpaymentWrapper>();
        }
    }
    
    public static List<batchsit_t_sub_pmt__x> querySubPaymentRecords(List<String> subPaymentIds, String selectedSlotCntId, Boolean slotCntcheckbox) {
        List<Decimal> subPaymentExtnlIds = new List<Decimal>();
        List<batchsit_t_sub_pmt__x> subPaymentList = new List<batchsit_t_sub_pmt__x>();
        for(String subPaymentId:subPaymentIds) {
            subPaymentExtnlIds.add(Decimal.valueOf(subPaymentId));
        }
        if(!subPaymentExtnlIds.isEmpty()) {
            if(slotCntcheckbox) {
                String query = 'SELECT Id, ExternalId, idn_pmt__c, idn_pmt__r.Name, idn_pmt__r.IDN_PROVR__c, amt_slot_pmt_sub__c, idn_pmt_sub__c, idn_slot_contract__c, idn_slot_contract__r.idn_auth__c, idn_slot_contract__r.Name, ' 
                    + 'idn_slot_contract__r.DTE_BEGIN_SLOT__c, idn_slot_contract__r.CDE_COUNTY__c, idn_slot_contract__r.CDE_COUNTY__r.Name, idn_period_serv__r.DTE_END_EFFV__c, idn_period_serv__r.DTE_BEGIN_EFFV__c '
                    + 'FROM batchsit_t_sub_pmt__x '
                    + 'WHERE idn_pmt_sub__c IN :subPaymentExtnlIds ';
                if(string.isNotEmpty(selectedSlotCntId)) {
                    query += 'AND idn_slot_contract__c = :selectedSlotCntId ';
                } else {
                    query += 'AND idn_slot_contract__c != null ';
                }
                query += 'AND idn_slot_contract__r.idn_auth__c = null';
                subPaymentList = Database.query(query);
            } else {
                subPaymentList = [ SELECT Id, ExternalId, idn_pmt__c, idn_pmt__r.Name, idn_pmt_sub__c, nbr_seq_hist__c, cde_status_pmt_sub__c, amt_total_pmt_sub__c, amt_slot_pmt_sub__c, amt_copay_pmt_sub__c, amt_rate_pmt_sub__c, 
                                  idn_pmt__r.IDN_PROVR__c, idn_pmt__r.IDN_PROVR__r.Name, idn_pmt__r.CDE_COUNTY__c, idn_pmt__r.CDE_COUNTY__r.Name, idn_pmt__r.DTE_PAID_PMT__c, 
                                  idn_auth__c, idn_auth__r.Name, idn_auth__r.IDN_PROVR__c, idn_auth__r.IDN_PROVR__r.Name, idn_auth__r.NAM_LAST__c, idn_auth__r.NAM_FIRST__c, idn_auth__r.IDN_CASE__c, idn_auth__r.IDN_CASE__r.Name, idn_auth__r.CDE_COUNTY__r.Name, 
                                  idn_period_serv__r.DTE_END_EFFV__c, idn_period_serv__r.DTE_BEGIN_EFFV__c FROM batchsit_t_sub_pmt__x 
                                  WHERE idn_pmt_sub__c IN:subPaymentExtnlIds AND (idn_slot_contract__c = null OR idn_slot_contract__r.idn_auth__c != null)
                                 ];
            }
            
        }
        return subPaymentList;
    }
    
    public static List<batchsit_t_sub_pmt__x> querySubPaymentRecords(List<String> subPaymentIds, String subPaymentId, String selectedSlotCntId, Boolean slotCntcheckbox) {
        Decimal subPaymentExtnlId;
        List<batchsit_t_sub_pmt__x> subPaymentList = new List<batchsit_t_sub_pmt__x>();
        for(String eachSubPaymentId:subPaymentIds) {
            if(eachSubPaymentId == subPaymentId) {
                subPaymentExtnlId = Decimal.valueOf(eachSubPaymentId);
            }
        }
        if(subPaymentExtnlId != null) {
            if(slotCntcheckbox) {
                String query = 'SELECT Id, ExternalId, idn_pmt__c, idn_pmt__r.Name, idn_pmt__r.IDN_PROVR__c, amt_slot_pmt_sub__c, idn_pmt_sub__c, idn_slot_contract__c, idn_slot_contract__r.idn_auth__c, idn_slot_contract__r.Name, ' 
                    + 'idn_slot_contract__r.DTE_BEGIN_SLOT__c, idn_slot_contract__r.CDE_COUNTY__c, idn_slot_contract__r.CDE_COUNTY__r.Name, idn_period_serv__r.DTE_END_EFFV__c, idn_period_serv__r.DTE_BEGIN_EFFV__c '
                    + 'FROM batchsit_t_sub_pmt__x '
                    + 'WHERE idn_pmt_sub__c = :subPaymentExtnlId ';
                if(string.isNotEmpty(selectedSlotCntId)) {
                    query += 'AND idn_slot_contract__c = :selectedSlotCntId ';
                } else {
                    query += 'AND idn_slot_contract__c != null ';
                }
                query += 'AND idn_slot_contract__r.idn_auth__c = null';
                subPaymentList = Database.query(query);
            } else {
                subPaymentList = [ SELECT Id, ExternalId, idn_pmt__c, idn_pmt__r.Name, idn_pmt_sub__c, nbr_seq_hist__c, cde_status_pmt_sub__c, amt_total_pmt_sub__c, amt_copay_pmt_sub__c, amt_rate_pmt_sub__c, 
                                  idn_pmt__r.IDN_PROVR__c, idn_pmt__r.IDN_PROVR__r.Name, idn_pmt__r.CDE_COUNTY__c, idn_pmt__r.CDE_COUNTY__r.Name, idn_pmt__r.DTE_PAID_PMT__c, 
                                  idn_auth__c, idn_auth__r.Name, idn_auth__r.IDN_PROVR__c, idn_auth__r.IDN_PROVR__r.Name, idn_auth__r.NAM_LAST__c, idn_auth__r.NAM_FIRST__c, idn_auth__r.IDN_CASE__c, idn_auth__r.IDN_CASE__r.Name, idn_auth__r.CDE_COUNTY__r.Name, 
                                  idn_period_serv__r.DTE_END_EFFV__c, idn_period_serv__r.DTE_BEGIN_EFFV__c FROM batchsit_t_sub_pmt__x 
                                  WHERE idn_pmt_sub__c = :subPaymentExtnlId AND (idn_slot_contract__c = null OR idn_slot_contract__r.idn_auth__c != null)
                                 ];
                
            }
        }
        return subPaymentList;
    }
    
    public static List<String> getPrvdrExtIds(String paymentId, String providerId, String caseId, String countyId, List<String> servicePeriodIds, String stateId, String childFirstName, String childLastName, List<String> providerIds, Boolean slotCntcheckbox) {
        Boolean doQueryPayment = false;
        List<String> externalIdsToBeReturned;
        // Rewritten to use bind variables and avoid string concatenation for dynamic SOQL
        List<String> whereParts = new List<String>();
        if (String.isNotBlank(paymentId)) {
            whereParts.add('Name = :paymentId');
            doQueryPayment = true;
        }
        // Do not mutate incoming providerIds unexpectedly; compute an effective set
        Set<String> effectiveProviderIds = new Set<String>();
        if (providerIds != null) effectiveProviderIds.addAll(providerIds);
        if (String.isNotBlank(providerId)) {
            effectiveProviderIds.add(providerId);
        }
        if (!effectiveProviderIds.isEmpty()) {
            whereParts.add('IDN_PROVR__c IN :effectiveProviderIds');
            doQueryPayment = true;
        }
        if (servicePeriodIds != null && !servicePeriodIds.isEmpty()) {
            whereParts.add('IDN_PERIOD_SERV__c IN :servicePeriodIds');
            doQueryPayment = true;
        }
        if (String.isNotBlank(countyId) && adjustmentEntrySearchFlag) {
            whereParts.add('CDE_COUNTY__c = :countyId');
        }
        if (doQueryPayment) {
            externalIdsToBeReturned = new List<String>();
            String baseQuery = 'SELECT IDN_EXTNL__c, IDN_PERIOD_SERV__r.IDN_EXTNL__c FROM T_PAYMT__c';
            if (!whereParts.isEmpty()) {
                baseQuery += ' WHERE ' + String.join(whereParts, ' AND ');
            }
            List<T_PAYMT__c> paymentBasedOnProvidedFilters = Database.query(baseQuery);
            Integer customOffset = 0, customOffsetGap = 5;
           	// Removed '100' number value and re-added Label by Rishav for CCCAP-2807
            // Integer limitForSearch = 100;
            Integer limitForSearch = Integer.valueOf(System.Label.Subpayment_Search_Limit);
            List<String> paymentIdsForThisChunk = new List<String>();
            Set<String> servicePeriodExtIdsSet = new Set<String>();
            Set<Decimal> alreadyExistingSubPaymentExternalIds = new Set<Decimal>();
            while(customOffset<paymentBasedOnProvidedFilters.size() && externalIdsToBeReturned.size() <= limitForSearch && Limits.getQueries() < 90) {       
                for(Integer i = customOffset;i<(customOffset+customOffsetGap>paymentBasedOnProvidedFilters.size()?paymentBasedOnProvidedFilters.size():customOffset+customOffsetGap);i++) {
                    paymentIdsForThisChunk.add(paymentBasedOnProvidedFilters.get(i).IDN_EXTNL__c);
                    servicePeriodExtIdsSet.add(paymentBasedOnProvidedFilters.get(i).IDN_PERIOD_SERV__r.IDN_EXTNL__c );
                }
                // Use bind variables for sub payment query
                String subPmtquery = 'SELECT idn_pmt_sub__c, idn_auth__c, idn_auth__r.Name, idn_auth__r.CDE_COUNTY__c, idn_auth__r.IDN_CASE__c, idn_auth__r.NAM_FIRST__c, idn_auth__r.NAM_LAST__c, idn_auth__r.IDN_CLIENT__r.IDN_STATE__c, idn_period_serv__c ' +
                                     'FROM batchsit_t_sub_pmt__x WHERE idn_pmt__c IN :paymentIdsForThisChunk';
                if (servicePeriodExtIdsSet != null && !servicePeriodExtIdsSet.isEmpty()) {
                    subPmtquery += ' AND idn_period_serv__c IN :servicePeriodExtIdsSet';
                }
                subPmtquery += ' LIMIT ' + limitForSearch;
                for (batchsit_t_sub_pmt__x subPayment : Database.query(subPmtquery)) {
                    if(!alreadyExistingSubPaymentExternalIds.contains(subPayment.idn_pmt_sub__c)) {
                        if(slotCntcheckbox) {
                            if(subPayment.idn_auth__c == null) {
                                externalIdsToBeReturned.add(subPayment.idn_pmt_sub__c+'');
                                alreadyExistingSubPaymentExternalIds.add(subPayment.idn_pmt_sub__c);
                                if(externalIdsToBeReturned.size()>limitForSearch) {
                                    break;
                                }
                            }
                        } else if((String.isEmpty(caseId) || (String.isNotEmpty(caseId)) && caseId == subPayment.idn_auth__r.IDN_CASE__c) 
                                  && (String.isEmpty(stateId) || (String.isNotEmpty(stateId)) && stateId == subPayment.idn_auth__r.IDN_CLIENT__r.IDN_STATE__c)
                                  && (String.isEmpty(childFirstName) || (String.isNotEmpty(childFirstName)) && childFirstName == subPayment.idn_auth__r.NAM_FIRST__c)
                                  && (String.isEmpty(childLastName) || (String.isNotEmpty(childLastName)) && childLastName == subPayment.idn_auth__r.NAM_LAST__c)
                                  && (String.isEmpty(countyId) || (String.isNotEmpty(countyId)) && countyId == subPayment.idn_auth__r.CDE_COUNTY__c)              
                                 ) {
                                     externalIdsToBeReturned.add(subPayment.idn_pmt_sub__c+'');
                                     alreadyExistingSubPaymentExternalIds.add(subPayment.idn_pmt_sub__c);
                                     if(externalIdsToBeReturned.size()>limitForSearch) {
                                         break;
                                     }
                                 }
                    }
                }
                paymentIdsForThisChunk.clear();
                servicePeriodExtIdsSet.clear();
                customOffset+= customOffsetGap;
            }
        }  
        return externalIdsToBeReturned;
    } 
    
    public static List<String> getSubPmtOrPrvdrExtIdsBasedOnAuth(String providerId, String caseId, String countyId, String stateId, String childFirstName, String childLastName, List<String> servicePeriodExtIds, Boolean needProviderIds, String selectedAuthId) {
        Boolean doQueryAuth = false;
        List<String> externalIdsToBeReturned;
        // Rewritten to use bind variables and avoid string concatenation for dynamic SOQL
        List<String> authWhere = new List<String>();
        if (String.isNotBlank(caseId)) {
            authWhere.add('IDN_CASE__c = :caseId');
            doQueryAuth = true;
        }
        if (String.isNotBlank(stateId)) {
            authWhere.add('IDN_CLIENT__r.IDN_STATE__c = :stateId');
            doQueryAuth = true;
        }
        if (String.isNotBlank(childFirstName)) {
            authWhere.add('NAM_FIRST__c = :childFirstName');
            doQueryAuth = true;
        }
        if (String.isNotBlank(childLastName)) {
            authWhere.add('NAM_LAST__c = :childLastName');
            doQueryAuth = true;
        }
        if (String.isNotBlank(countyId)) {
            authWhere.add('CDE_COUNTY__c = :countyId');
        }
        if (String.isNotBlank(providerId)) {
            authWhere.add('IDN_PROVR__c = :providerId');
        }
        if (String.isNotBlank(selectedAuthId)) {
            authWhere.add('Id = :selectedAuthId');
            doQueryAuth = true;
        }
        if (doQueryAuth) {
            externalIdsToBeReturned = new List<String>();
            String authBase = 'SELECT IDN_EXTNL__c, IDN_PROVR__c, DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c FROM T_AUTH__c';
            if (!authWhere.isEmpty()) {
                authBase += ' WHERE ' + String.join(authWhere, ' AND ');
            }
            authBase += ' order by DTE_BEGIN_EFFV_AUTH__c ASC NULLS LAST, DTE_END_EFFV_AUTH__c ASC NULLS LAST';
            List<T_AUTH__c> authBasedOnProvidedFilters = Database.query(authBase);
            if(needProviderIds) {
                if(!authBasedOnProvidedFilters.isEmpty()) {
                    if(String.isNotEmpty(providerId)) {
                        externalIdsToBeReturned.add(providerId);
                    } else {
                        for(T_AUTH__c auth:authBasedOnProvidedFilters) {
                            externalIdsToBeReturned.add(auth.IDN_PROVR__c);
                        }
                    }
                } 
                return externalIdsToBeReturned;
            }
            
            // Calculate min and max dates from all auth records
            Date minAuthBeginDate = null;
            Date maxAuthEndDate = null;
            for(T_AUTH__c auth : authBasedOnProvidedFilters) {
                if(auth.DTE_BEGIN_EFFV_AUTH__c != null && (minAuthBeginDate == null || auth.DTE_BEGIN_EFFV_AUTH__c < minAuthBeginDate)) {
                    minAuthBeginDate = auth.DTE_BEGIN_EFFV_AUTH__c;
                }
                if(auth.DTE_END_EFFV_AUTH__c != null && (maxAuthEndDate == null || auth.DTE_END_EFFV_AUTH__c > maxAuthEndDate)) {
                    maxAuthEndDate = auth.DTE_END_EFFV_AUTH__c;
                }
            }
            
            // Precompute all service periods that overlap any auth in the result set (single query)
            // Then, within each chunk, further narrow to service periods that overlap at least one auth in that chunk.
            List<T_SERV_PERIOD__c> allOverlappingServicePeriods = new List<T_SERV_PERIOD__c>();
            if (minAuthBeginDate != null || maxAuthEndDate != null) {
                String spQuery = 'SELECT IDN_EXTNL__c, DTE_BEGIN_EFFV__c, DTE_END_EFFV__c FROM T_SERV_PERIOD__c WHERE';
                if (minAuthBeginDate != null && maxAuthEndDate != null) {
                    spQuery += ' DTE_BEGIN_EFFV__c <= :maxAuthEndDate AND DTE_END_EFFV__c >= :minAuthBeginDate';
                } else if (maxAuthEndDate != null) {
                    spQuery += ' DTE_BEGIN_EFFV__c <= :maxAuthEndDate';
                } else {
                    spQuery += ' DTE_END_EFFV__c >= :minAuthBeginDate';
                }
                for (T_SERV_PERIOD__c sp : Database.query(spQuery)) {
                    // If caller supplied servicePeriodExtIds, honor it by intersecting
                    if (servicePeriodExtIds.isEmpty() || servicePeriodExtIds.contains(sp.IDN_EXTNL__c)) {
                        allOverlappingServicePeriods.add(sp);
                    }
                }
            }
            Integer customOffset = 0, customOffsetGap = 50;
            Integer limitForSearch = Integer.valueOf(System.Label.Subpayment_Search_Limit);
            Integer externalIdCount = limitForSearch - 1;
            List<String> authIdsForThisChunk = new List<String>();
            Set<Decimal> alreadyExistingSubPaymentExternalIds = new Set<Decimal>();
            while (customOffset < authBasedOnProvidedFilters.size() && externalIdsToBeReturned.size() <= limitForSearch && Limits.getQueries() < 40) {
                // Build per-chunk auth lists and compute the effective service periods for just this chunk
                Date chunkMin = null;
                Date chunkMax = null;
                authIdsForThisChunk.clear();
                for (Integer i = customOffset; i < (customOffset + customOffsetGap > authBasedOnProvidedFilters.size() ? authBasedOnProvidedFilters.size() : customOffset + customOffsetGap); i++) {
                    T_AUTH__c a = authBasedOnProvidedFilters.get(i);
                    authIdsForThisChunk.add(a.IDN_EXTNL__c);
                    if (a.DTE_BEGIN_EFFV_AUTH__c != null && (chunkMin == null || a.DTE_BEGIN_EFFV_AUTH__c < chunkMin)) {
                        chunkMin = a.DTE_BEGIN_EFFV_AUTH__c;
                    }
                    if (a.DTE_END_EFFV_AUTH__c != null && (chunkMax == null || a.DTE_END_EFFV_AUTH__c > chunkMax)) {
                        chunkMax = a.DTE_END_EFFV_AUTH__c;
                    }
                }
                // Derive filteredServicePeriodExtIds for this chunk only, based on overlap with any auth in this chunk
                Set<String> filteredServicePeriodExtIds = new Set<String>();
                if (!allOverlappingServicePeriods.isEmpty()) {
                    for (T_SERV_PERIOD__c sp : allOverlappingServicePeriods) {
                        Boolean overlaps = true;
                        if (chunkMin != null) {
                            overlaps = overlaps && (sp.DTE_END_EFFV__c >= chunkMin);
                        }
                        if (chunkMax != null) {
                            overlaps = overlaps && (sp.DTE_BEGIN_EFFV__c <= chunkMax);
                        }
                        if (overlaps) {
                            filteredServicePeriodExtIds.add(sp.IDN_EXTNL__c);
                        }
                    }
                }
                String subPaymentQuery = 'SELECT idn_pmt_sub__c, idn_auth__r.Name, idn_auth__r.IDN_PROVR__c FROM batchsit_t_sub_pmt__x WHERE idn_auth__c IN :authIdsForThisChunk';
                if (!filteredServicePeriodExtIds.isEmpty()) {
                    subPaymentQuery += ' AND idn_period_serv__c IN :filteredServicePeriodExtIds';
                }
                subPaymentQuery += ' LIMIT ' + limitForSearch;
                for (batchsit_t_sub_pmt__x subPayment : Database.query(subPaymentQuery)) {
                    if (!alreadyExistingSubPaymentExternalIds.contains(subPayment.idn_pmt_sub__c)) {
                        externalIdsToBeReturned.add(subPayment.idn_pmt_sub__c + '');
                        alreadyExistingSubPaymentExternalIds.add(subPayment.idn_pmt_sub__c);
                        if(externalIdsToBeReturned.size() > 99) {
                            break;
                        }
                    }
                }
                customOffset += customOffsetGap;
            }
        }
        return externalIdsToBeReturned;
    }
    
    public static LightningServerResponse doSearchSubPaymentForAdjustmentEntry(String paymentObjId, String subPaymentObjId, String subPaymentObjNAMFIRST, String servicePeriodObjDTEBEGINEFFV, String subPaymentObjNAMLAST, String servicePeriodObjDTEENDEFFV, T_ADJMT__c adjustmentInfo, String selectedAuthId, String selectedCaseId, String selectedSlotCntId, Boolean slotCntcheckbox) {
        String servicePeriodSubQuery;
        Date effEndDate;
        Date effBeginDate; 
        Date nulldate; 
        List<String> servicePeriodIds = new List<String>();
        List<String> servicePeriodExternalIdList = new List<String>();
        adjustmentEntrySearchFlag = false; //BG 7/30/2018 Making this flag as false to avoid County check on getPrvdrExtIds method
        // Rebuild query with bind variables and correct comparison operators
        servicePeriodSubQuery = 'SELECT IDN_EXTNL__c FROM T_SERV_PERIOD__c WHERE';
        if (String.isNotBlank(servicePeriodObjDTEENDEFFV) && String.isNotBlank(servicePeriodObjDTEBEGINEFFV)) {
            effEndDate = Date.valueOf(servicePeriodObjDTEENDEFFV);
            effBeginDate = Date.valueOf(servicePeriodObjDTEBEGINEFFV);
            if (servicePeriodSubQuery.length() != servicePeriodSubQuery.indexOf('WHERE') + 5) {
                servicePeriodSubQuery += ' AND';
            }
            servicePeriodSubQuery += ' DTE_BEGIN_EFFV__c <= :effEndDate AND DTE_END_EFFV__c >= :effBeginDate';
        } else if (String.isNotBlank(servicePeriodObjDTEENDEFFV)) {
            effEndDate = Date.valueOf(servicePeriodObjDTEENDEFFV);
            if (servicePeriodSubQuery.length() != servicePeriodSubQuery.indexOf('WHERE') + 5) {
                servicePeriodSubQuery += ' AND';
            }
            servicePeriodSubQuery += ' DTE_BEGIN_EFFV__c <= :effEndDate';
        } else if (String.isNotBlank(servicePeriodObjDTEBEGINEFFV)) {
            effBeginDate = Date.valueOf(servicePeriodObjDTEBEGINEFFV);
            if (servicePeriodSubQuery.length() != servicePeriodSubQuery.indexOf('WHERE') + 5) {
                servicePeriodSubQuery += ' AND';
            }
            servicePeriodSubQuery += ' DTE_END_EFFV__c >= :effBeginDate';
        }
        // Adding new changes for CHATS-4426 desig defect
        if(String.isEmpty(servicePeriodObjDTEENDEFFV) && String.isEmpty(servicePeriodObjDTEBEGINEFFV)) {
            if (servicePeriodSubQuery.length() != servicePeriodSubQuery.indexOf('WHERE') + 5) {
                servicePeriodSubQuery += ' AND';
            }
            // Bind local variables, not field references inline
            Date adjStart = adjustmentInfo.DTE_START_ADJMT__c;
            Date adjEnd = adjustmentInfo.DTE_END_ADJMT__c;
            servicePeriodSubQuery += ' DTE_BEGIN_EFFV__c <= :adjEnd AND DTE_END_EFFV__c >= :adjStart';
        } else if (String.isBlank(servicePeriodObjDTEBEGINEFFV)) {
            if (servicePeriodSubQuery.length() != servicePeriodSubQuery.indexOf('WHERE') + 5) {
                servicePeriodSubQuery += ' AND';
            }
            Date adjStartOnly = adjustmentInfo.DTE_START_ADJMT__c;
            servicePeriodSubQuery += ' DTE_END_EFFV__c >= :adjStartOnly';
        } else if (String.isBlank(servicePeriodObjDTEENDEFFV)) {
            if (servicePeriodSubQuery.length() != servicePeriodSubQuery.indexOf('WHERE') + 5) {
                servicePeriodSubQuery += ' AND';
            }
            Date adjEndOnly = adjustmentInfo.DTE_END_ADJMT__c;
            servicePeriodSubQuery += ' DTE_BEGIN_EFFV__c <= :adjEndOnly';
        } 
        
        if((effEndDate != nulldate || effBeginDate != nulldate) && (adjustmentInfo.DTE_END_ADJMT__c < effEndDate || adjustmentInfo.DTE_START_ADJMT__c > effBeginDate)) { 
            return new LightningServerResponse(false, 'Service Period Begin/End Dates are outside of the Care Start/End Dates of the Adjustment', null);         
        } else {
            Boolean hitApi =false;
            req = new requestParams();
            req.vacantSlotId = selectedSlotCntId;
            req.isSearchByVacantSlotContractId  = ''+slotCntcheckbox;
            req.subPymtId  = subPaymentObjId;
            
            Map<String, Object> objectData = new map<String, Object>();
            Boolean isSuccessful;
            String message = '';  
            List<T_SERV_PERIOD__c> servicePeriodIdList = Database.query(servicePeriodSubQuery);
            if(servicePeriodIdList.isEmpty()) {
                isSuccessful = false;
                if(String.isEmpty(servicePeriodObjDTEENDEFFV) && String.isEmpty(servicePeriodObjDTEBEGINEFFV)) {
                    message = 'There are no sub payment records corresponding to Care Start/End Dates of the Adjustment';
                } else {
                    message = 'There are no sub payment records corresponding to the provided Service Period Begin/End Dates';
                }
            } else {
                for(T_SERV_PERIOD__c srvsPeriod: servicePeriodIdList) {
                    servicePeriodIds.add(srvsPeriod.Id);
                    servicePeriodExternalIdList.add((String) (srvsPeriod.IDN_EXTNL__c));
                }
                String providerId = adjustmentInfo.IDN_PROVR__c, caseId = adjustmentInfo.IDN_CASE__c, countyId = adjustmentInfo.CDE_COUNTY__c;
                req.providerSfid = providerId; // added for CCCAP-9465 by Shashank
                if(String.isNotBlank(selectedCaseId)) {
                    caseId = selectedCaseId;
                }
                req.adjCountySFID = countyId;
                if(String.isNotEmpty(subPaymentObjNAMFIRST) || String.isNotEmpty(subPaymentObjNAMLAST) || String.isNotEmpty(caseId)) {
                    hitApi = true;
                    List<String> subPmtIds = new List<String>();                   
                    if(String.isNotEmpty(paymentObjId) || String.isNotEmpty(providerId)) {
                        if(String.isEmpty(subPaymentObjId)) {
                        List<String> providerIds = getSubPmtOrPrvdrExtIdsBasedOnAuth(providerId, caseId, countyId, null, subPaymentObjNAMFIRST, subPaymentObjNAMLAST, servicePeriodExternalIdList, true, selectedAuthId);   
                        System.debug('Returned providerIds:'+providerIds);
                            subPmtIds = getPrvdrExtIds(paymentObjId, providerId, caseId, countyId, servicePeriodIds, null, subPaymentObjNAMFIRST, subPaymentObjNAMLAST, providerIds, slotCntcheckbox);
                        }
                    } else {
                        if(String.isEmpty(subPaymentObjId)) {
                        subPmtIds = getSubPmtOrPrvdrExtIdsBasedOnAuth(providerId, caseId, countyId, null, subPaymentObjNAMFIRST, subPaymentObjNAMLAST, servicePeriodExternalIdList, false, selectedAuthId);   
                        }
                    }
                    req.subPymtIds = subPmtIds;
                } else if(String.isNotEmpty(paymentObjId) || String.isNotEmpty(providerId)) {
                    hitApi = true;
                    if(String.isNotEmpty(selectedAuthId)) {
                        List<String> subPaymentIds = new List<String>();
                        List<String> subPmtIds = getSubPmtOrPrvdrExtIdsBasedOnAuth(providerId, caseId, countyId, null, subPaymentObjNAMFIRST, subPaymentObjNAMLAST, servicePeriodExternalIdList, false, selectedAuthId);   
                        if(String.isNotEmpty(paymentObjId)) {
                            List<String> providerIds = getSubPmtOrPrvdrExtIdsBasedOnAuth(providerId, caseId, countyId, null, subPaymentObjNAMFIRST, subPaymentObjNAMLAST, servicePeriodExternalIdList, true, selectedAuthId);   
                            List<String> subPmtIdsTemp = getPrvdrExtIds(paymentObjId, providerId, caseId, countyId, servicePeriodIds, null, subPaymentObjNAMFIRST, subPaymentObjNAMLAST, providerIds, slotCntcheckbox);
                            Set<String> subPmtIdsTempSet = new Set<String>();
                            subPmtIdsTempSet.addAll(subPmtIdsTemp);
                            for(String sub :subPmtIds) {
                                if(subPmtIdsTempSet.contains(sub)) {
                                    subPaymentIds.add(sub);
                                }
                            }
                        } else {
                            subPaymentIds.addAll(subPmtIds);
                        } 
                        req.subPymtIds = subPaymentIds;
                    } else {
                        if(String.isEmpty(subPaymentObjId)) {
                            req.subPymtIds = getPrvdrExtIds(paymentObjId, providerId, caseId, countyId, servicePeriodIds, null, subPaymentObjNAMFIRST, subPaymentObjNAMLAST, new List<String>(), slotCntcheckbox);
                        }
                    }
                }
                req.beginDate = String.valueOf(adjustmentInfo.DTE_START_ADJMT__c);
                req.endDate = String.valueOf(adjustmentInfo.DTE_END_ADJMT__c);
                if (effBeginDate != null){
                    req.beginDate = String.valueOf(effBeginDate);
                }
                if (effEndDate != null){
                    req.endDate = String.valueOf(effEndDate);
                }
                if(hitApi && ((req.subPymtId!=''&& req.subPymtId!=null) || (req.subPymtIds!=null && req.subPymtIds.size()>0))){
                    objectData.put('SubpaymentSearchResults', hitSubpaymentWebService());
                }else{
                    objectData.put('SubpaymentSearchResults', new List<subpaymentWrapper>());
                }
                isSuccessful = true;
            }
            return new LightningServerResponse(isSuccessful, message, objectData);
        } 
    }
    public static List<subpaymentWrapper> hitSubpaymentWebService(){
        List<subpaymentWrapper> subpymntWrappers = new List<subpaymentWrapper>();
        Integer responsecode;
        try{
            List<subpaymentWrapper> responseWrap = new List<subpaymentWrapper>();
            HttpRequest httpRequest = new HttpRequest();
            Http http = new Http();
            httpRequest.setHeader('Content-type', 'application/json;charset=UTF-8');
            httpRequest.setHeader('Accept', 'application/json');
            httpRequest.setEndpoint(System.label.GetSubPymtRecords); 
            httpRequest.setMethod('POST');
            httpRequest.setTimeout(120000);
            String requestBody =  JSON.serialize(req);
            httpRequest.setBody(requestBody);
            Httpresponse response = http.send(httpRequest);
            responsecode		=	response.getStatusCode();
            string responseBody = response.getBody();
            Map<String, Object> listJson = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            if (listJson != null && listJson.containsKey('adjustmentSubPymtDetails') && listJson.get('adjustmentSubPymtDetails') != null) {
                subpymntWrappers = (List<subpaymentWrapper>) JSON.deserialize(JSON.serialize(listJson.get('adjustmentSubPymtDetails')), List<subpaymentWrapper>.class);
            } else {
                // unexpected payload shape; keep empty list and log in error branches below if status != 200
            }
            if(response != null && response.getStatusCode() != 200){
                ExceptionLoggingServices.captureExceptionLog(response, httpRequest, new Map<String,Object>{'Class__c'=>'SubPaymentSearchApxCtrl','Method__c'=>'hitSubpaymentWebService'});
                if(throwException){
                    throw new My1Exception(response.getBody());
                }
            }
        }catch (System.CalloutException e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'SubPaymentSearchApxCtrl','Method__c'=>'hitSubpaymentWebService'});
            if(throwException){
                throw e;
            }
        }catch(Exception ex) {
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'SubPaymentSearchApxCtrl','Method__c'=>'hitSubpaymentWebService'});             
            if(throwException){
                throw ex;
            }
        }
        return subpymntWrappers;
    }
    public class requestParams {
        public List<string> subPymtIds;
        public string subPymtId;
        public String vacantSlotId;
        public String adjCountySFID;
        public String providerSfid; // added for CCCAP-9465 by Shashank
        public String isSearchByVacantSlotContractId;
        public String beginDate;
        public String endDate;
    }
    public class subpaymentWrapper{
        @auraEnabled
        public String ExternalId;
        @auraEnabled
        public String pymtSFID;
        @auraEnabled
        public String pymtId;
        @auraEnabled
        public String paymentProviderSFID;
        @auraEnabled
        public String paymentProviderName;
        @auraEnabled
        public String paymentCountySFID;
        @auraEnabled
        public String paymentCountyName;
        @auraEnabled
        public String paymentDatePaid;
        @auraEnabled
        public String subPymtId;
        @auraEnabled
        public Integer nbrSeqHist;
        @auraEnabled
        public String subPymtStatus;
        @auraEnabled
        public decimal subPymtAmount;
        @auraEnabled
        public decimal subPymtSlotContractAmt;
        @auraEnabled
        public decimal subPymtCopayAmt;
        @auraEnabled
        public decimal subPymtAmtRate;
        @auraEnabled
        public String authSFID;
        @auraEnabled
        public String authid;
        @auraEnabled
        public String authProvSFID;
        @auraEnabled
        public String authProvName;
        @auraEnabled
        public String childLastName;
        @auraEnabled
        public String childFirstName;
        @auraEnabled
        public String caseSFID;
        @auraEnabled
        public String caseId;
        @auraEnabled
        public String county;
        @auraEnabled
        public String authCountySFID;
        @auraEnabled
        public String servicePeriodEndDte;
        @auraEnabled
        public String servicePeriodBgnDte;
        @auraEnabled
        public String slotSFID;
        @auraEnabled
        public String slotName;
        @auraEnabled
        public String slotCountySFID;
        @auraEnabled
        public String slotCountyName;
        @auraEnabled
        public String slotBeginDte;
        @auraEnabled
        public String slotEndDte;
    }
}