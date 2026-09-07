({
    doInit : function(component, event, helper) {
        var map = component.get("v.map");
        var day = component.get("v.day");
        
        if(day && day.Day){
            var dt = day.Day;
            var key = dt.getFullYear()+'-'+(dt.getMonth()+1)+'-'+dt.getDate();
            key = key.replace(/-0+/g, '-');
            component.set("v.key", key);
            var map = component.get("v.map");
            var isReadOnly = component.get("v.isReadOnly");
            
            if(key in map){
                var authEncmbr = map[key];
                component.set("v.anAuthEncmbr", authEncmbr);
                component.set("v.isRateTypeReadOnly", false);
                component.set("v.isCntHrReadOnly", false);
                component.set("v.originalHours", authEncmbr.cnt_hour_care__c);
                component.set("v.originalRateType", authEncmbr.cde_type_unit_care__c);
                if(authEncmbr.dte_care__c < helper.getPriorDate(9) ){
                    component.set("v.isRateTypeReadOnly", true);
                    component.set("v.isCntHrReadOnly", true);
                }
            }
            else{
                component.set("v.isRateTypeReadOnly", true);
                component.set("v.isCntHrReadOnly", true);
            }
            if(isReadOnly){
               component.set("v.isRateTypeReadOnly", true);
               component.set("v.isCntHrReadOnly", true); 
            }
            // set the values of map to the value attribute	
            // to get map values in lightning component use "map[key]" syntax. 
            
            // component.set("v.authEncmbrId", anAuthEncmbr);
            component.set("v.dayInCalendar", dt.getDate());
			
            var closureDates = component.get("v.provClosDteOptions");
            if(closureDates != undefined && closureDates != null){
                for(var i=0; i<closureDates.length; i++){                 
                    if(closureDates[i] == key){ 
                        component.set("v.isRateTypeReadOnly", true);
                        component.set("v.isCntHrReadOnly", true);
                        var rec = component.get("v.anAuthEncmbr");
                        rec.cnt_hour_care__c = 0;
                        component.set("v.anAuthEncmbr", rec);
                    }
                }
            }            
        }
    },
    updateAuthEncmbr : function(component, event, helper) {
        
        if(component.get("v.updatedSuccessfully")!= 'false' && component.get("v.isDirty")=='true'){ 
            helper.callServerAndHandleError(component,"c.callUpdate", 
                                            function(response){
                                                if(response.isSuccessful==true){
                                                    component.set("v.updatedSuccessfully", 'true');
                                                    component.set("v.isDirty",false);
                                                    var authEncmbr= component.get("v.anAuthEncmbr");
                                                    component.set("v.originalHours", authEncmbr.cnt_hour_care__c);
                                                    component.set("v.originalRateType", authEncmbr.cde_type_unit_care__c);
                                                }
                                                else{
                                                    component.set("v.updatedSuccessfully", 'false');
                                                    component.set("v.recordError",'Problem saving record, error: ' + response.message);  
                                                }
                                            }, {'authEncumbRec':component.get("v.anAuthEncmbr")}, false, null);
        }
    },
    markItDirty : function(component, event, helper) {
        var allValid = component.find('input-field').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        var anAuthEncmbr = component.get("v.anAuthEncmbr");
        var originalHours = parseInt(component.get("v.originalHours"));
        var enteredHours = parseInt(anAuthEncmbr.cnt_hour_care__c);
        var originalRateType = component.get("v.originalRateType");
        var enteredRateType = anAuthEncmbr.cde_type_unit_care__c;
        var authTerminated= component.get("v.authTerminated");
         if(enteredHours.toString()=='NaN'){
            component.set("v.updatedSuccessfully", 'false');
            component.set("v.recordError",'Value Cannot Be Blank');
        }
        else if (originalHours < enteredHours && anAuthEncmbr.dte_care__c < helper.getPriorDate(9)  ){
            component.set("v.updatedSuccessfully", 'false');
            component.set("v.recordError",'You can increase the value only for records today minus 9 days in the past through the end of the authorization');
            
        }
        else if (originalHours > enteredHours && anAuthEncmbr.dte_care__c <= helper.getCurrentSystemDate()  ){
            component.set("v.updatedSuccessfully", 'false');
            component.set("v.recordError",'Cannot decrease hours for past or current date');
            
        }
                else{
                    if(allValid){
                    component.set("v.updatedSuccessfully", '');
                    component.set("v.isDirty", 'true');
                    component.set("v.recordError",'');
                    var appEvent = $A.get("e.c:createEncumbranceEvent");
                    appEvent.setParams({ "encumbranceRec" : anAuthEncmbr , "isDelete" : false});
        			appEvent.fire();
                    }
                }
        if (originalRateType != enteredRateType){
            if (originalHours > enteredHours && anAuthEncmbr.dte_care__c <= helper.getCurrentSystemDate()  ){
                debugger;
                component.set("v.updatedSuccessfully", 'false');
                component.set("v.recordError",'Cannot decrease hours for past or current date');
                
            }else{
                component.set("v.updatedSuccessfully", '');
                component.set("v.isDirty", 'true');
                component.set("v.recordError",'');
                if(allValid){
                    var appEvent = $A.get("e.c:createEncumbranceEvent");
                    appEvent.setParams({ "encumbranceRec" : anAuthEncmbr, 'isDelete' :false });
                    appEvent.fire();
                }
            }
        }
        if(originalRateType == enteredRateType && originalHours == enteredHours){
            component.set("v.updatedSuccessfully", '');
            component.set("v.isDirty", 'false');
            component.set("v.recordError",'');  
        	var appEvent = $A.get("e.c:createEncumbranceEvent");
            appEvent.setParams({ "encumbranceRec" : anAuthEncmbr, 'isDelete' :true });
        	appEvent.fire();
        }
        if(enteredRateType == '' || enteredRateType == null){
           component.set("v.updatedSuccessfully", 'false');
           component.set("v.recordError",'Rate Type Cannot be None'); 
        }
        if(!allValid){
           component.set("v.updatedSuccessfully", 'false'); 
        }
        
    }
})