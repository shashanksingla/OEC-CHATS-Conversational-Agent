({
    // Sets row and column grid for month names
    setGridStyle: function(component, event, helper) {
        var monthsPerRow = component.get("v.monthsPerRow");
        var dynamicGridStyle = component.get("v.dynamicGridStyle");
        dynamicGridStyle = "slds-col slds-size_1-of-"+monthsPerRow;
        component.set("v.dynamicGridStyle",dynamicGridStyle);
    },
    
    // Pre selects months while component renders
    preSelectMonthsHelper: function(component, event, helper) {
        var monthList = ["January", "February", "March", "April", "May", "June","July", "August", "September", "October", "November", "December"];
        var preSelectedMonths = component.get("v.preSelectedMonths");
        var allSelectedMonthNumbersArray = [];
        var allSelectedMonthNamesArray = [];
        if(preSelectedMonths){
            if(preSelectedMonths.includes(",")){
                let preSelectedMonthsArray = preSelectedMonths.replaceAll(" ", "").split(",");
                for(var i=0; i<preSelectedMonthsArray.length; i++){
                    let monthChecked = "v.preSelectedMonthsMap.monthChecked_"+preSelectedMonthsArray[i];
                    component.set(monthChecked, true);
                    allSelectedMonthNumbersArray.push(preSelectedMonthsArray[i]);
                    allSelectedMonthNamesArray.push(monthList[preSelectedMonthsArray[i]]);
                }
            } else {
                let monthChecked = "v.preSelectedMonthsMap.monthChecked_"+preSelectedMonths;
                component.set(monthChecked, true);
                allSelectedMonthNumbersArray.push(preSelectedMonths);
                allSelectedMonthNamesArray.push(monthList[preSelectedMonths-1]);
            }
            component.set("v.selectedMonthNumbers", allSelectedMonthNumbersArray);
            component.set("v.selectedMonthNames", allSelectedMonthNamesArray);
        }
    },
	
	// Once checkbox is clicked, stores all selected month numbers and names in two array attributes    
    addRemoveSelectedMonths: function(component, event, helper) {
        var selectedMonthNumber = event.getSource().get("v.value");
        var selectedMonthName = event.getSource().get("v.label");
        var isChecked = event.getSource().get("v.checked");
        var allSelectedMonthNumbers = component.get("v.selectedMonthNumbers");
        var allSelectedMonthNames = component.get("v.selectedMonthNames");
        var allSelectedMonthNumbersSet = new Set(allSelectedMonthNumbers);
        var allSelectedMonthNamesSet = new Set(allSelectedMonthNames);
        if(isChecked) {
            if(!allSelectedMonthNumbersSet.has(selectedMonthNumber)){
                allSelectedMonthNumbersSet.add(selectedMonthNumber);
                allSelectedMonthNamesSet.add(selectedMonthName);
            }
        } else {
            if(allSelectedMonthNumbersSet.has(selectedMonthNumber)){
                allSelectedMonthNumbersSet.delete(selectedMonthNumber);
                allSelectedMonthNamesSet.delete(selectedMonthName);
            }
        }
        allSelectedMonthNumbers = Array.from(allSelectedMonthNumbersSet);
        allSelectedMonthNames = Array.from(allSelectedMonthNamesSet);
        if(component.get("v.isSorted") && allSelectedMonthNumbers.length > 1){
            var monthOrder = ["January", "February", "March", "April", "May", "June","July", "August", "September", "October", "November", "December"];
            var monthNameSorted = allSelectedMonthNames.sort(function(a, b) {
                return monthOrder.indexOf(a) - monthOrder.indexOf(b);
            });
            var monthNumberSorted = allSelectedMonthNumbers.sort(function(c, d) {
                return c - d;
            });
            component.set("v.selectedMonthNames", monthNameSorted);
            component.set("v.selectedMonthNumbers", monthNumberSorted);
        } else {
            component.set("v.selectedMonthNumbers", allSelectedMonthNumbers);
            component.set("v.selectedMonthNames", allSelectedMonthNames);
        }
    }
})