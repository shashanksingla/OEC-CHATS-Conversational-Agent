({
    calculateTotalIncome : function(component, event, helper) {
        var incomeRows = component.get('v.incomeRows');
        var annualIncome = 0;
        var annualIncome1 = 0;
        var annualIncome2 = 0;
        var annualIncome3 = 0;
        var annualIncome4 = 0;
        var annualIncome5 = 0;
        var annualIncome6 = 0;
        var annualIncome7 = 0;
        var annualIncome8 = 0;
        var annualIncome9 = 0;
        var annualIncome10 = 0;
        var fpg = 0;
        var countyValue = component.get("v.county");
        var familySizeValue = component.get("v.familySize");
        var c1 = component.get("v.c1");
        var c2 = component.get("v.c2");
        // Start: Added below codes and 'if' condition with new logic for CCCAP-3236, CCCAP-3709 & CCCAP-3790 by Rishav
        var hasEmploymentType = false;
        var empNumCountMap = new Map();
        var empNumIncomeMap = new Map();
        var empNumAvgIncomeMap = new Map();
        var empNumHourMap = new Map();
        var fedMinWageMap = new Map();
        incomeRows.forEach(function(ir){
            if(ir.amount != null && ir.amount != "" && ir.amount > 0){
                var empNumberTemp = ir.empNumber;
                //adding condition for One Time Payment for CCCAP-12098 
                if((ir.CDE_SOURCE_INCOME__c != "E" && ir.CDE_SOURCE_INCOME__c != "S") || ir.CDE_FREQ_PAY_ESTMD__c == 'ONE')
                    empNumberTemp = ""; // Emp # are ingored for non 'Employment' and 'Self Emp' income types
                if(empNumCountMap.has(empNumberTemp)){
                    empNumCountMap.set(empNumberTemp, empNumCountMap.get(empNumberTemp)+1);
                } else {
                    empNumCountMap.set(empNumberTemp, 1);
                }
                if(ir.CDE_SOURCE_INCOME__c == "E" || ir.CDE_SOURCE_INCOME__c == "S")
                    hasEmploymentType = true;
            }
        });
        if(hasEmploymentType){
            incomeRows.forEach(function(ir){
                if(ir.amount != null && ir.amount != "" && ir.amount > 0){
                    // Calculating per row annual income besed on frequency
                    var rowAnnualIncome = 0;
                    if(ir.CDE_FREQ_PAY_ESTMD__c == 'HLY'){
                        rowAnnualIncome = (((ir.amount) * (ir.hoursPerWeek)) * 4.33) * 12;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == 'WKY') {
                        rowAnnualIncome = (4.33*(ir.amount))*12;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == 'E2W') {
                        rowAnnualIncome = (4.33*(ir.amount/2))*12;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == '2PM') {
                        rowAnnualIncome = 24*ir.amount;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == 'MON') {
                        rowAnnualIncome = 12*ir.amount;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == 'E2M') {
                        rowAnnualIncome = 6*ir.amount;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == 'QRT') {
                        rowAnnualIncome = 4*ir.amount;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == '2PY') {
                        rowAnnualIncome = 2*ir.amount;
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == '1PY') {
                        rowAnnualIncome = parseFloat(ir.amount);
                    } else if(ir.CDE_FREQ_PAY_ESTMD__c == 'ONE') {
                        rowAnnualIncome = parseFloat(ir.amount);
                    }
                    // Creating Map of Emp # as key and total week hours for that Emp # as value
                    //adding condition for One Time Payment for CCCAP-12098 
                    if((ir.CDE_SOURCE_INCOME__c == "E" || ir.CDE_SOURCE_INCOME__c == "S") && ir.CDE_FREQ_PAY_ESTMD__c != 'ONE'){ // Only 'Employment' and 'Self Emp' income types are considered in fedMinWage calculation
                        if(empNumHourMap.has(ir.empNumber)) {
                            empNumHourMap.set(ir.empNumber, empNumHourMap.get(ir.empNumber) + parseFloat(ir.hoursPerWeek));
                        } else {
                            empNumHourMap.set(ir.empNumber, parseFloat(ir.hoursPerWeek));
                        }
                    }
                    // Creating Map of Emp # as key and total annual income for that Emp # as value
                    var empNumberTemp = ir.empNumber;
                    //adding condition for One Time Payment for CCCAP-12098 
                    if((ir.CDE_SOURCE_INCOME__c != "E" && ir.CDE_SOURCE_INCOME__c != "S") || ir.CDE_FREQ_PAY_ESTMD__c =='ONE')
                        empNumberTemp = ""; // Emp # are ignored for non 'Employment' and 'Self Emp' income types
                    if(empNumIncomeMap.has(empNumberTemp)) {
                        empNumIncomeMap.set(empNumberTemp, empNumIncomeMap.get(empNumberTemp) + rowAnnualIncome);
                    } else {
                        empNumIncomeMap.set(empNumberTemp, rowAnnualIncome);
                    }
                }
            });
            // Calcuating the average of annual income per emp # and total income
            empNumIncomeMap.forEach(function(value, key){
                if(key){
                    empNumAvgIncomeMap.set(key, value/empNumCountMap.get(key));
                    annualIncome += value/empNumCountMap.get(key);
                } else {
                    annualIncome += value;
                }
            });
            // Calcuating the fed min wage for each emp #
            empNumHourMap.forEach(function(value, key){
                var avgHour = value / empNumCountMap.get(key);
                fedMinWageMap.set(key, (avgHour*7.25*4.33*12).toFixed(2));
            });
            // Comparing fed min wage with income and setting Yes/No in UI
            var oldIncomeRows = component.get("v.incomeRows");
            var newIncomeRows = [];
            for (var ir of oldIncomeRows) {
                ir.fedMinWageMet = '';
                if(ir.CDE_SOURCE_INCOME__c == "E" || ir.CDE_SOURCE_INCOME__c == "S"){
                    if(empNumAvgIncomeMap.get(ir.empNumber) >= fedMinWageMap.get(ir.empNumber))
                        ir.fedMinWageMet = 'Yes';
                    else
                        ir.fedMinWageMet = 'No';
                }
                newIncomeRows.push(ir);
            }
            component.set("v.incomeRows", newIncomeRows);
        } else {
            // If no 'Employment' or 'Self Emp' type are present then simply calcualate income per row and add into total
            incomeRows.forEach(function(incomeRow){
                // Calculating per row annual income besed on frequency
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == 'HLY'){
                    annualIncome1 +=  (((incomeRow.amount) * (incomeRow.hoursPerWeek)) * 4.33) * 12;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == 'WKY'){
                    annualIncome2 += (4.33*(incomeRow.amount))*12;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == 'E2W'){
                    annualIncome3 += (4.33*(incomeRow.amount/2))*12;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == '2PM'){
                    annualIncome4 += 24*incomeRow.amount;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == 'MON'){
                    annualIncome5 += 12*incomeRow.amount;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == 'E2M'){
                    annualIncome6 += 6*incomeRow.amount;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == 'QRT'){
                    annualIncome7 += 4*incomeRow.amount;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == '2PY'){
                    annualIncome8 += 2*incomeRow.amount;
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == '1PY'){
                    annualIncome9 += parseFloat(incomeRow.amount);
                }
                if(incomeRow.CDE_FREQ_PAY_ESTMD__c == 'ONE'){
                    annualIncome10 += parseFloat(incomeRow.amount);
                }
            });
            annualIncome = annualIncome1+annualIncome2+annualIncome3+annualIncome4+annualIncome5+annualIncome6+annualIncome7+annualIncome8+annualIncome9+annualIncome10;
        }
        // End: CCCAP-3236
        // Clearing fedMinWageMet column in UI
        var oldIncomeRows = component.get("v.incomeRows");
        var newIncomeRows = [];
        for (var ir of oldIncomeRows) {
            if(ir.CDE_SOURCE_INCOME__c != "E" && ir.CDE_SOURCE_INCOME__c != "S"){
                ir.fedMinWageMet = '';
            }
            newIncomeRows.push(ir);
        }
        component.set("v.incomeRows", newIncomeRows);
        fpg =(annualIncome / (c1 + ((familySizeValue - 1) * c2))) * 100;
        // changes for CCCAP-13258
        let today = new Date();
        let pdfEffectiveDate = new Date($A.get("$Label.c.Parent_Fee_Formula_Change"));
        if(today>=pdfEffectiveDate){
            fpg = Math.trunc(fpg * 1000) / 1000;
            component.set('v.pfChangeEffective',true);
        }
        component.set('v.annualIncome', annualIncome.toFixed(2));
        component.set('v.monthlyIncome', (annualIncome/12).toFixed(2));
        component.set('v.fpg', fpg.toFixed(3));
        helper.fullParentFeeCalculation(component, event, helper, annualIncome, fpg.toFixed(3));
    },
    
    clearCells : function(component, event, helper) {
        component.set("v.familySize",0);
        component.set("v.incomeRows",[{'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''}, {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''},
                             {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''}, {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''},
                             {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''}, {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''},
                             {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''}, {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''},
                             {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''}, {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''},
                             {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''}, {'CDE_SOURCE_INCOME__c':'', 'empNumber':'', 'amount':'', 'CDE_FREQ_PAY_ESTMD__c':'', 'hoursPerWeek':'', 'fedMinWageMet':''}]);
        component.set('v.annualIncome', 0);
        component.set('v.monthlyIncome', 0);
        component.set('v.fpg', 0);
        component.set("v.incomeCelling",0);
        component.set('v.fullTimeFee', 0);
        component.set('v.partTimeFee', 0);
        component.set('v.fullTimeFeeDiscounted', 0);
        component.set("v.partTimeFeeDiscounted",0);
        component.set('v.fbgIncome', 0);
        component.set('v.countyMaxIncome', 0);
        component.set('v.SMI', 0);
        component.set("v.baseParentFee",0);
        component.set('v.addOnFee', 0);
        component.set('v.noOfChildReqCare', 0);
        component.set('v.fedMinWage', 0); // Added for CCCAP-3236 by Rishav
    },
    
    onClick: function (cmp, evt, helper) {
        cmp.set("v.pageMessages",null);
        var allValid = cmp.find('input-field').reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && inputCmp.get('v.validity').valid;
        }, true);
        var anyRowPopulated = false;
        cmp.get("v.incomeRows").forEach(function(incomeRow) {
            if(!$A.util.isEmpty(incomeRow.CDE_SOURCE_INCOME__c) || !$A.util.isEmpty(incomeRow.amount) || !$A.util.isEmpty(incomeRow.CDE_FREQ_PAY_ESTMD__c)){
                anyRowPopulated = true;
            }
        });
        if(!anyRowPopulated){
            cmp.set("v.pageMessages",[$A.get("$Label.c.INCOME_TOOL_AT_LEAST_ONE_ROW_REQ")]);
            cmp.set("v.messageType","error");
            allValid = false;
        }
        var incomeRowCmps = cmp.find('incomeRowCmp');
        incomeRowCmps.forEach(function(incomeRowCmp) {
            if(incomeRowCmp){
                allValid =  incomeRowCmp.validateMe() && allValid;
            }
        });
        return allValid;
    },
    
    fullParentFeeCalculation : function(component, event, helper,annualIncome, fpg) {
        helper.callServerAndHandleError(component,"c.parentFeeDataAll", 
                                        function(response){
                                            if(response.objectData){
                                                var fullTimeFee = parseFloat(response.objectData.fullTimeFee);
                                                var partTimeFee = parseFloat(response.objectData.partTimeFee);
                                                component.set("v.fullTimeFee", fullTimeFee.toFixed(2));
                                                component.set("v.partTimeFee", partTimeFee.toFixed(2));
                                                component.set("v.baseParentFee", response.objectData.baseParentFee);
                                                component.set("v.addOnFee", response.objectData.addOnFee);
                                                component.set("v.SMI", response.objectData.SMIPercent);
                                                component.set("v.fullTimeFeeDiscounted", Math.floor(response.objectData.fullTimeFee * 0.8));
                                                component.set("v.partTimeFeeDiscounted", Math.floor(response.objectData.partTimeFee * 0.8));
                                                component.set("v.fbgIncome", response.objectData.FPIGPercent); 
                                                var FPIGIncome = response.objectData.FPIGIncome;
                                                component.set("v.countyMaxIncome", response.objectData.countyMaxIncome);
                                            }
                                        }, {'annualIncome':annualIncome,'inputFPG':fpg,'noOfChildReq':component.get("v.noOfChildReqCare"),'county':component.get("v.county"),'familySize':component.get('v.familySize')}, false, null);        
    }
})