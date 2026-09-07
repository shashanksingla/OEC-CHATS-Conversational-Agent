({
    doInit : function(component, event, helper) {
        
        
        
        helper.callServerAndHandleError(component,"c.getEmploymentDetails",function(response){
            var records = response.objectData.data;
            
            component.set("v.EmploymentList",records);
        },{'recordId':component.get('v.recordId')},false,null);
    },
    onClick: function(cmp, event, helper){
        var navService = cmp.find("navService");
        var recordId=  event.currentTarget.dataset.item;
        var pageReference = {    
            "type": "standard__recordPage", 
            "attributes": {
                "recordId": recordId, 
                "actionName": "view"
            }
        }
        
        navService.generateUrl(pageReference)
        .then($A.getCallback(function(url) {
           
            window.open(url,'_blank'); //this opens your page in a seperate tab here
        }), 
              $A.getCallback(function(error) {
                 
              }));
    }
})