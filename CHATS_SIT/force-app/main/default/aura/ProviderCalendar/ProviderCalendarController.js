({
    doInit : function(component, event, helper){
        component.set("v.spinner", true);
        var action = component.get("c.getInitData");
        action.setParams({ recordid : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            
            if(result.isSuccessful == true) {
                component.set("v.provdName",result.objectData.prov.NAM_FACILITY__c);
                component.set("v.provdId",result.objectData.prov.Name);
                component.set("v.provClos",result.objectData.provCloMap);
                component.set("v.provClosList",result.objectData.provClosure);
                component.set("v.isReadOnly",result.objectData.profileCheck)
                component.set("v.provdSFId",result.objectData.prov.Id);
                component.set("v.countySFId",result.objectData.countyId);
                component.set("v.faStartDate",result.objectData.faRec.DTE_BEGIN_AGRMT__c);
                component.set("v.faEndDate",result.objectData.faRec.DTE_END_AGRMT__c);
                component.set("v.countyHolidays",result.objectData.holidayDates);
            }
        });
        $A.enqueueAction(action);
        
        //setting calendar data
        var today = new Date();
        var month = today.getMonth(); // Returns 9
        var year = today.getFullYear();
        component.set("v.selectedMonth",month);
        component.set("v.selectedYear",year);
        component.set("v.months",
                      [{ value: "0", label: "January" },
                       { value: "1", label: "February" },
                       { value: "2", label: "March" },
                       { value: "3", label: "April" },
                       { value: "4", label: "May" },
                       { value: "5", label: "June" },
                       { value: "6", label: "July" },
                       { value: "7", label: "August" },
                       { value: "8", label: "September" },
                       { value: "9", label: "October" },
                       { value: "10", label: "November" },
                       { value: "11", label: "December" }]
                     );
        window.setTimeout(function(){ component.set("v.spinner", false);}, 1000);
    },
    actionOnCancel : function(component, event, helper){
        var modalCall = component.find("warningModal");
        modalCall.hideConfirmModal();
    },
    handleCancelClick : function(component, event, helper){
        if(component.get("v.isReadOnly") == true){
            var recordId = component.get("v.recordId");
            helper.goToRecord(recordId,'detail');            
        }else{
            if(component.get("v.hideCalendar") == false){
                var modalCall = component.find('provCal');                
                modalCall.checkForUpdate();
            }            
            var ifFalse = 'true';
            if(component.get("v.ifError") == 'yesUpdate'){
                ifFalse='false';
                helper.callModal(component,'confirmationModalUnsavedChanges');
            }
            if(ifFalse=='true'){
                if(component.get("v.hasPastDate") == true){
                    helper.callModal(component,'confirmationModalOnCancelPastDate');
                }
                else{    
                    helper.callModal(component,'confirmationModalOnCancel');
                }
            }
        }
    },
    actionOnYesUnsavedChanges : function(component, event, helper){
        var modalCall = component.find('confirmationModalUnsavedChanges');
        modalCall.hideConfirmModal();
        if(component.get("v.hasPastDate") == true){
            helper.callModal(component,'confirmationModalOnCancelPastDate');
        }
        else{    
            helper.callModal(component,'confirmationModalOnCancel');
        }
    },
    actionOnCancelYesButton: function(component, event, helper){
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    addClosureRange : function(component, event, helper) {
        helper.callModal(component,'provClosModal');
    },
    viewCalendar : function(component, event, helper) {
        /*Mark all as undefined
         
        component.set("v.updatedSuccessfully", undefined);
              component.set("v.recordError",undefined);
			  component.set("v.ifError",undefined);
			   component.set("v.provClosure",undefined)
			    component.set("v.provClosList",undefined)
				component.set("v.allUpdated",undefined)
            */
        component.set("v.hideCalendar",false);
        helper.callModal(component,'provCal');
    },
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    },
    updateCalendar : function(component,event,helper){
        component.set("v.spinner", true); 
        component.set("v.oncChecked",false);
        component.set("v.attendanceChecked", false);
        if(component.get("v.hideCalendar") == true){
            component.set("v.spinner", false); 
        }
        else{
            helper.saveUpdates(component,event,helper);
        }
    },
    actiononNo : function(component, event, helper){
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    actionOnYes : function(component, event, helper){
        component.set("v.oncChecked",true);
        var modalCall = component.find('warningMsgModal');
        modalCall.hideConfirmModal();
        helper.saveUpdates(component,event,helper);
    },
    actiononNoAttendanceFound : function(component, event, helper){
        var modalCall = component.find('attendanceFoundWarningMsgModal');
        modalCall.hideConfirmModal();
    },
    actionOnYesAttendanceFound: function(component, event, helper){
        component.set("v.attendanceChecked", true);
        component.set("v.spinner", true); 
        var modalCall = component.find('attendanceFoundWarningMsgModal');
        modalCall.hideConfirmModal();
        helper.saveUpdates(component,event,helper);
    },
    updateCalendarWithRange : function(component, event, helper){
        var isPast = event.getParam('arguments').hasPastDateRange;
        if(isPast == true){
            component.set("v.hasPastDate", isPast);
        }else{
            component.set("v.hasPastDate", false);
        }
        component.set("v.hideCalendar",true);
        var action = component.get("c.getInitData");
        action.setParams({ recordid : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            
            if(result.isSuccessful == true) {
                component.set("v.provClos",result.objectData.provCloMap);
                component.set("v.provClosList",result.objectData.provClosure);
                component.set("v.isReadOnly",result.objectData.profileCheck);
            }
        });
        $A.enqueueAction(action);
    } 
})