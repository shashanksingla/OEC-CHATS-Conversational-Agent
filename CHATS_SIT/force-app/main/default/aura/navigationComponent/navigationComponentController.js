({
	doHandleCurrentTabNumberChange : function(component, event, helper) {
		var currentTabNumber = component.get("v.currentTabNumber");
        var totalTabs = component.get("v.totalTabs");
        var showFinishBtnForExmptProvider = component.get("v.showFinishBtnForExmptProvider");
        var showPreviousAlways = component.get("v.showPreviousAlways");
        if(totalTabs == 1 || currentTabNumber==totalTabs){
            component.set("v.showNext",false);
            component.set("v.showFinish",true);
        }
        else{
        if(component.get("v.showNextPeakFlow")){
            component.set("v.showNext",false);
            component.set("v.showFinish",false); 
        }
        else{
            component.set("v.showNext",true);
            component.set("v.showFinish",false);
        }
    }    
        
        if(currentTabNumber == 1 && !showPreviousAlways){
            component.set("v.showPrevious",false);
        }else{
            component.set("v.showPrevious",true);
        }
        if(totalTabs == 1 || showFinishBtnForExmptProvider){
            component.set("v.showNext",false);
            component.set("v.showFinish",true);
        }
	},
	doNext : function(component, event, helper) {
        var onNextFun = component.get("v.onNext");
        if(onNextFun!=null){
		  $A.enqueueAction(onNextFun);          
        }else{
	        component.set("v.currentTabNumber",component.get("v.currentTabNumber")+1);
        }
    },
	doPrevious : function(component, event, helper) {
		component.set("v.currentTabNumber",component.get("v.currentTabNumber")-1);
	},
	doFinish : function(component, event, helper) {
		helper.handleFinishLogic(component);
	}
})