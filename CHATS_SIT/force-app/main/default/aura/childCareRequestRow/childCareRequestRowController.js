({
    doInit:function(component,event,helper){
        component.set('v.ccReqRecordOnInit',JSON.parse(JSON.stringify(component.get('v.ccReqRecord'))));
        let ccReqRecord = component.get('v.ccReqRecord');
        if(ccReqRecord.OVERRIDDEN_DTE_BEGIN_EFFV__c){
            component.set('v.ccReqRecord.applicableBeginDate',component.get('v.ccReqRecord').OVERRIDDEN_DTE_BEGIN_EFFV__c);
        }else if(ccReqRecord.DTE_BEGIN_EFFV__c){
            component.set('v.ccReqRecord.applicableBeginDate',component.get('v.ccReqRecord').DTE_BEGIN_EFFV__c);
        }
    },
    checkforChange:function(component,event,helper){
        if(component.get('v.initialValueCCRequest')!=component.get('v.ccRequest') && component.get('v.ccRequest')){
            let ccReqRecord = component.get('v.ccReqRecord');
            let current = new Date();
            let DD = current.getDate();
            let MM = current.getMonth() + 1;
            let currentDate= current.getFullYear()+'-'+(MM<10?('0'+MM):MM)+'-'+ (DD<10?('0'+DD):DD);
            ccReqRecord.applicableBeginDate = currentDate;
            ccReqRecord.txt_cmt_ovrd__c = undefined;
            ccReqRecord.cde_reason_ovrd__c = undefined;
            component.set('v.ccReqRecord',ccReqRecord);
            component.set('v.isBeginDateDisabled',false);
            component.set('v.isOverriden',false);
        }else{
            let ccReqRecord = helper.getResetCCReq(component,event,helper);
            let initRecord = component.get('v.ccReqRecordOnInit');
            let initDate = initRecord.OVERRIDDEN_DTE_BEGIN_EFFV__c ? initRecord.OVERRIDDEN_DTE_BEGIN_EFFV__c:initRecord.DTE_BEGIN_EFFV__c;
            ccReqRecord.applicableBeginDate = initDate;
            component.set('v.ccReqRecord',ccReqRecord);
            component.set('v.isBeginDateDisabled',true);
            component.set('v.isOverriden',false);
        }
        helper.validateCurrentPage(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        return helper.validateCurrentPage(component);
    },
    handleBeginDateUpdate:function(component,event,helper){
        let ccReqRecord = component.get('v.ccReqRecord');
        let ccActualDate = ccReqRecord.OVERRIDDEN_DTE_BEGIN_EFFV__c ? ccReqRecord.OVERRIDDEN_DTE_BEGIN_EFFV__c:ccReqRecord.DTE_BEGIN_EFFV__c;
		if(ccReqRecord.applicableBeginDate == ccActualDate)
        {
            component.set('v.isOverriden',false);
            ccReqRecord.txt_cmt_ovrd__c = undefined;
            ccReqRecord.cde_reason_ovrd__c = undefined;
        }else{
            component.set('v.isOverriden',true);
        }
        var elements = component.find('input-field');
        if(!ccReqRecord.applicableBeginDate){
            component.find("T_INDIV_CAT_RQ__c-DTE_BEGIN_EFFV__c").set("v.message","");
            elements.forEach(elem =>{
                if(elem.get('v.name')=='Effective Begin Date'){                
                elem.setCustomValidity('Effective begin date is Mandatory');
                elem.reportValidity();
            }});
        }else{
            component.find("T_INDIV_CAT_RQ__c-DTE_BEGIN_EFFV__c").set("v.message","");
            elements.forEach(elem =>{
                if(elem.get('v.name')=='Effective Begin Date'){                
                elem.setCustomValidity('');
                elem.reportValidity();
            }});
        }
        component.set('v.ccReqRecord',ccReqRecord);
    }
})