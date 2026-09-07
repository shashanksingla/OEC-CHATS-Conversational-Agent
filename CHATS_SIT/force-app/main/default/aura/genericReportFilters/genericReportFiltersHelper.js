({
    checkCustomValidations : function(component){
        var validity = true;
        var validityPicklist = {};
        validityPicklist.valid = true;
        if(!$A.util.isEmpty(component.find('input-field'))){
            if(component.get("v.fieldType") != 'PICKLIST'){
                component.find('input-field').showHelpMessageIfInvalid();
                validity = component.find('input-field').get('v.validity').valid;
            }
        }
        if(component.get("v.fieldType") == 'PICKLIST'){
            component.find('input-field').showHelpMessageIfInvalid();
            validityPicklist = component.find('input-field').get('v.validity').valid;
        }
        if(component.get("v.fieldType") == 'Date'){
            validity = this.checkCustomDateValidations(component);
            console.log('validity---'+validity);
        }
        if(component.get("v.fieldType") == 'STRING' && component.get("v.fieldLabel") =='Zip Code'){
            var val=component.find("input-field").get('v.value');
            var inputCmp = component.find("input-field");
            if(!$A.util.isEmpty(val) && (isNaN(val) || val.length<5)){
                inputCmp.setCustomValidity("Zip code must be a numeric value of length 5.");
                validity = false;
            }else{
                inputCmp.setCustomValidity("");  
            }
            inputCmp.reportValidity();
        }
        if(component.get("v.isMonthYearFilter") || component.get('v.fieldType') == 'Month/Year'){
            validity = this.checkforMonthYearValidation(component);
        }
        return validity;
    },
    
    checkCustomTextValidationHlp : function(component, event, helper) {
        if(component.get("v.fieldType") == 'STRING' && component.get("v.fieldLabel") =='Zip Code'){
            var val=component.find("input-field").get('v.value');
            var inputCmp = component.find("input-field");
            if(!$A.util.isEmpty(val) && (isNaN(val) || val.length<5)){
                inputCmp.setCustomValidity("Zip code must be a numeric value of length 5.");
            }else{
                inputCmp.set("v.validity",{'valid':true});
                inputCmp.setCustomValidity("");  
            }
            inputCmp.reportValidity();
        }
    },
    
    checkforMonthYearValidation : function(component){
        var isValid = true;
        var startMonth = component.get("v.selectedMonth");
        var startYear = component.get("v.selectedYear");
        var required = component.get("v.required");
        var currentDate = this.getDateInUTC(new Date());
        var currentMonth = currentDate.getMonth();
        var nextMonth = new Date(currentDate.getFullYear(),currentDate.getMonth()+1,1);
        var feb2025 = new Date(2025,1,1);
        var fourYearEarlierDate = new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate());
        var startDate;
        
        if((!$A.util.isEmpty(startMonth)) && ($A.util.isEmpty(startYear))) {
            component.find('startYear').showHelpMessageIfInvalid();
            isValid = false;
        } else if((!$A.util.isEmpty(startYear)) && ($A.util.isEmpty(startMonth)) && (startYear != null)) {
            component.find('startMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else {
            if((!$A.util.isEmpty(startYear)) && (!$A.util.isEmpty(startMonth))){
                startDate = new Date(startYear, (startMonth - 1),1 );
            }
        }
        var startYearCmp = component.find("startYear");
        if(required){
            if(($A.util.isEmpty(startMonth))){
                component.find('startMonth').showHelpMessageIfInvalid();
                isValid = false;
            }
            if( ($A.util.isEmpty(startYear))){
                component.find('startYear').showHelpMessageIfInvalid();
                isValid = false;
            }
            if((!$A.util.isEmpty(startDate)) && startDate < fourYearEarlierDate) {
                startYearCmp.setCustomValidity(component.get('v.fieldLabel')+" cannot be earlier than 4 years.");
                isValid = false;
            } else if((!$A.util.isEmpty(startDate)) && startDate >= nextMonth) {
                startYearCmp.setCustomValidity(component.get('v.fieldLabel')+" should be less than equals to current month.");
                isValid = false;
            } else{
                startYearCmp.setCustomValidity("");
            }
            startYearCmp.reportValidity();
        }else{
            if((!$A.util.isEmpty(startDate)) && startDate < fourYearEarlierDate) {
                startYearCmp.setCustomValidity(component.get('v.fieldLabel')+" cannot be earlier than 4 years.");
                isValid = false;
            } else if(component.get('v.reportName') == 'RE206' && (!$A.util.isEmpty(startDate)) && startDate >= nextMonth){
                startYearCmp.setCustomValidity(component.get('v.fieldLabel')+" should be less than equals to current month.");
                isValid = false;
            } else if(component.get('v.reportName') == 'RE206' && (!$A.util.isEmpty(startDate)) && startDate < feb2025){
                startYearCmp.setCustomValidity(component.get('v.fieldLabel')+" should be after Feb 2025.");
                isValid = false;
            } 
            else{
                startYearCmp.setCustomValidity("");
            }
            startYearCmp.reportValidity();
        }
        return isValid;
    },
    
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    
    checkCustomDateValidations: function(component){
        var isValid = true;
        var currentDate = this.getDateInUTC(new Date());
        var selectedDateValue = component.find("inputDate").get('v.value');
        var selectedDateInUTC = this.getDateInUTC(new Date(component.find("inputDate").get('v.value')));
        var FourYearsPastDate = new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate());
        var nextMonth = new Date(currentDate.getFullYear(),currentDate.getMonth()+1,1);
        console.log('checkCustomDateValidations selectedDateInUTC--'+selectedDateInUTC);
        console.log('checkCustomDateValidations nextMonth--'+nextMonth);
        console.log('checkCustomDateValidations currentDate--'+currentDate);
        console.log('checkCustomDateValidations fieldLabel--'+component.get("v.fieldLabel"));
        console.log('checkCustomDateValidations ReportName--'+component.get("v.reportName"));
        if($A.util.isEmpty(selectedDateValue)){
            if(((component.get("v.fieldLabel") == 'Case End Date') && (component.get("v.reportName") == 'RE114')) ||
               (['AppRecvdBeginDate', 'AppRecvdEndDate', 'AppProcdBeginDate', 'AppProcdEndDate'].includes(component.get("v.fieldAPIName")) && component.get("v.reportName") == 'RE230') || // Modified by Rishav for CCCAP-7662
               ((component.get("v.fieldLabel") == '* From Date' || component.get("v.fieldLabel") == '* To Date') && (component.get("v.reportName") == 'RE304')) ||
               (component.get("v.reportName") == 'RE306')) {
                component.find("inputDate").set("v.errors",[]);
            } else if(component.get("v.fieldAPIName") == 'ToDate' && component.get("v.reportName") == 'RE218') { // Added by Rishav for CCCAP-6791
                var todayDate = new Date();
                var dd = todayDate.getDate();
                var MM = todayDate.getMonth()+1;
                var yyyy = todayDate.getFullYear();
                if(dd<10){
                    dd = '0' + dd;
                }
                if(MM<10){
                    MM = '0' + MM;
                }
                component.find("inputDate").set("v.errors", []);
                component.find("inputDate").set("v.value", yyyy+'-'+MM+'-'+dd);
            } else {
                component.find("inputDate").set("v.errors",[{"message":"Please enter a value."}]);
                isValid = false;
            }
        } else if((!$A.util.isEmpty(selectedDateValue)) && selectedDateInUTC >= nextMonth && (component.get("v.fieldLabel") == 'Case Begin Date')) {
            component.find("inputDate").set("v.errors",[{"message":"Case Begin Date should be less than or equals to current month."}]);
            isValid = false;
        } else if((!$A.util.isEmpty(selectedDateValue)) && selectedDateInUTC< FourYearsPastDate && (component.get("v.fieldLabel") == 'Case Begin Date')) {
            component.find("inputDate").set("v.errors",[{"message":"Case Begin Date cannot be earlier than 4 years."}]);
            isValid = false;
        } else if((!$A.util.isEmpty(selectedDateValue)) && selectedDateInUTC< FourYearsPastDate && (component.get("v.fieldLabel") == 'Case End Date')) {
            component.find("inputDate").set("v.errors",[{"message":"Case End Date cannot be earlier than 4 years."}]);
            isValid = false;
        } //CCCAP-13192
            else if((!$A.util.isEmpty(selectedDateValue)) && selectedDateInUTC< FourYearsPastDate && (component.get("v.fieldLabel") == 'Application Received Begin Date')) {
                component.find("inputDate").set("v.errors",[{"message":"Report cannot be requested more than 4 years in the past"}]);
                isValid = false;
            }
            else if((!$A.util.isEmpty(selectedDateValue)) && selectedDateInUTC> currentDate && (component.get("v.fieldLabel") == 'Application Received End Date')) {
                    component.find("inputDate").set("v.errors",[{"message":"Report cannot be requested for the future date."}]);
                    isValid = false;
            }
        //End CCCAP-13192
            
            else if(!$A.util.isEmpty(selectedDateValue) && component.get("v.reportName") == 'RE230') { // Modified by Rishav for CCCAP-7662
            if(selectedDateInUTC > currentDate){
                isValid = false;
                if(['AppRecvdBeginDate', 'AppProcdBeginDate'].includes(component.get("v.fieldAPIName"))){
                    component.find("inputDate").set("v.errors",[{"message":"Begin Date should be less than or equals to today."}]);
                } else {
                    component.find("inputDate").set("v.errors",[{"message":"End Date should be less than or equals to today."}]);
                }
            }
        } else {
            component.find("inputDate").set("v.errors",[]);
        }
        if(!$A.util.isEmpty(selectedDateValue) && component.get("v.fieldAPIName") == 'FromDate' && component.get("v.reportName") == 'RE218') { // Added by Rishav for CCCAP-6791
            var currentDate = this.getDateInUTC(new Date());
            if(selectedDateInUTC > currentDate){
                component.find("inputDate").set("v.errors",[{"message":"Begin Date should be less than or equals to today."}]);
                isValid = false;
            }
        }
        if(isValid){
            isValid = this.checkValidity(component,component.find("inputDate").get('v.value'));
        }
        console.log('isValid--in date--'+isValid);
        return isValid;
    },
    
    validateDateHlp : function(component, event, helper) {
        var selectedYear = component.get("v.selectedYear");
        var selectedMonth = component.get("v.selectedMonth");
        if((!$A.util.isEmpty(selectedYear) && selectedYear.length == 4)){
            var isValid = helper.checkforMonthYearValidation(component);
            if(isValid){
                var dateStr;
                var required = component.get("v.required");
                if(required){
                    dateStr = selectedYear+'-'+ (selectedMonth.length==2?selectedMonth:'0'+selectedMonth)+'-'+this.firstday(selectedYear,selectedMonth);
                }else{
                    dateStr = selectedYear+'-'+ (selectedMonth.length==2?selectedMonth:'0'+selectedMonth)+'-'+this.lastday(selectedYear,selectedMonth);
                }
                component.set("v.fieldValue",dateStr);
                helper.setFieldValueForReport(component);
            }
        }
        return isValid;
    },
    
    validateMonthDateHlp : function(component, event, helper) {
        var selectedMonth = component.get("v.selectedMonth");
        var selectedYear = component.get("v.selectedYear");
        if(!component.set("v.isFinishedFlow") && selectedYear != null ){
            if(!$A.util.isEmpty(selectedMonth)){
                var isValid = helper.checkforMonthYearValidation(component);
                if(isValid){
                    var dateStr;
                    var required = component.get("v.required");
                    if(required) {
                        dateStr = selectedYear+'-'+ (selectedMonth.length==2?selectedMonth:'0'+selectedMonth)+'-'+this.firstday(selectedYear,selectedMonth);
                        
                    } else {
                        dateStr = selectedYear+'-'+ (selectedMonth.length==2?selectedMonth:'0'+selectedMonth)+'-'+this.lastday(selectedYear,selectedMonth);
                    }
                    component.set("v.fieldValue",dateStr);
                    helper.setFieldValueForReport(component);
                }
            }
        }
        return isValid;
    },
    
    lastday : function(y,m){
        return  new Date(y, m, 0).getDate(); // works for months starting index :1 (Jan)
    },
    
    firstday : function(y,m){
        return  new Date(y, m, 1).getDate(); //// works for months starting index :1 (Jan)
    }, 
    
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    
    leapYear :function(year) {
        return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    },
    
    checkValidity: function(component,date) {
        var valid = true;
        var dateStr = date;
        var dateArr;
        var dayStr;
        var monthStr;
        if(!$A.util.isEmpty(date)){
            dateArr = date.split("/");
            if(!$A.util.isEmpty(dateArr)){
                if(dateArr.length>1){
                    dayStr = dateArr[1];
                    monthStr = dateArr[0];
                }
            }
        }
        if(component.get("v.required") == true && $A.util.isEmpty(date)){
            component.set("v.validity", {'valid':false});
            component.find("inputDate").set("v.errors",[{"message":"Please enter a value."}]);
        } else if(!$A.util.isEmpty(date)) {
            if(date.length <8){
                valid = false; 
            }
            date = this.getDateInUTC(new Date(date));
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
            } else if((dayStr < 1) || (dayStr > 31)) {
                valid = false;
            } else if(((monthStr == 6) || (monthStr == 4) || (monthStr == 9) || (monthStr == 11)) && (dayStr > 30)){   
                valid = false;
            } else if((month == 1 || monthStr == 2) && (((year % 400) == 0) || ((year % 4) == 0)) && ((year % 100) != 0) && (dayStr > 29)) {
                valid = false;
            } else if((month == 1 || monthStr == 2) && ((year % 100) == 0) && (dayStr > 29)) {
                valid = false;
            } else if((month == 1 || monthStr == 2) && (dayStr > 28)){
                var isLeapYear = this.leapYear(year);
                if(!isLeapYear){
                    valid = false; 
                }
            } else if( (year <1000 || year >9999)){ 
                valid = false; 
            } else if(!$A.util.isEmpty(dateArr)){
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
            } else {}
            
            if(!valid) {
                component.find("inputDate").set("v.errors",[{"message":"Please enter valid date format(MM/DD/YYYY) or valid date."}]);
                component.set("v.validity",{'valid':false});
            } else {
                component.find("inputDate").set("v.errors",[]);
                component.set("v.validity",{'valid':true});
            }
        } else {
            component.set("v.validity",{'valid':true});
            component.find("inputDate").set("v.errors",[]);
        }
        return valid;
    }
})