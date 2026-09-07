({
    getRelationshipHlp : function(component, event, helper) {
        var action = component.get('c.getDoInit');
        action.setParams({
            'recordId':component.get("v.newRelationshipObj").IDN_CLIENT__c
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    var relationshipObj = component.get("v.newRelationshipObj");
                    /* if(res.objectData.getSobjectName != undefined){
                        if(res.objectData.getSobjectName == 'T_SBSD_INDIV__c'){
                            relationshipObj.IDN_CLIENT__c =component.get("v.recordId");
                        }
                    }*/
                }
            } else {
            }
        });        
        $A.enqueueAction(action); 
    }
})