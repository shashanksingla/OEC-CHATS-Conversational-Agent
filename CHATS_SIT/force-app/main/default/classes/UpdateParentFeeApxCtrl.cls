public with sharing class UpdateParentFeeApxCtrl {
    
    @AuraEnabled
    public static LightningServerResponse saveCaseCopayRecord(batchsit_t_sbsd_case_copay__x caseCopayRec, String parentFee, String effectiveDate, String overrideReason,
                                                              Boolean isFirstCaseCopayRec,batchsit_t_sbsd_case_copay__x newCaseCopayRec) {
                                                                  Map<String, Object> objectData = new map<String, Object>();
                                                                  Boolean isSuccessful=true;
                                                                  String message;
                                                                  Date effectiveDateFormat = Date.valueOf(effectiveDate);
                                                                  String month = String.valueOf(effectiveDateFormat.month());
                                                                  String day =String.valueOf(effectiveDateFormat.day());
                                                                    List<batchsit_t_sbsd_case_copay__x> caseCopayRecCreated = new List<batchsit_t_sbsd_case_copay__x>();
                                                                  if(month.length()==1){
                                                                      month = '0'+month;
                                                                  }
                                                                  if(day.length()==1){
                                                                      day = '0'+day;
                                                                  }
                                                                  try{
                                                                      if(isFirstCaseCopayRec){
                                                                          HttpResponse createResponse = HerokuService.caseCopyCreate(parentFee, String.valueOf(newCaseCopayRec.amt_copay_case_ft__c), 
                                                                                                                                     String.valueOf(newCaseCopayRec.amt_copay_case_pt__c), overrideReason, 
                                                                                                                                     String.valueOf(newCaseCopayRec.cde_rec_copay__c), 
                                                                                                                                     String.valueOf(effectiveDateFormat.year()+'-'+month+'-'+day), 
                                                                                                                                     '' , 
                                                                                                                                     String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c), 
                                                                                                                                     String.valueOf(newCaseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(newCaseCopayRec.amt_copay_case_pt_qlty__c), 
                                                                                                                                     String.valueOf(newCaseCopayRec.ind_qlty__c),false);  
                                                                          if(createResponse != null && createResponse.getStatusCode()==200){
                                                                              String errorMessage = '';
                                                                              Map<String,Object> mapDataForEachResult= (Map<String,Object>)JSON.deserializeUntyped(createResponse.getBody());
                                                                              if(mapDataForEachResult.containsKey('successInd') && mapDataForEachResult.get('successInd')!='Y' && mapDataForEachResult.containsKey('errMessage') && mapDataForEachResult.get('errMessage')!=null){
                                                                                  errorMessage+=mapDataForEachResult.get('errMessage')+',';
                                                                              }
                                                                              if(String.isNotEmpty(errorMessage)){
                                                                                  errorMessage = errorMessage.removeEnd(',');
                                                                                  objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, 'Create Case Parent Fee failed:'+errorMessage));
                                                                                  objectData.put('title','Create Case Parent Fee Failed');
                                                                                  objectData.put('isSuccessful',false);
                                                                                  objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessage);
                                                                              }else{
                                                                                  objectData.put('isSuccessful',true);
                                                                                  caseCopayRecCreated = [SELECT Id, idn_case__c, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                                                                                                         amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                                                                                         cde_rec_copay__c, dte_begin_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                                                                                         amt_copay_case_pt_qlty__c, ind_qlty__c 
                                                                                                         FROM batchsit_t_sbsd_case_copay__x
                                                                                                         WHERE idn_case__c=:caseCopayRec.idn_case__c
                                                                                                         ORDER By ExternalId DESC];
                                                                              }
                                                                          }else{
                                                                              objectData.put('title','Something unexpected happened!!');
                                                                              objectData.put('description',createResponse.getBody());
                                                                              objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, createResponse.getBody()));
                                                                          }
                                                                          
                                                                      }
                                                                      else{
                                                                         if(caseCopayRec.dte_begin_effv__c != effectiveDateFormat || ((caseCopayRec.dte_begin_effv__c >=caseCopayRec.dte_end_effv__c)))
                                                                         {
                                                                              HttpResponse createResponse =  HerokuService.caseCopyCreate(parentFee, String.valueOf(newCaseCopayRec.amt_copay_case_ft__c), 
                                                                                                                                          String.valueOf(newCaseCopayRec.amt_copay_case_pt__c), overrideReason, 
                                                                                                                                          String.valueOf(newCaseCopayRec.cde_rec_copay__c), 
                                                                                                                                          String.valueOf(effectiveDateFormat.year()+'-'+month+'-'+day), 
                                                                                                                                          '' , 
                                                                                                                                          String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c), 
                                                                                                                                          String.valueOf(newCaseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(newCaseCopayRec.amt_copay_case_pt_qlty__c), 
                                                                                                                                          String.valueOf(newCaseCopayRec.ind_qlty__c),false);
                                                                              if(createResponse != null && createResponse.getStatusCode()==200){
                                                                                  String errorMessage = '';
                                                                                  Map<String,Object> mapDataForEachResult= (Map<String,Object>)JSON.deserializeUntyped(createResponse.getBody());
                                                                                  if(mapDataForEachResult.containsKey('successInd') && mapDataForEachResult.get('successInd')!='Y' && mapDataForEachResult.containsKey('errMessage') && mapDataForEachResult.get('errMessage')!=null){
                                                                                      errorMessage+=mapDataForEachResult.get('errMessage')+',';
                                                                                  }
                                                                                  if(String.isNotEmpty(errorMessage)){
                                                                                      errorMessage = errorMessage.removeEnd(',');
                                                                                      objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, 'Create Case Parent Fee failed:'+errorMessage));
                                                                                      objectData.put('title','Create Case Parent Fee Failed');
                                                                                      objectData.put('isSuccessful',false);
                                                                                      objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessage);
                                                                                  }else{
                                                                                      List<string> parentFeeIds = new List<String>();
                                                                                      caseCopayRecCreated = [SELECT Id, idn_case__c, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                                                                                                             amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                                                                                             cde_rec_copay__c, dte_begin_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                                                                                             amt_copay_case_pt_qlty__c, ind_qlty__c ,
                                                                                                             externalId
                                                                                                             FROM batchsit_t_sbsd_case_copay__x
                                                                                                             WHERE idn_case__c=:caseCopayRec.idn_case__c
                                                                                                             ORDER By ExternalId DESC];
                                                                                      for(batchsit_t_sbsd_case_copay__x pF : caseCopayRecCreated){
                                                                                          parentFeeIds.add(pF.externalId);
                                                                                      }
                                                                                      if(caseCopayRec.dte_begin_effv__c <=caseCopayRec.dte_end_effv__c || caseCopayRec.dte_end_effv__c == null){
                                                                                          String endDateStr = '';
                                                                                          Date prevPFEndDate = effectiveDateFormat.addDays(-1); // corrected Enddate logic for CCCAP-14705 by Shashank.
                                                                                          endDateStr = String.valueOf(prevPFEndDate.year()+'-'+prevPFEndDate.month()+'-'+prevPFEndDate.day());
                                                                                          HttpResponse response = HerokuService.caseCopyUpdate('', String.valueOf(caseCopayRec.amt_copay_case_ft__c), 
                                                                                                                                           String.valueOf(caseCopayRec.amt_copay_case_pt__c), String.valueOf(caseCopayRec.cde_reason_ovrd__c) , 
                                                                                                                                           String.valueOf(caseCopayRec.cde_rec_copay__c), 
                                                                                                                                           String.valueOf(caseCopayRec.dte_begin_effv__c.year()+'-'+caseCopayRec.dte_begin_effv__c.month()+'-'+caseCopayRec.dte_begin_effv__c.day()), 
                                                                                                                                           endDateStr,
                                                                                                                                           String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c), 
                                                                                                                                           String.valueOf(caseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(caseCopayRec.amt_copay_case_pt_qlty__c), 
                                                                                                                                           String.valueOf(caseCopayRec.ind_qlty__c),String.valueOf(caseCopayRec.idn_sbsd_case_copay__c));
                                                                                      if(response != null && response.getStatusCode()==200){
                                                                                          String errorMessageCopayUpdate = '';
                                                                                          Map<String,Object> mapDataForEachCopayUpdateResult= (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
                                                                                          if(mapDataForEachCopayUpdateResult.containsKey('successInd') && mapDataForEachCopayUpdateResult.get('successInd')!='Y' && mapDataForEachCopayUpdateResult.containsKey('errMessage') && mapDataForEachCopayUpdateResult.get('errMessage')!=null){
                                                                                              errorMessageCopayUpdate+=mapDataForEachCopayUpdateResult.get('errMessage')+',';
                                                                                          }
                                                                                          if(String.isNotEmpty(errorMessageCopayUpdate)){
                                                                                              errorMessageCopayUpdate = errorMessageCopayUpdate.removeEnd(',');
                                                                                              objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, 'Case Parent Fee Update failed:'+errorMessageCopayUpdate));
                                                                                              objectData.put('title','Update Failed');
                                                                                              objectData.put('isSuccessful',false);
                                                                                              objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessageCopayUpdate);
                                                                                          }else{
                                                                                            objectData.put('isSuccessful',true);
                                                                                          }
                                                                                      }else{
                                                                                          objectData.put('title','Something unexpected happened!!');
                                                                                          objectData.put('description',response.getBody());
                                                                                          objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, response.getBody()));
                                                                                      }
                                                                                      }else{
                                                                                          objectData.put('isSuccessful',true);
                                                                                      }
                                                                                      
                                                                                  }
                                                                              }else{
                                                                                  objectData.put('title','Something unexpected happened!!');
                                                                                  objectData.put('description',createResponse.getBody());
                                                                                  objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, createResponse.getBody()));
                                                                              } 
                                                                          }
                                                                          else{
                                                                              if(caseCopayRec.dte_begin_effv__c <=caseCopayRec.dte_end_effv__c || caseCopayRec.dte_end_effv__c == null){
                                                                                 system.debug('update case copay--'+caseCopayRec);
                                                                                 // Calculate currentPFendDate for the second invocation as well
                                                                                 List<string> parentFeeIds = new List<String>();
                                                                                 List<batchsit_t_sbsd_case_copay__x> caseCopayRecForEndDate = [SELECT Id, idn_sbsd_case_copay__c, dte_begin_effv__c,externalId
                                                                                                                                               FROM batchsit_t_sbsd_case_copay__x
                                                                                                                                               WHERE idn_case__c=:caseCopayRec.idn_case__c
                                                                                                                                               ORDER By ExternalId DESC];
                                                                                 for(batchsit_t_sbsd_case_copay__x pF : caseCopayRecForEndDate){
                                                                                     parentFeeIds.add(pF.externalId);
                                                                                 }
                                                                                 integer currentPFIndex = parentFeeIds.indexOf(String.valueOf(caseCopayRec.idn_sbsd_case_copay__c));
                                                                                 Date currentPFendDate = null;
                                                                                 if(currentPFIndex>-1 && currentPFIndex > 0){
                                                                                     // Get the begin date of the next record and subtract 1 day
                                                                                     Date nextRecordBeginDate = caseCopayRecForEndDate[currentPFIndex-1].dte_begin_effv__c;
                                                                                     if(nextRecordBeginDate != null){
                                                                                         currentPFendDate = nextRecordBeginDate.addDays(-1);
                                                                                     }
                                                                                 }
                                                                                 String endDateStr = '';
                                                                                 if(currentPFendDate != null){
                                                                                     endDateStr = String.valueOf(currentPFendDate.year()+'-'+currentPFendDate.month()+'-'+currentPFendDate.day());
                                                                                 }
                                                                              HttpResponse response = HerokuService.caseCopyUpdate(parentFee, String.valueOf(caseCopayRec.amt_copay_case_ft__c), 
                                                                                                                                   String.valueOf(caseCopayRec.amt_copay_case_pt__c), String.valueOf(caseCopayRec.cde_reason_ovrd__c) , 
                                                                                                                                   String.valueOf(caseCopayRec.cde_rec_copay__c), 
                                                                                                                                   String.valueOf(caseCopayRec.dte_begin_effv__c.year()+'-'+caseCopayRec.dte_begin_effv__c.month()+'-'+caseCopayRec.dte_begin_effv__c.day()), 
                                                                                                                                   endDateStr, 
                                                                                                                                   String.valueOf(caseCopayRec.idn_case__c), String.valueOf(caseCopayRec.nbr_seq_hist__c), 
                                                                                                                                   String.valueOf(caseCopayRec.amt_copay_case_ft_qlty__c), String.valueOf(caseCopayRec.amt_copay_case_pt_qlty__c), 
                                                                                                                                   String.valueOf(caseCopayRec.ind_qlty__c),String.valueOf(caseCopayRec.idn_sbsd_case_copay__c));
                                                                              if(response != null && response.getStatusCode()==200){
                                                                                  String errorMessageCopayUpdate = '';
                                                                                  Map<String,Object> mapDataForEachCopayUpdateResult= (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
                                                                                  if(mapDataForEachCopayUpdateResult.containsKey('successInd') && mapDataForEachCopayUpdateResult.get('successInd')!='Y' && mapDataForEachCopayUpdateResult.containsKey('errMessage') && mapDataForEachCopayUpdateResult.get('errMessage')!=null){
                                                                                      errorMessageCopayUpdate+=mapDataForEachCopayUpdateResult.get('errMessage')+',';
                                                                                  }
                                                                                  if(String.isNotEmpty(errorMessageCopayUpdate)){
                                                                                      errorMessageCopayUpdate = errorMessageCopayUpdate.removeEnd(',');
                                                                                      objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, 'Case Parent Fee Update failed:'+errorMessageCopayUpdate));
                                                                                      objectData.put('title','Update Failed');
                                                                                      objectData.put('isSuccessful',false);
                                                                                      objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessageCopayUpdate);
                                                                                  }else{
                                                                                      objectData.put('isSuccessful',true);
                                                                                  }
                                                                              }else{
                                                                                  objectData.put('title','Something unexpected happened!!');
                                                                                  objectData.put('description',response.getBody());
                                                                                  objectData.put('xLog',getXLog('saveCaseCopayRecord',null,'Web Service', null, response.getBody()));
                                                                              } 
                                                                              }else{
                                                                                          objectData.put('isSuccessful',true);
                                                                                      }
                                                                              
                                                                          } 
                                                                          
                                                                      }
                                                                      isSuccessful=true;
                                                                      if(caseCopayRecCreated.size()>0){
                                                                          objectData.put('caseCopayRecIdCreated',caseCopayRecCreated.get(0).Id);
                                                                          objectData.put('caseCopayRecExtIdCreated',caseCopayRecCreated.get(0).idn_sbsd_case_copay__c);
                                                                          objectData.put('caseCopayRecCreated',caseCopayRecCreated.get(0));
                                                                      }
                                                                  }
                                                                  catch(Exception ex){
                                                                      objectData.put('isSuccessful',false);
                                                                      objectData.put('title','Something unexpected happened!!');
                                                                      objectData.put('description',ex.getMessage());
                                                                      objectData.put('xLog',getXLog('getInitData',ex.getMessage(),ex.getTypeName(),null , null));
                                                                      
                                                                  }
                                                                  return new LightningServerResponse(isSuccessful,message,objectData);
                                                              }
    @AuraEnabled
    public static LightningServerResponse getInitData(String caseRecId) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        List<batchsit_t_fcompsn_eligty__x> householdEligity = new List<batchsit_t_fcompsn_eligty__x>();
        List<batchsit_t_fcompsn_eligty_detail__x> eligDetail = new List<batchsit_t_fcompsn_eligty_detail__x>();
        Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
        String caseExternalId;
        List<batchsit_t_sbsd_case_copay__x> caseCopayRecord =new List<batchsit_t_sbsd_case_copay__x>();
        String profileName = [Select Name from Profile where Id =: UserInfo.getProfileId() Limit 1].Name;
        Boolean isReadOnlyUser =false;
        
        try{
            if(caseRecId != null){
                for(T_SBSD_CASE__c cse :[Select id,IDN_EXTNL__c,CDE_COUNTY__c,CDE_COUNTY__r.name from T_SBSD_CASE__c where id=:caseRecId]){
                    caseExternalId =cse.IDN_EXTNL__c;
                    if(cse.CDE_COUNTY__r.name =='Adams'){
                        objectData.put('isAdamCounty',true);
                    }
                }
            }
            //CCCAP-14993
            if(FeatureManagement.checkPermission('Read_Only_User') || FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor')){
                isReadOnlyUser=true;
            }
            objectData.put('isReadOnlyUser',isReadOnlyUser);
            
            system.debug('caseExternalId--'+caseExternalId);
            if(!String.isBlank(caseExternalId)){
                objectData.put('caseExternalId', caseExternalId);
                caseCopayRecord =   [SELECT Id, idn_case__c,idn_case__r.Id, idn_sbsd_case_copay__c,amt_copay_case_assesd__c,
                                         amt_copay_case_ft__c, amt_copay_case_pt__c, cde_reason_ovrd__c, 
                                         cde_rec_copay__c, dte_begin_effv__c, dte_end_effv__c, nbr_seq_hist__c,  amt_copay_case_ft_qlty__c,
                                         amt_copay_case_pt_qlty__c, ind_qlty__c
                                         FROM batchsit_t_sbsd_case_copay__x
                                         WHERE idn_case__c =:caseExternalId ORDER BY dte_begin_effv__c DESC,ExternalId desc ]; 
               
                
                system.debug('caseCopayRecord--'+caseCopayRecord);
                Set<Decimal> eliRunIds = new Set<Decimal>();
                String idnRunEligty ;
                
                for(batchsit_t_eligty_run__x eli : [Select Id,idn_run_eligty__c,ExternalId, cde_eligty_cfmd__c,idn_case__c,dte_run_eligty__c from batchsit_t_eligty_run__x where
                                                    idn_case__c=:caseExternalId and cde_eligty_cfmd__c='CFM' order by ExternalId DESC limit 1]){
                                                        eliRunIds.add(eli.idn_run_eligty__c);
                                                        idnRunEligty = String.valueOf(eli.idn_run_eligty__c);
                                                        
                                                    }
                system.debug('eliRunIds--'+eliRunIds);
                if(Test.isRunningTest()){
                    eliRunIds.add(123);
                    idnRunEligty= '123';
                    batchsit_t_fcompsn_eligty__x fcm=new batchsit_t_fcompsn_eligty__x(idn_run_eligty__c='123',idn_eligty_fcompsn__c=1267);
                    householdEligity.add(fcm);
                    eligDetail.add(new batchsit_t_fcompsn_eligty_detail__x(idn_eligty_fcompsn__c='1267'));
                    fcompsnEligtyIdToRecord.put('1267',fcm);
                }
                if(eliRunIds.size()>0 && String.isNotBlank(idnRunEligty)) {
                    Map<Decimal, batchsit_t_fcompsn_eligty_detail__x> eligibilityHouseHoldIdToEligDetail = new Map<Decimal, batchsit_t_fcompsn_eligty_detail__x>();
                    householdEligity = [select id,ExternalId,idn_run_eligty__c,amt_copay_ft__c,amt_copay_pt__c,idn_eligty_fcompsn__c ,cde_reason_change_fcompsn__c
                                        from batchsit_t_fcompsn_eligty__x where idn_run_eligty__c  =:idnRunEligty 
                                        AND (cde_reason_change_fcompsn__c!='NCT' OR cde_reason_change_fcompsn__c=null) order by idn_eligty_fcompsn__c desc LIMIT 1];
                    if(!householdEligity.isEmpty()){
                        for(batchsit_t_fcompsn_eligty__x fcompsnEligty:householdEligity){
                            fcompsnEligtyIdToRecord.put(String.valueOf(fcompsnEligty.idn_eligty_fcompsn__c),fcompsnEligty);
                        }
                    }
                    if(fcompsnEligtyIdToRecord.size()>0){
                        for(batchsit_t_fcompsn_eligty_detail__x fcomElig : [Select Id,idn_eligty_fcompsn__c,cde_status_eligty_family__c ,dte_begin_effv__c
                                                                            from batchsit_t_fcompsn_eligty_detail__x 
                                                                            where idn_eligty_fcompsn__c IN: fcompsnEligtyIdToRecord.keySet() and 
                                                                            cde_status_eligty_family__c != 'INE' ORDER BY dte_begin_effv__c DESC LIMIT 1    ])
                        {
                            
                            eligibilityHouseHoldIdToEligDetail.put(decimal.valueOf(fcomElig.idn_eligty_fcompsn__c), fcomElig);
                            eligDetail.add(fcomElig);
                            
                        }  
                    }
                    system.debug('eligibilityHouseHoldIdToEligDetail--'+eligibilityHouseHoldIdToEligDetail);
                    system.debug('householdEligity--'+householdEligity);
                    system.debug('eligDetail---'+eligDetail);
                    if(eligDetail.size()>0) {
                        system.debug('eligDetail---'+eligDetail);
                        objectData.put('eligDetail', eligDetail);
                    }
                    if(householdEligity.size()>0){
                        objectData.put('householdEligity', householdEligity[0]);
                    }
                }
            }
            if (Test.isRunningTest()){
                caseCopayRecord.add(new batchsit_t_sbsd_case_copay__x(idn_case__c='test'));
            }
            if(caseCopayRecord.size()>0) {
                System.debug(caseCopayRecord.get(0));
                system.debug('caseCopayRecord.get(0)----'+caseCopayRecord.get(0));
                objectData.put('caseCopayRecord', caseCopayRecord.get(0));
            }
            /*String recommendedCopayUnit = AuthorizationStatusController.getAuthWeight( caseRecId, true,  'N');
if(String.isNotBlank(recommendedCopayUnit)){
objectData.put('recommendedCopayUnit', recommendedCopayUnit);
}
system.debug('recommendedCopayUnit---'+recommendedCopayUnit);*/
            isSuccessful=true;
        }
        catch(Exception ex){
            isSuccessful=false;
            system.debug('exception message--'+ex.getMessage());
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            objectData.put('xLog',getXLog('getInitData',ex.getMessage(),ex.getTypeName(),null , null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse getAuthWeight(String caseRecId,String effectiveDateStr) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful;
        String message;
        String recommendedCopayUnit = AuthorizationStatusController.getAuthWeight( caseRecId, true,'N', effectiveDateStr);
        if(String.isNotBlank(recommendedCopayUnit)){
            objectData.put('recommendedCopayUnit', recommendedCopayUnit);
        }
        isSuccessful=true;
        return new LightningServerResponse(isSuccessful,'SuccessFull',objectData);
    }
    @AuraEnabled
    public Static Boolean getPrivateRates(List<ParentFeeAllocationWrapper> caseParentFeeAllocations,Date caseParentFeeDate, String recommendedCopayUnit,String caseExternalId, Integer caseParentFeeAmt){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        Set<String> authExternalIdSet = new Set<String>();
        Set<String> providerExternalIdSet = new Set<String>();
        Set<String> childExternalIdSet = new Set<String>();
        List<batchsit_t_sbsd_indiv_care_level__x> indcareLvl = new List<batchsit_t_sbsd_indiv_care_level__x>();
        Map<String,String> childProviderMap = new Map<String,String>();
        Map<String,String> childAgeGroup = new Map<String,String>();
        Map<String,String> providerChildMap = new Map<String,String>();
        Map<String,String> providerChildCombinedMap = new Map<String,String>();
        List<T_FISCAL_SCH__c> fiscalAgreeList = new List<T_FISCAL_SCH__c>();
        Map<String,String> careUnitMap = new Map<String,String>();
        String countyId;
        Boolean showPrivatePayAmtMsg = false;
        String recommentCopayUnitCode ;//=careUnitMap.get(recommendedCopayUnit);
        if(caseExternalId != null){
            T_SBSD_CASE__c caseObj = [SELECT id,CDE_COUNTY__c,IDN_EXTNL__c from T_SBSD_CASE__c where IDN_EXTNL__c=:caseExternalId ];
            if(caseObj!= null){
                countyId = caseObj.CDE_COUNTY__c;
            }
        }
         if(recommendedCopayUnit != null){
            
            Schema.DescribeFieldResult fieldResult = Field_Utility__c.R00715__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry f : ple)
            {
                if(recommendedCopayUnit == f.getLabel()){
                        recommentCopayUnitCode = f.getValue();
                }
                careUnitMap.put(f.getLabel(), f.getValue());
            }   
            
        }
        for(ParentFeeAllocationWrapper wrap: caseParentFeeAllocations ){
            authExternalIdSet.add(wrap.authExternalId);
            providerExternalIdSet.add(wrap.providerExternalId);
            childExternalIdSet.add(wrap.childExternalId);
            childProviderMap.put(wrap.childExternalId, wrap.providerExternalId);
            providerChildMap.put(wrap.providerExternalId, wrap.childExternalId);
        }
        system.debug('caseParentFeeAllocations--'+caseParentFeeAllocations);
        system.debug('providerChildMap--'+providerChildMap);
        system.debug('childProviderMap--'+childProviderMap);
        system.debug('childExternalIdSet--'+childExternalIdSet);
        system.debug('providerExternalIdSet--'+providerExternalIdSet);
        indcareLvl = [Select id,cde_level_care__c,idn_sbsd_indiv_care_level__c,dte_begin_effv__c,dte_end_effv__c,
                      idn_client__c from batchsit_t_sbsd_indiv_care_level__x where idn_client__c IN:childExternalIdSet];
        for(batchsit_t_sbsd_indiv_care_level__x indivCare :indcareLvl){
            if(indivCare.dte_begin_effv__c <=caseParentFeeDate && (indivCare.dte_end_effv__c >= caseParentFeeDate || indivCare.dte_end_effv__c==null)){
                childAgeGroup.put(indivCare.idn_client__c,indivCare.cde_level_care__c);
            }
            //childAgeGroup
            
        }
		system.debug('childAgeGroup--'+childAgeGroup);
        Map<String,T_FISCAL_SCH__c> rateSchMap = new Map<String,T_FISCAL_SCH__c>();
        Map<String,Decimal> ageGroupFiscalRateMap = new Map<String,Decimal>();
        for(T_FISCAL_SCH__c rateSch :[Select DTE_BEGIN_EFFV__c,(Select cde_age_group__c,cde_care_unit__c,idn_fiscal_sch__c,
                                      cde_rate_type__c,amt_provr__c from batchsit_t_fiscal_rate__r Where cde_care_unit__c=:recommentCopayUnitCode),DTE_END_EFFV__c,Provider_Id__c,IDN_AGRMT_FISCAL__r.ID_SERVICE__r.External_ID__c,
                                      TXT_CHATS_RATING__c,CDE_RATE_TYPE__c FROM T_FISCAL_SCH__c where DTE_BEGIN_EFFV__c<=:caseParentFeeDate and
                                      (DTE_END_EFFV__c>=:caseParentFeeDate OR DTE_END_EFFV__c =NULL) and //Provider_Id__c IN:providerExternalIdSet and
                                      IDN_AGRMT_FISCAL__r.CDE_COUNTY__c =:countyId and IDN_AGRMT_FISCAL__r.ID_SERVICE__r.External_ID__c IN:providerExternalIdSet]){
                                          for(batchsit_t_fiscal_rate__x rateObj :rateSch.batchsit_t_fiscal_rate__r){
                                              String rateKey = rateSch.IDN_AGRMT_FISCAL__r.ID_SERVICE__r.External_ID__c +'_'+ rateObj.cde_age_group__c +'_'+ rateObj.cde_rate_type__c;
                                             system.debug('rateObj-cde_care_unit__c-'+rateObj.cde_care_unit__c);
                                              //if(careUnitMap != null && careUnitMap.containsKey(recommendedCopayUnit) && rateObj.cde_care_unit__c ==careUnitMap.get(recommendedCopayUnit)){
                                                  if(!ageGroupFiscalRateMap.containsKey(rateKey)){
                                                      ageGroupFiscalRateMap.put(rateKey, rateObj.amt_provr__c);
                                                  }
                                              //}
                                          } 
                                          rateSchMap.put(rateSch.IDN_AGRMT_FISCAL__r.ID_SERVICE__r.External_ID__c, rateSch);
        }
        system.debug('rateSchMap--'+rateSchMap);
        system.debug('ageGroupFiscalRateMap--'+ageGroupFiscalRateMap);
        Map<String,Decimal> kidsAmt = new Map<String,Decimal>();
        Decimal privatePayAmt=0;
        for(ParentFeeAllocationWrapper wrap: caseParentFeeAllocations ){
            T_FISCAL_SCH__c rateSchObj = rateSchMap.get(wrap.providerExternalId);
            String clientId = providerChildMap.get(wrap.providerExternalId);
            String childAgeGroupVal = childAgeGroup.get(wrap.childExternalId);
            String rateKey = wrap.providerExternalId +'_'+ childAgeGroupVal +'_'+ wrap.majorityCareUnit;
            system.debug('rateKey--'+rateKey);
            system.debug('childAgeGroupVal--'+childAgeGroupVal);
            system.debug('rateSchObj--'+rateSchObj);
            if(ageGroupFiscalRateMap.containsKey(rateKey)){
                Decimal amount = ageGroupFiscalRateMap.get(rateKey)*wrap.authorizedDays;
                privatePayAmt = privatePayAmt + amount;
            }
            system.debug('privatePayAmt--'+privatePayAmt);
        }
        system.debug('privatePayAmt--'+privatePayAmt);
        objectData.put('privatePayAmt',privatePayAmt);
        if(caseParentFeeAmt >privatePayAmt){
            showPrivatePayAmtMsg = true;
        }
        return showPrivatePayAmtMsg;
        }
   
   
    @AuraEnabled
    public Static LightningServerResponse getAuthCopayRecords(String caseExternalId, String EffectiveDate,String caseParentFeeAmt,String recommendedCopayUnit) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        String EffectiveMonth ;
        Integer EffectiveYear ;
        List<String> dateParts = new List<String>();
        String requestString;
        Date caseParentFeeBeginDate;
        List<ParentFeeAllocationWrapper> caseParentFeeAllocations = new List<ParentFeeAllocationWrapper>();
        try{
            dateParts= EffectiveDate.split('-');
            if(dateParts.size()>1){
                EffectiveMonth =String.valueOf(dateParts[1]);
                EffectiveYear =Integer.valueOf(dateParts[0]);
                caseParentFeeBeginDate = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
            }
            requestString='caseId:'+caseExternalId+',month:'+EffectiveMonth+',year:'+EffectiveYear+',EffectiveDate:'+EffectiveDate;
            HttpResponse response = ParentFeeFlowWSCaller.callSearchParentFeeWS(caseExternalId,EffectiveMonth,EffectiveYear,EffectiveDate,caseParentFeeAmt);
            if(response.getStatusCode()==200){
                caseParentFeeAllocations= ParentFeeFlowIntegrator.getCaseParentFeeAllocations(response.getBody());
                if(caseParentFeeAllocations != null && caseParentFeeAllocations.size()>0){
                    objectData.put('caseParentFeeAllocations',caseParentFeeAllocations);
                    if(caseParentFeeBeginDate != null){
                       Boolean showPrivatePayAmtMsg = getPrivateRates(caseParentFeeAllocations,caseParentFeeBeginDate, recommendedCopayUnit, caseExternalId,Integer.valueOf(caseParentFeeAmt));
                       objectData.put('privatePayAmtMsg',showPrivatePayAmtMsg);
                    }
                }
                else{
                    objectData.put('title','No Data found.');
                    objectData.put('description','We could not find  authorizations that are active on the case parent fee Effective Begin Date. Please enter another effective date.');
                }
            }else{
                objectData.put('title','Something unexpected happened!!');
                objectData.put('description',response.getBody());
                objectData.put('xLog',getXLog('getAuthCopayRecords',null,'Web Service', requestString, response.getBody()));
            }
            isSuccessful= true;
            message='Sucessfull';
        }catch(Exception ex){
            isSuccessful= false;
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            objectData.put('xLog',getXLog('getAuthCopayRecords',ex.getMessage(),ex.getTypeName(),requestString , null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);   
    }
    @AuraEnabled
    public Static LightningServerResponse getCaseParentFeeRecord(String caseExternalId, String EffectiveDate, String caseParentFeeAmt) {
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful = true;
        String message='';
        String EffectiveMonth ;
        Integer EffectiveYear ;
        List<String> dateParts = new List<String>();
        String requestString;
        List<ParentFeeAllocationWrapper> caseParentFeeAllocations = new List<ParentFeeAllocationWrapper>();
        try{
            dateParts= EffectiveDate.split('-');
            if(dateParts.size()>1){
                EffectiveMonth =String.valueOf(dateParts[1]);
                EffectiveYear =Integer.valueOf(dateParts[0]);
            }
            requestString='caseId:'+caseExternalId+',month:'+EffectiveMonth+',year:'+EffectiveYear+',EffectiveDate:'+EffectiveDate;
            HttpResponse response = ParentFeeFlowWSCaller.callSearchParentFeeWS(caseExternalId,EffectiveMonth,EffectiveYear,EffectiveDate,caseParentFeeAmt);
            if(response.getStatusCode()==200){
                Map<String,Object> caseParentFeeDetails = ParentFeeFlowIntegrator.getCaseParentFeeDetails(response.getBody());
                if(caseParentFeeDetails.containsKey('caseCopayId') && caseParentFeeDetails.get('caseCopayId')!=null){
                    objectData.put('caseParentFeeDetails',caseParentFeeDetails);
                }
                else{
                    objectData.put('title','No Data found.');
                    objectData.put('description','We could not find  authorizations that are active on the case parent fee Effective Begin Date. Please enter another effective date.');
                }
            }else{
                objectData.put('title','Something unexpected happened!!');
                objectData.put('description',response.getBody());
                objectData.put('xLog',getXLog('getAuthCopayRecords',null,'Web Service', requestString, response.getBody()));
            }
            isSuccessful= true;
            message='Sucessfull';
        }catch(Exception ex){
            isSuccessful= false;
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            objectData.put('xLog',getXLog('getAuthCopayRecords',ex.getMessage(),ex.getTypeName(),requestString , null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);   
    }
    @AuraEnabled
    public static LightningServerResponse saveAuthCopay(String effDtStr, String authCopayWrapStr){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        try{
            if(String.isNotBlank(authCopayWrapStr)){
                List<String> dateParts = new List<String>();
                dateParts= effDtStr.split('-');
                Date effDt = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                List<ParentFeeAllocationWrapper> caseParentFeeAllocations  = (List<ParentFeeAllocationWrapper>)JSON.deserialize(authCopayWrapStr, List<ParentFeeAllocationWrapper>.class);
                return upsertParentFeeData(authCopayWrapStr,effDt,false,false);
                
            }
        }
        catch(Exception ex){
            objectData.put('isSuccessful',false);
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            objectData.put('xLog',getXLog('saveAuthCopay',ex.getMessage(),ex.getTypeName(),null , null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse updateAuthCopay(String effDtStr, String authCopayWrapStr,Boolean isUpdate){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        try{
            if(String.isNotBlank(authCopayWrapStr)){
                List<String> dateParts = new List<String>();
                dateParts= effDtStr.split('-');
                Date effDt = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
                List<ParentFeeAllocationWrapper> caseParentFeeAllocations  = (List<ParentFeeAllocationWrapper>)JSON.deserialize(authCopayWrapStr, List<ParentFeeAllocationWrapper>.class);
                return upsertParentFeeData(authCopayWrapStr,effDt,true,isUpdate);
            }
        }
        catch(Exception ex){
            objectData.put('isSuccessful',false);
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            objectData.put('xLog',getXLog('updateAuthCopay',ex.getMessage(),ex.getTypeName(),null , null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse upsertParentFeeData(String caseParentFeeAllocationsJSON,Date effectiveCaseCopayBeginDate, Boolean isUpdate, Boolean updateAmount){
        List<ParentFeeAllocationWrapper> caseParentFeeAllocations = (List<ParentFeeAllocationWrapper>)JSON.deserialize(caseParentFeeAllocationsJSON, List<ParentFeeAllocationWrapper>.class);
        Map<String, Object> objectData = new map<String, Object>();
        String monthStr; //= String.valueOf(effectiveCaseCopayBeginDate.Month());
        String yearStr ;//= String.valueOf(effectiveCaseCopayBeginDate.year());
        if(effectiveCaseCopayBeginDate != null){
            monthStr= String.valueOf(effectiveCaseCopayBeginDate.Month());
            yearStr = String.valueOf(effectiveCaseCopayBeginDate.year());
        }
        Boolean isSuccessful = true;
        String message='';
        try{
            if(isUpdate){
                List<ParentFeeAllocationWrapper> caseParentFeeAllocationsToBeEndDated = new List<ParentFeeAllocationWrapper>();
                for(ParentFeeAllocationWrapper caseParentFeeAllocation:caseParentFeeAllocations){
                    if(updateAmount){
                        caseParentFeeAllocationsToBeEndDated.add(caseParentFeeAllocation);
                    }else{
                        if(String.isNotEmpty(caseParentFeeAllocation.authCopayExternalId)){
                            caseParentFeeAllocationsToBeEndDated.add(caseParentFeeAllocation);
                        }  
                    }
                }
                if(!caseParentFeeAllocationsToBeEndDated.isEmpty()){
                     String bodyForcallUpdateParentFeeWS ='';
                    if(updateAmount){
                        bodyForcallUpdateParentFeeWS = ParentFeeFlowIntegrator.getBodyForAuthAmountUpdateParentFeeWS(effectiveCaseCopayBeginDate,caseParentFeeAllocationsToBeEndDated);
                    }else{
                        bodyForcallUpdateParentFeeWS = ParentFeeFlowIntegrator.getBodyForUpdateParentFeeWS(effectiveCaseCopayBeginDate,caseParentFeeAllocationsToBeEndDated);
                    }
                    HttpResponse response = ParentFeeFlowWSCaller.callUpdateParentFeeWS(bodyForcallUpdateParentFeeWS);
                    if(response.getStatusCode()!=200){
                        objectData.put('title','Something unexpected happened!!');
                        objectData.put('description',response.getBody());
                        objectData.put('xLog',getXLog('upsertParentFeeData',null,'Web Service', bodyForcallUpdateParentFeeWS, response.getBody()));
                    }else{
                        List<Object> data = (List<Object>)JSON.deserializeUntyped(response.getBody());
                        String errorMessage = '';
                        for(Object dataForEachResult:data){
                            Map<String,Object> mapDataForEachResult= (Map<String,Object>)dataForEachResult;
                            if(mapDataForEachResult.containsKey('successInd') && mapDataForEachResult.get('successInd')!='Y' && mapDataForEachResult.containsKey('errMessage') && mapDataForEachResult.get('errMessage')!=null){
                                errorMessage+=mapDataForEachResult.get('errMessage')+',';
                            }
                        }
                        if(String.isNotEmpty(errorMessage)){
                            errorMessage = errorMessage.removeEnd(',');
                            objectData.put('xLog',getXLog('upsertParentFeeData',null,'Web Service', bodyForcallUpdateParentFeeWS, 'Update failed:'+errorMessage));
                            objectData.put('title','Update Failed');
                            objectData.put('isSuccessful',false);
                            objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessage);
                        }else{
                            objectData.put('isSuccessful',true);
                        }
                        
                    }
                }else{
                    objectData.put('title','No Records To Update');
                    objectData.put('description','There are no Parent Fee Allocation data to be updated');
                }
            }else{
                if(!caseParentFeeAllocations.isEmpty()){
                    String bodyForcallCreateParentFeeWS = ParentFeeFlowIntegrator.getBodyForCreateParentFeeWS(effectiveCaseCopayBeginDate,caseParentFeeAllocations,'N','N',monthStr,yearStr);
                    HttpResponse response2 = ParentFeeFlowWSCaller.callCreateParentFeeWS(bodyForcallCreateParentFeeWS);
                    if(response2.getStatusCode()!=200){
                        objectData.put('title','Something unexpected happened!!');
                        objectData.put('description',response2.getBody());
                        objectData.put('xLog',getXLog('upsertParentFeeData',null,'Web Service', bodyForcallCreateParentFeeWS, response2.getBody()));
                    }else{
                        List<Object> data = (List<Object>)JSON.deserializeUntyped(response2.getBody());
                        String errorMessage = '';
                        for(Object dataForEachResult:data){
                            Map<String,Object> mapDataForEachResult= (Map<String,Object>)dataForEachResult;
                            if(mapDataForEachResult.containsKey('successInd') && mapDataForEachResult.get('successInd')!='Y' && mapDataForEachResult.containsKey('errMessage') && mapDataForEachResult.get('errMessage')!=null){
                                errorMessage+=mapDataForEachResult.get('errMessage')+',';
                            }
                        }
                        if(String.isNotEmpty(errorMessage)){
                            errorMessage = errorMessage.removeEnd(',');
                            objectData.put('xLog',getXLog('upsertParentFeeData',null,'Web Service', bodyForcallCreateParentFeeWS, 'Create failed:'+errorMessage));
                            objectData.put('title','Create Failed');
                            objectData.put('isSuccessful',false);
                            objectData.put('description','We are not able to process your request at this moment.<br/>'+errorMessage);
                        }else{
                            objectData.put('isSuccessful',true);
                        }
                    }
                }else{
                    objectData.put('title','No Records To Update');
                    objectData.put('description','There are no Parent Fee Allocation data to be created');
                }
            }
        }catch(Exception ex){
            objectData.put('isSuccessful',false);
            objectData.put('title','Something unexpected happened!!');
            objectData.put('description',ex.getMessage());
            objectData.put('xLog',getXLog('upsertParentFeeData',ex.getMessage(),ex.getTypeName(),null , null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }  
    @AuraEnabled
    public static LightningServerResponse getActiveAuthorizationForCase(String caseId,String newDate){
        Map<String, Object> objectData = new map<String, Object>();
        Boolean isSuccessful=true;
        String message;
        Set<Id> setProviderIds= new Set<Id>();
        String countyId ;    
        String isQualityRating ='N';
        Boolean indQuality= false;
        try{
            List<String> dateParts = new List<String>();
            dateParts= newDate.split('-');
            Date effParentFeeDt = Date.newInstance(Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]), Integer.valueOf(dateParts[2]));
	    Date endOfMonthDate = effParentFeeDt.addMonths(1).toStartofMonth().addDays(-1);
            T_AUTH__c auth = new T_AUTH__c();
            for(T_AUTH__c authRec :[Select Id, IDN_PROVR__c,IDN_CASE__c,IDN_CASE__r.CDE_COUNTY__c,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c from T_AUTH__c where IDN_CASE__c =:caseId and
				    (
                                        (DTE_BEGIN_EFFV_AUTH__c <=:effParentFeeDt and (DTE_END_EFFV_AUTH__c>=:effParentFeeDt or DTE_END_EFFV_AUTH__c=null)) or 
                                         (DTE_BEGIN_EFFV_AUTH__c >=:effParentFeeDt and DTE_BEGIN_EFFV_AUTH__c <=:endOfMonthDate )
                                    
                                    )])
            {
                auth =authRec;
                countyId=authRec.IDN_CASE__r.CDE_COUNTY__c;
                if(authRec.IDN_PROVR__c != null){
                    setProviderIds.add(authRec.IDN_PROVR__c);
                }
            }
             List<T_PROVR_FISCAL_AGREMENT__c> fiscalAgreeList = new List<T_PROVR_FISCAL_AGREMENT__c>();
            if(countyId != null && setProviderIds.size()>0){
                fiscalAgreeList =[Select Id, (Select TXT_CHATS_RATING__c,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c from Rate_Schedules__r where DTE_BEGIN_EFFV__c<=: effParentFeeDt and 
                                              (DTE_END_EFFV__c >=: effParentFeeDt or DTE_END_EFFV__c=null) order by CreatedDate DESC limit 1 )  from T_PROVR_FISCAL_AGREMENT__c where ID_SERVICE__c in :setProviderIds and 
                                  DTE_BEGIN_AGRMT__c<=: effParentFeeDt and (DTE_END_AGRMT__c >=: effParentFeeDt or DTE_END_AGRMT__c=null) and CDE_COUNTY__c=:countyId];
                for(T_PROVR_FISCAL_AGREMENT__c fiscalAgreement :fiscalAgreeList ){
                    if(fiscalAgreement.Rate_Schedules__r != null){
                        if(fiscalAgreement.Rate_Schedules__r.get(0)!= null && 
                           (fiscalAgreement.Rate_Schedules__r.get(0).TXT_CHATS_RATING__c=='Level 3'
                            ||fiscalAgreement.Rate_Schedules__r.get(0).TXT_CHATS_RATING__c=='Level 4'
                            ||fiscalAgreement.Rate_Schedules__r.get(0).TXT_CHATS_RATING__c=='Level 5')){
                                indQuality=true;
                                isQualityRating ='Y';
                                break;
                            }  
                    }
                }  
            }
            objectData.put('isQualityRating',isQualityRating);
        }catch(Exception ex){
            objectData.put('isSuccessful',false);
            objectData.put('xLog',getXLog('getActiveAuthorizationForCase',ex.getMessage(),ex.getTypeName(),null , null));
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse deleteParentFeeData(String caseCopayExternalId){
        return ViewCaseParentFeeApxCtrl.deleteParentFeeData(caseCopayExternalId);
    }    
    public static Exception_Log__c getXLog(String methodName,String exceptionMessage,String exceptionType, String request, String response){
        Exception_Log__c xLog = new Exception_Log__c();
        xLog.Class__c = 'UpdateParentFeeApxCtrl';
        xLog.Method__c = methodName;
        xLog.Exception_Message__c = exceptionMessage;
        xLog.Exception_Type__c = exceptionType;
        xLog.Request__c = request; 
        xLog.Response__c = response;
        return xLog;
    }
}