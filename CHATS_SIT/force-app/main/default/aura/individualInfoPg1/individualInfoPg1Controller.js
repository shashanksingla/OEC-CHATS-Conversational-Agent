({
    doInit :function(component,event,helper){
        component.set('v.selKindleVal',component.get('v.indivRec.CDE_ATTENDING_SCHOOL1__c'));
        helper.validateDOBDependency(component,event,helper);
    },
    handleKindleUpdate:function(component,event,helper){
        if(component.get('v.selKindleVal') == 'Y' && 
           (component.get('v.indivRec.CDE_ATTENDING_SCHOOL1__c') == 'N' || component.get('v.indivRec.CDE_ATTENDING_SCHOOL1__c') == 'Unknown')){
            component.set('v.indivRec.CDE_ATTENDING_SCHOOL_BEGINDATE__c',null);
        }
        component.set('v.selKindleVal',component.get('v.indivRec.CDE_ATTENDING_SCHOOL1__c'));
        helper.validateDOBDependency(component,event,helper);
    },
    //CCCAP-13633
    handleStsUpdate:function(component, event, helper) {
        console.log("enter");
        console.log('print',component.get("v.caseIndiv.Individual_Status__c"));
        if(component.get("v.caseIndiv.Individual_Status__c")=='PC'||component.get("v.caseIndiv.Individual_Status__c")=='AC') {
            component.set("v.indivRec.CDE_GENDER__c", '3');
            component.set("v.indivRec.CDE_ATTENDING_SCHOOL1__c", 'Unknown');
            component.set("v.indivRec.IND_CHILD_IDEA__c", 'N');
            component.set("v.indivRec.IND_CHILD_SCREEN__c", 'N');
            component.set("v.indivRec.IND_CDE_TYPE_VERIF_DOB__c", 'N/A-adult caretaker');
            component.set("v.indivRec.CDE_ETNCTY__c", 'U');
            component.set("v.indivRec.CDE_RACE__c", '6');
            component.set("v.indivRec.CDE_SOURCE_VRFYD_DOB__c",'');
			component.set("v.indivInfoRec.CDE_VALUE_INFO_INDIV__c", 'N/A-adult caretaker');
        }else{
            component.set("v.indivRec.CDE_GENDER__c", '');
            component.set("v.indivRec.CDE_ATTENDING_SCHOOL1__c", '');
            component.set("v.indivRec.IND_CHILD_IDEA__c", '');
            component.set("v.indivRec.IND_CHILD_SCREEN__c", '');
            component.set("v.indivRec.IND_CDE_TYPE_VERIF_DOB__c", '');
            component.set("v.indivRec.CDE_ETNCTY__c", '');
            component.set("v.indivRec.CDE_RACE__c", '');

        }
    },
    //end CCCAP-13633
    handleDobChange:function(component,event,helper){
        helper.validateDOBDependency(component,event,helper);
    },
    handleFieldLevelValidation : function(component, event, helper) {
        helper.handleFieldLevelValidation(component);
    },
    handleValidateCurrentPage : function(component, event, helper) {
        helper.validateCurrentPage(component);
    }
})