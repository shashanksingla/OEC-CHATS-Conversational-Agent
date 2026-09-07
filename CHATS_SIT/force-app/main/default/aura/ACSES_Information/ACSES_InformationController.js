({
    ACSESCallout : function(cmp, e, h) {
        try{
            cmp.set("v.toggleSpinner",true);
            var isInputValid = cmp.get("v.supportType") && cmp.get("v.parentStateId");
            var errorMessage = !cmp.get("v.supportType") && !cmp.get("v.parentStateId")?'Please select Search Type and Parent name':
            (cmp.get("v.supportType") && !cmp.get("v.parentStateId"))?'Please select Parent Name':
            (!cmp.get("v.supportType") && cmp.get("v.parentStateId"))?'Please select Search Type':'No Error';
            if(errorMessage === "No Error"){
                cmp.set("v.recordError",null);
                h.sendACSESRequest(cmp);
                if(!cmp.get("v.endDate")){
                    var setNewDate = new Date();
                    setNewDate = setNewDate.getFullYear()+'-'+(setNewDate.getMonth() + 1 )+ '-'+ setNewDate.getDate();
                    cmp.set("v.endDate",setNewDate);
                }
            }else
                h.errorChecker(cmp,['Error: '+errorMessage]);
        }catch(e){
            h.errorChecker(cmp,['Error: '+e]);
        }
    },
    redirect: function (){
        window.history.back();
    },
    getParentStateId : function(cmp, e, h){
        var options = [], caseId = cmp.get("v.caseId"), action = cmp.get("c.parentStateIdToNameMap");
        action.setParams({ "caseId" : caseId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var res = JSON.parse(response.getReturnValue());
                if(res){
                    for(var i in res)
                        options.push({label: res[i].NAM_INDIV__c , value: res[i].IDN_STATE__c });
                }
                cmp.set("v.parentNameStateId",options);
            }else if (state === "ERROR") {
                h.errorChecker(cmp,response.getError());
            }else
                h.errorChecker(cmp,['State - for Parent State Id check:'+state]);
        });
        $A.enqueueAction(action);
    }
})