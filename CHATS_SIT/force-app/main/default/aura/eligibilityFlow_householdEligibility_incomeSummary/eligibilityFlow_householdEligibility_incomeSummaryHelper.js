({
    computeGrossValues : function(component,transactionalArray,grossValues,amountValuesOfTransactionalArray) {
        
        for(var i=0;i<transactionalArray.length;i++) {
            if(component.get("v."+transactionalArray[i]) && component.get("v."+transactionalArray[i]).length>0) {
                var transaction = component.get("v."+transactionalArray[i]);
                var grossValue=0;
                for(var j=0;j<transaction.length;j++) {
                    if(grossValues[i]=='grossSelfEmpexpense' || grossValues[i]=='grossIncomeDeduction') {
                        grossValue -= parseFloat(transaction[j][amountValuesOfTransactionalArray[i]]);
                    } else {
                        grossValue += parseFloat(transaction[j][amountValuesOfTransactionalArray[i]]);
                    }
                }
                component.set("v."+grossValues[i],grossValue.toFixed(2));    
            }
        }
        component.set("v.initLoaded",true);
    }
})