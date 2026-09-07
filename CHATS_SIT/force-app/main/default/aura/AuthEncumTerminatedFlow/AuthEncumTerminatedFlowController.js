({
	doInit : function(component, event, helper) {
        var today = new Date();
        var month = today.getMonth(); // Returns 9
        var year = today.getFullYear();
        component.set("v.selectedMonth",month);
        component.set("v.selectedYear",year);
        component.set("v.months",
                      [{ value: "0", label: "January" },
                       { value: "1", label: "February" },
                       { value: "2", label: "March" },
                       { value: "3", label: "April" },
                       { value: "4", label: "May" },
                       { value: "5", label: "June" },
                       { value: "6", label: "July" },
                       { value: "7", label: "August" },
                       { value: "8", label: "September" },
                       { value: "9", label: "October" },
                       { value: "10", label: "November" },
                       { value: "11", label: "December" }]
                     );
                    
    },
     viewEncumbrances : function(component, event, helper) {
        var allValid = component.find('viewCalendarInput').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        if (allValid) {    
            var seletedMonth = component.get("v.selectedMonth");
            var seletedYear = component.get("v.selectedYear");
             var childCmp = component.find("authEncumbranceRelatedList");
            debugger;
           childCmp.getAuthEncumb(seletedMonth,seletedYear);
        } else {
        }},
        doCancel : function(component, event, helper) {
            var recordId = component.get("v.recordId");
            var currentTabNumber = component.get("v.currentTabNumber");
            helper.redirectToRecord(component.get("v.recordId"));
            
        }, 
})