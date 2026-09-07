({
    /*
    doInit : function(component, event, helper) {
        if(component.get("v.convertTime")==true){
            
            var dateWithTime = component.get("v.value");
            if(!$A.util.isEmpty(dateWithTime)){
                // Provides locale information
                var format = $A.get("$Locale.timeFormat");
                format = format.replace(":ss", "");
                var langLocale = $A.get("$Locale.langLocale");
                var timezone = $A.get("$Locale.timezone");
                var newDate = new Date(dateWithTime);
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
                    var onlyDate = yyyy+'-'+MM+'-'+dd;
                    component.set("v.val",onlyDate);
                    component.set("v.value",onlyDate);
                });                
            }
        }else{
            var dateWithTime = component.get("v.value");
            if(dateWithTime && dateWithTime!=null){
                var onlyDate = dateWithTime.toString().substring(0,10);
                component.set("v.val",onlyDate);
            }
        }
    }, 
    updateVal : function(component, event, helper) {
        var value = component.get("v.value");
        if(value && value!=null){
            var onlyDate = value.toString().substring(0,10);
            component.set("v.val",onlyDate);
        }
    },
    doCheckInputDateFieldvalidity : function(component, event, helper) {
        var inputCmp =  component.find('inputDate');
        inputCmp.showHelpMessageIfInvalid();
        component.set("v.validity",inputCmp.get('v.validity'));
    },
    updateValue : function(component, event, helper) {
        component.set("v.value",component.get("v.val"));
    } 
    */
    
    checkValidity: function(component, event, helper) {
        var valid = true;
        var date = component.get("v.value");
        var dateStr = date;
        var dateArr;
        var dayStr;
        var monthStr;
        if(!$A.util.isEmpty(date)){
            dateArr = date.split("/");
            if(!$A.util.isEmpty(dateArr)){
                if(dateArr.length > 1){
                    dayStr = dateArr[1];
                    monthStr = dateArr[0];
                }
            }
        }
        if(component.get("v.required") == true && $A.util.isEmpty(component.get("v.value"))) {
            component.set("v.validity", {'valid':false});
            component.find("inputDate").set("v.errors", [{"message":"Please enter a value."}]);
        } else if(!$A.util.isEmpty(component.get("v.value"))) {
            if(date.length <8){
                valid = false; 
            }
            date = helper.getDateInUTC(new Date(date));
            var month = parseInt(date.getMonth());
            var day   = parseInt(date.getDate());
            var year  = parseInt(date.getFullYear());
            if(isNaN(month) || isNaN(day) || isNaN(year)){
                valid = false;
            }
            var yearSt = year.toString();
            if(yearSt.length > 3){
                var dateYrArr = dateStr.split("-");
                if(!$A.util.isEmpty(dateYrArr)){
                    if(dateYrArr.length > 1){
                        var yearStr = dateYrArr[0];
                        dayStr = dateYrArr[2];
                        monthStr = dateYrArr[1];
                        var yearInt = parseInt(yearStr);
                        // Salesforce can accept dates between Jan 1, 1700 and December 31, 4000
                        if((!$A.util.isEmpty(yearInt)) && (yearInt < 1700 || yearInt > 4000)){
                            valid = false;
                        }
                    }
                }
            }
            if((month < 0) || (month > 11)) {
                valid = false;
            } else if((dayStr < 1) || (dayStr > 31)) {
                valid = false;
            } else if(((monthStr == 6) || (monthStr == 4) || (monthStr == 9) || (monthStr == 11)) && (dayStr > 30)) {
                valid = false;
            } else if((month == 1 || monthStr == 2) && (((year % 400) == 0) || ((year % 4) == 0)) && ((year % 100) != 0) && (dayStr > 29)) {
                valid = false;
            } else if((month == 1 || monthStr == 2) && ((year % 100) == 0) && (dayStr > 29)) {
                valid = false;
            } else if((month == 1 || monthStr == 2) && (dayStr > 28)) {
                var isLeapYear = helper.leapYear(year);
                if(!isLeapYear){
                    valid = false; 
                }
            } else if((year < 1700 || year > 4000)) {
                // Salesforce can accept dates between Jan 1, 1700 and December 31, 4000
                valid = false;
            } else if(!$A.util.isEmpty(dateArr)) {
                if(dateArr.length > 1){
                    var yearStr = dateArr[2];
                    var yearInt = parseInt(yearStr);
                    if((!$A.util.isEmpty(yearStr)) && yearStr.length < 4){
                        valid = false; 
                    }
                    if((!$A.util.isEmpty(yearInt)) && yearInt < 1000){
                        valid = false;
                    }
                }
            }
            if(!valid){
                component.find("inputDate").set("v.errors", [{"message":"Please enter valid date format(MM/DD/YYYY) or valid date."}]);
                component.set("v.validity", {'valid':false});
            } else {
                component.find("inputDate").set("v.errors", []);
                component.set("v.validity", {'valid':true});
            }
        } else {
            component.set("v.validity", {'valid':true});
            component.find("inputDate").set("v.errors", []);
        }
    },
    
    showCustomError: function(component, event, helper) {
        component.find("inputDate").set("v.errors", [{"message":component.get("v.errorMessage")}]);
        component.set("v.validity", {'valid':false});
    },
    
    hideCustomError: function(component, event, helper) {
        component.find("inputDate").set("v.errors", []);
        component.set("v.validity", {'valid':false});
    }
})