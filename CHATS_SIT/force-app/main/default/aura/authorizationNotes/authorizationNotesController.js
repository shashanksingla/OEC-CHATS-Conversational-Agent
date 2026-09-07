({
    doInit : function(component, event, helper) {
        var action1 = component.get("c.fetchLoggedInUserId");
        action1.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.loggedInUserId", response.getReturnValue());
            } else {
               
            }
        });
        $A.enqueueAction(action1);
        // Getting SobjectName
        var action2 = component.get("c.getSobjectName");
        action2.setParams({"recordId": component.get("v.recordId")});
        action2.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                component.set("v.isSobjectName",true);
                if(res.objectData.sObjName){
                    component.set("v.sObjectName", res.objectData.sObjName);
                    if(res.objectData.sObjName =='T_AUTH__c'){
                        component.set("v.isNew",true);
                    }else{
                        component.set("v.isNew",false);  
                    }  
                }
                if(res.objectData.authNote){
                    var simpleNewAuthNotes = component.get("v.simpleNewAuthNotes");
                    var authNote = res.objectData.authNote[0];
                    simpleNewAuthNotes.idn_auth__c = authNote.idn_auth__r.Id;
                    
                    
                    component.set("v.simpleNewAuthNotes",simpleNewAuthNotes);
                    component.set("v.isAuthIdChangeFirst",true);
                }
            } else {
               
            }
        });
        $A.enqueueAction(action2);
    },
    handleDefaultAuthChange : function(component, event, helper){
         component.set("v.isAuthIdChangeFirst",true);
        var simpleNewAuthNotes = component.get("v.simpleNewAuthNotes");
        simpleNewAuthNotes.idn_auth__c = component.get("v.authRec").Id;
        
        component.set("v.simpleNewAuthNotes",simpleNewAuthNotes);
    },
    saveRecord : function(component, event, helper){
        var simpleNewAuthNotes = component.get("v.simpleNewAuthNotes");
        var isNew = component.get("v.isNew");
        if(simpleNewAuthNotes.idn_auth__c =='' || simpleNewAuthNotes.idn_auth__c == undefined){
             var recordError2 =[];
                    recordError2.push('Please enter Mandatory fields');
                    component.set("v.message",'error');
                    component.set("v.recordError",recordError2);
            
        }else if(simpleNewAuthNotes.txt_notes__c =='' || simpleNewAuthNotes.txt_notes__c == undefined){
             var recordError1 =[];
                    recordError1.push('Please enter Mandatory fields');
                    component.set("v.message",'error');
                    component.set("v.recordError",recordError1);
        }else{
            helper.checkValidations(component, event, helper);
        }
       // if(!isNaN(simpleNewAuthNotes.idn_notes_auth__c) && simpleNewAuthNotes.idn_notes_auth__c >0){
            
          
       /* }else if(isNaN(simpleNewAuthNotes.idn_notes_auth__c)){
            var recordError =[];
            recordError.push('Please Note ID should be number.');
            component.set("v.message",'error');
            component.set("v.recordError",recordError);
        }else if(simpleNewAuthNotes.idn_notes_auth__c <=0){
            var recordError1 =[];
            recordError1.push('Please Note ID should be greater than 0.');
            component.set("v.message",'error');
            component.set("v.recordError",recordError1);
        } */
    },
    handleCancelAuthNote : function(component, event, helper) {
        helper.redirectToRecord(component.get("v.recordId"));
    },
    handleAuthIdChange :function(component, event, helper) {
        
        component.set("v.isAuthIdChange",true);
        var isNew = component.get("v.isNew");
        var isAuthIdChangeFirst = component.get("v.isAuthIdChangeFirst");
        if(isAuthIdChangeFirst){
            component.set("v.isAuthIdChangeFirst",false);
            component.set("v.isAuthIdChange",false);
            
        }
    },
    handleRecordUpdated :function(component, event, helper) {
    },
})