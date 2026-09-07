({
    getEmploymentPayStubHlp : function(component, event, helper) {
        var action = component.get('c.getDoInit');
        action.setParams({
            'recordId':component.get("v.newEmploymentPayStabObj").IDN_EMPLMT_INCOME__c
        });
        console.log('input---'+JSON.stringify(component.get("v.newEmploymentPayStabObj")));
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                console.log('res--in provider--'+JSON.stringify(res));
                if(res.isSuccessful){
                    var employmentPayStabObj = component.get("v.newEmploymentPayStabObj");
                    console.log("res.---"+JSON.stringify(res));
                    if(res.objectData.getSobjectName != undefined){
                        if(res.objectData.getSobjectName == 'T_EMPLMT_INCOME__c'){
                            employmentPayStabObj.IDN_EMPLMT_INCOME__c =component.get("v.recordId");
                        }
                    }
                    component.set("v.options", res.objectData.rateTypeOptions);
                }
            } else {
            }
        });        
        $A.enqueueAction(action); 
    }
})