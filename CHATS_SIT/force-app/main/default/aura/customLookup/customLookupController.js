({
    onfocus : function(component,event,helper){
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC  
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },
    onblur : function(component,event,helper){       
        component.set("v.listOfSearchRecords", null );
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    keyPressController : function(component, event, helper) {
        // get the search Input keyword   
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
        if( getInputkeyWord.length > 0 ){
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{  
            component.set("v.listOfSearchRecords", null ); 
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        }
    },   
    // function for clear the Record Selection 
    clear :function(component,event,heplper){
        var pillTarget = component.find("lookup-pill");
        var lookUpTarget = component.find("lookupField"); 
        
        $A.util.addClass(pillTarget, 'slds-hide');
        $A.util.removeClass(pillTarget, 'slds-show');
        
        $A.util.addClass(lookUpTarget, 'slds-show');
        $A.util.removeClass(lookUpTarget, 'slds-hide');
        
        component.set("v.SearchKeyWord",null);
        component.set("v.value",'');
        component.set("v.listOfSearchRecords", null );
        component.set("v.selectedRecord", {} );   
    },
     // function for clear the Record Selection 
    clearLkUpValues :function(component,event,heplper){
        var pillTarget = component.find("lookup-pill");
        var lookUpTarget = component.find("lookupField"); 
        
        $A.util.addClass(pillTarget, 'slds-hide');
        $A.util.removeClass(pillTarget, 'slds-show');
        
        $A.util.addClass(lookUpTarget, 'slds-show');
        $A.util.removeClass(lookUpTarget, 'slds-hide');
        
        component.set("v.SearchKeyWord",null);
        component.set("v.value",'');
        component.set("v.listOfSearchRecords", null );
        component.set("v.selectedRecord", {} ); 
        $A.util.removeClass(component.find("searchIconId"), 'customIconPostionClass');
            $A.util.removeClass(component.find("inputLookup"), 'customBorderClass');
            component.find("inputLookup").set("v.errors", []);
            component.set('v.errorMessage', null);
            component.set('v.error', false);
            component.set("v.validity", {'valid':true}); 
    },
    
    // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper) {
        // get the selected Account record from the COMPONETN event 	 
        var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        component.set("v.selectedRecord" , selectedAccountGetFromEvent); 
        component.set("v.value" , selectedAccountGetFromEvent.Id); 
        
        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');
        
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
        
        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, 'slds-hide');
        $A.util.removeClass(lookUpTarget, 'slds-show');  
        
    },    
    showError: function(component, event, helper) {
        var errorMessage = event.getParam('arguments').errorMessage;
        component.set('v.errorMessage', errorMessage);
        component.set('v.error', true);
    },
    hideError: function(component, event, helper) {
        component.set('v.errorMessage', null);
        component.set('v.error', false);
    },
    doCheckValidity: function(component, event, helper) {
        if(component.get("v.required")==true && (component.get("v.selectedRecord.Id")==null || component.get("v.selectedRecord.Id")=='' || component.get("v.selectedRecord.Id")== undefined)){
            console.log("error message for no value");
            $A.util.addClass(component.find("searchIconId"), 'customIconPostionClass');
            $A.util.addClass(component.find("inputLookup"), 'customBorderClass');
            component.find("inputLookup").set("v.errors", [{message:"Please provide a value"}]);
            //component.set('v.errorMessage', 'Please provide a value');
            component.set('v.error', true);
            component.set("v.validity", {'valid':false});            
        }else{
            $A.util.removeClass(component.find("searchIconId"), 'customIconPostionClass');
            $A.util.removeClass(component.find("inputLookup"), 'customBorderClass');
            if(!component.get("v.isDisabled")){
                component.find("inputLookup").set("v.errors", []);
            }
            component.set('v.errorMessage', null);
            component.set('v.error', false);
            component.set("v.validity", {'valid':true});            
        }
        console.log("Method got called successfully");
    },
    doInit: function (component, event, helper) {
        var value = component.get('v.value');
        console.log("value---"+value);
        if (!$A.util.isEmpty(value)) {
            //component.set('v.valueLabel', '');
        //} else if ($A.util.isEmpty(component.get('v.valueLabel'))) {
            helper.getRecordByParent(component, event, value);
        }
    },   
    handleValueChange: function(component, event, helper) {
        var value = component.get('v.value');
        console.log("value---"+value);
        if (!$A.util.isEmpty(value)) {
            //component.set('v.valueLabel', '');
        //} else if ($A.util.isEmpty(component.get('v.valueLabel'))) {
            helper.getRecordByParent(component, event, value);
        }
    }
})