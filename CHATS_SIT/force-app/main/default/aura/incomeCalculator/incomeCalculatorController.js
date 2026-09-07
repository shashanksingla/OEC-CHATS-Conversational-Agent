({
    doInit  : function(component, event, helper) {
        helper.callServerAndHandleError(component,"c.getFPGValues",
                                        function(response){
                                            component.set("v.c1",response.objectData.c1);
                                            component.set("v.c2",response.objectData.c2);
                                        }, {}, false, null);   
    },
    
    calculateIncome : function(component, event, helper) {
        if(helper.onClick(component, event, helper)==true){
            helper.calculateTotalIncome(component, event, helper);
            helper.callServerAndHandleError(component,"c.getCountyData", 
                                            function(response){
                                                if(response.objectData && response.objectData.data)
                                                    component.set("v.incomeCelling",response.objectData.data.ELIGIBILITY_Q1_1__c);
                                            }, {'county':component.get("v.county")}, false, null);   
        }
    },
    
    clearFields : function(component, event, helper) {
        helper.clearCells(component, event, helper);
    },
    
    // Added for CCCAP-3807 by Rishav
    addIncomeRow : function(component, event, helper) {
        var incomeRows = component.get("v.incomeRows");
        var singleRow = {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''};
        incomeRows.push(singleRow);
        component.set("v.incomeRows", incomeRows);
    }
})