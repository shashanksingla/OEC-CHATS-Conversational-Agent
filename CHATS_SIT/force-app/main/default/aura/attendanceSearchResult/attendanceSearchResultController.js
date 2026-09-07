({
    // Added by Rishav for CCCAP-5186
    sortbyColumn: function(component, event, helper) {
        var dataToSort = null;
        var searchResults1 = component.get("v.searchResults1");
        var searchResults2 = component.get("v.searchResults2");
        if(searchResults1.length > 1){
            dataToSort = searchResults1;
        }
        if(dataToSort != null && dataToSort != undefined){
            var id = event.target.id;
            if(undefined !== id && "" !== id){
                component.set("v.showSpinner", true);
                var sortAsc = component.get("v.sortAsc"),
                    field = id,
                    sortField = id,
                    records = dataToSort,
                    dummyRecordArray = [],
                    sortedRecord = [];
                for (var i = 0; i < records.length; i++) {
                    dummyRecordArray[i] = records[i];
                    dummyRecordArray[i].parentIndex = i;
                }
                sortAsc = sortField != field || !sortAsc;
                dummyRecordArray.sort(function(a, b) {
                    var t1 = a[field] == b[field],
                        t2 = (!a[field] && b[field]) || (a[field] < b[field]);
                    return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
                });
                for (var i = 0; i < records.length; i++) {
                    sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
                }
                component.set("v.searchResults1", sortedRecord);
                component.set("v.sortAsc", sortAsc);
                component.set("v.sortField", id);
                component.set("v.showSpinner", false);
            }
        }
        dataToSort = null
        if(searchResults2.length > 1){
            dataToSort = searchResults2;
        }
        if(dataToSort != null && dataToSort != undefined){
            var id = event.target.id;
            if(undefined !== id && "" !== id){
                component.set("v.showSpinner", true);
                var sortAsc = component.get("v.sortAsc"),
                    field = id,
                    sortField = id,
                    records = dataToSort,
                    dummyRecordArray = [],
                    sortedRecord = [];
                for (var i = 0; i < records.length; i++) {
                    dummyRecordArray[i] = records[i];
                    dummyRecordArray[i].parentIndex = i;
                }
                sortAsc = sortField != field || !sortAsc;
                dummyRecordArray.sort(function(a, b) {
                    var t1 = a[field] == b[field],
                        t2 = (!a[field] && b[field]) || (a[field] < b[field]);
                    return t1 ? 0 : (sortAsc ? -1 : 1) * (t2 ? 1 : -1);
                });
                for (var i = 0; i < records.length; i++) {
                    sortedRecord.push(records[dummyRecordArray[i].parentIndex]);
                }
                component.set("v.searchResults2", sortedRecord);
                component.set("v.sortAsc", sortAsc);
                component.set("v.sortField", id);
                component.set("v.showSpinner", false);
            }
        }
    }
})