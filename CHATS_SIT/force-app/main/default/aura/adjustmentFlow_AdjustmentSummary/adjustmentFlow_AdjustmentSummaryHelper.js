({
	calculateTotalAmount : function(adjustmentDtlWarp, cmp) {
        var totalAmount=0;
        for(var i=0;i<adjustmentDtlWarp.length;i++) {
                totalAmount = totalAmount + parseFloat(adjustmentDtlWarp[i].ajustmentDetails.AMT_DETAIL_ADJMT__c); 
            }
        cmp.set("v.adjustmentObj.AMT_ADJMT__c",totalAmount);    
    },
    
    sortBy: function(component, id) {
        debugger;
        var sortAsc = component.get("v.sortAsc"),
            field = id,
            sortField = id,
            records = component.get("v.adjustmentDtlWarp"),
            dummyRecordArray = [],
            sortedRecord = [],
        
        	fieldPath = field.split(/\./),
            fieldValue = this.fieldValue;
        
        // dummyRecord will possess all 'PAYLOAD' Object from all records
        for (var i = 0; i < records.length; i++) {
            dummyRecordArray[i] = records[i];
            // Another additional attribute 'parentIndex' is added to keep track of actual index of the object
            dummyRecordArray[i].parentIndex = i;
        }
            sortAsc = sortField != field || !sortAsc;
            // dummyRecord Array is Sorted
            dummyRecordArray.sort(function(a, b) {
                
                var aValue = fieldValue(a, fieldPath),
                	bValue = fieldValue(b, fieldPath),
                	t1 = aValue == bValue,
                	t2 = (!aValue && bValue) || (aValue < bValue);
                	//t1 = a[field] == b[field],
                    //t2 = (!a[field] && b[field]) || (a[field] < b[field]);
                return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
            });
        
        for (var i = 0; i < records.length; i++) {
            sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
        }
        console.log('------records', records);
        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", id);
        component.set("v.adjustmentDtlWarp", sortedRecord);
    },
    
    fieldValue: function(object, fieldPath) {
        debugger;
        var result = object;
        fieldPath.forEach(function(field) {
            if(result) {
                result = result[field];
            }
        });
        return result;
    }
})