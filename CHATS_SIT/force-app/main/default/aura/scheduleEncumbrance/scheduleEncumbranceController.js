({
    doInit : function(component, event, helper){
        var isReadOnly = component.get("v.isReadOnly");
        var timezone = $A.get("$Locale.timezone");
        console.log('user timezone-->'+timezone);
        component.set("v.timezone",timezone);
        var counter = component.get("v.counter");
        var finalCount = 0;  
        for(var i = 0; i < 31; i++){
            finalCount++; 
        }
        var isCreate = component.get("v.isCreate");
        var isAuthFlowFirstTime = component.get("v.isAuthFlowFirstTime");
        var isAuthUpdatedInCreateFlow = component.get("v.isAuthUpdatedInCreateFlow");
        var actions;
        console.log('read',isReadOnly);
        console.log('create', isCreate);
        console.log('isAuthFlowFirstTime', isAuthFlowFirstTime);
        console.log('isAuthUpdatedInCreateFlow', isAuthUpdatedInCreateFlow);
        if(!isReadOnly){
            if(isCreate){
                if(isAuthFlowFirstTime){
                    actions = [{label: 'Delete', name: 'delete'}]; 
                } else if(isAuthUpdatedInCreateFlow) {
                    actions = [{label: 'Delete', name: 'delete'}];
                } else if(!isAuthFlowFirstTime) {
                    actions = [{label: 'Delete', name: 'delete' }, {label: 'Edit', name: 'edit'}];  
                }
            } else {
                actions = [{label: 'Delete', name: 'delete' }, {label: 'Edit', name: 'edit'}]; 
            }
        }
        component.set("v.monthdate" , finalCount);
        if(!isReadOnly){
            component.set('v.columns', [
                {label: 'Frequency', fieldName: 'Recur_Type__c', type: 'text'},
                {label: 'Recurrence Day', fieldName: 'DaysOfMonth__c', type: 'text',wrapText: true},
                {label: 'Days in Week', fieldName: 'WeekDays__c', type: 'text', wrapText: true},
                {label: 'Start Date', fieldName: 'DTE_Begin_Date__c', type: 'date-local', typeAttributes: {timezone: timezone}},
                {label: 'End Date', fieldName: 'DTE_End_Date__c', type: 'date-local', typeAttributes: {timezone: timezone}},
                {type: 'action', typeAttributes: {rowActions: actions} }
            ]);
        } else {
            component.set('v.columns', [
                {label: 'Frequency', fieldName: 'Recur_Type__c', type: 'text'},
                {label: 'Recurrence Day', fieldName: 'DaysOfMonth__c', type: 'text',wrapText: true},
                {label: 'Days in Week', fieldName: 'WeekDays__c', type: 'text',wrapText: true},
                {label: 'Start Date', fieldName: 'DTE_Begin_Date__c', type: 'date-local',typeAttributes: {timezone: timezone}},
                {label: 'End Date', fieldName: 'DTE_End_Date__c', type: 'date-local',typeAttributes: {timezone: timezone}}
            ]);
        }
    },

    closeModel : function(component, event, helper) {
      component.set("v.enterRecurrence", false);
    },

    getValueForChange : function(component, event, helper) {
        console.log('isHardDelete-->'+component.get("v.isHardDelete"));
        
    },

    doCancel : function(component, event, helper){
        component.set("v.enterRecurrence", false);
    },
    
    doSchedule : function(component,event, helper){
        var inputCmp =  component.find('frequencyId');
        inputCmp.showHelpMessageIfInvalid();
        var frequencyIdValidity = inputCmp.get("v.validity");
        if(frequencyIdValidity.valid){
            component.set("v.valid", false);
            var scheduleRecurrObj = component.get("v.scheduleRecurrObj");
            var dayNamesSelected = component.get("v.dayNamesSelected");
            console.log('dayNamesSelected-->' + JSON.stringify(dayNamesSelected));
            if(scheduleRecurrObj.Recur_Type__c === 'Daily/Weekly' || scheduleRecurrObj.Recur_Type__c ==='Every Other Week'){
                var isValid= helper.checkCustomValidations(component,event, helper);
                console.log('isValid-->' + isValid);
                if(isValid){
                    if(!$A.util.isEmpty(dayNamesSelected)){
                        var isFirstDay =false;
                        var daysString ='';
                        for(var i=0;i<dayNamesSelected.length;i++){
                            console.log('dayNamesSelected[i]--'+dayNamesSelected[i]);
                            if(dayNamesSelected[i]=='1'){
                                if(!isFirstDay){
                                    isFirstDay=true;
                                    daysString=daysString+'Sun';
                                }else{
                                     daysString=daysString+',Sun';
                                }
                                scheduleRecurrObj.Sun__c=true;  
                            }else if(dayNamesSelected[i]=='2'){
                                scheduleRecurrObj.Mon__c=true;  
                                if(!isFirstDay){
                                    isFirstDay=true;
                                    daysString=daysString+'Mon';
                                }else{
                                     daysString=daysString+',Mon';
                                }
                            }else if(dayNamesSelected[i]=='3'){
                                scheduleRecurrObj.Tue__c=true; 
                                if(!isFirstDay){
                                    isFirstDay=true;
                                    daysString=daysString+'Tue';
                                }else{
                                     daysString=daysString+',Tue';
                                }
                            }else if(dayNamesSelected[i]=='4'){
                                scheduleRecurrObj.Wed__c=true;  
                                if(!isFirstDay){
                                    isFirstDay=true;
                                    daysString=daysString+'Wed';
                                }else{
                                     daysString=daysString+',Wed';
                                }
                            }else if(dayNamesSelected[i]=='5'){
                                scheduleRecurrObj.Thur__c=true;
                                if(!isFirstDay){
                                    isFirstDay=true;
                                    daysString=daysString+'Thu';
                                }else{
                                     daysString=daysString+',Thu';
                                }
                            }else if(dayNamesSelected[i]=='6'){
                                scheduleRecurrObj.Fri__c=true; 
                                if(!isFirstDay){
                                    isFirstDay=true;
                                    daysString=daysString+'Fri';
                                }else{
                                     daysString=daysString+',Fri';
                                }
                            }else if(dayNamesSelected[i]=='7'){
                                scheduleRecurrObj.Sat__c=true; 
                                if(!isFirstDay){
                                    isFirstDay=true;
                                    daysString=daysString+'Sat';
                                }else{
                                     daysString=daysString+',Sat';
                                }
                            }
                        }
                        scheduleRecurrObj.WeekDays__c = daysString;
                        component.set("v.scheduleRecurrObj", scheduleRecurrObj);
                        helper.finish(component, event, helper, scheduleRecurrObj);
                    } else {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type":"error",
                            "message": 'Please select atleast one day of week.'
                        });
                        toastEvent.fire();
                    }
                }
            } else if(scheduleRecurrObj.Recur_Type__c === 'Monthly') {
                var validity = helper.checkCustomValidations(component, event, helper);
                console.log('validity-->' + component.get("v.valid"));
                if(validity){
                    helper.finish(component, event, helper, scheduleRecurrObj);
                }
            }
        }
    },

    handleChangeJobType : function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        component.set("v.selectedJobType",selectedOptionValue);
    },

    handleChangeFrequency : function(component, event, helper){
        var scheduleRecurrObj = component.get("v.scheduleRecurrObj");
        var selectedOptionValue = event.getParam("value");
        scheduleRecurrObj.Recur_Type__c = selectedOptionValue;
        component.set("v.jobFrequency", selectedOptionValue);
        component.set("v.scheduleRecurrObj", scheduleRecurrObj);
        console.log('selectedOptionValue-->' + selectedOptionValue);
        // Start: Added by Rishav for CCCAP-7504
        var picklistCmpList = [];
        if(!$A.util.isEmpty(component.find("picklist"))){
            picklistCmpList.push(component.find("picklist"));
            picklistCmpList.forEach(function(picklistCmp) {
                if(picklistCmp.get("v.name") == 'DaysOfMonth'){
                    picklistCmp.resetOptions();
                }
            });
        }
        // End: CCCAP-7504
    },
    
    pickTime : function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        component.set("v.time",selectedOptionValue);
        var time =component.get("v.time");
        var hours = time.split(":")[0];
        var minutes = time.split(":")[1];
        component.set("v.minute" , minutes);
        component.set("v.hours", hours);
    },
    
    startDate : function(component, event, helper){
        /*
        var selectedOptionValue = event.getParam("value");
        component.set("v.startDate",selectedOptionValue);
        var startDate =component.get("v.startDate");
        var d = new Date(startDate);
        var month =d.getMonth();
        var date =d.getDate();
        var day =d.getDay();
        component.set("v.startday",day);
        component.set("v.startDateOfMonth",date);
        component.set("v.startMonth",month);
        */
    },
    
    endDate : function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        /* 
        component.set("v.EndDate",selectedOptionValue);
        var endDate =component.get("v.EndDate");
        var d = new Date(endDate);
        var month =d.getMonth();
        var date =d.getDate();
        var day =d.getDay();
        component.set("v.endday",day);
        component.set("v.endDayOfMonth",date);
        component.set("v.endMonth",month);
        */
    },

    selectWeek : function(component, event, helper){
        console.log('event getSource(checked)-->' + event.getSource().get('v.checked'));
        console.log('event getSource(value)-->' + event.getSource().get('v.value'));
        var weekval = event.getSource().get('v.value');
        var selectedweek = [];
        var dayNamesSelected = component.get("v.dayNamesSelected");
        if(dayNamesSelected.length > 0){
            selectedweek= dayNamesSelected;
        }
        if(event.getSource().get('v.checked') ===true){
            if(!selectedweek.includes(weekval) ){
                selectedweek.push(event.getSource().get('v.value'));
                component.set("v.dayNamesSelected", selectedweek);
            }
        } else {
            selectedweek.splice(dayNamesSelected.indexOf(event.getSource().get('v.value')), 1);
        }
    },

    handleChangeDate : function(component, event, helper){
        var selectedOptionValue = event.getParam("value");
        component.set("v.counter", selectedOptionValue);
        console.log('selectedOptionValue-->' + selectedOptionValue);
    },

    handleRowAction : function(component, event, helper){
        var rows= component.get("v.scheduleRecurr");
        var action = event.getParam( 'action' );
        var row = event.getParam('row');
        var recId = row.Id;
        console.log('action-->'+JSON.stringify(action));
        console.log('row-->'+JSON.stringify(row));
        console.log('rows-->'+JSON.stringify(rows));
        switch (action.name) {
            case 'edit':{
                /*
                var editRecordEvent = $A.get("e.force:editRecord");
                editRecordEvent.setParams({
                    "recordId": recId
                });
                editRecordEvent.fire();
                */
                if(!$A.util.isEmpty(recId)){
                    component.set("v.recurrenceRecordId",recId);
                    component.set("v.showEditModal",true);
                }
                break;
                $A.get('e.force:refreshView').fire();
                // component.set("v.scheduleRecurrObj",row);
            }
            case 'delete':{
                const rowIndex = rows.indexOf(row);
                rows.splice(rowIndex, 1);
                if(!$A.util.isEmpty(recId)){
                    helper.deleteRecurrence(component, event, helper,recId);
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type":"success",
                        "message": 'Authorization Recurrence has been deleted successfully.'
                    });
                    toastEvent.fire();
                }
                component.set("v.scheduleRecurr",rows);
            }
        }
    },

    refreshAll : function(component, event, helper){
        var eventMsg = event.getParam("message").toUpperCase();
        console.log('eventMsg-->' + eventMsg);
        if(eventMsg &&  eventMsg.includes("AUTHORIZATION RECURRENCE HAS BEEN UPDATED SUCCESSFULLY")){
            var action = component.get('c.getScheduleRecurrences');
        action.setParams({
            'recordId' : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state == 'SUCCESS') {
                var res =response.getReturnValue();
                if(res.isSuccessful){
                    if(res.objectData.recurrenceList){
                        component.set("v.scheduleRecurr",res.objectData.recurrenceList);
                    }
                }
            } 
        });
        $A.enqueueAction(action);
        }
    }

})