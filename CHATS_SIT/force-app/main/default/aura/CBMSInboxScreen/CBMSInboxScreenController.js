({
    doInit :  function(component, event, helper) {
         var initRequired= component.get("v.initRequired");
        if(initRequired==true){
        helper.initHelper(component, helper);  
        }  
    },
    viewCBMSResults : function(component, event, helper) {
        var isValid = helper.validateCurrentPage(component);
        if(isValid){
            
            helper.viewCBMSHelper(component, helper); 
        }  
    },
    sortbyColumn: function(component, event, helper) {
        var dataToSort = component.get("v.cbmsResultWrapper"); // corrected CBMSResultWrapper for CCCAP-14433 by Shashank S.
        
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
    
    navigateToPDFCmp : function(component, event, helper) {
        var idx = event.currentTarget.dataset.index;
        var navigtonCheck = component.get('v.navigationCheck');
        var navEvent = $A.get("e.force:navigateToComponent");

        if(navEvent){
            component.set("v.navigationCheck", true); 
            navEvent.setParams({
                componentDef : "c:viewReferralApplnPDF",
                componentAttributes: {
                    recordId : idx,
                    navigationCheck : component.get('v.navigationCheck')
                    
                }
            });
            navEvent.fire();
        }
        
        if(component.get('v.navigationCheck') == true){
            var navEvent = $A.get("e.force:navigateToComponent");
            if(navEvent){
                navEvent.setParams({
                    componentDef : "c:CBMSInboxScreen",
                    componentAttributes: {
                        navigationCheck : component.get("v.navigationCheck"),
                        CBMSInboxWrapper: component.get("v.CBMSInboxWrapper"),
                        cbmsResultWrapper: component.get("v.cbmsResultWrapper"),
                        initDone: true,
                         initRequired: false,
                        FinalList:component.get('v.FinalList'),
                        options_:component.get("v.options_"),
                        totalSize:component.get("v.totalSize"),
                        start:component.get("v.start"),
                        end:component.get("v.end")
                    }
                });
                
                navEvent.fire();
            }
        }
        
    },
    
    previous : function(component, event, helper){
        helper.returnPrevious(component, event);
    },
    next : function(component, event, helper){
        helper.returnNext(component, event);
    }
})