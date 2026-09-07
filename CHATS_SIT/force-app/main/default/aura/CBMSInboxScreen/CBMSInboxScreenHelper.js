({
    initHelper : function(component, event, helper){
        var CBMSInboxWrapper = {};
        var cmpFromDate = component.get('v.CBMSInboxWrapper.fromDate');
        var cmpToDate = component.get('v.CBMSInboxWrapper.toDate');
        CBMSInboxWrapper.searchType = 'StringSearch';
        CBMSInboxWrapper.status = 'NEW;PEN;INC;';
        component.set("v.CBMSInboxWrapper", CBMSInboxWrapper);
        var options= component.get("v.options_");
         options.push({
                        'label' : '--None--',
                        'value' : null,
                        'class' : 'optionClass'
                    });
        var action = component.get('c.getInitCBMSRequestData');
        action.setCallback(this, function(response) {
            var state = response.getState();
            var res=response.getReturnValue();
            if (component.isValid() && state == 'SUCCESS') { 
                if(!$A.util.isEmpty(res) && !$A.util.isEmpty(res.objectData)){
                    
                    if(!$A.util.isEmpty(res.objectData.todayMinus30Days)){
                        component.set("v.CBMSInboxWrapper.fromDate",res.objectData.todayMinus30Days);
                    }
                    if(!$A.util.isEmpty(res.objectData.todayDate)){
                        component.set("v.CBMSInboxWrapper.toDate",res.objectData.todayDate);
                    }
                    if(!$A.util.isEmpty(res.objectData.user)){
                        component.set("v.CBMSInboxWrapper.county",res.objectData.user+';');
                    }
                    if(!$A.util.isEmpty(res.objectData.statusPickList)){
                        options = options.concat(res.objectData.statusPickList.map(function(v) {
                        var option = {
                            'label' : v.label,
                            'value' : v.value,
                            'class' : 'optionClass',
                            'selected' : false								
                        };
                        if(v.value=='NEW'|| v.value=='PEN' || v.value=='INC')
                            option.selected=true;
                        return option;
                    }));
                    }
                    var peakDefaultResult = component.get('v.CBMSInboxWrapper');
                    component.set("v.options_",options);
                    component.set('v.toDisplatDefault',true);
                    component.set("v.initDone", true);
                    this.viewCBMSHelper(component, helper);
                } 
            }
        });        
        $A.enqueueAction(action);
        
    },
    
    viewCBMSHelper : function(component, helper){
        component.set("v.showSpinner", true);
        var pageSize = component.get("v.pageSize");
        var CBMSInboxWrapper =component.get("v.CBMSInboxWrapper");
        
        if(CBMSInboxWrapper.fromDate !=null && CBMSInboxWrapper.fromDate.trim() == '' ){
            CBMSInboxWrapper.fromDate = null;
        }
        if(CBMSInboxWrapper.toDate !=null && CBMSInboxWrapper.toDate.trim() == '' ){
            CBMSInboxWrapper.toDate = null;
        }
        debugger;
        var action = component.get("c.processViewResults");
        action.setParams({ peakSearchWrapperStr : JSON.stringify(CBMSInboxWrapper) });
        action.setCallback(this, function(response) {
            var state = response.getReturnValue();
            debugger;
            if(component.isValid() && response.getState() === "SUCCESS"){
                debugger;
                component.set('v.FinalList',state.objectData.test);
                var paginationList = [];
                var items = component.get('v.FinalList').length;
                component.set("v.totalSize", items);
                component.set("v.start",0);
                component.set("v.end",pageSize-1);
               console.log('FinalList---'+JSON.stringify(state.objectData.test));
                if(items < pageSize){
                    paginationList= state.objectData.test;
                }
                else{
                    for(var i=0; i< pageSize; i++){
                        paginationList.push(state.objectData.test[i]);
                    } 
                }
                component.set('v.cbmsResultWrapper',paginationList);

                var navigtonCheck = component.get('v.navigationCheck');
                if(items == 0 && !component.get('v.navigationCheck'))
                {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        type:"error",
                        "message": "No CBMS Referral results found. Please refine the filter."
                    });
                    toastEvent.fire();
                }else{
                    component.set('v.navigationCheck',false); 
                }
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
    
    checkCustomValidations: function(component, event, helper){
        var isValid= true;
        var currentDate = new Date();
        
        var cmpFromDate = component.get('v.CBMSInboxWrapper.fromDate');
        var fromDate;
        var cmpToDate = component.get('v.CBMSInboxWrapper.toDate');
        var toDate;
        if(cmpFromDate != null){
            fromDate= new Date(component.get('v.CBMSInboxWrapper.fromDate'));
            var earlierToDate = new Date(fromDate.getFullYear(),fromDate.getMonth(),fromDate.getDate()+31) ;
        }
        if(cmpToDate != null){
            toDate= new Date(component.get('v.CBMSInboxWrapper.toDate')); 
        }
        
        var earlierFromDate =new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate()) ;
        var ssnNumber = component.get('v.CBMSInboxWrapper.ssn');

        
        if((fromDate!=null || fromDate!=undefined || fromDate!='') && fromDate > currentDate) 
        {	component.find('fromDate').set('v.message', 'Referral Received From Date should be less than today.') ;
         isValid = false;
        }else if((fromDate!=null || fromDate!=undefined || fromDate!='') && fromDate < earlierFromDate) 
        {fromDate != null && component.find('fromDate').set('v.message', 'Referral Received From Date cannot be earlier than 4 years.') ;
         isValid = false;
        }else{
            component.find('fromDate').set('v.message', '') ; 
        }
        if((toDate!=null || toDate!=undefined || toDate!='') && toDate > currentDate) 
        {component.find('toDate').set('v.message', 'Referral Received To Date should be less than today.') ;
         isValid = false;
        }else if((toDate!=null || toDate!=undefined || toDate!='') && toDate < fromDate) 
        {component.find('toDate').set('v.message', 'Referral Received To Date cannot be less than Referral Received From Date.') ;
         isValid = false;
        }else if((toDate!=null || toDate!=undefined || toDate!='') && toDate > earlierToDate)
        {component.find('toDate').set('v.message', 'Referral Received To Date cannot be more than 1 Month after Referral Received From Date.') ;
         isValid = false;
        }else{
            component.find('toDate').set('v.message', '') ; 
        }
        /*if(toDate==null || toDate==undefined || toDate==''){
            component.find('toDate').set('v.message', 'Complete the field') ;
            isValid = false;
        }
        if(fromDate==null || fromDate==undefined || fromDate==''){
            component.find('fromDate').set('v.message', 'Complete the field') ;
            isValid = false;
        }*/
        if(ssnNumber != null){
            if(ssnNumber.length > 9){
                component.find('param-ssn').set('v.message', 'SSN Number cannot be greater than 9 digits. Please enter a valid SSN Number.') ;
                isValid = false;
            }else{
                component.find('param-ssn').set('v.message', '') ;  
            }
        }
        return isValid;
    },

    
    sortBy: function(component, id) {
        component.set("v.showSpinner", true);
        var field = id;
        var records = component.get("v.cbmsResultWrapper") || [];
        var sortAsc = component.get("v.sortAsc");
        var sortField = component.get("v.sortField");

        // Toggle asc/desc if same field, else start ascending
        sortAsc = sortField !== field ? true : !sortAsc;

        // Helper: normalize value (null/undefined/empty -> null)
        var val = function (r) {
            var v = r && r[field];
            return (v === '' || v === undefined || v === null) ? null : v;
        };

        // Detect type from first non-null value
        var detected = 'string';
        var isoDateRegex = /^\d{4}-\d{2}-\d{2}$/; // YYYY-MM-DD
        for (var i = 0; i < records.length; i++) {
            var s = val(records[i]);
            if (s === null) continue;
            if (typeof s === 'number') { detected = 'number'; break; }
            if (Object.prototype.toString.call(s) === '[object Date]') { detected = 'date'; break; }
            if (typeof s === 'string') {
                var trimmed = s.trim();
                if (isoDateRegex.test(trimmed)) { detected = 'date'; break; }
                if (!isNaN(parseFloat(trimmed.replace(/,/g,'')))) { detected = 'number'; break; }
                if (!isNaN(Date.parse(trimmed))) { detected = 'date'; break; }
                detected = 'string'; break;
            }
            if (!isNaN(Date.parse(s))) { detected = 'date'; break; }
            break;
        }

        // Single compact comparator
        var cmp = function(a, b) {
            var av = val(a), bv = val(b);
            if (av === null && bv === null) return 0;
            if (av === null) return sortAsc ? 1 : -1;
            if (bv === null) return sortAsc ? -1 : 1;

            if (detected === 'number') {
                var na = (typeof av === 'number') ? av : parseFloat(String(av).replace(/,/g,''));
                var nb = (typeof bv === 'number') ? bv : parseFloat(String(bv).replace(/,/g,''));
                na = isNaN(na) ? (sortAsc ? Number.POSITIVE_INFINITY : Number.NEGATIVE_INFINITY) : na;
                nb = isNaN(nb) ? (sortAsc ? Number.POSITIVE_INFINITY : Number.NEGATIVE_INFINITY) : nb;
                return sortAsc ? (na - nb) : (nb - na);
            }
            if (detected === 'date') {
                // Simple standards-based date sorting:
                // - If value is a Date, compare getTime()
                // - If value is a string 'YYYY-MM-DD', compare lexicographically (safe for ISO format)
                // - Else fallback to Date.parse
                var getTime = function(x) {
                    if (x instanceof Date) return x.getTime();
                    var s = String(x).trim();
                    if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s; // return string for lexicographic compare
                    return Date.parse(s);
                };
                var ta = getTime(av);
                var tb = getTime(bv);

                // If both are ISO strings, lexicographic compare
                if (typeof ta === 'string' && typeof tb === 'string') {
                    var r = ta.localeCompare(tb);
                    return sortAsc ? r : -r;
                }

                // Normalize to numbers where possible
                ta = typeof ta === 'number' ? ta : NaN;
                tb = typeof tb === 'number' ? tb : NaN;

                if (isNaN(ta) && isNaN(tb)) return 0;
                if (isNaN(ta)) return sortAsc ? 1 : -1;
                if (isNaN(tb)) return sortAsc ? -1 : 1;
                return sortAsc ? (ta - tb) : (tb - ta);
            }
            // string
            var sa = String(av).toLowerCase();
            var sb = String(bv).toLowerCase();
            var res = sa.localeCompare(sb, undefined, { sensitivity: 'base' });
            return sortAsc ? res : -res;
        };

        // Sort in place (clone to avoid mutating references during compare)
        var sorted = records.slice().sort(cmp);

        component.set("v.sortAsc", sortAsc);
        component.set("v.sortField", field);
        component.set("v.cbmsResultWrapper", sorted);
        component.set("v.showSpinner", false);
    },
    returnPrevious : function(component, event){
        /*---Pagination previous Button Click--*/
        var wrapperList = component.get("v.FinalList");//All Account List
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        var paginationList = wrapperList.slice(start-pageSize,start);//Slicing List as page number
        start = start - pageSize;
        end = end - pageSize;
        component.set("v.start",start);
        component.set("v.end",end);
        component.set('v.cbmsResultWrapper', paginationList);
        var currentPageNumber= component.get('v.currentPageNumber')-1;//Current Page Number
        component.set('v.currentPageNumber',currentPageNumber);
    },
    returnNext : function(component, event)
    { /*---Pagination Next Button Click--*/
        var wrapperList = component.get("v.FinalList");//All Account List
        var end = component.get("v.end");
        var start = component.get("v.start");
        var pageSize = component.get("v.pageSize");
        var paginationList = [];
        var paginationList = wrapperList.slice(end+1,end+pageSize+1);//Slicing List as page number
        start = start + pageSize;
        end = end + pageSize;
        component.set("v.start",start);
        component.set("v.end",end);
        component.set('v.cbmsResultWrapper', paginationList);
        var currentPageNumber= component.get('v.currentPageNumber')+1;//Current Page Number
        component.set('v.currentPageNumber',currentPageNumber);
    }
})