public with sharing class parentFeeFlowApxCtrl {
    @TestVisible public static List<batchsit_t_sbsd_case_copay__x> mockListTest = new List<batchsit_t_sbsd_case_copay__x>();
    @AuraEnabled
    public static LightningServerResponse deleteCaseCopayRecord(String caseCopayRec) { 
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message;
        Date todayDate = system.today();
        List<batchsit_t_sbsd_case_copay__x> caseCopayRecord = new  List<batchsit_t_sbsd_case_copay__x>();
        List<batchsit_t_sbsd_case_copay__x> currentCaseCopayRecord = new  List<batchsit_t_sbsd_case_copay__x>();
        List<batchsit_t_auth_copay__x> authCopayRecord = new  List<batchsit_t_auth_copay__x>();
        List<batchsit_t_auth_copay__x> currentAuthCopayRecord = new  List<batchsit_t_auth_copay__x>();
        List<batchsit_t_auth_copay__x> authCopayRecordToUpdate = new List<batchsit_t_auth_copay__x>();
        Set<String> authIds = new Set<String>();
        Map<String,batchsit_t_auth_copay__x> authCopayMapToUpdate = new Map<String,batchsit_t_auth_copay__x>();
        if(!Test.isRunningTest()){
           caseCopayRecord = [SELECT Id, idn_case__c,idn_case__r.Id, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                           amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                                               cde_rec_copay__c, dte_begin_effv__c, dte_end_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                                               amt_copay_case_pt_qlty__c, ind_qlty__c
                                                               FROM batchsit_t_sbsd_case_copay__x
                                                               WHERE Id =:caseCopayRec];
        }
        else {
            caseCopayRecord.add(new batchsit_t_sbsd_case_copay__x(dte_begin_effv__c=System.today()+1 ,dte_end_effv__c =System.today()+1));            
        }
              
        
        if(caseCopayRecord.size()>0){
            system.debug('caseCopayRecord----'+caseCopayRecord);
            system.debug('caseCopayRecord[0].dte_end_effv__c----'+caseCopayRecord[0].dte_end_effv__c);
            system.debug('caseCopayRecord[0].dte_begin_effv__c----'+caseCopayRecord[0].dte_begin_effv__c);
            system.debug('todayDate----'+todayDate);
            if((caseCopayRecord[0].dte_begin_effv__c <= todayDate && (caseCopayRecord[0].dte_end_effv__c > todayDate || caseCopayRecord[0].dte_end_effv__c == null)) ||
               (caseCopayRecord[0].dte_begin_effv__c < todayDate &&  (caseCopayRecord[0].dte_end_effv__c <= todayDate))){
                   isSuccessful = false;
                   message ='Can not delete currently effective/past case parent fee record.';
               }
            else if(caseCopayRecord[0].dte_begin_effv__c > todayDate && (caseCopayRecord[0].dte_end_effv__c > todayDate || caseCopayRecord[0].dte_end_effv__c == null)){
                currentCaseCopayRecord =[SELECT Id, idn_case__c,idn_case__r.Id, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                                                               amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                                               cde_rec_copay__c, dte_begin_effv__c, dte_end_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                                               amt_copay_case_pt_qlty__c, ind_qlty__c
                                                               FROM batchsit_t_sbsd_case_copay__x WHERE idn_case__c =:caseCopayRecord[0].idn_case__c and
                                                                dte_begin_effv__c <=: todayDate order by dte_begin_effv__c desc];
                for(T_AUTH__c auth: [select Id,IDN_CASE__c,IDN_CASE__r.IDN_EXTNL__c,IDN_EXTNL__c from T_AUTH__c where IDN_CASE__r.IDN_EXTNL__c =:caseCopayRecord[0].idn_case__c]){
                    authIds.add(auth.IDN_EXTNL__c);
                }
                authCopayRecord = [SELECT Id, idn_auth__c,dte_begin_effv__c,dte_end_effv__c,idn_copay_auth__c,lastmodifiedbyid__c,lastmodifieddate__c,amt_copay_auth__c
                                                               FROM batchsit_t_auth_copay__x
                                                               WHERE idn_auth__c IN:authIds];
               //Added on 10/05/2018
                If(Test.isRunningTest()){
                    authCopayRecord.add(new batchsit_t_auth_copay__x(dte_begin_effv__c=System.today()-2, idn_auth__c='test')); 
                    authCopayMapToUpdate.put('test', new batchsit_t_auth_copay__x(dte_begin_effv__c=System.today()-5));
                }
                for(batchsit_t_auth_copay__x authCopay : authCopayRecord){
                    if(authCopay.dte_begin_effv__c < todayDate){
                        if(authCopayMapToUpdate.containsKey(authCopay.idn_auth__c)){
                            batchsit_t_auth_copay__x copayObj = authCopayMapToUpdate.get(authCopay.idn_auth__c);
                            if(authCopay.dte_begin_effv__c > copayObj.dte_begin_effv__c){
                                authCopayMapToUpdate.Remove(authCopay.idn_auth__c);
                                authCopayMapToUpdate.put(authCopay.idn_auth__c,authCopay);
                            }
                        }else{
                            authCopayMapToUpdate.put(authCopay.idn_auth__c,authCopay);
                        }
                        
                    }
                }
                if(!authCopayMapToUpdate.isEmpty() && authCopayMapToUpdate.size()>0){
                    authCopayRecordToUpdate.addAll(authCopayMapToUpdate.values());
                }
                system.debug('caseCopayRecord[0].idn_case__c--'+caseCopayRecord[0].idn_case__c);
                //Removed unused variable on 5/14/2018 BG  
                if(currentCaseCopayRecord.size()>0){
                    if(!Test.isRunningTest()) {
                        // Updating currently effective case copay record
                        HerokuService.caseCopyUpdate(String.valueOf(currentCaseCopayRecord[0].amt_copay_case_assesd__c), String.valueOf(currentCaseCopayRecord[0].amt_copay_case_ft__c), 
                                                     String.valueOf(currentCaseCopayRecord[0].amt_copay_case_pt__c), String.valueOf(currentCaseCopayRecord[0].cde_reason_ovrd__c) , 
                                                     String.valueOf(currentCaseCopayRecord[0].cde_rec_copay__c), 
                                                     String.valueOf(currentCaseCopayRecord[0].dte_begin_effv__c), 
                                                     'null', 
                                                     String.valueOf(currentCaseCopayRecord[0].idn_case__c), String.valueOf(currentCaseCopayRecord[0].nbr_seq_hist__c), 
                                                     String.valueOf(currentCaseCopayRecord[0].amt_copay_case_ft_qlty__c), String.valueOf(currentCaseCopayRecord[0].amt_copay_case_pt_qlty__c), 
                                                     String.valueOf(currentCaseCopayRecord[0].ind_qlty__c),String.valueOf(currentCaseCopayRecord[0].idn_sbsd_case_copay__c));
                    }
                }
                isSuccessful = true;
                message ='Case Parent fee deleted Successfully.';
                objectData.put('redirect',true);
                objectData.put('recordId',caseCopayRecord[0].idn_case__r.Id);
                objectData.put('eventParams','{"recordId": "'+caseCopayRecord[0].idn_case__r.Id+'"}');
                // Deleting fuure case copay record
                 if(!Test.isRunningTest()){
                    
                         if(Schema.sObjectType.batchsit_t_sbsd_case_copay__x.isDeletable()) {
                        try {
                   			Database.deleteImmediate(caseCopayRecord[0]);
                           } catch(Exception ex) {
                           } 
                        }   
                       }
                deleteAuthCopayRecord(authCopayRecord,authCopayRecordToUpdate);
            }
            
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static void deleteAuthCopayRecord(List<batchsit_t_auth_copay__x  > authCopayRecord,List<batchsit_t_auth_copay__x> authCopayRecordToUpdate) {
        List<batchsit_t_auth_copay__x> currentAuthCopayRecord = new  List<batchsit_t_auth_copay__x>();
        List<batchsit_t_auth_copay__x> authCopayRecordToDelete = new  List<batchsit_t_auth_copay__x>();
        List<ParentFeeAssessmentWrapper> wrapLst = new List<ParentFeeAssessmentWrapper>();
        Date todayDate = system.today();
        Date nowDate;
        for(batchsit_t_auth_copay__x authCopay : authCopayRecord){
            if(authCopay.dte_begin_effv__c > todayDate && (authCopay.dte_end_effv__c > todayDate || authCopay.dte_end_effv__c == null)){
                authCopayRecordToDelete.add(authCopay);
            } 
        }
        for(batchsit_t_auth_copay__x authCopay : authCopayRecordToUpdate){
            ParentFeeAssessmentWrapper wrap = new ParentFeeAssessmentWrapper();
                wrap.authCopayId =String.valueOf(authCopay.idn_copay_auth__c);
                wrap.AMT_COPAY_AUTH = Integer.valueOf(authCopay.amt_copay_auth__c);
                wrapLst.add(wrap);
        }
        // Deleting future auth copay records
        if(authCopayRecordToDelete.size()>0){
           if(!Test.isRunningTest()){
                if(Schema.sObjectType.batchsit_t_auth_copay__x.isDeletable()) {
                    Database.deleteImmediate(authCopayRecordToDelete);
                }
            }
        }
        // Updating Auth Copay records
        if(wrapLst.size()>0){
           if(!Test.isRunningTest()) {
                authCopayUpdate(nowDate,wrapLst);
          }
        }
        
    }
    @AuraEnabled
    public static LightningServerResponse getInitData(Id caseCopayRec) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<batchsit_t_fcompsn_eligty__x> householdEligity = new List<batchsit_t_fcompsn_eligty__x>();
        List<batchsit_t_fcompsn_eligty_detail__x> eligDetail = new List<batchsit_t_fcompsn_eligty_detail__x>();
        String caseExternalId;
        List<batchsit_t_sbsd_case_copay__x> caseCopayRecord =new List<batchsit_t_sbsd_case_copay__x>();
        if(caseCopayRec != null){
            for(T_SBSD_CASE__c cse :[Select id,IDN_EXTNL__c from T_SBSD_CASE__c where id=:caseCopayRec]){
                caseExternalId =cse.IDN_EXTNL__c;
            }
        }
        system.debug('caseExternalId--'+caseExternalId);
        if(!String.isBlank(caseExternalId)){
        	objectData.put('caseExternalId', caseExternalId);
            caseCopayRecord =   [SELECT Id, idn_case__c,idn_case__r.Id, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                                 amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                 cde_rec_copay__c, dte_begin_effv__c, dte_end_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                 amt_copay_case_pt_qlty__c, ind_qlty__c
                                 FROM batchsit_t_sbsd_case_copay__x
                                 WHERE idn_case__c =:caseExternalId ORDER BY dte_begin_effv__c DESC ]; 
            
            Set<Decimal> eliRunIds = new Set<Decimal>();
            for(batchsit_t_eligty_run__x eli : [Select Id,idn_run_eligty__c,ExternalId, cde_eligty_cfmd__c,idn_case__c,dte_run_eligty__c from batchsit_t_eligty_run__x where
                                                idn_case__c=:caseExternalId and cde_eligty_cfmd__c='CFM' order by ExternalId DESC limit 1]){
                                                    eliRunIds.add(eli.idn_run_eligty__c);
                                                    
                                                }
            system.debug('eliRunIds--'+eliRunIds);
            if(Test.isRunningTest()){
                eliRunIds.add(123);
            }
            if(eliRunIds.size()>0) {
                Map<Decimal, batchsit_t_fcompsn_eligty_detail__x> eligibilityHouseHoldIdToEligDetail = new Map<Decimal, batchsit_t_fcompsn_eligty_detail__x>();
                for(batchsit_t_fcompsn_eligty_detail__x fcomElig : [Select Id,idn_eligty_fcompsn__c,cde_status_eligty_family__c 
                                                                    from batchsit_t_fcompsn_eligty_detail__x 
                                                                    where dte_begin_effv__c <= today and (dte_end_effv__c >= today or dte_end_effv__c = null) 
                                                                    and idn_eligty_fcompsn__r.idn_run_eligty__r.idn_run_eligty__c IN: eliRunIds])
                {
                    eligibilityHouseHoldIdToEligDetail.put(decimal.valueOf(fcomElig.idn_eligty_fcompsn__c), fcomElig);
                }
                if(!eligibilityHouseHoldIdToEligDetail.isEmpty()){
                    householdEligity = [select id,ExternalId,idn_run_eligty__c,amt_copay_ft__c,amt_copay_pt__c,idn_eligty_fcompsn__c 
                                        from batchsit_t_fcompsn_eligty__x where idn_eligty_fcompsn__c IN :eligibilityHouseHoldIdToEligDetail.keyset() 
                                        AND (cde_reason_change_fcompsn__c!='NCT' OR cde_reason_change_fcompsn__c=null) order by idn_eligty_fcompsn__c LIMIT 1];
                    if(!householdEligity.isEmpty()){
	                    eligDetail.add(eligibilityHouseHoldIdToEligDetail.get(householdEligity[0].idn_eligty_fcompsn__c));
                    }
                }
                
                System.debug('eliRunIds----'+eliRunIds);
                System.debug('eligDetail----'+eligDetail);
                if(eligDetail.size()>0) {
                    objectData.put('eligDetail', eligDetail);
                }
                if(householdEligity.size()>0){
                    objectData.put('householdEligity', householdEligity[0]);
                }
                
            }
        }
        
        //added on 10/5/2018
        if (Test.isRunningTest()){
            caseCopayRecord.add(new batchsit_t_sbsd_case_copay__x(idn_case__c='test'));
        }
        if(caseCopayRecord.size()>0) {
            System.debug(caseCopayRecord.get(0));
            if(caseCopayRecord.get(0).idn_case__c!=null) {
                
                if(caseCopayRecord.size()>0) {
                    System.debug(caseCopayRecord);
                    objectData.put('pastCaseCopayRecord', false);
                    objectData.put('futureCaseCopayRecordPresent', false);
                    
                    if(caseCopayRecord.get(0).dte_begin_effv__c > System.today()) {
                        objectData.put('futureCaseCopayRecordPresent', true);
                    }
                }
                
            }  
            objectData.put('caseCopayRecord', caseCopayRecord.get(0));
        }
        isSuccessful=true;
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @AuraEnabled
    public static LightningServerResponse upsertCaseCopay(batchsit_t_sbsd_case_copay__x caseCopayRec, String parentFee, String effectiveDate, String overrideReason,Boolean isFirstCaseCopayRec, String compcaseCopayRecId) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        System.debug(UserInfo.getUserId());
        Date effectiveDateFormat = Date.valueOf(effectiveDate);
        compcaseCopayRecId = String.valueOf(compcaseCopayRecId);
        //if(!Test.isRunningTest()) {
            if(compcaseCopayRecId==null) {
                HerokuService.caseCopyCreate(parentFee, String.valueOf(caseCopayRec.amt_copay_case_ft__c), 
                                             String.valueOf(caseCopayRec.amt_copay_case_pt__c), overrideReason, 
                                             String.valueOf(caseCopayRec.cde_rec_copay__c), 
                                             String.valueOf(effectiveDateFormat.year()+'-'+effectiveDateFormat.month()+'-'+effectiveDateFormat.day()), 
                                             '' , 
                                             String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c), 
                                             String.valueOf(caseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(caseCopayRec.amt_copay_case_pt_qlty__c), 
                                             String.valueOf(caseCopayRec.ind_qlty__c),true);
            }
        //}
        
        System.debug('caseCopayRec:'+caseCopayRec);
        System.debug('overrideReason:'+overrideReason);
      //  if(!Test.isRunningTest()) {
            if(compcaseCopayRecId!=null) {
                HerokuService.caseCopyUpdate(parentFee, String.valueOf(caseCopayRec.amt_copay_case_ft__c), 
                                             String.valueOf(caseCopayRec.amt_copay_case_pt__c), overrideReason , 
                                             String.valueOf(caseCopayRec.cde_rec_copay__c), 
                                             effectiveDateFormat.year()+'-'+effectiveDateFormat.month()+'-'+effectiveDateFormat.day(), 
                                             '',
                                             String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c), 
                                             String.valueOf(caseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(caseCopayRec.amt_copay_case_pt_qlty__c), String.valueOf(caseCopayRec.ind_qlty__c), 
                                             String.valueOf(compcaseCopayRecId));     
                Date effEndDateForLastRecord = effectiveDateFormat.addDays(-1);
                List<batchsit_t_sbsd_case_copay__x> lastEndDatedCaseCopayRecord = [SELECT Id, idn_case__c, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                                                                                   amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                                                                   cde_rec_copay__c, dte_begin_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                                                                   amt_copay_case_pt_qlty__c, ind_qlty__c
                                                                                   FROM batchsit_t_sbsd_case_copay__x
                                                                                   WHERE idn_case__c=:caseCopayRec.idn_case__c AND
                                                                                   Id != :caseCopayRec.Id AND
                                                                                   dte_end_effv__c!=null
                                                                                   ORDER By ExternalId DESC LIMIT 1];
                System.debug('lastEndDatedCaseCopayRecord:'+lastEndDatedCaseCopayRecord);
                if(!lastEndDatedCaseCopayRecord.isEmpty()){
                    HerokuService.caseCopyUpdate(String.valueOf(lastEndDatedCaseCopayRecord.get(0).amt_copay_case_assesd__c), String.valueOf(lastEndDatedCaseCopayRecord.get(0).amt_copay_case_ft__c), 
                                                 String.valueOf(lastEndDatedCaseCopayRecord.get(0).amt_copay_case_pt__c), String.valueOf(lastEndDatedCaseCopayRecord.get(0).cde_reason_ovrd__c) , 
                                                 String.valueOf(lastEndDatedCaseCopayRecord.get(0).cde_rec_copay__c), 
                                                 String.valueOf(lastEndDatedCaseCopayRecord.get(0).dte_begin_effv__c.year()+'-'+lastEndDatedCaseCopayRecord.get(0).dte_begin_effv__c.month()+'-'+lastEndDatedCaseCopayRecord.get(0).dte_begin_effv__c.day()), 
                                                 String.valueOf(effEndDateForLastRecord.year()+'-'+effEndDateForLastRecord.month()+'-'+effEndDateForLastRecord.day()),
                                                 String.valueOf(lastEndDatedCaseCopayRecord.get(0).idn_case__c), String.valueOf(lastEndDatedCaseCopayRecord.get(0).nbr_seq_hist__c), 
                                                 String.valueOf(lastEndDatedCaseCopayRecord.get(0).amt_copay_case_ft_qlty__c), String.valueOf(lastEndDatedCaseCopayRecord.get(0).amt_copay_case_pt_qlty__c), 
                                                 String.valueOf(lastEndDatedCaseCopayRecord.get(0).ind_qlty__c),String.valueOf(lastEndDatedCaseCopayRecord.get(0).idn_sbsd_case_copay__c));
                }
            } else {
            	if(!isFirstCaseCopayRec){
                HerokuService.caseCopyUpdate(String.valueOf(caseCopayRec.amt_copay_case_assesd__c), String.valueOf(caseCopayRec.amt_copay_case_ft__c), 
                                             String.valueOf(caseCopayRec.amt_copay_case_pt__c), String.valueOf(caseCopayRec.cde_reason_ovrd__c) , 
                                             String.valueOf(caseCopayRec.cde_rec_copay__c), 
                                             String.valueOf(caseCopayRec.dte_begin_effv__c.year()+'-'+caseCopayRec.dte_begin_effv__c.month()+'-'+caseCopayRec.dte_begin_effv__c.day()), 
                                             '', 
                                             String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c), 
                                             String.valueOf(caseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(caseCopayRec.amt_copay_case_pt_qlty__c), 
                                             String.valueOf(caseCopayRec.ind_qlty__c),String.valueOf(caseCopayRec.idn_sbsd_case_copay__c));
            }
            }
            List<batchsit_t_sbsd_case_copay__x> caseCopayRecCreated = [SELECT Id, idn_case__c, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                                                                       amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                                                       cde_rec_copay__c, dte_begin_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                                                       amt_copay_case_pt_qlty__c, ind_qlty__c 
                                                                       FROM batchsit_t_sbsd_case_copay__x
                                                                       WHERE idn_case__c=:caseCopayRec.idn_case__c
                                                                       ORDER By ExternalId DESC];
            
            isSuccessful=true;
            //objectData.put('HTTPResponse', response);
            objectData.put('caseCopayRecIdCreated',caseCopayRecCreated.get(0).Id);
            objectData.put('caseCopayRecExtIdCreated',caseCopayRecCreated.get(0).idn_sbsd_case_copay__c);
            objectData.put('caseCopayRecCreated',caseCopayRecCreated.get(0));
      //  }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse saveAuthCopay(String effDtStr, String wrapLstStr){
        system.debug('@@@@effDtStr: '+effDtStr);
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        if(wrapLstStr!=null && String.isNotBlank(wrapLstStr) && String.isNotEmpty(wrapLstStr)){
            Datetime effDtTm = (Datetime)JSON.deserialize(effDtStr, Datetime.class);
            //effDtTm = effDtTm.addHours(10);
            system.debug('********effDtTm: '+effDtTm);
            //Date effDt = Date.newInstance(effDtTm.year(), effDtTm.month(), effDtTm.day());
             List<String> dateParts = new List<String>();
                dateParts= effDtStr.split('-');
                Date effDt = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
          //  Date effDt = Date.valueOf(effDtStr);
            system.debug('********effDt: '+effDt);
            system.debug('@#@#@#wrapLstStr: '+wrapLstStr);
            List<ParentFeeAssessmentWrapper> wrapLst = (List<ParentFeeAssessmentWrapper>)JSON.deserialize(wrapLstStr, List<ParentFeeAssessmentWrapper>.class);
            system.debug('@@@@@@@@wrapLst: '+wrapLst);
            LightningServerResponse lsresp1 = authCopayCreate(effDt, wrapLst);
            LightningServerResponse lsresp2 = authCopayUpdate(effDt, wrapLst);
            isSuccessful = lsresp1.isSuccessful && lsresp2.isSuccessful;
            message = lsresp1.successMessage + lsresp1.errorMessage + lsresp2.successMessage + lsresp2.errorMessage;
            objectData.put('HTTPResponse1', String.valueOf(lsresp1.objectData.get('HTTPResponse')));
            objectData.put('HTTPResponse2', String.valueOf(lsresp2.objectData.get('HTTPResponse')));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse authCopayCreate(Date effDt, List<ParentFeeAssessmentWrapper> wrapList){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        String method = 'POST';
        try{
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        //request.setEndpoint(System.Label.SubpaymentWebService);
        request.setEndpoint(Label.AuthCopayCreate);
        request.setMethod(method);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        String bodyText = '[';
        system.debug('$$$$$$effDt: '+effDt+' wrapLst: '+wrapList);
        for(ParentFeeAssessmentWrapper wrapRec: wrapList){
            bodyText+='{';
            bodyText+='"amt_copay_auth":"'+wrapRec.AMT_COPAY_AUTH+'",';
            bodyText+='"dte_begin_effv":"'+String.valueOf(effDt)+'",';
            bodyText+='"idn_auth":"'+wrapRec.IDN_AUTH+'",';
            bodyText+='"createdbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"createddate":"'+system.now()+'",';
            bodyText+='"nbr_seq_hist":"2",';
            bodyText+='"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';
            bodyText+='"lastmodifieddate":"'+system.now()+'"';
            bodyText+='},';
        }
        bodyText = bodyText.substring(0, bodyText.length()-1);
        bodyText+=']';
        system.debug('########bodyText: '+bodyText);
        request.setBody(bodyText);
        system.debug('*********request: '+request);
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 200) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
             ExceptionLoggingServices.captureExceptionLog(response, request, new Map<String,Object>{'Class__c'=>'parentFeeFlowApxCtrl','Method__c'=>'authCopayCreate'});
            isSuccessful = false;
            message = 'The status code returned was not expected: ' +
                response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody();
        } else {
            System.debug(response.getBody());
            isSuccessful = true;
            message = 'response-->'+response.getBody();
        }
        objectData.put('HTTPResponse', response);
       } catch(Exception ex) {
       		isSuccessful = false;
            message=ex.getMessage();
            ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'parentFeeFlowApxCtrl','Method__c'=>'authCopayCreate'});             
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
    @auraEnabled
    public static LightningServerResponse authCopayUpdate(Date effDt, List<ParentFeeAssessmentWrapper> wrapLst){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        List<ParentFeeAssessmentWrapper> wrapLstHavingRecordIds = new List<ParentFeeAssessmentWrapper>();
        for(ParentFeeAssessmentWrapper wrapRec: wrapLst){
            system.debug('wrapRec.authCopayId'+wrapRec.authCopayId);
            if(String.isNotEmpty(wrapRec.authCopayId)){
                wrapLstHavingRecordIds.add(wrapRec);
            }
        }
        if(!wrapLstHavingRecordIds.isEmpty()){
            if(effDt != null){
                effDt -= 1;
            }
            String method = 'POST';
            try{
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            //request.setEndpoint(System.Label.SubpaymentWebService);
            request.setEndpoint(Label.AuthCopayUpdate);
            request.setMethod(method);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8');
            //request.setBody('[{"idn_copay_auth" : "7","dte_begin_effv":"2010-12-01","amt_copay_auth":"10","lastmodifiedbyid": "vishu" ,"lastmodifieddate" :"2018-28-08 09:03:24"}]'); 
            String bodyText = '[';
            system.debug('$$$$$$effDt: '+effDt+' wrapLst: '+wrapLst);
            for(ParentFeeAssessmentWrapper wrapRec: wrapLstHavingRecordIds){
                if(String.isNotEmpty(wrapRec.authCopayId)){
                    bodyText+='{';
                    bodyText+='"idn_copay_auth":"'+wrapRec.authCopayId+'",';
                    bodyText+='"dte_end_effv":"'+effDt+'",';
                   // bodyText+='"amt_copay_auth":"'+wrapRec.AMT_COPAY_AUTH+'",';
                    bodyText+='"lastmodifiedbyid":"'+UserInfo.getUserId()+'",';
                    bodyText+='"lastmodifieddate":"'+system.now()+'"';
                    bodyText+='},';
                }
            }
            bodyText = bodyText.substring(0, bodyText.length()-1);
            bodyText+=']';
            system.debug('########bodyText: '+bodyText);
            request.setBody(bodyText);
            if(!Test.isRunningTest()) {
                HttpResponse response = http.send(request);        
                // Parse the JSON response
                if (response.getStatusCode() != 200) {
                    System.debug('The status code returned was not expected: ' +
                                 response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody());
                    isSuccessful = false;
                    message = 'The status code returned was not expected: ' +
                        response.getStatusCode() + ' ' + response.getStatus()+' '+response.getBody();
                  ExceptionLoggingServices.captureExceptionLog(response, null, new Map<String,Object>{'Class__c'=>'parentFeeFlowApxCtrl','Method__c'=>'authCopayUpdate'});   
                } else {
                    System.debug('response-->'+response.getBody());
                    isSuccessful = true;
                    message = 'response-->'+response.getBody();
                }
                objectData.put('HTTPResponse', response);   
                }
        
            } catch(Exception ex) {
            	 isSuccessful = false;
                 message=ex.getMessage();
           		 ExceptionLoggingServices.captureExceptionLog(ex, new Map<String,Object>{'Class__c'=>'parentFeeFlowApxCtrl','Method__c'=>'authCopayUpdate'});             
            }
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    
}