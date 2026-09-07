({    
    setChildStateOptions : function(component) {
        /*var opts = [
            { value: "Red", label: "Red" },
            { value: "Green", label: "Green" },
            { value: "Blue", label: "Blue" }
        ];*/
        var caseId = component.get('v.recordId');
        
        var action = component.get('c.getChildStateOptions');
        action.setParams({
            'caseId' : caseId
        });
        component.set("v.showSpinner", true);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                
                var returnedPicklistValues = response.getReturnValue();
                var options = [];
                options = options.concat(returnedPicklistValues.map(function(v) { 
                    return {
                        'label' : v.label,
                        'value' : v.value,
                    };
                }));                
                component.set('v.childStateOptions', options);                
            } 
            component.set("v.showSpinner", false);            
        });        
        $A.enqueueAction(action);
        
    },
       
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    goToAuth: function(authId){
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": authId,
            "slideDevName": "related"
        });
        navEvt.fire();
    },
    checkValidations : function(component, event, helper) {
        debugger;
        var caseRec = component.get("v.caseRec");
        var authRecToBeUpserted = component.get("v.authRec");
        var authRecClone = component.get("v.authRecClone");
        var authDropInDays = JSON.parse(JSON.stringify( component.get("v.authDropInDays")));
        var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
        var isBeginDateValid = true;
        var isReadOnly = component.get("v.isReadOnly");
        var isCreateCorrp = false;
        if(!isReadOnly){
            authRecToBeUpserted.Number_of_Drop_in_Days__c =authDropInDays;
           
            if((authRecToBeUpserted.Number_of_Drop_in_Days__c != authRecClone.Number_of_Drop_in_Days__c)){
                if(sObjectName == 'T_AUTH__c'){
                    isCreateCorrp =true;
                }
            }
            
        }
        //TEST
        component.set("v.isCreateCorrp",isCreateCorrp);
        if(sObjectName == 'T_SBSD_CASE__c'){
            var cmp = component.find('confirmationModalOnCountyCheck_1');
            var cmp1 = component.find('confirmationModalOnCareLevel');
            
            if(!$A.util.isEmpty(cmp)){
                cmp.hideConfirmModal(); 
            }
            if(!$A.util.isEmpty(cmp1)){
                cmp1.hideConfirmModal();
            }
            authRecToBeUpserted.CDE_COUNTY__c = caseRec.CDE_COUNTY__c;
            authRecToBeUpserted.IDN_CASE__c = caseRec.Id; 
            debugger;
            var date, lastDay,lastCsReder;
            if(caseRec.DTE_REDET_CASE__c){
                date = this.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c));
              lastCsReder = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);  
            }
            if(caseRec.DTE_REDET_CASE__c && (!component.get("v.isChildWefareCare"))){
            	date = this.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c));
                lastDay = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);
            } else {
                date = this.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c));
                lastDay = new Date(date.getFullYear() + 1, parseInt(date.getMonth()) + 1, 0);
            }
            var childEndDate =component.get("v.eligibleChildEndDate");
            if(!$A.util.isEmpty(childEndDate)){
                childEndDate= this.getDateInUTC(new Date(childEndDate));
            }
            //var lastDay = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);
            if(!$A.util.isEmpty(childEndDate) && (!component.get("v.isChildWefareCare"))){
                if(childEndDate < lastDay){
                    lastDay =childEndDate;
                }  
            }
            component.set("v.authEndDate",lastDay);
            if((!component.get("v.isChildWefareCare")) && sObjectName == 'T_SBSD_CASE__c'){
                if(this.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c)) > lastCsReder){
                    isBeginDateValid = false;
                }                
            }
            var key = lastDay.getFullYear()+'-'+(lastDay.getMonth()+1)+'-'+lastDay.getDate();
            authRecToBeUpserted.DTE_END_EFFV_AUTH__c = lastDay; 
        }
        var isProceedAuthEncumb = true;
        var isProceedAuthEncumbRecurr = true;
        // Alert the user with the value returned 
        // from the server
        var hoursPerWeekDayChanged = component.get('v.hoursPerWeekDayChanged');
        var hoursPerWeekDay = component.get("v.hoursPerWeekDay");
        var isValidCareUnit = true;
        var rateTypeErrorMsg ='';
        for(var i=0;i<hoursPerWeekDay.length;i++){
            if(((hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c != '--None--') && (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c != undefined)) &&
               ((hoursPerWeekDay[i].CNT_HOUR_CARE__c != '') && (hoursPerWeekDay[i].CNT_HOUR_CARE__c != undefined)) ){
                if (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c.indexOf(';') > -1) { 
                    rateTypeErrorMsg =hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c;
                    isValidCareUnit = false;
                    break;
                }
            }else{
                isProceedAuthEncumb = false;
                break;
            }
        }
        var authTerminated = component.get("v.authTerminated"); 
        var isEncumbrnceCreated = component.get("v.isEncumbrnceCreated");
        var originalBeginDate = component.get("v.originalBeginDate");
        var currentBeginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
        var originalProviderId = component.get("v.originalProviderId");
        var currentProviderId = authRecToBeUpserted.IDN_PROVR__c;
        var originalClientId = component.get("v.originalClientId");
        var currentClientId = authRecToBeUpserted.IDN_CLIENT__c;
        if (sObjectName == 'T_SBSD_CASE__c' && isEncumbrnceCreated && (originalBeginDate!==currentBeginDate || originalProviderId!==currentProviderId || originalClientId!==currentClientId )){
            if(!component.get("v.isModifiedAfterChange")){
                component.set("v.scheduleRecurr",[]);
            }
        }
        // Recurrence check
        var scheduleRecurr = component.get("v.scheduleRecurr");
        if($A.util.isEmpty(scheduleRecurr)){
            isProceedAuthEncumbRecurr =false;
        }
        // End
        var missedSchedule =false;
        var isInValidRecurrence = false;
        var currentBeginDateTemp = currentBeginDate;
        var authEndDate = component.get("v.authEndDate");
        var authRec = component.get("v.authRec");
        if(sObjectName == 'T_SBSD_CASE__c'){
           if(authEndDate==null){
            authEndDate=lastDay;
        } 
        }else{
            authEndDate = this.getDateInUTC(new Date(authRec.DTE_END_EFFV_AUTH__c));
            component.set("v.authEndDate",authEndDate);
        }
        if(!$A.util.isEmpty(scheduleRecurr)){

        if(authEndDate==null){
            authEndDate=lastDay;
        }
      
            var formattedAuthEndDate = authEndDate.getFullYear() + '-' + this.padNumber(authEndDate.getMonth() + 1) + '-' + this.padNumber(authEndDate.getDate())
            var formattedBeginDate;
        if(!$A.util.isEmpty(scheduleRecurr)){
           // const sortedScheduleRecurr = scheduleRecurr.sort((a, b) => b.DTE_Begin_Date__c - a.DTE_Begin_Date__c);
            scheduleRecurr.sort(function compare(a, b) {
                var dateA = new Date(a.DTE_Begin_Date__c);
                var dateB = new Date(b.DTE_Begin_Date__c);
                return dateA - dateB;
            });
            
            var lastRecurr = scheduleRecurr[scheduleRecurr.length-1];
            var firstRecurr = scheduleRecurr[0];
            
            if (currentBeginDate.indexOf('T') > -1) {
                var beginDateTemp = currentBeginDate.split("T");
                if(!$A.util.isEmpty(beginDateTemp)){
                    formattedBeginDate =beginDateTemp[0];
                }
            }else{
                formattedBeginDate=currentBeginDate;
            }      
            for(let obj of scheduleRecurr){
                console.log('currentBeginDateTemp--'+currentBeginDateTemp);
                 console.log('DTE_Begin_Date__c--'+obj.DTE_Begin_Date__c);
                 console.log('DTE_End_Date__c--'+obj.DTE_End_Date__c);
                console.log('formattedBeginDate--'+formattedBeginDate);
                console.log('formattedAuthEndDate--'+formattedAuthEndDate);
                if(firstRecurr.DTE_Begin_Date__c != formattedBeginDate){
                    debugger;
                    missedSchedule=true;
                }
                if(lastRecurr.DTE_End_Date__c != formattedAuthEndDate){
                    debugger;
                    missedSchedule=true;
                }
                if(obj.DTE_Begin_Date__c <= currentBeginDateTemp && obj.DTE_End_Date__c >= currentBeginDateTemp){
                    currentBeginDateTemp=obj.DTE_End_Date__c;
                    var dateA = new Date(currentBeginDateTemp);
                    dateA.setDate(dateA.getDate() + 1);
                    var formatted = dateA.getFullYear() + '-' + this.padNumber(dateA.getMonth() + 1) + '-' + this.padNumber(dateA.getDate())
                    currentBeginDateTemp =formatted;
                }else{
                    debugger;
                    missedSchedule=true;  
                }
            }
            if(firstRecurr.DTE_Begin_Date__c < formattedBeginDate){
                debugger;
                isInValidRecurrence=true;
            }
            console.log('length--'+scheduleRecurr.length);
            
            console.log('lastRecurr'+lastRecurr.DTE_End_Date__c);
            console.log('firstRecurr'+firstRecurr.DTE_Begin_Date__c);
            console.log('missedSchedule'+missedSchedule);
            console.log('scheduleRecurr sorted'+scheduleRecurr);
            console.log('sortedScheduleRecurr--'+JSON.stringify(scheduleRecurr));
            
        }
    }
       var isChildRateTypeCorrect = false;
        for(var i=0;i<hoursPerWeekDay.length;i++){
            if((hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c == '55')){
                if(!component.get("v.isChildDisable")){
                    isChildRateTypeCorrect = true;
                    break;
                }else{
                    isChildRateTypeCorrect = false;
                    break;
                }
            }
        }
        if((!isProceedAuthEncumb || isChildRateTypeCorrect) && sObjectName == 'T_SBSD_CASE__c'){
            component.set("v.showSpinner",false);
            var recordError2 =[];
            var message;
            if(!isProceedAuthEncumb){
                message ='Please fill all fields of Standard Schedule Section.';
            }else if(isChildRateTypeCorrect){
              message = $A.get("$Label.c.Child_Disability_Validation_Msg");  
            }
            recordError2.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError2); 
        } else if(isInValidRecurrence && sObjectName == 'T_SBSD_CASE__c'){
            var recordError2 =[];
            var recurrenceErrorMsg = $A.get("$Label.c.recurrenceErrorMsg");
            var message =recurrenceErrorMsg;
            
            recordError2.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
            component.set("v.showSpinner",false);
        }/*else if(!isProceedAuthEncumbRecurr && sObjectName == 'T_SBSD_CASE__c'){
            var recordError2 =[];
            var message ='Please select atleast one recurrence pattern.';
            recordError2.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
            component.set("v.showSpinner",false);
        }else if(missedSchedule && sObjectName == 'T_SBSD_CASE__c'){
            var recordError2 =[];
            var message ='Please enter reoccurrence pattern/s to cover the full authorization period, ';
            var formattedAuthEndDateTemp = this.padNumber(authEndDate.getMonth() + 1) + '/' + this.padNumber(authEndDate.getDate()) + '/' +  authEndDate.getFullYear();
            var dateArr = formattedBeginDate.split('-');
            if(!$A.util.isEmpty(dateArr)){
                var formattedBeginDateTemp = dateArr[1] + '/' + dateArr[2] + '/' + dateArr[0];
                message=message+formattedBeginDateTemp+' - '+formattedAuthEndDateTemp;
            }
            recordError2.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
            component.set("v.showSpinner",false);
        }else if(missedSchedule ){
            var recordError2 =[];
            var message ='Please enter reoccurrence pattern/s to cover the full authorization period, ';
            var formattedAuthEndDateTemp = this.padNumber(authEndDate.getMonth() + 1) + '/' + this.padNumber(authEndDate.getDate()) + '/' +  authEndDate.getFullYear();
            var dateArr = formattedBeginDate.split('-');
            if(!$A.util.isEmpty(dateArr)){
                var formattedBeginDateTemp = dateArr[1] + '/' + dateArr[2] + '/' + dateArr[0];
                message=message+formattedBeginDateTemp+' - '+formattedAuthEndDateTemp;
            }
            recordError2.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError2);
            component.set("v.showSpinner",false);
        }*/
        else {
            if (sObjectName == 'T_SBSD_CASE__c' && isEncumbrnceCreated && (originalBeginDate!==currentBeginDate || originalProviderId!==currentProviderId || originalClientId!==currentClientId )){
                helper.callServerAndDeleteRecords(component,function(response){
                    var authRec = component.get("v.authRec");
                    authRec.Id = null;
                    component.set("v.authRec", authRec);
                    component.set("v.isEncumbrnceCreated" , false);
                    authRecToBeUpserted.Id = null;
                    helper.callServerAndHandleError(component,"c.upsertRecordAuth", 
                                                        function(response){
                                                        if(isBeginDateValid){
                                                             var mergedAuth = helper.merge(component.get("v.authRec"), response.objectData.upsertedRecords[0]);
                                                             component.set("v.authRec", mergedAuth);
                                                             /*var oldSlotId = component.get("v.authRecClone").IDN_SLOT_CONTRACT__c;
                                                           
                                                             helper.callServerAndHandleError(component,"c.createSCAssociationRecord", 
                                                                                            function(response){
                                                                                                mergedAuth.IDN_SLOT_CONTRACT__c= response.objectData.SlotContractId;
                                                                                                component.set("v.authRec", mergedAuth);
                                                                                            }, {'authId': mergedAuth.Id,'scAssRec':mergedAuth.IDN_SLOT_CONTRACT__c,'scAssRecOldValue':oldSlotId}, false, null);
                                                            */
                                                            var isEncumCreate = component.get("v.isEncumbrnceCreated");
                                                            if(sObjectName == 'T_SBSD_CASE__c'){
                                                                if(isProceedAuthEncumb){
                                                                    if(isValidCareUnit){
                                                                        if(!isEncumCreate){
                                                                            helper.callServerAndHandleError(component,"c.createAuthEncmbrRecords", 
                                                                                                            function(resp){
                                                                                                                if(resp){
                                                                                                                    var isSuccess = resp.isSuccessful;
                                                                                                                if(isSuccess){
                                                                                                                    var authRecUpdated = component.get("v.authRecUpdated");
                                                                                                                    this.createAuthStatusRecord(component, event, helper,authRecUpdated,mergedAuth);
                                                                                                                    // CCCAP-8970 Changes
        var xLog =component.get("v.xLogAuthStatus");
        
        this.logWebservice(component, event, helper,xLog);
        // End
                                                                                                                    var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                    component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                     component.set("v.showSpinner", false);                                                                                                                  
                                                                                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                                                                    if(!$A.util.isEmpty(resp.objectData)){
                                                                                                                        console.log('createAuthEncmbrRecords-1-');
                                                                                                                        if(!$A.util.isEmpty(resp.objectData.xLog)){
                                                                                                                            console.log('createAuthEncmbrRecords--');
                                                                                                                            this.logWebservice(component, event, helper,resp.objectData.xLog);
                                                                                                                        }
                                                                                                                    }
                                                                                                                }
                                                                                                                else{
                                                                                                                    if(!$A.util.isEmpty(resp.objectData)){
                                                                                                                        console.log('createAuthEncmbrRecords-1-');
                                                                                                                        if(!$A.util.isEmpty(resp.objectData.xLog)){
                                                                                                                            console.log('createAuthEncmbrRecords--');
                                                                                                                            this.logWebservice(component, event, helper,resp.objectData.xLog);
                                                                                                                        }
                                                                                                                    }
                                                                                                                }
                                                                                                                }
                                                                                                            },
                                                                                                            {'authRecId': mergedAuth.Id,
                                                                                                            'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr)}
                                                                                                            , false, null); 
                                                                        }
                                                                        else{
                                                                            helper.callServerAndHandleError(component,"c.updateAuthEncmbrRecordsBasedOnPatterns", 
                                                                                                            function(resp){
                                                                                                                if(resp){
                                                                                                                    var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                    if(resp.successMessage == 'No encumbrance records returned from web service'){
                                                                                                                        component.set("v.showSpinner", false);
                                                                                                                        var recordError2 =[];
                                                                                                                        var message = resp.successMessage;
                                                                                                                        recordError2.push(message);
                                                                                                                        component.set("v.message",'error');
                                                                                                                        component.set("v.recordError",recordError2);
                                                                                                                    }else{
                                                                                                                        component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                        component.set("v.showSpinner", false);
                                                                                                                        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1); 
                                                                                                                    }
                                                                                                                    
                                                                                                                }
                                                                                                            },
                                                                                                            {'authRecId': mergedAuth.Id,
                                                                                                             'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),
                                                                                                             'isUpdate':isProceedAuthEncumb,'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr),
                                                                                                             'currentMode':sObjectName =='T_SBSD_Case__c'?'case':(isReadOnly?'viewAuth':'editAuth')}
                                                                                                            , false, null); 
                                                                        }
                                                                        
                                                                    }
                                                                    else{
                                                                        component.set("v.showSpinner", false);
                                                                        var recordError3 =[];
                                                                        var message = 'Invalid Rate Type '+rateTypeErrorMsg+' please select one rate type per record.';
                                                                        recordError3.push(message);
                                                                        component.set("v.message",'error');
                                                                        component.set("v.recordError",recordError3);  
                                                                    }
                                                                    
                                                                }else{
                                                                    component.set("v.showSpinner", false);
                                                                    var recordError4 =[];
                                                                    var message1 = 'Please fill all fields of Standard Schedule Section.';
                                                                    recordError4.push(message);
                                                                    component.set("v.message",'error');
                                                                    component.set("v.recordError",recordError4);   
                                                                }
                                                                // Removed Auth Status Record Creation
                                                              
                                                                //end
                                                            }
                                                            else{
                                                                if(isValidCareUnit){
                                                                    helper.callServerAndHandleError(component,"c.updateAuthEncmbrRecordsBasedOnPatterns", 
                                                                                                    function(resp){
                                                                                                        debugger;
                                                                                                        if(resp){
                                                                                                            if(resp.successMessage == 'No encumbrance records returned from web service'){
                                                                                                                var recordError2 =[];
                                                                                                                var message = resp.successMessage;
                                                                                                                recordError2.push(message);
                                                                                                                component.set("v.message",'error');
                                                                                                                component.set("v.recordError",recordError2);
                                                                                                            }else{
                                                                                                                var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                                                            }
                                                                                                        }
                                                                                                    },
                                                                                                    {'authRecId': mergedAuth.Id,
                                                                                                     'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),
                                                                                                     'isUpdate':isProceedAuthEncumb,'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr),
                                                                                                     'currentMode':sObjectName =='T_SBSD_Case__c'?'case':(isReadOnly?'viewAuth':'editAuth')}
                                                                                                    , false, null); 
                                                                }else{
                                                                    var recordError3 =[];
                                                                    var message = 'Invalid Rate Type '+rateTypeErrorMsg+' please select one rate type per record.';
                                                                    recordError3.push(message);
                                                                    component.set("v.message",'error');
                                                                    component.set("v.recordError",recordError3);
                                                                }
                                                            }
                                                        }
                                                        }, {'lstSObject':[authRecToBeUpserted],'lastDay':key,'isBeginDateValid':isBeginDateValid}, false, null);
                    
                },[authRecToBeUpserted]);                                    
            }
            else{
                if(isReadOnly){
                    debugger;
                    helper.callServerAndHandleError(component,"c.updateAuthEncmbrRecordsBasedOnPatterns", 
                                                                                                        function(resp){
                                                                                                            debugger;
                                                                                                            if(resp){
                                                                                                                if(resp.successMessage == 'No encumbrance records returned from web service'){
                                                                                                                    var recordError2 =[];
                                                                                                                    var message = resp.successMessage;
                                                                                                                    recordError2.push(message);
                                                                                                                    component.set("v.message",'error');
                                                                                                                    component.set("v.recordError",recordError2);
                                                                                                                }else{
                                                                                                                    var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                    component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                                                                }
                                                                                                            }
                                                                                                        },
                                                                                                        {'authRecId': component.get("v.authRec").Id,
                                                                                                         'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),
                                                                                                         'isUpdate':false,'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr),
                                                                                                         'currentMode':sObjectName =='T_SBSD_Case__c'?'case':(isReadOnly?'viewAuth':'editAuth')}
                                                                                                        , false, null);
                }else{
                helper.callServerAndHandleError(component,"c.upsertRecordAuth", 
                                                    function(response){
                                                        if(isBeginDateValid){
                                                        var mergedAuth = helper.merge(component.get("v.authRec"), response.objectData.upsertedRecords[0]);
                                                         component.set("v.authRec", mergedAuth);
                                                         /*var oldSlotId = component.get("v.authRecClone").IDN_SLOT_CONTRACT__c;
                                                         helper.callServerAndHandleError(component,"c.createSCAssociationRecord", 
                                                                                            function(response){
                                                                                                mergedAuth.IDN_SLOT_CONTRACT__c= response.objectData.SlotContractId;
                                                                                                component.set("v.authRec", mergedAuth);
                                                                                            }, {'authId': mergedAuth.Id,'scAssRec':mergedAuth.IDN_SLOT_CONTRACT__c,'scAssRecOldValue':oldSlotId}, false, null);
                                                          */  
                                                        var isEncumCreate = component.get("v.isEncumbrnceCreated"); 
                                                        component.set("v.showSpinner", false);
                                                        if(sObjectName == 'T_SBSD_CASE__c'){
                                                            if(isProceedAuthEncumb){
                                                                if(!authTerminated){
                                                                    if(isValidCareUnit){
                                                                    if(!isEncumCreate){
                                                                        helper.callServerAndHandleError(component,"c.createAuthEncmbrRecords", 
                                                                                                        function(resp){
                                                                                                            debugger;
                                                                                                            if(resp){
                                                                                                                var isSuccess = resp.isSuccessful;
                                                                                                                if(isSuccess){
                                                                                                                    debugger;
                                                                                                                    var authRecUpdated = component.get("v.authRecUpdated");
                                                                                                                    // CCCAP-8970 Changes
        var xLog =component.get("v.xLogAuthStatus");
        
        this.logWebservice(component, event, helper,xLog);
        // End
                                                                                                                    this.createAuthStatusRecord(component, event, helper,authRecUpdated,mergedAuth);
                                                                                                                    var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                    component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                                                                    if(!$A.util.isEmpty(resp.objectData)){
                                                                                                                        console.log('createAuthEncmbrRecords-1-');
                                                                                                                        if(!$A.util.isEmpty(resp.objectData.xLog)){
                                                                                                                            console.log('createAuthEncmbrRecords--');
                                                                                                                            this.logWebservice(component, event, helper,resp.objectData.xLog);
                                                                                                                        }
                                                                                                                    }
                                                                                                                }
                                                                                                                else{
                                                                                                                    console.log('exception came--');
                                                                                                                    if(!$A.util.isEmpty(resp.objectData)){
                                                                                                                        console.log('createAuthEncmbrRecords-1-');
                                                                                                                        if(!$A.util.isEmpty(resp.objectData.xLog)){
                                                                                                                            console.log('createAuthEncmbrRecords--');
                                                                                                                            this.logWebservice(component, event, helper,resp.objectData.xLog);
                                                                                                                        }
                                                                                                                    }
                                                                                                                    //Exception Handling for auth encumbrance
                                                                                                                    //end
                                                                                                                }
                                                                                                            }
                                                                                                        },
                                                                                                        {'authRecId': mergedAuth.Id,
                                                                                                        'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr)}
                                                                                                        , false, null); 
                                                                    }
                                                                    else{
                                                                        helper.callServerAndHandleError(component,"c.updateAuthEncmbrRecordsBasedOnPatterns", 
                                                                                                        function(resp){
                                                                                                            if(resp){
                                                                                                                var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                if(resp.successMessage == 'No encumbrance records returned from web service'){
                                                                                                                    var recordError2 =[];
                                                                                                                    var message = resp.successMessage;
                                                                                                                    recordError2.push(message);
                                                                                                                    component.set("v.message",'error');
                                                                                                                    component.set("v.recordError",recordError2);
                                                                                                                }else{
                                                                                                                    component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1); 
                                                                                                                }
                                                                                                                
                                                                                                            }
                                                                                                        },
                                                                                                        {'authRecId': mergedAuth.Id,
                                                                                                         'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),
                                                                                                         'isUpdate':isProceedAuthEncumb,'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr),
                                                                                                         'currentMode':sObjectName =='T_SBSD_Case__c'?'case':(isReadOnly?'viewAuth':'editAuth')}
                                                                                                        , false, null); 
                                                                    }
                                                                    
                                                                }
                                                                else{
                                                                    var recordError3 =[];
                                                                    var message = 'Invalid Rate Type '+rateTypeErrorMsg+' please select one rate type per record.';
                                                                    recordError3.push(message);
                                                                    component.set("v.message",'error');
                                                                    component.set("v.recordError",recordError3);  
                                                                }
                                                                }else{
                                                                   var recordError5 =[];
                                                                    var message2  ='A terminated authorization cannot be updated';
                                                                    recordError5.push(message2);
                                                                    component.set("v.message",'error');
                                                                    component.set("v.recordError",recordError5);  
                                                                }
                                                                
                                                            }else{
                                                                var recordError4 =[];
                                                                var message1 = 'Please fill all fields of Standard Schedule Section.';
                                                                recordError4.push(message);
                                                                component.set("v.message",'error');
                                                                component.set("v.recordError",recordError4);   
                                                            }
                                                            //Removed Auth statud creation
                                                           
                                                            //end
                                                        }
                                                        else{
                                                            if(isValidCareUnit){
                                                                if(isProceedAuthEncumb){
                                                                    if(!authTerminated){
                                                                        helper.callServerAndHandleError(component,"c.updateAuthEncmbrRecordsBasedOnPatterns", 
                                                                                                        function(resp){
                                                                                                            debugger;
                                                                                                            if(resp){
                                                                                                                if(resp.successMessage == 'No encumbrance records returned from web service'){
                                                                                                                    var recordError2 =[];
                                                                                                                    var message = resp.successMessage;
                                                                                                                    recordError2.push(message);
                                                                                                                    component.set("v.message",'error');
                                                                                                                    component.set("v.recordError",recordError2);
                                                                                                                }else{
                                                                                                                    var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                    component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                                                                }
                                                                                                            }
                                                                                                        },
                                                                                                        {'authRecId': mergedAuth.Id,
                                                                                                         'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),
                                                                                                         'isUpdate':isProceedAuthEncumb,'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr),
                                                                                                         'currentMode':sObjectName =='T_SBSD_Case__c'?'case':(isReadOnly?'viewAuth':'editAuth')}
                                                                                                        , false, null); 
                                                                    }
                                                                    else{
                                                                        var recordError5 =[];
                                                                        var message2  ='A terminated authorization cannot be updated';
                                                                        recordError5.push(message2);
                                                                        component.set("v.message",'error');
                                                                        component.set("v.recordError",recordError5);
                                                                    }  
                                                                }else{
                                                                    helper.callServerAndHandleError(component,"c.updateAuthEncmbrRecordsBasedOnPatterns", 
                                                                                                        function(resp){
                                                                                                            debugger;
                                                                                                            if(resp){
                                                                                                                if(resp.successMessage == 'No encumbrance records returned from web service'){
                                                                                                                    var recordError2 =[];
                                                                                                                    var message = resp.successMessage;
                                                                                                                    recordError2.push(message);
                                                                                                                    component.set("v.message",'error');
                                                                                                                    component.set("v.recordError",recordError2);
                                                                                                                }else{
                                                                                                                    var careDateToAuthEncmbr = resp.objectData.careDateToAuthEncmbr;
                                                                                                                    component.set("v.careDateToAuthEncmbr", careDateToAuthEncmbr);
                                                                                                                    component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
                                                                                                                }
                                                                                                            }
                                                                                                        },
                                                                                                        {'authRecId': mergedAuth.Id,
                                                                                                         'hoursPerWeekDayStr': JSON.stringify(hoursPerWeekDay),
                                                                                                         'isUpdate':false,'hoursPerWeekDayRecurrStr':JSON.stringify(scheduleRecurr),
                                                                                                         'currentMode':sObjectName =='T_SBSD_Case__c'?'case':(isReadOnly?'viewAuth':'editAuth')}
                                                                                                        , false, null); 
                                                                }
                                                                
                                                            }else{
                                                                var recordError3 =[];
                                                                var message = 'Invalid Rate Type '+rateTypeErrorMsg+' please select one rate type per record.';
                                                                recordError3.push(message);
                                                                component.set("v.message",'error');
                                                                component.set("v.recordError",recordError3);
                                                            }
                                                        }
                                                    }
                                                    }, {'lstSObject':[authRecToBeUpserted],'lastDay':key,'isBeginDateValid':isBeginDateValid}, false, null);
                                                }
            }
        }
    },
    createAuthStatusRecord : function(component, event, helper,authRecUpdated,mergedAuth){
        // Creating Auth Status Record
        var authRecUpdated = component.get("v.authRecUpdated");
        var authStatusRecord = component.get("v.authStatusRecord");
        authStatusRecord.createdbyid__c = authRecUpdated.CreatedById;
        authStatusRecord.createddate__c = new Date();
        authStatusRecord.lastmodifiedbyid__c = authRecUpdated.CreatedById;
        authStatusRecord.lastmodifieddate__c = new Date();
        authStatusRecord.idn_auth__c = mergedAuth.Id ;//component.get('v.recordId'); 
        authStatusRecord.cde_status_auth__c = '2';
        authStatusRecord.dte_begin_effv__c = mergedAuth.DTE_BEGIN_EFFV_AUTH__c;
        var lstSObject = [];
        if(authStatusRecord!=undefined){
            lstSObject.push(authStatusRecord);
        }
         // CCCAP-8970 Changes
         var xLog =component.get("v.xLogAuthStatus");
         xLog.Method__c='createAuthStatusRecord';
         xLog.Class__c='authorizationFlowHelper';
         xLog.Exception_Message__c='calling auth status creation service with auth id '+ mergedAuth.Id;
         this.logWebservice(component, event, helper,xLog);
         // End
        debugger;
        console.log('lstSObject--upsertAuthStatus-'+JSON.stringify(lstSObject));
        debugger;
        var action = component.get("c.upsertAuthStatus");
        action.setParams({"authStatus":authStatusRecord,"isNew":true});
        action.setCallback(this, function(response) {
            var state = response.getState();
            var res = response.getReturnValue();
            console.log('res-res.objectData-'+res.objectData);
            if(!$A.util.isEmpty(res.objectData)){
                console.log('logWebservice-1-');
                if(!$A.util.isEmpty(res.objectData.xLog)){
                    console.log('logWebservice--');
                    this.logWebservice(component, event, helper,res.objectData.xLog);
                }
            }
            if (state === "SUCCESS") {
                console.log('---'+JSON.stringify(response.getReturnValue()));
                console.log("From server: " + response.getReturnValue());
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    logWebservice :function(component, event, helper,xlog){
        console.log('--logException--'+xlog);
        helper.callServer(component,"c.logException", 
                          function(response){
                              console.log("Exception occurred on server and has been logged.");
                          }, {"xLog":xlog}, false);

    },
    doValidateRecurrenceHlp : function(component, event, helper) {
        debugger;
        var caseRec = component.get("v.caseRec");
        var authRecToBeUpserted = component.get("v.authRec");
        var authRecClone = component.get("v.authRecClone");
        var authDropInDays = component.get("v.authDropInDays");
        var sObjectName = component.get('v.sObjectName');//=='T_AUTH__c'
        var isBeginDateValid = true;
        var isReadOnly = component.get("v.isReadOnly");
        
        //TEST
        if(sObjectName == 'T_SBSD_CASE__c'){
            var cmp = component.find('confirmationModalOnCountyCheck_1');
            var cmp1 = component.find('confirmationModalOnCareLevel');
            
            if(!$A.util.isEmpty(cmp)){
                cmp.hideConfirmModal(); 
            }
            if(!$A.util.isEmpty(cmp1)){
                cmp1.hideConfirmModal();
            }
            var date, lastDay;
            if(caseRec.DTE_REDET_CASE__c && (!component.get("v.isChildWefareCare"))){
                date = this.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c));
                lastDay = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);
            } else {
                date = this.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c));
                lastDay = new Date(date.getFullYear() + 1, parseInt(date.getMonth()) + 1, 0);
            }
            var childEndDate =component.get("v.eligibleChildEndDate");
            if(!$A.util.isEmpty(childEndDate)){
                childEndDate= this.getDateInUTC(new Date(childEndDate));
            }
            //var lastDay = new Date(date.getFullYear(), parseInt(date.getMonth()) + 1, 0);
            if(!$A.util.isEmpty(childEndDate) && (!component.get("v.isChildWefareCare"))){
                if(childEndDate < lastDay){
                    lastDay =childEndDate;
                }  
            }
            console.log('lastDay--'+lastDay);
            component.set("v.authEndDate",lastDay);
            console.log('childEndDate--'+childEndDate);
            console.log('caseRec.DTE_REDET_CASE__c--'+caseRec.DTE_REDET_CASE__c);
            if((!component.get("v.isChildWefareCare")) && sObjectName == 'T_SBSD_CASE__c'){
                if(this.getDateInUTC(new Date(authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c)) > this.getDateInUTC(new Date(caseRec.DTE_REDET_CASE__c))){
                    isBeginDateValid = false;
                }                
            }
            var key = lastDay.getFullYear()+'-'+(lastDay.getMonth()+1)+'-'+lastDay.getDate();
            authRecToBeUpserted.DTE_END_EFFV_AUTH__c = lastDay; 
            
        }
        if(sObjectName != 'T_SBSD_CASE__c'){
          
            var authEndDate = this.getDateInUTC(new Date(authRecToBeUpserted.DTE_END_EFFV_AUTH__c));
            component.set("v.authEndDate",authEndDate);
        }
        var isProceedAuthEncumb = true;
        // Alert the user with the value returned 
        // from the server
        var hoursPerWeekDayChanged = component.get('v.hoursPerWeekDayChanged');
        var hoursPerWeekDay = component.get("v.hoursPerWeekDay");
        var isValidCareUnit = true;
        var rateTypeErrorMsg ='';
        for(var i=0;i<hoursPerWeekDay.length;i++){
            if(((hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c != '--None--') && (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c != undefined)) &&
               ((hoursPerWeekDay[i].CNT_HOUR_CARE__c != '') && (hoursPerWeekDay[i].CNT_HOUR_CARE__c != undefined)) ){
                if (hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c.indexOf(';') > -1) { 
                    rateTypeErrorMsg =hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c;
                    isValidCareUnit = false;
                    break;
                }
            }else{
                isProceedAuthEncumb = false;
                break;
            }
        }
        var isChildRateTypeCorrect = false;
        for(var i=0;i<hoursPerWeekDay.length;i++){
            if((hoursPerWeekDay[i].CDE_TYPE_UNIT_CARE__c == '55')){
                if(!component.get("v.isChildDisable")){
                    isChildRateTypeCorrect = true;
                    break;
                }else{
                    isChildRateTypeCorrect = false;
                    break;
                }
            }
        }
        if((!isProceedAuthEncumb || isChildRateTypeCorrect) ){
            component.set("v.showSpinner",false);
            var recordError2 =[];
            var message;
            if(!isProceedAuthEncumb){
                message ='Please fill all fields of Standard Schedule Section.';
            }else if(isChildRateTypeCorrect){
                message = $A.get("$Label.c.Child_Disability_Validation_Msg");  
            }
            recordError2.push(message);
            component.set("v.message",'error');
            component.set("v.recordError",recordError2); 
        }else{
            debugger;
            var authTerminated = component.get("v.authTerminated"); 
            var isEncumbrnceCreated = component.get("v.isEncumbrnceCreated");
            var originalBeginDate = component.get("v.originalBeginDate");
            var currentBeginDate = authRecToBeUpserted.DTE_BEGIN_EFFV_AUTH__c;
            var originalProviderId = component.get("v.originalProviderId");
            var currentProviderId = authRecToBeUpserted.IDN_PROVR__c;
            var originalClientId = component.get("v.originalClientId");
            var currentClientId = authRecToBeUpserted.IDN_CLIENT__c;
            var isAuthUpdated = false;
            var isAuthFirstTime = true;
            debugger;
            if (sObjectName == 'T_SBSD_CASE__c' && isEncumbrnceCreated){
                isAuthFirstTime =false;
                if( (originalBeginDate!==currentBeginDate || originalProviderId!==currentProviderId || originalClientId!==currentClientId )){
                    isAuthUpdated = true;
                }
            }
            debugger;
            component.set("v.showSpinner", false);
            component.set("v.message",'');
            component.set("v.recordError",[]);
            var childComponent = component.find("authorizationInfoPg1");
            childComponent.childRecurrenceMethod(true,true,isAuthFirstTime,isAuthUpdated);
            // go-ahead with recurrence
        }
    },
    padNumber : function(number) {
        var string  = '' + number;
        string      = string.length < 2 ? '0' + string : string;
        return string;
    },
	callModalOnChngSCRec:function(component, event, helper){  
        var doProceed = true;
        var isCreate = component.get("v.isCreate");
        var authRecToBeUpserted = component.get("v.authRec");
        var authSlotContID = authRecToBeUpserted.IDN_SLOT_CONTRACT__c;
        var authRecClone = component.get("v.authRecClone");
        var scAssRecOldValue = authRecClone.IDN_SLOT_CONTRACT__c;
    	if(!isCreate) {
            if(!$A.util.isEmpty(scAssRecOldValue) && !$A.util.isEmpty(authSlotContID) && scAssRecOldValue != authSlotContID){
                component.set("v.replaceMessage","Slot Contract association on the authorization is being replaced. Do you want to proceed further with changes?");
                component.set("v.showSpinner", false);
                helper.callModal(component,'confirmationModalOnReplaceofscAssRec');
                doProceed = false;
            }
            else if(!$A.util.isEmpty(scAssRecOldValue) && $A.util.isEmpty(authSlotContID)){
                component.set("v.replaceMessage","Slot Contract association on the authorization is being removed. Do you want to proceed further with changes?");
                component.set("v.showSpinner", false);
                helper.callModal(component,'confirmationModalOnReplaceofscAssRec');
                doProceed = false;
            }
        }
		return doProceed; 
    },
    
    // Added by Rishav for CCCAP-6983
    validateIfBelowSchoolAge : function(component, event, helper) {
        component.set("v.showSpinner", false);
        var action = component.get("c.validateIfBelowSchoolAge");
        var authRec = component.get("v.authRec");
        action.setParams({
            authBeginDate : authRec.DTE_BEGIN_EFFV_AUTH__c,
            clientId : authRec.IDN_CLIENT__c,
            hoursPerWeekDay : component.get("v.hoursPerWeekDay")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if((res.objectData.showWarningBelowSchoolAge)) {
                    component.set("v.warningMessageBelowSchoolAge", res.objectData.warningMessageBelowSchoolAge);
                    helper.callModal(component, 'confirmationModalBelowSchoolAge');
                } else  {
                    component.set("v.warningMessageBelowSchoolAge", res.objectData.warningMessageBelowSchoolAge);
                    helper.checkValidations(component, event, helper);
                }
            } else if(state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type":'error',
                    "message": errors[0].message
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
})