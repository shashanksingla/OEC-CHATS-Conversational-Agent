({
    doInit : function(cmp, event, helper) {
        var urlStr = window.location.origin + window.location.pathname;
        cmp.set('v.showMore', urlStr.endsWith('view'));
        helper.retrieveExtObjData(cmp, event, helper);
    },
    
    callDoInit : function(cmp, event, helper) {
        helper.callDoInitHelper(cmp, event, helper); 
    },
    
    navigateToChilComponent : function(component, event, helper) {
        helper.navigateToChilComponentHelper(component, event, helper); 
    },
    
    sortColumn: function(cmp, event, helper){
        if(!cmp.get("v.showMore")){
            cmp.set("{!v.orderByField}", event.target.id);
            var sortOrder = !cmp.get("v.sortAscDsc") || cmp.get("v.sortAscDsc") === 'ASC'?'DESC':'ASC';
            cmp.set("{!v.sortAscDsc}", sortOrder);
            helper.sortBy(cmp,event.target.id);
        }
    },
    
    navigateToDetail : function(component, event, helper){
        helper.navigateToDetailHelper(component, event, helper); 
    },
    
    supportTicketLink : function (component, event, helper){
        helper.supportTicketLinkHelper(component, event, helper); 
    },
    
    supportTicketLink1 : function (component, event, helper){
        helper.supportTicketLink1Helper(component, event, helper);
    },
    
    createRecord : function (component, event, helper) {
        helper.createRecordHelper(component, event, helper);
    },
    
    showModal: function (component, event, helper) {
        component.set("v.recordTobeDeleted", event.currentTarget.getAttribute("data-recId"));
        component.find("countyDifferentThanUserCounty").openModal();
        
    },
    
    handleDeleteRecord: function(component, event, helper) {
        helper.handleDeleteRecordHelper(component, event, helper);
        
    }
})