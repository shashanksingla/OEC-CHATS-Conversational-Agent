({
    handleModalButtonClick: function(component, evt, helper) {
        component.set("v.showcomp",true);
        var seletedMonth = component.get("v.selectedMonth");//component.find("month").get("v.value");
        var seletedYear = component.get("v.selectedYear");//component.find("year").get("v.value");
        //component.find("selectedMonth").set("v.value", seletedMonth);
        //component.find("selectedYear").set("v.value", seletedYear);
        helper.getDaysInAMonth(seletedMonth, seletedYear, component);
    },
    doInit : function(component, evt, helper) {
        
    },
    handleUpdateStatus : function(component, evt, helper) {
        var cells = component.find('provCalEditCell');
        for(var i in cells){
            var cell = cells[i];
            var isDirty = cell.get('v.isDirty');
            //var careDate = cell.get('v.anAuthEncmbr').dte_care__c ;
            if(isDirty == 'true' ){
                cell.set("v.updatedSuccessfully", 'true');
                cell.set("v.isDirty",false);
                
            }
        }
    },
    handleUpdateCheck : function(component, evt, helper) {
        var checkAny=false;
        var cells = component.find('provCalEditCell');
        for(var i in cells){
            var cell = cells[i];
            var isDirty = cell.get('v.isDirty');
            //var careDate = cell.get('v.anAuthEncmbr').dte_care__c ;
            if(isDirty == 'true' ){
               
                checkAny=true;
                
            }
        }
        if(checkAny!=true)
        {
            component.set("v.ifError",'noupdate');
        }
        if(checkAny==true)
        {
            component.set("v.ifError",'yesUpdate');
        }
    },
})