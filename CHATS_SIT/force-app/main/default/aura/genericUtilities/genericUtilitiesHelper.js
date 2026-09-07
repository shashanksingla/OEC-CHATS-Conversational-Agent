({
    //Generic Method to call server methods. Accepts component, methodName, callback function, parameters to be passed to server method and cacheable as input
    callServer : function(cmp, method, callback, params, cacheable) {
        var action = cmp.get(method);
        
        if (params) {
            action.setParams(params);
            
        }
        if (cacheable) {
            action.setStorable();
        }
        cmp.set("v.showSpinner", true);
        
        action.setCallback(this,function(response) {
            cmp.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") { 
                // pass returned value to callback function
                callback.call(this, response.getReturnValue()); 
            } else if (state === "ERROR") {
                // generic error handler
                var errors = response.getError();
                var errorMsg = '';
                
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        errorMsg = errors[0].message;
                    }
                } else {
                    errorMsg = "Unknown Error";
                }                
                cmp.set("v.error",errorMsg+",Details:"+JSON.stringify(errors));
                
            }
        });  
        $A.enqueueAction(action);
    },
    merge : function(obj1,obj2){
        var obj3 = {};
        for (var attrname in obj1) { obj3[attrname] = obj1[attrname]; }
        for (var attrname in obj2) { obj3[attrname] = obj2[attrname]; }
        return obj3;
    },
    getCurrentSystemDate : function(addDays,addMonths,addYears){
        
        var today = new Date();
        var dd = addDays?today.getDate()+addDays:today.getDate();
        var MM = addMonths?today.getMonth()+1+addMonths:today.getMonth()+1;
        var yyyy = addYears?today.getFullYear()+addYears:today.getFullYear();
        if(dd<10){
            dd='0'+dd;
        } 
        if(MM<10){
            MM='0'+MM;
        } 
        return yyyy+'-'+MM+'-'+dd;
    },
    handleDate : function(dateValue,addDays,addMonths,addYears){
        
        
        var dd = addDays?dateValue.getDate()+addDays:dateValue.getDate();
        var MM = addMonths?dateValue.getMonth()+1+addMonths:dateValue.getMonth()+1;
        var yyyy = addYears?dateValue.getFullYear()+addYears:dateValue.getFullYear();
        if(dd<10){
            dd='0'+dd;
        } 
        if(MM<10){
            MM='0'+MM;
        } 
        return yyyy+'-'+MM+'-'+dd;
    },
    redirectToLightningComponent : function(componentName, params){
        
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : componentName,
            componentAttributes: params
        });
        evt.fire();            
    },
    redirectToRecord : function(recordId){
        var navEvt = $A.get("e.force:navigateToURL");
        navEvt.setParams({
            "url": "/" + recordId
//            "slideDevName": "detail"
        });
        navEvt.fire();
    },
    fireToast : function(mode, type, title, message){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "mode": mode,
            "type": type,
            "title": title,
            "message": message
        });
        toastEvent.fire();
    },
    convertDateToUserTimezone : function(component,dateWithTime,variableName){
        if(!$A.util.isEmpty(dateWithTime)){
            // Provides locale information
            var format = $A.get("$Locale.timeFormat");
            format = format.replace(":ss", "");
            var langLocale = $A.get("$Locale.langLocale");
            var timezone = $A.get("$Locale.timezone");
            
            
            $A.localizationService.UTCToWallTime(new Date(dateWithTime), timezone, function(walltime) {
                
                var dd = walltime.getDate();
                var MM = walltime.getMonth()+1;
                var yyyy = walltime.getFullYear();
                if(dd<10){
                    dd='0'+dd;
                } 
                if(MM<10){
                    MM='0'+MM;
                } 
                //var onlyDate = walltime.getMonth()+'/'+walltime.getDate()+'/'+walltime.getYear();
                var onlyDate = yyyy+'-'+MM+'-'+dd;
                
                component.set("v."+variableName,onlyDate);
                
                // Returns the local time without the seconds, for example, 9:00 PM
                //displayValue = $A.localizationService.formatDateTimeUTC(walltime, format, langLocale);
            });                
        }
    },
    getTimeConversionOffset : function(component,variableName){
        var timezone = $A.get("$Locale.timezone");
        var self=this;
        $A.localizationService.WallTimeToUTC(new Date(), timezone, function(utc) {
            
            var todayDate = new Date();
           
           
            var offset = 0;
            if(utc.getDate()!=todayDate.getDate()){
                if(utc.getDate()>todayDate.getDate()){
                    offset = 1;
                }else if(utc<new Date()){
                    offset = -1;
                }   
				       
                component.set("v."+variableName,offset);                
            }
        });        
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    leapYear : function(year){
        
        return (year % 100 === 0) ? (year % 400 === 0) : (year % 4 === 0);
    }       
})