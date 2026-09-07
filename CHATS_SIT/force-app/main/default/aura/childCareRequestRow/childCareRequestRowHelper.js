({
    getResetCCReq : function(component,event,helper){
        let ccReqRecord = JSON.parse(JSON.stringify(component.get('v.ccReqRecord')));
        ccReqRecord.txt_cmt_ovrd__c = component.get('v.ccReqRecordOnInit').txt_cmt_ovrd__c;
        ccReqRecord.cde_reason_ovrd__c = component.get('v.ccReqRecordOnInit').cde_reason_ovrd__c;
        return ccReqRecord;        
    },
    checkCustomValidations : function(component){
        //should be implemented in child component if there are any custom validations.
        
        
        var isValid = true;
        //added below block for CCCAP-11830
        let current = new Date();
        let DD = current.getDate();
        let MM = current.getMonth() + 1;
        let currentDate= current.getFullYear()+'-'+(MM<10?('0'+MM):MM)+'-'+ (DD<10?('0'+DD):DD);
        
        let beginDate =  (component.get('v.ccReqRecord') || {}).applicableBeginDate;
        let datePersonEnteredHome = (component.get('v.caseIndividual') || {}).DTE_BEGIN_EFFV__c;
        let endDate = (component.get('v.ccReqRecord') || {}).DTE_END_EFFV__c;
        if(component.get('v.isOverriden')){
            if(beginDate < datePersonEnteredHome){
                component.find("T_INDIV_CAT_RQ__c-DTE_BEGIN_EFFV__c").set("v.message",'Effective Begin Date cannot be before the date the Child Entered Home '+$A.localizationService.formatDateUTC(new Date(component.get('v.caseIndividual').DTE_BEGIN_EFFV__c), "MM-DD-YYYY") +'.');
                isValid = false;
            }else if(beginDate > currentDate){
                isValid = false;
                component.find("T_INDIV_CAT_RQ__c-DTE_BEGIN_EFFV__c").set("v.message",'Effective Begin Date cannot be a future date.');
            }else if(endDate && beginDate < endDate){
                isValid = false;
                component.find("T_INDIV_CAT_RQ__c-DTE_BEGIN_EFFV__c").set("v.message",'Effective Begin Date cannot be before the most recent Child Care Request Effective End date '+$A.localizationService.formatDateUTC(new Date(endDate), "MM-DD-YYYY")+ '.');
            }else{
                component.find("T_INDIV_CAT_RQ__c-DTE_BEGIN_EFFV__c").set("v.message","");
            }
        }else{
            component.find("T_INDIV_CAT_RQ__c-DTE_BEGIN_EFFV__c").set("v.message","");
        }
        /*Commenting as part of CHATS-4146
        var caseIndividual = cmp.get("v.caseIndividual");
        var ccRequest = cmp.get("v.ccRequest");
        var initialValueCCRequest = cmp.get("v.initialValueCCRequest");
        var reasonEndingCare = cmp.get("v.reasonEndingCare");
        var initialReasonEndingCare = cmp.get("v.initialReasonEndingCare");
        if((ccRequest!=initialValueCCRequest) || (reasonEndingCare!=initialReasonEndingCare)){
            
            if((reasonEndingCare!='' && reasonEndingCare!=null) && ccRequest){
                cmp.find("reasonEndingCare").set("v.message","Must be blank when CC Request checkbox is changed from false to true (unchecked to checked)");
                isValid = false;
            }
            
            if(!ccRequest && (reasonEndingCare=='' || reasonEndingCare==null)){
                cmp.find("reasonEndingCare").set("v.message","Required when CC Request checkbox is changed from true to false (checked to unchecked)");
                isValid = false;
            }
            
            if((reasonEndingCare!='' && reasonEndingCare!=null) && caseIndividual.Child_Care_Requests__r==undefined){
                cmp.find("reasonEndingCare").set("v.message","Must be blank as the individual on the case has not yet requested care");
                isValid = false;
            }
        }
        if(isValid){
            cmp.find("reasonEndingCare").set("v.message",null);
        }
        */
        return isValid;
    }
})