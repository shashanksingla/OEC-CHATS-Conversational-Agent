({
	getProviderHeader : function(component) {
        var extnlObjRecId = component.get("v.recordId");
        var extObjName;
        if(component.get("v.sObjectName")=='T_CHATS_PROVR_CNT_INFO_c__x'){
            extObjName = 'Provider Contact';
        }else if(component.get("v.sObjectName")=='T_CHATS_PROVR_CAPACITY_c__x'){
            extObjName = 'Provider Capacity';
        }else if(component.get("v.sObjectName")=='T_CHATS_PROVR_COND_c__x'){
            extObjName = 'Provider Condition';
        }
        var action = component.get("c.providerHeaderId");
        action.setParams({	"extnlObjRecId" : extnlObjRecId ,
                          	"extObjName" : extObjName });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == "SUCCESS"){
                var prvId = response.getReturnValue();
                component.set("v.providerId", prvId);
                component.set("v.showcomponent", true);
            }
        });
        $A.enqueueAction(action);
	}
})