({
    callModal : function(cmp, modalName) {
        var modalCall = cmp.find(modalName);
        modalCall.openModal();
    },
    
    decrementCurrentTabNumber : function(cmp){
        cmp.set("v.currentTabNumber",cmp.get("v.currentTabNumber")-1);
    },
    
    exemptDecrementCurrentTabNumber : function(cmp){
        cmp.set("v.showFinishBtnForExmptProvider",false);
        cmp.set("v.currentTabNumber",cmp.get("v.currentTabNumber")-2);
    },
    
    actionOnDoNextTab1 : function(component, event,helper){
        component.set("v.showFinishBtnForExmptProvider",true);
        console.log('--showFinishBtnForExmptProvider--'+component.get("v.showFinishBtnForExmptProvider"));
    },
    
    clearObjectFields : function(domObject, sObjectFields){
        for(var eachFiscalObjField in sObjectFields){
            domObject[sObjectFields[eachFiscalObjField]] = '';
        }   
    }
})