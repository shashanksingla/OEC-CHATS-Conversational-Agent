({
    myAction : function(component, event, helper) {
        
    },
    setAddress : function(component, event, helper){
        component.set("v.selectedAddress", component.get("v.returnedAddress"));
    }    
})