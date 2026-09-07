({
    // Changes array of values to semicolon seperated single string
    formatMonthList: function(monthList) {
        var monthListString = monthList.toString();
        if(monthList.length > 1){
            monthListString = monthListString.replaceAll(",", ";");
        }
        return monthListString;
	},
    
    // Changes semicolon seperated string to comma seperated string
    reFormatMonthList: function(monthList) {
        var monthListString = monthList;
        if(monthListString.includes(";")){
            monthListString = monthListString.replaceAll(";", ",");
        }
        return monthListString;
	},
    
    // Clears all the storage attributes
    resetFieldValues: function(component, event, helper, monthList) {
        var emptyArray = [];
        component.set("v.selectedActivityMonths", emptyArray);
        component.set("v.selectedRegistrationMonths", emptyArray);
        component.set("v.selectedTransportationMonth", emptyArray);
        component.set("v.fiscalRateValues.TXT_ACT_MONTH__c", null);
        component.set("v.fiscalRateValues.TXT_REG_MONTH__c", null);
        component.set("v.fiscalRateValues.TXT_TRANS_MONTH__c", null);
    }
})