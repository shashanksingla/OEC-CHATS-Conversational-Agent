({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        
        var isValid = true;
        var adjustment = cmp.get("v.adjustment");
        if(adjustment && cmp.get("v.pageMode")!='view'){
            debugger;
            var responsiblePartyObj = cmp.get("v.responsiblePartyObj");
            if(responsiblePartyObj.Selected__c){
                console.log('message--'+cmp.find("IPVRecordId").get("v.message"));
                if(!$A.util.isEmpty(cmp.find("IPVRecordId").get("v.message"))){
                    isValid =false;
                }
            }
            console.log('isValid- in -'+isValid);
        }
        return isValid;
    },
    fireEventHlp :function(component, event, helper) {
        var responsiblePartyObj = component.get("v.responsiblePartyObj");
        console.log('responsiblePartyObj@@ -'+JSON.stringify(responsiblePartyObj));
        var responsiblePartyList = component.get("v.responsiblePartyList");
        var IPVRecordId = component.get("v.IPVRecordId");
        var adjustment = component.get("v.adjustment");
        if(responsiblePartyObj.Selected__c){
            if(adjustment.CDE_TYPE_CLSFN__c =='1'){
                component.set("v.IPVRecordReq",true);
            }else{
                component.set("v.IPVRecordReq",false);   
            }
            var ipvRec = component.find("IPVRecordId");
            if($A.util.isEmpty(responsiblePartyObj.IPV_Info__c) && (adjustment.CDE_TYPE_CLSFN__c =='1') && ipvRec != undefined){
                ipvRec.set("v.message","Investigation Record ID is a required field when Classification Type is Fraud/IPV.");
            }else{
                if(ipvRec != undefined)
                	ipvRec.set("v.message","");
                // new code for validation
                if(component.get("v.adjustment").CDE_TYPE_ADJMT__c=='Recovery' && component.get("v.adjustment").IDN_CASE__c!=null && component.get("v.adjustment").IDN_CASE__c!=undefined){
                    if(!$A.util.isEmpty(responsiblePartyObj.IPV_Info__c)){
                        this.getIPVRecord(component,event,helper);
                    }else{
                        if(ipvRec != undefined)
                        	ipvRec.set("v.message","");
                        component.set("v.IPVRecordReq",false);
                        var appEvent = $A.get("e.c:createRespParty");
                        appEvent.setParams({ "selectedRec":responsiblePartyObj.Selected__c,"responsiblePartyObj" : responsiblePartyObj ,"key":responsiblePartyObj.IDN_CLIENT__c, "responsiblePartyList" : responsiblePartyList });
                        appEvent.fire();
                    }
                }
                // end
            }
        }
        else{
            component.find("IPVRecordId").set("v.message","");
            component.set("v.IPVRecordReq",false);
            var appEvent = $A.get("e.c:createRespParty");
            appEvent.setParams({ "selectedRec":responsiblePartyObj.Selected__c,"responsiblePartyObj" : responsiblePartyObj ,"key":responsiblePartyObj.IDN_CLIENT__c, "responsiblePartyList" : responsiblePartyList });
            appEvent.fire(); 
            
        }
        
    },
    getIPVRecord :function(component, event, helper) {
        debugger;
        var responsiblePartyObj = component.get("v.responsiblePartyObj");
        var responsiblePartyList = component.get("v.responsiblePartyList");
        console.log('responsiblePartyObj--'+JSON.stringify(responsiblePartyObj));
        var action1 = component.get('c.getSelectedIPVRecord');
        action1.setParams({
            'IPVRecordId' : responsiblePartyObj.IPV_Info__c
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    console.log('respone---'+JSON.stringify(res));
                    if(res.objectData.IPVRecord){
                        component.set("v.IPVRecord", res.objectData.IPVRecord); 
                        var IPVRecord = component.get("v.IPVRecord");
                        if(!$A.util.isEmpty(responsiblePartyObj.IPV_Info__c) && !$A.util.isEmpty(IPVRecord) && !$A.util.isEmpty(IPVRecord.Individual_ID__c) && !$A.util.isEmpty(responsiblePartyObj) ){
                            console.log('inside the check');
                            debugger;
                            if(responsiblePartyObj.IDN_CLIENT__c != IPVRecord.Individual_ID__c){
                                //show erro
                                debugger;
                                component.find("IPVRecordId").set("v.message","Investigation Record ID is not associated with the individual selected.  Please verify and update the record ID.");
                                console.log('inside the check loop'+IPVRecord.Individual_ID__c);
                            }else{
                                var appEvent = $A.get("e.c:createRespParty");
                                appEvent.setParams({ "selectedRec":responsiblePartyObj.Selected__c,"responsiblePartyObj" : responsiblePartyObj ,"key":responsiblePartyObj.IDN_CLIENT__c, "responsiblePartyList" : responsiblePartyList });
                                appEvent.fire();  
                            }
                        }
                    }  else{
                        debugger
                        component.find("IPVRecordId").set("v.message","Investigation Record ID is not associated with the individual selected.  Please verify and update the record ID.");
                        console.log('inside the check else respone loop'+IPVRecord.Individual_ID__c);
                    } 
                }
            } else {
                console.log('error in InputPicklist');
            }
        });        
        $A.enqueueAction(action1);
        
    }
})