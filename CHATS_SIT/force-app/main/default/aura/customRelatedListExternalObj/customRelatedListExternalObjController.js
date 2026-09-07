({
    doInit : function(cmp, event, helper) {
    	if(!cmp.get("v.isNavigateToCmp")){
            var urlStr = window.location.origin + window.location.pathname;
            console.log('string', urlStr);
            cmp.set('v.showMore', urlStr.endsWith('view'));
            console.log('showmore', cmp.get("v.showMore"));
        }
        var isReturnBackToCaseCommentsList = cmp.get("v.returnBackToCaseCommentsList"); //component.get("v.componentAttributes").returnBackToCaseCommentsList;
        if(isReturnBackToCaseCommentsList == 'true'){
            cmp.set("v.pickListTypeFields", "cde_type_note_cmt__c,R00700__c,Field_Utility__c;cde_type_cmt__c,R00838__c,Field_Utility__c");
            cmp.set("v.componentAttributesTypes", "ExternalId;cde_type_cmt__c;txt_subj__c;cde_type_note_cmt__c;createddate__c");
            cmp.set("v.orderByField", "createddate__c");
            cmp.set("v.sortAscDsc", "DESC");
            cmp.set("v.childApiName", "batchsit_t_sbsd_case_cmt__x");
            cmp.set("v.parentObjIdentifier", "IDN_EXTNL__c");
            cmp.set("v.recordsLimit", "365");
            cmp.set("v.relatedListHeader", "Case Comment")
        }
        helper.retrieveExtObjData(cmp, event, helper);
        if(cmp.get("v.isReturnBackToCaseCommentsList") == true){
            console.log('aura coming?');
            this.navigateToChilComponent(cmp,event,helper);
            //window.history.back();
        }
    },
    navigateToChilComponent : function(component, event, helper) {
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:customRelatedListExternalObj",
            componentAttributes: {
                sortAscDsc : component.get("v.sortAscDsc"),
                orderByField : component.get("v.orderByField"),
                recCount : component.get("v.recCount"),
                listRecordsToDisplay : component.get("v.listRecordsToDisplay"),
                relatedListHeader : component.get("v.relatedListHeader"),
                parentObjIdentifier : component.get("v.parentObjIdentifier"),
                childApiName : component.get("v.childApiName"),
                pickListTypeFields: component.get("v.pickListTypeFields"),
                componentAttributesValues: component.get("v.componentAttributesValues"),
                fieldTypes: component.get("v.fieldTypes"),
                componentAttributes: component.get("v.componentAttributes"),
                componentAttributesValues: component.get("v.componentAttributesValues"),
                componentAttributesTypes: component.get("v.componentAttributesTypes"),
                recordId: component.get("v.recordId"),
                isNavigateToCmp:true,
                showMore:false
            }
        });
        if(component.get("v.showMore"))
            evt.fire();
        else
            window.history.back();
    },
    sortColumn: function(cmp, event, helper){
        if(!cmp.get("v.showMore")){
            console.log('what getting', event.target.id);
            cmp.set("{!v.orderByField}", event.target.id);
            var sortOrder = !cmp.get("v.sortAscDsc") || cmp.get("v.sortAscDsc") === 'ASC'?'DESC':'ASC';
            cmp.set("{!v.sortAscDsc}", sortOrder);
            helper.retrieveExtObjData(cmp,event, helper);
            $A.util.toggleClass(cmp.find("mySpinner"), "slds-hide");
        }
    }
})