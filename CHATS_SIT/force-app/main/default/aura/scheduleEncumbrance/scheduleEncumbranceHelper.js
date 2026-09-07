({
    checkForDuplicateSchedule : function(component,event, helper) {
        var isDuplicate=false;
        var scheduleRecurrObj = component.get("v.scheduleRecurrObj");
        var scheduleRecurr = component.get("v.scheduleRecurr");
        debugger;
        console.log('scheduleRecurrObj--'+JSON.stringify(scheduleRecurrObj));
        console.log('scheduleRecurr--'+JSON.stringify(scheduleRecurr));
        if(!$A.util.isEmpty(scheduleRecurr) && !$A.util.isEmpty(scheduleRecurr) ){
            debugger;
            for(let obj of scheduleRecurr){
                debugger;
                console.log('obj--'+JSON.stringify(obj));
                if((obj.DTE_Begin_Date__c ==scheduleRecurrObj.DTE_Begin_Date__c) || (obj.DTE_End_Date__c ==scheduleRecurrObj.DTE_End_Date__c)||
                (scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_End_Date__c >= obj.DTE_Begin_Date__c) ||
                (scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_End_Date__c >= obj.DTE_End_Date__c)|| 
                (scheduleRecurrObj.DTE_Begin_Date__c >= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_End_Date__c)||
                (scheduleRecurrObj.DTE_Begin_Date__c >= obj.DTE_Begin_Date__c && scheduleRecurrObj.DTE_End_Date__c <= obj.DTE_End_Date__c)||
                (scheduleRecurrObj.DTE_Begin_Date__c <= obj.DTE_End_Date__c && scheduleRecurrObj.DTE_End_Date__c >= obj.DTE_End_Date__c)){
                 
                 isDuplicate =true;
                 break;
             }
            }
        }
        return isDuplicate;
    },
    checkCustomValidations : function(component,event, helper) {
        console.log('iscreate--'+component.get("v.isCreate"));
        var scheduleRecurrObj = component.get("v.scheduleRecurrObj");
        var isValid=false;
        var cmpBeginDate = component.find("inputDate").get('v.value');
        debugger;
        var todayDate = new Date();
        var todayDateUTC = helper.getDateInUTC(todayDate);
        var todayDateMinus9Days = todayDateUTC;
        todayDateMinus9Days = todayDateMinus9Days.setDate(todayDateMinus9Days.getDate() - 9);

        var isCreate = component.get("v.isCreate");
        var endDate = component.find("endDate").get('v.value');
        var validityBeginDate = helper.checkValidity(component, event, helper,cmpBeginDate,"inputDate");
        var validityEndDate =  helper.checkValidity(component, event, helper,endDate,"endDate");
        var inputCmp =  component.find('picklist');
        var validity;
        if(!$A.util.isEmpty(inputCmp)){
            inputCmp.showHelpMessageIfInvalid();
            validity = inputCmp.get("v.validity");
        }
        debugger;
        console.log('validityBeginDate--'+validityBeginDate);
        console.log('validityEndDate--'+validityEndDate);
        debugger;
        if(validityBeginDate && validityEndDate){
            var beginDate = helper.getDateInUTC(cmpBeginDate);
            var endDate1 = helper.getDateInUTC(endDate);
            var authBeginDate = helper.getDateInUTC(component.get("v.authBeginDate"));
            //var authEndDate = helper.getDateInUTC(component.get("v.authEndDate"));
            var authEndDate = component.get("v.authEndDate");
            debugger;
            console.log('authBeginDate--'+authBeginDate);
            console.log('beginDate--'+beginDate);
            console.log('endDate1--'+endDate1);
            console.log('authEndDate--'+authEndDate);
            console.log('authEndDate-without convert-'+component.get("v.authEndDate"));
            if(beginDate >endDate1){
                debugger;
                component.find("inputDate").set("v.errors",[{"message":"Begin Date can not be greater than End Date."}]);
                validityBeginDate =false;
            }else if(beginDate<authBeginDate){
                debugger;
                var formattedAuthBeginDate =  this.padNumber(authBeginDate.getMonth() + 1) + '/' + this.padNumber(authBeginDate.getDate()) +'/'+authBeginDate.getFullYear();
                var beginMsg= "Begin date cannot be less than authorization begin date, "+formattedAuthBeginDate;
                component.find("inputDate").set("v.errors",[{"message":beginMsg}]);
                validityBeginDate =false;
            }else if(endDate1>authEndDate){
                debugger;
                var formattedAuthEndDate =  this.padNumber(authEndDate.getMonth() + 1) + '/' + this.padNumber(authEndDate.getDate()) +'/'+authEndDate.getFullYear();
                var endMsg= "End date cannot be greater than authorization end date, "+formattedAuthEndDate;
                component.find("endDate").set("v.errors",[{"message":endMsg}]);
                validityEndDate =false;
            }

              if(beginDate <todayDateMinus9Days){
                component.find("inputDate").set("v.errors",[{"message":"Begin Date can not be prior to today + 9 days in past."}]);
                validityBeginDate =false;
            } else if(beginDate<todayDateUTC && (!isCreate)){
                debugger;
                var beginMsg= "Begin date should be in future";
                component.find("inputDate").set("v.errors",[{"message":beginMsg}]);
                validityBeginDate =false;
            }
            
        }
        if(scheduleRecurrObj.Recur_Type__c ==='Monthly'){
            if(validityBeginDate && validityEndDate && validity.valid){
                isValid = true;
                component.set("v.valid",isValid);
                debugger;
            }
        }else if(validityBeginDate && validityEndDate){
            isValid = true;
            component.set("v.valid",isValid);
            debugger;
        }
        
        console.log('isValid before return--'+isValid);
        return isValid;
    },
    checkValidity: function(component, event, helper,date,auraId) {
        var valid = true;
        var validity = true;
        var dateStr = date;
        var dateArr;
        var dayStr;
        var monthStr;
        debugger;
        if(!$A.util.isEmpty(date)){
            dateArr = date.split("/");
            if(!$A.util.isEmpty(dateArr)){
                if(dateArr.length>1){
                    dayStr = dateArr[1];
                    monthStr = dateArr[0];
                }
            }
        }
        
        if( $A.util.isEmpty(date)){
            debugger;
            validity = false;
            component.set("v.validity",{'valid':false});
            component.find(auraId).set("v.errors",[{"message":"Please enter a value."}]);
        }else if(!$A.util.isEmpty(date)){
            if(date.length <8){
                valid = false; 
            }
            date = helper.getDateInUTC(new Date(date));
            
            var month = parseInt(date.getMonth());
            var day   = parseInt(date.getDate());
            var year  = parseInt(date.getFullYear());
            if(isNaN(month) || isNaN(day) || isNaN(year))  valid = false;
            
            var yearSt = year.toString();
            if(yearSt.length >3){
                var dateYrArr = dateStr.split("-");
                if(!$A.util.isEmpty(dateYrArr)){
                    if(dateYrArr.length>1){
                        var yearStr =dateYrArr[0];
                        dayStr = dateYrArr[2];
                        monthStr = dateYrArr[1];
                        var yearInt  =parseInt(yearStr);
                        
                        if((!$A.util.isEmpty(yearInt)) && (yearInt< 1000 || yearInt >9999) ){
                            valid = false;   
                        }
                    }
                }
            }
            
            if((month < 0) || (month > 11)) {
                
                valid = false;
            }
            else if((dayStr < 1) || (dayStr > 31)) {valid = false;}
                else if(((monthStr == 6) || (monthStr == 4) || (monthStr == 9) || (monthStr == 11)) && (dayStr > 30)){   
                    
                    valid = false;
                }
                    else if((month == 1 || monthStr == 2) && (((year % 400) == 0) || ((year % 4) == 0)) && ((year % 100) != 0) && (dayStr > 29)) {
                        
                        
                        valid = false;}
                        else if((month == 1 || monthStr == 2) && ((year % 100) == 0) && (dayStr > 29)) {valid = false;}
                            else if((month == 1 || monthStr == 2) && (dayStr > 28)){
                                var isLeapYear = helper.leapYear(year);
                                if(!isLeapYear){
                                    valid = false; 
                                }
                            }
                                else if( (year <1000 || year >9999)){ valid = false; }
                                    else if(!$A.util.isEmpty(dateArr)){
                                        if(dateArr.length>1){
                                            var yearStr =dateArr[2];
                                            var yearInt  =parseInt(yearStr);
                                            
                                            if((!$A.util.isEmpty(yearStr)) && yearStr.length <4){
                                                valid = false; 
                                            }
                                            if((!$A.util.isEmpty(yearInt)) && yearInt< 1000){
                                                valid = false;   
                                            }
                                        }
                                    }
            
            if(!valid){
                debugger;
                component.find(auraId).set("v.errors",[{"message":"Please enter valid date format(MM/DD/YYYY) or valid date."}]);
                component.set("v.validity",{'valid':false});
                component.set("v.valid",false);
                validity = false;
            }else{
                component.find(auraId).set("v.errors",[]);
                debugger;
                component.set("v.valid",true);
                validity = true;
                component.set("v.validity",{'valid':true});
            }
        }else{
            debugger;
            validity = true;
            component.set("v.validity",{'valid':true});
            component.find(auraId).set("v.errors",[]);
        }
        return validity;
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    leapYear :function(year)
    {
        return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    },
    finish :  function(component,event, helper,scheduleRecurrObj) {
        debugger;
        component.set("v.scheduleRecurrObj",scheduleRecurrObj);
        var isDuplicate = helper.checkForDuplicateSchedule(component,event, helper);
        if(isDuplicate){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "type":"error",
                "message": 'A reoccurrence pattern already exists for the date/s entered.'
            });
            toastEvent.fire();
        }else{
            var scheduleRecurr = component.get("v.scheduleRecurr");
            scheduleRecurr.push(scheduleRecurrObj);
            component.set("v.isModifiedAfterChange",true);
            console.log('scheduleRecurr arr--'+JSON.stringify(scheduleRecurr));
            //component.set("v.scheduleRecurrObj",{'sobjectType':'Auth_Schedule_Recurrence__c','Recur_Type__c':'','RecurDay__c':'','DaysOfMonth__c':'','DTE_Begin_Date__c':'','DTE_End_Date__c':''});
            component.set("v.showSpinner",false);
            component.set("v.scheduleRecurr",scheduleRecurr);
            var dateToSelect =component.get("v.dateToSelect");
            if(!$A.util.isEmpty(dateToSelect)){
                for(var i=0;i<dateToSelect.length;i++){
                    console.log('dateToSelect--'+JSON.stringify(dateToSelect[i]));
                    console.log('dateToSelect[]--'+dateToSelect[i].selected);
                    dateToSelect[i].selected =false;
                   // dateToSelect[i].set("v.selected", false);
                }
            }
          debugger;
            console.log('dateToSelect--'+JSON.stringify(dateToSelect));
            component.set("v.dateToSelect",[]);
            component.set("v.dateToSelect",dateToSelect);
            component.set("v.scheduleRecurrObj",{'sobjectType':'Auth_Schedule_Recurrence__c','Recur_Type__c':'','RecurDay__c':'','DaysOfMonth__c':'','DTE_Begin_Date__c':'','DTE_End_Date__c':''});
            var weekTimes =component.find("weekTime");
            if(!$A.util.isEmpty(weekTimes)){
                for(var i=0;i<weekTimes.length;i++){
                    console.log('weekTimes--'+JSON.stringify(weekTimes[i]));
                    console.log('weekTimes[]--'+weekTimes[i].checked);
                    weekTimes[i].set("v.checked", false);
                }
            }
            component.set("v.dayNamesSelected",[]);
            component.set("v.jobFrequency",'');
           debugger;
            //component.set("v.enterRecurrence",false);
            debugger;
        }
    },
    padNumber : function(number) {
        var string  = '' + number;
        string      = string.length < 2 ? '0' + string : string;
        return string;
    },
    deleteRecurrence: function(component, event, helper,recId){
        var action = component.get('c.deleteSchedule');
        action.setParams({
            'recordId' : recId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type":"success",
                        "message": 'Authorization Recurrence has been deleted successfully.'
                    });
                    toastEvent.fire();
                }
            } 
        });        
        $A.enqueueAction(action);
    },
})