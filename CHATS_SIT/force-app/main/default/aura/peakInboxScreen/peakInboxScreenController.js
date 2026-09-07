({
    doInit :  function(component, event, helper) {
    	var initRequired= component.get("v.initRequired");
        if(initRequired==true){
            helper.initHelper(component, helper);  
        } 
    },
    viewPeakResults : function(component, event, helper) {
        var isValid = helper.validateCurrentPage(component);
        if(isValid){
            
            helper.viewPeakHelper(component, helper); 
        }  
    },
    sortbyColumn: function(component, event, helper) {
        var dataToSort = component.get("v.peakResultWrapper");
        
        if(dataToSort != null && dataToSort != undefined){
            var idToSort = event.target.id;
            if(undefined !== idToSort && "" !==idToSort){
                helper.sortBy(component, idToSort);
            }
        }
    },
    clickNext: function(component){
        var currentNumber = component.get('v.currentPageNo');
        var length = component.get('v.searchResult').length;
        var searchResultCount = component.get('v.searchResultCount');
        currentNumber++;
        if(!(currentNumber<Math.ceil(length/searchResultCount))){
            //if we're already at maximum, don't do anything
            return;
        }
        component.set('v.currentPageNo', currentNumber);
    },
    clickPrevious: function(component){
        var currentNumber = component.get('v.currentPageNo');
        if(currentNumber==0){
            //if we're already at page zero, don't do anything
            return;
        }
        component.set('v.currentPageNo', --currentNumber);
    },    
    validateAPCounty : function(component, event, helper) {
        var idx = event.currentTarget.dataset.index;
        component.set("v.selectedIDx", idx);
        
        var action = component.get("c.validateCounty");
        action.setParams({"recordId": idx});        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state === "SUCCESS") {
                var res = response.getReturnValue();
                if(res.objectData.isValidCounty == false){
                    var recordError = 'The Peak Application that you are trying to access belongs to '+res.objectData.countyName+' county. This does not match your assigned county(ies). Would you like to countinue?';
                    component.set("v.msgOnDiffOwnerCounty", recordError);
                    var modalCall = component.find("warningModalOnDiffOwnerCounty");
                    if(modalCall){
                        modalCall.openModal();
                    }
                } else {
                    helper.navigateToPDFCmp(component, event, helper);
                }
            }
        });        
        $A.enqueueAction(action);
    },
    navigateToPDF : function(component, event, helper) {
        helper.navigateToPDFCmp(component, event, helper);
    },    
    previous : function(component, event, helper){
        helper.returnPrevious(component, event);
    },
    next : function(component, event, helper){
        helper.returnNext(component, event);
    },
    closeModal : function(component, event, helper){
        var modalCall = component.find("warningModalOnDiffOwnerCounty");
        $A.util.removeClass(modalCall.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(modalCall.find('confirmMsgModal'), 'slds-fade-in-open'); 
    }
})