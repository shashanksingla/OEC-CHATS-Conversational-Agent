({
    doInit : function(component, event, helper) {
        if((component.get("v.sObjectName")=='T_CHATS_PROVR_STATUS__c')||(component.get("v.extSObject")=='T_CHATS_PROVR_CNT_INFO_c__x')||
           (component.get("v.extSObject")=='T_CHATS_PROVR_COND_c__x') ||(component.get("v.extSObject")=='T_CHATS_PROVR_CAPACITY_c__x')){
            component.set("v.providerId",component.get("v.recordId"));
            component.set("v.showHeader",true);
        }else{
            component.set("v.fields",[component.get("v.providerLookupName")]);                
        }
    },
    doSetProviderId : function(component, event, helper) {
        
        
        var childRecord = component.get('v.childRecord');
        var providerLookupName = component.get("v.providerLookupName");
       
        if(childRecord!=null &&
           childRecord[providerLookupName]!=undefined && 
           childRecord[providerLookupName]!=null && 
           childRecord[providerLookupName]!=''){
            var recordError = component.get('v.recordError');
            var providerId = childRecord[providerLookupName];
            
            component.set("v.providerId",providerId);
            component.set("v.showHeader",true);
        }
    },
    handleClick : function(component, event, helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
       navEvt.setParams({
           "recordId": component.get("v.providerId")
       });
       navEvt.fire();
   }
})