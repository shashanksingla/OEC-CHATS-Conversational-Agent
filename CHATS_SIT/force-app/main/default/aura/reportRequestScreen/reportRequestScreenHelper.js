({
    doInitHlp : function(component, event, helper) {
        var action = component.get('c.getInitReportRequestData');
        component.set("v.showSpinner", true);
        if(!$A.util.isEmpty(component.get("v.selectedReport"))){
            var selectedReportCopy =JSON.parse(JSON.stringify( component.get("v.selectedReport")));
            component.set("v.selectedReportCopy",selectedReportCopy);
            var reportName = component.get("v.selectedReport").DeveloperName;
            var selectedReport = component.get("v.selectedReport");
            if(reportName != "RE231")
            {
                component.set("v.isMultiSelectCounty", true);
            }
            component.set("v.isCountyRequired", reportName != "RE306");
            action.setParams({
                'ReportName' : reportName
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                var res=response.getReturnValue();
                component.set("v.showSpinner", false);
                if (component.isValid() && state == 'SUCCESS') {
                    if(reportName == "RE803" || reportName == "RE705"){
                        component.set("v.isProvidorMandatory", false);
                    }else{
                        component.set("v.isProvidorMandatory", true);
                    }
                    if(reportName == "RE219" || reportName == "RE222"){
                        let currentYear = (new Date()).getFullYear();
                        let yearOptions = [{ value: "", label: "--None--" }];
                        let start = reportName == "RE219" ? 2022: 2024;
                        for(let i =start;i<=currentYear;i++){
                            yearOptions.push({'label':i,'value':i});
                        }
                        component.set('v.startYearOptions',yearOptions);
                        component.set('v.endYearOptions',JSON.parse(JSON.stringify(yearOptions)));
                    }
                    if(!$A.util.isEmpty(res) && !$A.util.isEmpty(res.objectData)){
                        if(!$A.util.isEmpty(res.objectData.requestDataList)){
                            component.set("v.reoprtRequestFilterList",res.objectData.requestDataList);
                            component.set("v.initData",res.objectData.requestDataList[0]);
                        }
                        if(!$A.util.isEmpty(res.objectData.reportInboxURL)){
                            component.set("v.reportInboxURL",res.objectData.reportInboxURL);
                        }
                        if(!$A.util.isEmpty(res.objectData.successMsg)){
                            component.set("v.successMsg",res.objectData.successMsg);
                        }
                        if(!$A.util.isEmpty(res.objectData.requestInboxMsg)){
                            component.set("v.requestInboxMsg",res.objectData.requestInboxMsg);
                        }
                        if(!$A.util.isEmpty(res.objectData.errorMsg)){
                            component.set("v.errorMsg",res.objectData.errorMsg);
                        }
                        if(!$A.util.isEmpty(res.objectData.todayDate)){
                            if(selectedReport.isDateDefaulted__c){
                                component.set("v.endDate",res.objectData.todayDate);
                                component.set("v.endDateCopy",res.objectData.todayDate);
                            }
                        }
                        if(!$A.util.isEmpty(res.objectData.todayMinus30Days)){
                            if(selectedReport.isDateDefaulted__c){
                                component.set("v.beginDate",res.objectData.todayMinus30Days);
                                component.set("v.beginDateCopy",res.objectData.todayMinus30Days);
                            }
                        }
                        if(!$A.util.isEmpty(res.objectData.countyOptionMap)){
                            var optionMap =res.objectData.countyOptionMap;
                            var selectedCounty = component.get("v.selectedCounty");
                            var countyOptions = [{'value':null,'label':'--None--','selected':false}];
                            for (var p in optionMap) {
                                if( optionMap.hasOwnProperty(p) ) {
                                    countyOptions.push({'value':optionMap[p],'label':p,'selected':selectedCounty==optionMap[p]?true:false});
                                }
                            }
                            component.set("v.countyOptions",countyOptions);
                            component.set("v.isCountyOptions",true);
                        }
                        /* *** CCCAP-12937 ***
                        if(reportName == "RE229"){ // Added by Rishav for CCCAP-6604
                            component.set("v.beginDate", $A.get("$Label.c.RE229_Default_beginDate"));
                            component.set("v.beginDateCopy", $A.get("$Label.c.RE229_Default_beginDate"));
                        }
                        */
                        if(reportName == 'RE221'){ // added for CCCAP-12495
                            component.set('v.missingYearError','Please select a date');
                        }
                    }
                } else {
                }
            });
            $A.enqueueAction(action);
        }
    },
    
    submitReportRequestHlp : function(component, event, helper) {
        var dataValue = component.get("v.initData");
        var reoprtRequestFilterList = component.get("v.reoprtRequestFilterList");
        var reportRequestFilterListToCreate = [];
        var reportRequestToCreate = [];
        var reqObj =component.get("v.reportRequestObj");
        var selectedReport = component.get("v.selectedReport");
        reqObj.Report_Name__c =component.get("v.selectedReport").Report_Name__c;
        reqObj.Report_Type__c =component.get("v.selectedReport").Report_Type__c;
        reqObj.Report_Id__c =component.get("v.selectedReport").DeveloperName;
        reqObj.Request_Type__c =component.get("v.selectedReport").Request_Type__c;
        reqObj.County__c =component.get("v.selectedCounty");
        reqObj.Request_Description__c =component.get("v.selectedReport").Description__c;
        reportRequestToCreate.push(reqObj);
        var filterObjectJSON ="[";
        var beginDate, endDate;
        var beginDateRE304, endDateRE304;
        var beginDateRE117,endDateRE117; // CCCAP-13192
        var beginDateRE218, endDateRE218; // Added by Rishav for CCCAP-6791
        var AppRecvdBeginDate, AppRecvdEndDate, AppProcdBeginDate, AppProcdEndDate; // Added by Rishav for CCCAP-7662
        var validFlow = true;
        var reportRequestFilterObj = component.get("v.reportRequestFilterObj");
        
        for(var j in reoprtRequestFilterList){
            var reportRequestFilterObj = component.get("v.reportRequestFilterObj");
            reportRequestFilterObj.Field__c = reoprtRequestFilterList[j].Field_Api_Name__c;
            if(!$A.util.isEmpty(dataValue) && !$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")])){
                if(!$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c])){
                    if(component.get("v.selectedReport").Report_Name__c =='RE304 - Provider Notes Report'){
                        if(reportRequestFilterObj.Field__c == 'FromDate'){
                            beginDateRE304 = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                        if(reportRequestFilterObj.Field__c == 'ToDate'){
                            endDateRE304 = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                    }
                    if(component.get("v.selectedReport").DeveloperName == 'RE218'){ // Added by Rishav for CCCAP-6791
                        if(reportRequestFilterObj.Field__c == 'FromDate'){
                            beginDateRE218 = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                            component.set("v.beginDate", beginDateRE218);
                        }
                        if(reportRequestFilterObj.Field__c == 'ToDate'){
                            endDateRE218 = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                            component.set("v.endDate", endDateRE218);
                        }
                    }
                    //CCCAP-13192
                    if(component.get("v.selectedReport").DeveloperName == 'RE117'){ 
                        if(reportRequestFilterObj.Field__c == 'FromDate'){
                            beginDateRE117 = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                            component.set("v.beginDate", beginDateRE117);
                            console.log('date',component.get( "v.beginDate"));
                        }
                        if(reportRequestFilterObj.Field__c == 'ToDate'){
                            endDateRE117 = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                            component.set("v.endDate", endDateRE117);
                            console.log('date',component.get("v.endDate"));
                        }
                    }
                    //end CCCAP-13192
                    if(component.get("v.selectedReport").DeveloperName == 'RE230'){ // Added by Rishav for CCCAP-7662
                        if(reportRequestFilterObj.Field__c == 'AppRecvdBeginDate'){
                            AppRecvdBeginDate = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                        if(reportRequestFilterObj.Field__c == 'AppRecvdEndDate'){
                            AppRecvdEndDate = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                        if(reportRequestFilterObj.Field__c == 'AppProcdBeginDate'){
                            AppProcdBeginDate = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                        if(reportRequestFilterObj.Field__c == 'AppProcdEndDate'){
                            AppProcdEndDate = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                    }
                    if(selectedReport.isMonthYearFilter__c){
                        if( reportRequestFilterObj.Field__c =='CaseBeginDate'){
                            beginDate=dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                        if( reportRequestFilterObj.Field__c =='CaseEndDate'){
                            endDate=dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                        }
                    }
                    reportRequestFilterObj.Value__c =dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                    reportRequestFilterListToCreate.push(reportRequestFilterObj);
                } 
            }
            component.set("v.reportRequestFilterObj", {'sobjectType': 'Canned_Report_Request_Filter__c',
                                                       'Field__c': '',
                                                       'Value__c': '',
                                                       'Canned_Report_Request__c': ''
                                                      });
        }
        
        if((component.get("v.selectedReport").DeveloperName == 'RE110')){
            var reportRequestFilterObj = component.get("v.reportRequestFilterObj");
            var beginDateDis= component.get("v.beginDateDis");
            var endDateDis= component.get("v.endDateDis");
            if(!$A.util.isEmpty(beginDateDis) && !$A.util.isEmpty(endDateDis) ){
                reportRequestFilterObj.Field__c = 'beginDateDis';
                reportRequestFilterObj.Value__c =beginDateDis;
                reportRequestFilterListToCreate.push(reportRequestFilterObj);
                component.set("v.reportRequestFilterObj",{'sobjectType': 'Canned_Report_Request_Filter__c',
                                                          'Field__c': '',
                                                          'Value__c': '',
                                                          'Canned_Report_Request__c': ''
                                                         });
                reportRequestFilterObj = component.get("v.reportRequestFilterObj");
                reportRequestFilterObj.Field__c = 'endDateDis';
                reportRequestFilterObj.Value__c =endDateDis;
                reportRequestFilterListToCreate.push(reportRequestFilterObj);
                component.set("v.reportRequestFilterObj",{'sobjectType': 'Canned_Report_Request_Filter__c',
                                                          'Field__c': '',
                                                          'Value__c': '',
                                                          'Canned_Report_Request__c': ''
                                                         });
            }
        }
        // Added by Rishav for CCCAP-6791
        if((component.get("v.selectedReport").DeveloperName == 'RE218')){
            var beginDateUTC = this.getDateInUTC(new Date(beginDateRE218));
            var endDateUTC = this.getDateInUTC(new Date(endDateRE218));
            if(endDateUTC < beginDateUTC){
                component.set("v.message", 'error');
                component.set("v.recordError", ['End Date cannot be less than begin date']);
                validFlow = false;
            }
        }
        //  End: CCCAP-6791
        //  CCCAP-13192
        if((component.get("v.selectedReport").DeveloperName == 'RE117')){
            var beginDateUTC = this.getDateInUTC(new Date(beginDateRE117));
            var endDateUTC = this.getDateInUTC(new Date(endDateRE117));
            if(endDateUTC < beginDateUTC){
                component.set("v.message", 'error');
                component.set("v.recordError", ['End Date cannot be less than begin date']);
                validFlow = false;
            }
        }
        //  End CCCAP-13192
        
        // Added by Rishav for CCCAP-7662
        if((component.get("v.selectedReport").DeveloperName == 'RE230')){
            var hasErrorMessage = false;
            var is30DaysReport = false;
            var isDateRangeValid = false;
            var beginDateUTC, endDateUTC;
            if(!$A.util.isEmpty(AppRecvdBeginDate) && !$A.util.isEmpty(AppRecvdEndDate)){
                beginDateUTC = this.getDateInUTC(new Date(AppRecvdBeginDate));
                endDateUTC = this.getDateInUTC(new Date(AppRecvdEndDate));
                if(endDateUTC < beginDateUTC){
                    component.set("v.message", 'error');
                    component.set("v.recordError", ['End Date cannot be less than Begin Date']);
                    validFlow = false;
                    hasErrorMessage = true;
                } else {
                    isDateRangeValid = true;
                    if(!is30DaysReport){
                        let diffTime = Math.abs(endDateUTC - beginDateUTC);
                        let diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        if(diffDays > 30)
                            is30DaysReport = true;
                        component.set("v.beginDate", AppRecvdBeginDate);
                        component.set("v.endDate", AppRecvdEndDate);
                    }
                }
            }
            if(!$A.util.isEmpty(AppProcdBeginDate) && !$A.util.isEmpty(AppProcdEndDate)){
                beginDateUTC = this.getDateInUTC(new Date(AppProcdBeginDate));
                endDateUTC = this.getDateInUTC(new Date(AppProcdEndDate));
                if(endDateUTC < beginDateUTC){
                    component.set("v.message", 'error');
                    component.set("v.recordError", ['End Date cannot be less than Begin Date']);
                    validFlow = false;
                    hasErrorMessage = true;
                } else {
                    isDateRangeValid = true;
                    if(!is30DaysReport){
                        let diffTime = Math.abs(endDateUTC - beginDateUTC);
                        let diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        if(diffDays > 30)
                            is30DaysReport = true;
                        component.set("v.beginDate", AppProcdBeginDate);
                        component.set("v.endDate", AppProcdEndDate);
                    }
                }
            }
            if(!isDateRangeValid){
                validFlow = false;
                if(!hasErrorMessage){
                    component.set("v.message", 'error');
                    component.set("v.recordError", ['At least one date filter must be selected']);
                }
            }
        }
        // End: CCCAP-7662
        
        if(component.get("v.selectedReport").DeveloperName == 'RE306'){
            var beginDateRE306, endDateRE306;
            for(var j in reoprtRequestFilterList){
                var fieldApiName = reoprtRequestFilterList[j].Field_Api_Name__c;
                if(!$A.util.isEmpty(dataValue) && !$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")])){
                    var val = dataValue[component.get("v.requestFilterObjectName")][0][fieldApiName];
                    if(!$A.util.isEmpty(val)){
                        if(fieldApiName == 'DateOfComplaintBeginDate') { beginDateRE306 = val; }
                        if(fieldApiName == 'DateOfComplaintEndDate')   { endDateRE306   = val; }
                    }
                }
            }
            var todayUTC = this.getDateInUTC(new Date());
            if(!$A.util.isEmpty(beginDateRE306)){
                var beginUTC306 = this.getDateInUTC(new Date(beginDateRE306));
                if(beginUTC306 > todayUTC){
                    component.set("v.message", 'error');
                    component.set("v.recordError", ['Begin date should be less than or equal to today']);
                    validFlow = false;
                }
            }
            if(!$A.util.isEmpty(endDateRE306)){
                var endUTC306 = this.getDateInUTC(new Date(endDateRE306));
                if(endUTC306 > todayUTC){
                    component.set("v.message", 'error');
                    component.set("v.recordError", ['End date should be less than or equal to today']);
                    validFlow = false;
                }
            }
            if(!$A.util.isEmpty(endDateRE306) && $A.util.isEmpty(beginDateRE306)){
                component.set("v.message", 'error');
                component.set("v.recordError", ['Please Enter Date of Complaint Begin Date']);
                validFlow = false;
            } else if(!$A.util.isEmpty(beginDateRE306) && !$A.util.isEmpty(endDateRE306)){
                var beginUTC = this.getDateInUTC(new Date(beginDateRE306));
                var endUTC   = this.getDateInUTC(new Date(endDateRE306));
                if(endUTC < beginUTC){
                    component.set("v.message", 'error');
                    component.set("v.recordError", ['Date of Complaint End Date cannot be less than Date of Complaint Begin Date']);
                    validFlow = false;
                }
            }
        }
        if((component.get("v.selectedReport").Report_Name__c =='RE304 - Provider Notes Report')){
            if($A.util.isEmpty(endDateRE304) && $A.util.isEmpty(beginDateRE304)){
                component.set("v.message",'error');
                component.set("v.recordError",['At least one date is required.']);
                validFlow =false;
            } else if(!$A.util.isEmpty(endDateRE304) && !$A.util.isEmpty(beginDateRE304)) {
                var beginArr = beginDateRE304.split('-');
                var endArr = endDateRE304.split('-');
                if(beginArr.length >1 && endArr.length >1 ){
                    var beginDateStr = new Date(beginArr[0],beginArr[1],beginArr[2]);
                    var endDateStr = new Date(endArr[0],endArr[1],endArr[2]);
                    var oneYearEarlierDate =new Date(beginDateStr.getFullYear()+1,beginDateStr.getMonth(),beginDateStr.getDate()) ;
                    console.log('oneYearEarlierDate-valdation--'+oneYearEarlierDate);
                    if(endDateStr > oneYearEarlierDate){
                        component.set("v.message",'error');
                        component.set("v.recordError",['End Date cannot be more than 1 Year after begin date']);
                        validFlow =false;
                    } else if(endDateStr<beginDateStr){
                        component.set("v.message",'error');
                        component.set("v.recordError",['End Date cannot be less than begin date']);
                        validFlow =false;
                    }
                }
            } else if(!$A.util.isEmpty(endDateRE304) && $A.util.isEmpty(beginDateRE304)){
                var endArr = endDateRE304.split('-');
                if(endArr.length >1 ){
                    endArr[1] = endArr[1]-1;
                    var endDateStr = new Date(endArr[0],endArr[1],endArr[2]);
                    var oneYearLaterDateTemp= endDateStr.setFullYear(endDateStr.getFullYear() - 1);
                    var oneYearLaterDate1 =new Date(endDateStr.getFullYear(),endDateStr.getMonth(),endDateStr.getDate()) ;
                    // var oneYearLaterDate = endDateStr.getFullYear() +'-'+endArr[1] +'-'+endArr[2];
                    var  month =endDateStr.getMonth();
                    var day=endDateStr.getDate();
                    month = month+1;
                    if(month <10){
                        month = '0'+ month;
                    }
                    if(endDateStr.getDate() <10){
                        day = '0'+endDateStr.getDate();
                    }
                    var oneYearLaterDate = endDateStr.getFullYear() +'-'+month +'-'+day;
                    console.log('endDateStr--'+endDateStr);
                    console.log('endDateRE304--'+endDateRE304);
                    console.log('oneYearLaterDate--'+oneYearLaterDate);
                    var reportRequestFilterObj = component.get("v.reportRequestFilterObj");
                    reportRequestFilterObj.Field__c ='FromDate';
                    reportRequestFilterObj.Value__c =oneYearLaterDate;
                    reportRequestFilterListToCreate.push(reportRequestFilterObj);
                    component.set("v.reportRequestFilterObj",{'sobjectType': 'Canned_Report_Request_Filter__c',
                                                              'Field__c': '',
                                                              'Value__c': '',
                                                              'Canned_Report_Request__c': ''
                                                             });
                    /* for(var j in reportRequestFilterListToCreate){
                        var reportRequestFilterObj = reoprtRequestFilterList[j];
                        if(reportRequestFilterObj.Field__c =='ToDate'){
                            reportRequestFilterListToCreate[j].Value__c = oneYearLaterDate;
                            reportRequestFilterListToCreate=reportRequestFilterListToCreate;
                        }
                    }*/
                }
            } else if($A.util.isEmpty(endDateRE304) && !$A.util.isEmpty(beginDateRE304)){
                var beginArr = beginDateRE304.split('-');
                if(beginArr.length >1 ){
                    beginArr[1] = beginArr[1]-1;
                    var beginDateStr = new Date(beginArr[0],beginArr[1],beginArr[2]);
                    console.log('month--'+beginDateStr.getMonth());
                    console.log('date--'+beginDateStr.getDate());
                    console.log('date--'+beginArr[0]);
                    console.log('date--'+beginArr[1]);
                    console.log('date--'+beginArr[2]);
                    var oneYearEarlierDatetemp = beginDateStr.setFullYear(beginDateStr.getFullYear() + 1);
                    var  month =beginDateStr.getMonth();
                    var day=beginDateStr.getDate();
                    month=month+1;
                    if(month <10){
                        month = '0'+month;
                    }
                    if(beginDateStr.getDate() <10){
                        day = '0'+beginDateStr.getDate();
                    }
                    var oneYearEarlierDate = beginDateStr.getFullYear() +'-'+month +'-'+day; 
                    console.log('beginDateStr--'+beginDateStr);
                    console.log('beginDateRE304--'+beginDateRE304);
                    console.log('oneYearEarlierDate--'+oneYearEarlierDate);
                    var reportRequestFilterObj = component.get("v.reportRequestFilterObj");
                    reportRequestFilterObj.Field__c ='ToDate';
                    reportRequestFilterObj.Value__c =oneYearEarlierDate;
                    reportRequestFilterListToCreate.push(reportRequestFilterObj);
                    component.set("v.reportRequestFilterObj",{'sobjectType': 'Canned_Report_Request_Filter__c',
                                                              'Field__c': '',
                                                              'Value__c': '',
                                                              'Canned_Report_Request__c': ''
                                                             });
                }
            }
        } 
        if(!$A.util.isEmpty(endDate) && !$A.util.isEmpty(beginDate)){
            var beginArr = beginDate.split('-');
            var endArr = endDate.split('-');
            if(beginArr.length >1 && endArr.length >1 ){
                var beginDateStr = new Date(beginArr[0],beginArr[1],beginArr[2]);
                var endDateStr = new Date(endArr[0],endArr[1],endArr[2]);
                if(endDateStr < beginDateStr){
                    component.set("v.message",'error');
                    component.set("v.recordError",['Case End Date should be less than Begin Date.']);
                    validFlow =false;
                } 
            }
        }
        if(validFlow){
            var beginDate =component.get("v.beginDate");
            var endDate =component.get("v.endDate");
            if(selectedReport.DeveloperName == 'RE100'){
                if(!$A.util.isEmpty(beginDate) && !$A.util.isEmpty(endDate)){
                    beginDate = component.get("v.beginDate");
                    endDate =component.get("v.endDate");
                }  else if(!$A.util.isEmpty(component.get("v.beginDateDis")) && !$A.util.isEmpty(component.get("v.endDateDis"))){
                    beginDate = component.get("v.beginDateDis");
                    endDate =component.get("v.endDateDis");
                }
            } 
            // START: Added by Barkha for CCCAP-5445
            var beginDateUTC = this.getDateInUTC(new Date(beginDate));
            var endDateUTC = this.getDateInUTC(new Date(endDate));
            var oneMonthEndDate = new Date(beginDateUTC.getFullYear(), beginDateUTC.getMonth()+1, beginDateUTC.getDate());
            console.log('oneMonthEndDate: '+ oneMonthEndDate +' ==== endDateUTC: '+ endDateUTC);
            if(selectedReport.Report_Name__c == 'RE226 - Payments Utilization Report'){
                if(endDateUTC >= oneMonthEndDate){
                    component.set("v.successMsg", $A.get("$Label.c.Canned_Report_Request_Check_Tomorrow"));
                } else {
                    var msg = $A.get("$Label.c.Canned_Report_Request_Success_Msg");
                    component.set("v.successMsg", msg);
                }
            }
            // END: CCCAP-5445
            // START: Added by Diya for CCCAP-6052
            if(selectedReport.Report_Name__c == 'RE208 - Recovery Review Report'){
                if(endDateUTC >= oneMonthEndDate){
                    component.set("v.successMsg", $A.get("$Label.c.Canned_Report_Request_Check_Tomorrow"));
                } else {
                    var msg = $A.get("$Label.c.Canned_Report_Request_Success_Msg");
                    component.set("v.successMsg", msg);
                }
            }
            // END: CCCAP-6052
            // Start: Added by Rishav for CCCAP-6604
            /* *** CCCAP-12937 ***
            if(component.get("v.selectedReport").DeveloperName == 'RE229'){
                if(endDate == null){
                    endDate = helper.getCurrentSystemDate(0, 0, 0);
                    endDateUTC = this.getDateInUTC(new Date());
                }
                if(endDateUTC >= oneMonthEndDate){
                    component.set("v.successMsg", $A.get("$Label.c.Canned_Report_Request_Check_Tomorrow"));
                } else {
                    var msg = $A.get("$Label.c.Canned_Report_Request_Success_Msg");
                    component.set("v.successMsg", msg);
                }
            }*/
            // End: CCCAP-6604
            // Start: Added by Rishav for CCCAP-7088 & CCCAP-7662
            if(component.get("v.selectedReport").DeveloperName == 'RE230'){
                if(endDateUTC >= oneMonthEndDate){
                    component.set("v.successMsg", $A.get("$Label.c.Canned_Report_Request_Check_Tomorrow"));
                } else {
                    var msg = $A.get("$Label.c.Canned_Report_Request_Success_Msg");
                    component.set("v.successMsg", msg);
                }
            }
            // End: CCCAP-7088
            // Added by Rishav for CCCAP-6791
            if((component.get("v.selectedReport").DeveloperName == 'RE218')){
                var beginDateUTC = this.getDateInUTC(new Date(beginDateRE218));
                var endDateUTC = this.getDateInUTC(new Date(endDateRE218));
                var oneMonthEndDate = new Date(beginDateUTC.getFullYear(), beginDateUTC.getMonth()+1, beginDateUTC.getDate());
                if(endDateUTC >= oneMonthEndDate){
                    component.set("v.successMsg", $A.get("$Label.c.Canned_Report_Request_Check_Tomorrow"));
                } else {
                    var msg = $A.get("$Label.c.Canned_Report_Request_Success_Msg");
                    component.set("v.successMsg", msg);
                }
            }
            //  End: CCCAP-6791
            // Added by Shashank for CCCAP-12495
            if(component.get("v.selectedReport").DeveloperName == 'RE221'){
                let startMonth = component.get("v.selectedStartMonth");
                let endMonth = component.get("v.selectedEndMonth");
                let startYear = component.get("v.selectedStartYear");
                let endYear = component.get("v.selectedEndYear");
                if(startMonth === endMonth && startYear === endYear){
                    component.set("v.successMsg", $A.get("$Label.c.Canned_Report_Request_Success_Msg"));
                } else {
                    component.set("v.successMsg", $A.get("$Label.c.Canned_Report_Request_Check_Tomorrow"));                    
                }
            }
            var action = component.get('c.submitReportReq');
            action.setParams({
                'startDate':beginDate,'endDate':endDate,'filterRequestList':JSON.stringify(reportRequestFilterListToCreate),
                'reportRequestStr':JSON.stringify(reportRequestToCreate),'beginMonthStr':component.get('v.selectedStartMonth'),'beginYearStr':component.get('v.selectedStartYear'),
                'endMonthStr':component.get('v.selectedEndMonth'),'endYearStr':component.get('v.selectedEndYear'),"providerIdVal":component.get("v.providerIdVal"),
                'providerName':component.get('v.providerRecord.NAM_FACILITY__c')
            });
            action.setCallback(this, function(response) {
                component.set("v.isReportRequested",true);
                component.set("v.showSpinner", false);
                var state = response.getState();
                var res=response.getReturnValue();
                if (component.isValid() && state == 'SUCCESS') {
                    if(!$A.util.isEmpty(res)){
                        if(res.isSuccessful){
                            component.set("v.selectedCounty","");
                            component.set("v.initData",{});
                            component.set("v.providerIdVal","");
                            component.set("v.providerRecord",{});
                            component.set("v.selectedLookUpRecord",{});
                            component.set("v.isRequestSuccessFull",true);
                            component.set("v.isRefreshAfterSubmit",false);
                            component.set("v.isRefreshAfterSubmit",true);
                            if(!$A.util.isEmpty(component.find("multiSelectPicklist"))){
                                var childComponent = component.find("multiSelectPicklist");
                                childComponent.resetOptions();
                            }
                            //added by Nikita for CCCAP-12973
                            var filters = component.find('input-filters');
                            if(!$A.util.isEmpty(filters)){
                                if(!$A.util.isEmpty(filters.length)){
                                    for(var i=0; i<filters.length; i++ ){
                                        if(!$A.util.isEmpty(filters[i])){
                                            if(filters[i].get('v.fieldType') == 'REFERENCE'){
                                                filters[i].set('v.disabled',false);
                                            }
                                        }
                                    }
                                }
                            }
                            component.set("v.isCountyOptions",false);
                            component.set("v.isCountyOptions",true);
                            component.set("v.endDate",component.get("v.endDateCopy"));
                            component.set("v.beginDate",component.get("v.beginDateCopy"));
                            component.set("v.beginDateDis",component.get("v.beginDateCopy"));
                            component.set("v.endDateDis",component.get("v.endDateCopy"));
                            component.set("v.isFinishedFlow",true);
                            component.set("v.selectedEndYear",null);
                            component.set("v.selectedStartYear",null);
                            component.set("v.selectedStartMonth","");
                            component.set("v.selectedEndMonth","");
                            component.set("v.isFinishedFlow",false);
                            var selectedReportCopy =JSON.parse(JSON.stringify( component.get("v.selectedReportCopy")));
                            component.set("v.selectedReport",selectedReportCopy);
                            // reset county
                            var selectedCounty = component.get("v.selectedCounty");
                            var countyOptions = [];
                            var optionMap = component.get("v.countyOptions");
                            for (var p in optionMap) {
                                if( optionMap.hasOwnProperty(p) ) {
                                    countyOptions.push({'value':optionMap[p].value,'label':optionMap[p].label,'selected':selectedCounty==optionMap[p].value?true:false});
                                }
                            }
                            component.set("v.countyOptions",countyOptions);
                            component.set("v.isCountyOptions",false);
                            component.set("v.isCountyOptions",true);
                            // End
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Success!",
                                "type" : "success",
                                "mode": 'dismissible',
                                "duration":'8000',
                                "message": component.get("v.successMsg"),
                                "messageTemplate": component.get("v.successMsg")+' {0}.',
                                "messageTemplateData": [{
                                    "url": '/'+component.get("v.reportInboxURL"),
                                    "label": component.get("v.requestInboxMsg"),
                                }]
                            });
                            toastEvent.fire();
                            $A.get('e.force:refreshView').fire();
                        }else{
                            component.set("v.isRequestSuccessFull",false);
                            var toastEvent1 = $A.get("e.force:showToast");
                            toastEvent1.setParams({
                                "title": "Error!",
                                "message": component.get("v.errorMsg"),
                                "type" : "error"
                            });
                            toastEvent1.fire();
                        }
                    }
                } else {
                }
            });
            $A.enqueueAction(action);
        } else {
            component.set("v.showSpinner", false);
        }
    },
    
    checkValidity: function(component, event, helper,value) {
        var valid = true;
        var date = value;
        var dateStr = date;
        var dateArr;
        var dayStr;
        var monthStr;
        if(!$A.util.isEmpty(date)){
            dateArr = date.split("/");
            if(!$A.util.isEmpty(dateArr)){
                if(dateArr.length>1){
                    dayStr = dateArr[1];
                    monthStr = dateArr[0];
                }
            }
        }
        if(date.length <8){
            valid = false; 
        }
        date = helper.getDateInUTC(new Date(date));
        var month = parseInt(date.getMonth());
        var day   = parseInt(date.getDate());
        var year  = parseInt(date.getFullYear());
        if(isNaN(month) || isNaN(day) || isNaN(year)) {
            valid = false;
        }
        var yearSt = year.toString();
        if(yearSt.length >3){
            var dateYrArr = dateStr.split("-");
            if(!$A.util.isEmpty(dateYrArr)){
                if(dateYrArr.length>1){
                    var yearStr =dateYrArr[0];
                    dayStr = dateYrArr[2];
                    monthStr = dateYrArr[1];
                    var yearInt  =parseInt(yearStr);
                    if((!$A.util.isEmpty(yearInt)) && (yearInt< 1000 || yearInt >9999)){
                        valid = false;   
                    }
                }
            }
        }
        if((month < 0) || (month > 11)) {
            valid = false;
        } else if((dayStr < 1) || (dayStr > 31)) {
            valid = false;
        } else if(((monthStr == 6) || (monthStr == 4) || (monthStr == 9) || (monthStr == 11)) && (dayStr > 30)){ 
            valid = false;
        } else if((month == 1 || monthStr == 2) && (((year % 400) == 0) || ((year % 4) == 0)) && ((year % 100) != 0) && (dayStr > 29)) {
            valid = false;
        } else if((month == 1 || monthStr == 2) && ((year % 100) == 0) && (dayStr > 29)) {
            valid = false;
        } else if((month == 1 || monthStr == 2) && (dayStr > 28)){
            var isLeapYear = helper.leapYear(year);
            if(!isLeapYear){
                valid = false; 
            }
        } else if( (year <1000 || year >9999)) {
            valid = false;
        } else if(!$A.util.isEmpty(dateArr)) {
            if(dateArr.length>1){
                var yearStr =dateArr[2];
                var yearInt  =parseInt(yearStr);
                if((!$A.util.isEmpty(yearStr)) && yearStr.length <4){
                    valid = false; 
                }
                if((!$A.util.isEmpty(yearInt)) && yearInt< 1000){
                    valid = false;   
                }
            }
        }
        return valid;
    },
    
    checkforDateValidation: function(component, event, helper,value) {
        var beginDate = component.get("v.beginDate");
        var endDate = component.get("v.endDate");
        var benginDateValidaity =false;
        var endDateValidaity =false;
        var selectedReport = component.get("v.selectedReport");
        
        benginDateValidaity = this.beginDateValidation(component, event, helper);
        if(selectedReport.Hide_End_Date__c){
            endDateValidaity = true;
        } else {
            endDateValidaity = this.endDateValidation(component, event, helper);
        }
        if(!$A.util.isEmpty(selectedReport) && !$A.util.isEmpty(selectedReport.Start_Date_Label__c)){
            if(endDateValidaity && benginDateValidaity){
                var isValid;
                if(selectedReport.Hide_End_Date__c){
                    isValid = this.checkRE108CustomValidations(component, event, helper);
                } else {
                    if(selectedReport.isMonthYearFilter__c){
                        isValid = this.checkRE114DateValidations(component, event, helper);
                    } else {
                        if(component.get("v.selectedReport").DeveloperName == 'RE116'){
				isValid =  this.checkRE116CustomValidations(component, event, helper);
                        }else{
                           	isValid = this.checkCustomValidations(component, event, helper); 
                        } 
                    }
                    /* *** CCCAP-12937 ***
                    if(component.get("v.selectedReport").DeveloperName == 'RE229'){ // Added by Rishav for CCCAP-6604
                        isValid = this.checkRE229CustomValidations(component, event, helper);
                        if(isValid){
                            isValid = this.checkCustomValidations(component, event, helper);
                        }
                    }*/
                }
                return isValid;
            } else {
                return false;
            }
        } else {
            return true;
        }
        
    },
    
    beginDateValidation : function(component, event, helper) {
        var beginDate = component.get("v.beginDate");
        var validaity =false;
        var selectedReport = component.get("v.selectedReport");
        
        if(!$A.util.isEmpty(selectedReport) && !$A.util.isEmpty(selectedReport.Start_Date_Label__c)){
            if($A.util.isEmpty(beginDate) && selectedReport.Date_Required__c){
                component.find("beginInputDate").set("v.errors",[{"message":"Please enter a value."}]);
                component.set("v.message",'error');
                component.set("v.recordError",['You must choose a value from the required filter fields.']);
                validaity=false;
            } else if(!$A.util.isEmpty(beginDate)) {
                validaity = helper.checkValidity(component, event, helper,beginDate);
                if(validaity) {
                    component.find("beginInputDate").set("v.errors",[]);
                } else {
                    component.find("beginInputDate").set("v.errors",[{"message":"Please enter valid date format(MM/DD/YYYY)."}]);
                }
            } else {
                validaity=true;
            }
        } else {
            return true; 
        }
        return validaity;
    },
    
    endDateValidation : function(component, event, helper,value) {
        var endDate = component.get("v.endDate");
        var validaity = false;
        var selectedReport = component.get("v.selectedReport");
        
        if(!$A.util.isEmpty(selectedReport) && !$A.util.isEmpty(selectedReport.Start_Date_Label__c)) {
            if($A.util.isEmpty(endDate) && selectedReport.EndDateRequired__c) {
                component.find("endInputDate").set("v.errors",[{"message":"Please enter a value."}]);
                component.set("v.message",'error');
                component.set("v.recordError",['You must choose a value from the required filter fields.']);
                validaity =false;
            } else if(!$A.util.isEmpty(endDate)) {
                validaity = helper.checkValidity(component, event, helper,endDate);
                if(validaity) {
                    component.find("endInputDate").set("v.errors",[]);
                } else {
                    component.find("endInputDate").set("v.errors",[{"message":"Please enter valid date format(MM/DD/YYYY)."}]);
                }
            } else {
                validaity =true;
            }
        } else {
            return true;
        }
        return validaity;
    },
    
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    
    checkRE108CustomValidations: function(component, event, helper){
        // 4 years back; Past, current, future dates are valid.
        var selectedReport = component.get("v.selectedReport");
        var isValid= true;
        var currentDate = this.getDateInUTC(new Date());
        var cmpBeginDate = component.get('v.beginDate');
        var beginDate= this.getDateInUTC(new Date(component.get('v.beginDate')));
        var earlierBeginDate = new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate());
        
        // 4 years back; past
        if((!$A.util.isEmpty(cmpBeginDate)) && beginDate < earlierBeginDate) {	
            component.find("beginInputDate").set("v.errors",[{"message":"Begin Date cannot be earlier than 4 years."}]);
            isValid = false;
        } else {
            component.find("beginInputDate").set("v.errors",[]);
        }
        return isValid;
    },
    
    checkCustomValidations: function(component, event, helper){
        var selectedReport = component.get("v.selectedReport");
        var isValid= true;
        var currentDate = this.getDateInUTC(new Date());
        var cmpBeginDate = component.get('v.beginDate');
        var cmpEndDate = component.get('v.endDate');
        var beginDate= this.getDateInUTC(new Date(component.get('v.beginDate')));
        var endDate= this.getDateInUTC(new Date(component.get('v.endDate')));
        var earlierBeginDate =new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate());
        var earlierEndDate = new Date(beginDate.getFullYear(),beginDate.getMonth()+1,beginDate.getDate());
        var oneYearEarlierDate =new Date(beginDate.getFullYear()+1,beginDate.getMonth(),beginDate.getDate());
        var diffTime = Math.abs(endDate - beginDate);
        var diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if(beginDate > currentDate  && (!selectedReport.FutureBeginDate__c)) {	
            component.find("beginInputDate").set("v.errors",[{"message":"Begin Date should be less than or equals to today."}]);
            isValid = false;
        } else if(beginDate > currentDate && beginDate.getMonth() != currentDate.getMonth() && (selectedReport.FutureBeginDate__c) && (selectedReport.DeveloperName == 'RE114')){
            component.find("beginInputDate").set("v.errors",[{"message":"Begin Date should be less than or equals to current month."}]);
            isValid = false;
        } else if((!$A.util.isEmpty(cmpBeginDate)) && beginDate < earlierBeginDate && ((!selectedReport.isOneYearReport__c) || selectedReport.DeveloperName == 'RE226')){
            component.find("beginInputDate").set("v.errors",[{"message":"Begin Date cannot be earlier than 4 years."}]);
            isValid = false;
        } else {
            component.find("beginInputDate").set("v.errors",[]);
        }
        if(endDate > currentDate && (!selectedReport.FutureEndDate__c)) {
            component.find("endInputDate").set("v.errors",[{"message":"End Date should be less than or equals to today."}]);
            isValid = false;
        } else if(!$A.util.isEmpty(cmpEndDate)  && endDate < beginDate) {
            component.find("endInputDate").set("v.errors",[{"message":"End Date cannot be less than begin date."}]);
            isValid = false;
        } else if((endDate > earlierEndDate || diffDays>30) && selectedReport.oneMonthDiffCheck__c){ 
            component.find("endInputDate").set("v.errors",[{"message":"End Date cannot be more than 1 Month after begin date."}]);
            isValid = false;
        } else if(endDate >= oneYearEarlierDate && selectedReport.isOneYearReport__c){ 
            component.find("endInputDate").set("v.errors",[{"message":"End Date cannot be more than 1 Year after begin date."}]);
            isValid = false;
        } else if( (!$A.util.isEmpty(cmpEndDate)) && endDate< earlierBeginDate && ((!selectedReport.isOneYearReport__c) || selectedReport.DeveloperName == 'RE226')){
            component.find("endInputDate").set("v.errors",[{"message":"End Date cannot be earlier than 4 years."}]);
            isValid = false;
        } else {
            component.find("endInputDate").set("v.errors",[]);             
        }
        if(selectedReport.DeveloperName == 'RE110'){
            var validaity= this.validateBeginRE110DateHlp(component, event, isValid);
            if(!validaity){
                isValid= validaity;
            }
        }
        //added by Shashank on CCCAP-12974
        if(component.get('v.selectedReport').DeveloperName == 'RE206'){
            let april_1_25 = new Date(2025, 3,1 );
            if((!$A.util.isEmpty(component.get('v.beginDate'))) && this.getDateInUTC(new Date(component.get('v.beginDate'))) < april_1_25){
                component.find("beginInputDate").set("v.errors",[{"message":"Claim Begin Date should be after April 2025."}]);
                isValid = false;
            }
        }
        return isValid;
    },
    
    checkforMonthYearValidation : function(component, event, helper){
        var isValid= true;
        var startMonth = component.get("v.selectedStartMonth");
        var endMonth = component.get("v.selectedEndMonth");
        var startYear = component.get("v.selectedStartYear");
        var endYear = component.get("v.selectedEndYear");
        var currentDate = this.getDateInUTC(new Date());
        var reportName = component.get("v.selectedReport").DeveloperName;
        var fourYearEarlierDate =new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate());
        var startDate ;//= new Date(startYear, startMonth,1 );
        var endDate;// = new Date(endYear, endMonth,1 );
        var startYearCmp = component.find("startYear");
        var endYearCmp = component.find("endYear");
        startYearCmp.setCustomValidity("");
        endYearCmp.setCustomValidity("");
        if((!$A.util.isEmpty(startMonth)) && ($A.util.isEmpty(startYear))) {            
            startYearCmp.showHelpMessageIfInvalid();
            isValid = false;
        } else if((!$A.util.isEmpty(startYear)) && ($A.util.isEmpty(startMonth))){
            component.find('startMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else {
            if((!$A.util.isEmpty(startYear)) && (!$A.util.isEmpty(startMonth))){
                startDate = new Date(startYear, (startMonth - 1),1 );
            }
        }
        if((!$A.util.isEmpty(endMonth)) && ($A.util.isEmpty(endYear))) {
            endYearCmp.showHelpMessageIfInvalid();
            isValid = false;
        } else if((!$A.util.isEmpty(endYear)) && ($A.util.isEmpty(endMonth))){
            component.find('endMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else {
            if((!$A.util.isEmpty(endYear)) && (!$A.util.isEmpty(endMonth))){
                endDate = new Date(endYear, (endMonth - 1),1 );
            }
        }
        //Added for CCCAP-12495 by Shashank 
        if(component.get("v.selectedReport").DeveloperName == 'RE221'){
            if(startDate && endDate){
                let oneYearEarlierDate = new Date((+startYear+1),(startMonth-1),1);
                if(endDate > oneYearEarlierDate){
                    endYearCmp.setCustomValidity("End Date cannot be more than 1 Year after begin date");
                    isValid = false;
                }                
            }else if($A.util.isEmpty(startDate)){
                startYearCmp.setCustomValidity("Case Parent Fee Begin Date is required.");
                isValid = false;
            }else{
                isValid = true;
            }
            //CCCAP-13651
            let cnty = component.get("v.selectedCounty");
            if($A.util.isEmpty(cnty) && $A.util.isEmpty(startDate)){
                component.set("v.message",'error');
                component.set("v.recordError",["You must choose a value from the required filter fields."]);
                isValid = false;
            }

            //end CCCAP-13651
        }
        if((!$A.util.isEmpty(startDate)) && startDate < fourYearEarlierDate) {
            startYearCmp.setCustomValidity("Begin Date cannot be earlier than 4 years.");
            isValid = false;
        } 
        if((!$A.util.isEmpty(endDate)) && endDate < fourYearEarlierDate) {
            endYearCmp.setCustomValidity("End Date cannot be earlier than 4 years.");
            isValid = false;
        } else if((!$A.util.isEmpty(endYear)) && ( !$A.util.isEmpty(endMonth)) && (!$A.util.isEmpty(startDate)) && (!$A.util.isEmpty(endDate)) && startDate > endDate){
            endYearCmp.setCustomValidity("End Date cannot be less than the begin date.");
            isValid = false;
        }
        startYearCmp.reportValidity();
        endYearCmp.reportValidity();
        return isValid;
    },
    // added RE116 for CCCAP-11681 by Raina
    checkRE116CustomValidations : function(component, event, helper){
        var selectedReport = component.get("v.selectedReport");
        var isValid= true;
        var currentDate = this.getDateInUTC(new Date());
        var beginDate= this.getDateInUTC(new Date(component.get('v.beginDate')));
        var endDate= this.getDateInUTC(new Date(component.get('v.endDate')));
       	var FourYearDate =new Date(beginDate.getFullYear()+4,beginDate.getMonth(),beginDate.getDate());
        
        if(beginDate > currentDate  && (!selectedReport.FutureBeginDate__c)) {	
            component.find("beginInputDate").set("v.errors",[{"message":"Begin Date should be less than or equals to today."}]);
            isValid = false;
        }else{
		component.find("beginInputDate").set("v.errors",[]);
	}
		
	if(endDate > currentDate && (!selectedReport.FutureEndDate__c)) {
            component.find("endInputDate").set("v.errors",[{"message":"End Date should be less than or equals to today."}]);
            isValid = false;
        }else if(endDate >= FourYearDate){
		component.find("endInputDate").set("v.errors",[{"message":"End Date cannot be greater than 4 years from begin date."}]);
            	isValid = false;
	}else if(beginDate > endDate){
		component.find("endInputDate").set("v.errors",[{"message":"End Date cannot be less than begin date."}]);
            	isValid = false;
	}else{
            component.find("endInputDate").set("v.errors",[]);             
        }
	return isValid;
    },
    // For CCCAP-13192
    checkRE117CustomValidations:function(component, event, helper){
        var retValue = true;
        var dataValue = component.get("v.initData");
        var reoprtRequestFilterList = component.get("v.reoprtRequestFilterList");
        var caseStatus = [];
        var caseMode = [] ;
        var startDate='';
        var endDate='';
        var twoYearsDate;
        var startDateValue;
        var errorList = [];
        component.set("v.message",null);
        for(var j in reoprtRequestFilterList){
            var reportRequestFilterObj = component.get("v.reportRequestFilterObj");
            reportRequestFilterObj.Field__c =reoprtRequestFilterList[j].Field_Api_Name__c;
            if(!$A.util.isEmpty(dataValue) && !$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")])){
                if(!$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c])){
                    var filterVal = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                    if(reportRequestFilterObj.Field__c == 'Case_Status__c') {
                        caseStatus = filterVal.split(';'); // For multiselect as part of CCCAP-13743
                    } else if(reportRequestFilterObj.Field__c == 'Case_Mode__c') {
                        caseMode = filterVal.split(';'); // For multiselect as part of CCCAP-13743
                    }else if(reportRequestFilterObj.Field__c == 'FromDate') {
                        startDate = filterVal;
                        startDateValue=new Date(startDate);
                        twoYearsDate= new Date(startDateValue.getFullYear()+2,startDateValue.getMonth(),startDateValue.getDate());
                    }else if(reportRequestFilterObj.Field__c == 'ToDate') {
                        endDate = filterVal;
                    }
                }
            }
        }/*
         	if ((caseStatus === "REO" && caseMode === "INT") ||(caseStatus === "OPN" && caseMode === "INT") || (caseStatus === "PEN" && caseMode === "RED")){
                errorList.push('Please select valid case status mode combination');
            retValue = false;
        }*/
        // }
        //  For multiselect as part of CCCAP-13743
        var isInvalid = caseStatus.some(function(status) {
            return caseMode.some(function(mode) {
                return (
                    (status === "REO" && mode === "INT") ||
                    (status === "OPN" && mode === "INT") ||
                    (status === "PEN" && mode === "RED")
                );
            });
        });
        
        if (isInvalid) {
            errorList.push('Please select valid case status mode combination');
            retValue = false;
        }
        // end CCCAP-13743
        if($A.util.isEmpty(startDate)||$A.util.isEmpty(endDate)){
            errorList.push('You must choose a value from the required filter fields.');
            retValue=false;
        }
        if(new Date(endDate)>twoYearsDate){
           component.find('ApplnRecEndDateErr').set('v.message',"Report cannot be requested more than 2 years of data");
           retValue=false; 
        }else{
           component.find('ApplnRecEndDateErr').set('v.message',"");
        }

        if(retValue == false) {
            component.set("v.message",'error');
            component.set("v.recordError",errorList);
            return false;
        } else {
            return true;
        }
    },
    
    // added RE219/RE222 for CCCAP-11787/CCCAP-12512 by Shashank
    checkReviewReportCustomValidations : function(component, event, helper){
        var isValid= true;
        var startMonth = component.get("v.selectedStartMonth");
        var endMonth = component.get("v.selectedEndMonth");
        var startYear = component.get("v.selectedStartYear");
        var endYear = component.get("v.selectedEndYear");
        var currentDate = this.getDateInUTC(new Date());
        var startDate;
        var endDate;
        var startYearCmp = component.find("startYear");
        var endYearCmp = component.find("endYear");
        
        if(($A.util.isEmpty(startMonth)) && ($A.util.isEmpty(startYear))) {
            startYearCmp.showHelpMessageIfInvalid();
            component.find('startMonth').showHelpMessageIfInvalid();
            isValid = false;
        }else if($A.util.isEmpty(startYear)) {
            startYearCmp.showHelpMessageIfInvalid();
            isValid = false;
        } else if($A.util.isEmpty(startMonth)){
            component.find('startMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else {
            if((!$A.util.isEmpty(startYear)) && (!$A.util.isEmpty(startMonth))){
                startDate = new Date(startYear, (startMonth - 1),1 );
            }
        }
        if(($A.util.isEmpty(endMonth)) && ($A.util.isEmpty(endYear))) {
            endYearCmp.showHelpMessageIfInvalid();
            component.find('endMonth').showHelpMessageIfInvalid();
            isValid = false;
        }else if($A.util.isEmpty(endYear)) {
            endYearCmp.showHelpMessageIfInvalid();
            isValid = false;
        } else if($A.util.isEmpty(endMonth)){
            component.find('endMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else {
            if((!$A.util.isEmpty(endYear)) && (!$A.util.isEmpty(endMonth))){
                endDate = new Date(endYear, (endMonth - 1),1 );
            }
        }
        var oct_2022 = new Date(2022,9,1);
        var getCurrentMonth_1 =new Date(currentDate.getFullYear(),currentDate.getMonth(),1);
        // validations on Sample Begin Month/Year for RE219 for CCCAP-11787/CCCAP-12512
        if(($A.util.isEmpty(startDate))){
            component.find('startYearMsg').set('v.message',"");
            isValid = false;
        }else if((!$A.util.isEmpty(startDate)) && startDate < oct_2022){
            component.find('startYearMsg').set('v.message',"Begin date cannot be prior to October 2022.");
            isValid = false;
        }else {
            component.find('startYearMsg').set('v.message',"");
        }
        // validations on Sample End Month/Year for RE219/RE222 for CCCAP-11787/CCCAP-12512
        if(($A.util.isEmpty(endDate))){
            component.find('endYearMsg').set('v.message',"");
            isValid = false;
        }else if((!$A.util.isEmpty(endDate)) && endDate >= getCurrentMonth_1) {
            var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "June", "July", "Aug", "Sep", "Oct", "Nov", "Dec"];
            var month = monthNames[endDate.getMonth()];
            component.find('endYearMsg').set('v.message',"End date cannot be requested for "+month+"/"+endDate.getFullYear());
            isValid = false;
        }else if((!$A.util.isEmpty(endYear)) && ( !$A.util.isEmpty(endMonth)) && (!$A.util.isEmpty(startDate)) && (!$A.util.isEmpty(endDate)) && startDate > endDate){
            component.find('endYearMsg').set('v.message',"End Date cannot be less than begin date.");
            isValid = false;
        }else {
            component.find('endYearMsg').set('v.message',"");
        }
        return isValid;
    },
    checkRE114DateValidations: function(component){
        var selectedReport = component.get("v.selectedReport");
        var isValid= true;
        var currentDate = this.getDateInUTC(new Date());
        var cmpBeginDate = component.get('v.beginDate');
        var cmpEndDate = component.get('v.endDate');
        var beginDate= this.getDateInUTC(new Date(component.get('v.beginDate')));
        var endDate= this.getDateInUTC(new Date(component.get('v.endDate')));
        var earlierBeginDate =new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate());
        var earlierEndDate = new Date(beginDate.getFullYear(),beginDate.getMonth()+1,beginDate.getDate());
        var nextMonth = new Date(currentDate.getFullYear(),currentDate.getMonth()+1,1);
        
        if((!$A.util.isEmpty(cmpBeginDate)) && beginDate >= nextMonth) {
            component.find("beginInputDate").set("v.errors",[{"message":"Begin Date should be less than equals to current month."}]);
            isValid = false;
        } else if((!$A.util.isEmpty(cmpBeginDate)) && beginDate< earlierBeginDate) {
            component.find("beginInputDate").set("v.errors",[{"message":"Begin Date cannot be earlier than 4 years."}]);
            isValid = false;
        } else {
            component.find("beginInputDate").set("v.errors",[]);
        }
        return isValid;
    },
    
    checkforMonthYearValidationForRE114 : function(component, event, helper){
        var isValid= true;
        var startMonth = component.get("v.selectedStartMonth");
        var endMonth = component.get("v.selectedEndMonth");
        var startYear = component.get("v.selectedStartYear");
        var endYear = component.get("v.selectedEndYear");
        var currentDate = this.getDateInUTC(new Date());
        var fourYearEarlierDate =new Date(currentDate.getFullYear()-4,currentDate.getMonth(),currentDate.getDate()) ;
        var startDate ;//= new Date(startYear, startMonth,1 );
        var endDate;// = new Date(endYear, endMonth,1 );
        var nextMonth = new Date(currentDate.getFullYear(),currentDate.getMonth()+1,1) ;
        var startYearCmp = component.find("startYear");
        var endYearCmp = component.find("endYear");
        
        if(($A.util.isEmpty(startMonth)) || ($A.util.isEmpty(startYear))) {
            component.find('startMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else if((!$A.util.isEmpty(startMonth)) && ($A.util.isEmpty(startYear))) {
            component.find('startYear').showHelpMessageIfInvalid();
            isValid = false;
        } else if((!$A.util.isEmpty(startYear)) && ($A.util.isEmpty(startMonth)) && (startYear != null)) {
            component.find('startMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else {
            if((!$A.util.isEmpty(startYear)) && (!$A.util.isEmpty(startMonth))) {
                startDate = new Date(startYear, (startMonth - 1),1 );
            }
        }
        if((!$A.util.isEmpty(endMonth)) && ($A.util.isEmpty(endYear))) {
            component.find("endYear").showHelpMessageIfInvalid();
            isValid = false;
        } else if((!$A.util.isEmpty(endYear)) && ($A.util.isEmpty(endMonth))) {
            component.find('endMonth').showHelpMessageIfInvalid();
            isValid = false;
        } else {
            if((!$A.util.isEmpty(endYear)) && (!$A.util.isEmpty(endMonth))) {
                endDate = new Date(endYear, (endMonth - 1),1 );
            }
        }
        if((!$A.util.isEmpty(startDate)) && startDate < fourYearEarlierDate) {
            startYearCmp.setCustomValidity("Begin Date cannot be earlier than 4 years.");
            isValid = false;
        } else if((!$A.util.isEmpty(startDate)) && startDate >= nextMonth) {	
            startYearCmp.setCustomValidity("Begin Date should be less than equals to current month.");         
            isValid = false;
        } else {
            startYearCmp.setCustomValidity("");
        }
        if((!$A.util.isEmpty(endDate)) && endDate < fourYearEarlierDate) {
            endYearCmp.setCustomValidity("End Date cannot be earlier than 4 years.");
            isValid = false;
        } else if((!$A.util.isEmpty(endYear)) && ( !$A.util.isEmpty(endMonth)) && (!$A.util.isEmpty(startDate)) && (!$A.util.isEmpty(endDate)) && startDate > endDate) {
            endYearCmp.setCustomValidity("End Date cannot be less than begin date.");
            isValid = false;
        } else {
            endYearCmp.setCustomValidity("");
        }
        startYearCmp.reportValidity();
        endYearCmp.reportValidity();
        return isValid;
    },
    
    validateRE803Filters : function(component, event){
        console.log('Inside RE803 Validator');
        var retValue = true;
        var dataValue = component.get("v.initData");
        var reoprtRequestFilterList = component.get("v.reoprtRequestFilterList");
        var fromDate = null;
        var toDate = null ;
        var caseId = null;
        var errorList = [];
        
        component.set("v.message",null);
        for(var j in reoprtRequestFilterList){
            var reportRequestFilterObj = component.get("v.reportRequestFilterObj");
            reportRequestFilterObj.Field__c =reoprtRequestFilterList[j].Field_Api_Name__c;
            console.log('FIELD NAME-->'  + reportRequestFilterObj.Field__c);
            if(!$A.util.isEmpty(dataValue) && !$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")])){
                if(!$A.util.isEmpty(dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c])){
                    var filterVal = dataValue[component.get("v.requestFilterObjectName")][0][reoprtRequestFilterList[j].Field_Api_Name__c];
                    if(reportRequestFilterObj.Field__c == 'FromDate') {
                        fromDate = new Date(filterVal);
                    } else if(reportRequestFilterObj.Field__c == 'ToDate') {
                        toDate = new Date(filterVal);
                    } else if(reportRequestFilterObj.Field__c == 'CaseId') {
                        caseId = filterVal;
                    }
                }
            }
        }
        console.log('DATECOMPARISIONL::' + (fromDate < toDate) );
        if(fromDate == null || fromDate == ""){
            errorList.push('Provide Start Date.');
            retValue = false;
        }
        if(toDate == null || toDate == ""){
            errorList.push('Provide End Date.');
            retValue = false;
        }
        if(toDate != null && fromDate != null && (fromDate > toDate)){
            errorList.push('Case End Date should be less than Begin Date.');
            retValue = false;
        }
        if(caseId == null && (component.get("v.providerIdVal") == null || component.get("v.providerIdVal") == undefined ||component.get("v.providerIdVal") == '')){
            errorList.push('Must provide Either Case or Provider');
            retValue = false;
        }
        if(retValue == false) {
            console.log('INSIDE ERROR');
            component.set("v.message",'error');
            component.set("v.recordError",errorList);
            return false;
        } else {
            console.log('return TRUE');
            return true;
        }
    },
    
    validateBeginRE110DateHlp : function(component, event,valid){
        var beginDate= component.get("v.beginDate");
        var endDate= component.get("v.endDate");
        var beginDateDis= component.get("v.beginDateDis");
        var endDateDis= component.get("v.endDateDis");
        var validaity = true;
        var beginDateValid = true;
        var endDateValid = true;
        if(!$A.util.isEmpty(beginDateDis)) {
            beginDateValid  = this.checkValidity(component, event, this,beginDateDis);
            if(beginDateValid) {
                component.find("beginInputDateDisqualification").set("v.errors",[]);                    
            } else {
                component.find("beginInputDateDisqualification").set("v.errors",[{"message":"Please enter valid date format(MM/DD/YYYY)."}]);
            }
        }
        if(!$A.util.isEmpty(endDateDis)) {
            endDateValid = this.checkValidity(component, event, this,endDateDis);
            if(endDateValid) {
                component.find("endInputDateDisqualification").set("v.errors",[]);                    
            } else {
                component.find("endInputDateDisqualification").set("v.errors",[{"message":"Please enter valid date format(MM/DD/YYYY)."}]);
            }
        }
        if(beginDateValid && endDateValid) {
            validaity =true;
        } else {
            validaity =false;
        }
        if(validaity) {
            if(!$A.util.isEmpty(beginDate) && $A.util.isEmpty(endDate)) {
                component.set("v.message",'error');
                validaity = this.disQualDateCheck(component,beginDateDis,endDateDis,validaity);
                if(validaity) {
                    component.find("endInputDate").set("v.errors",[{"message":"Please enter a value."}]);
                    component.set("v.recordError",['You must choose a value from the required filter fields.']);
                }
                validaity = false;
            } else if($A.util.isEmpty(beginDate) && !$A.util.isEmpty(endDate)) {
                component.set("v.message",'error');
                validaity = this.disQualDateCheck(component,beginDateDis,endDateDis,validaity);
                if(validaity) {
                    component.find("beginInputDate").set("v.errors",[{"message":"Please enter a value."}]);
                    component.set("v.recordError",['You must choose a value from the required filter fields.']);
                }
                validaity = false;
            } else if(!$A.util.isEmpty(beginDate) && !$A.util.isEmpty(endDate)) {
                validaity = this.disQualDateCheck(component,beginDateDis,endDateDis,validaity);
                if(validaity) {
                    validaity= this.validateOneYearDiffDates(component, beginDate,endDate);
                }
            } else if($A.util.isEmpty(beginDate) && $A.util.isEmpty(endDate)) {
                if(!$A.util.isEmpty(beginDateDis) && $A.util.isEmpty(endDateDis)) {
                    component.find("endInputDateDisqualification").set("v.errors",[{"message":"Please enter a value."}]);
                    component.set("v.message",'error');
                    component.set("v.recordError",['You must choose a value from the required filter fields.']);
                    validaity = false;
                } else if($A.util.isEmpty(beginDateDis) && !$A.util.isEmpty(endDateDis)) {
                    component.find("beginInputDateDisqualification").set("v.errors",[{"message":"Please enter a value."}]);
                    component.set("v.message",'error');
                    component.set("v.recordError",['You must choose a value from the required filter fields.']);
                    validaity = false;
                } else if(!$A.util.isEmpty(beginDateDis) && !$A.util.isEmpty(endDateDis)) {
                    validaity = this.validateOneYearDiffDates(component, beginDateDis, endDateDis);
                } else if($A.util.isEmpty(beginDateDis) && $A.util.isEmpty(endDateDis)) {
                    console.log('show error message for dis');
                    component.set("v.message",'error');
                    component.set("v.recordError",['You must choose a value']);
                    validaity = false;
                } else {
                    if(valid) {
                        component.find("beginInputDate").set("v.errors",[]);
                        component.find("endInputDate").set("v.errors",[]);
                    }
                    component.find("endInputDateDisqualification").set("v.errors",[]);
                    component.find("beginInputDateDisqualification").set("v.errors",[]);
                }
            } else {
                if(valid) {
                    component.find("beginInputDate").set("v.errors",[]);
                    component.find("endInputDate").set("v.errors",[]);
                }
                component.find("endInputDateDisqualification").set("v.errors",[]);
                component.find("beginInputDateDisqualification").set("v.errors",[]);
            }
            if(validaity) {
                if(valid) {
                    component.find("beginInputDate").set("v.errors",[]);
                    component.find("endInputDate").set("v.errors",[]);
                }
                component.find("endInputDateDisqualification").set("v.errors",[]);
                component.find("beginInputDateDisqualification").set("v.errors",[]);
            }  
        }
        return validaity;
    },
    
    validateOneYearDiffDates : function(component, startDate, endDate){
        var beginArr = startDate.split('-');
        var endArr = endDate.split('-');
        var validFlow = true;
        if(beginArr.length >1 && endArr.length >1) {
            var beginDateStr = new Date(beginArr[0],beginArr[1],beginArr[2]);
            var endDateStr = new Date(endArr[0],endArr[1],endArr[2]);
            var oneYearEarlierDate =new Date(beginDateStr.getFullYear()+1,beginDateStr.getMonth(),beginDateStr.getDate()) ;
            console.log('oneYearEarlierDate-valdation--'+oneYearEarlierDate);
            if(endDateStr > oneYearEarlierDate) {
                component.set("v.message",'error');
                component.set("v.recordError",['End Date cannot be more than 1 Year after begin date']);
                validFlow =false;
            } else if(endDateStr<beginDateStr) {
                component.set("v.message",'error');
                component.set("v.recordError",['End Date cannot be less than begin date']);
                validFlow = false;
            }
        }
        return validFlow;
    },
    
    disQualDateCheck : function(component, beginDateDis,endDateDis,validaity){
        if(!$A.util.isEmpty(beginDateDis) && $A.util.isEmpty(endDateDis)) {
            //  component.find("endInputDateDisqualification").set("v.errors",[{"message":"Please enter a value."}]);
            component.set("v.message",'error');
            component.set("v.recordError",['Must provide either Allegation Received Begin and End Dates or Disqualification Begin and End Dates.']);
            validaity =false;
        } else if($A.util.isEmpty(beginDateDis) && !$A.util.isEmpty(endDateDis)) {
            // component.find("beginInputDateDisqualification").set("v.errors",[{"message":"Please enter a value."}]);
            component.set("v.message",'error');
            component.set("v.recordError",['Must provide either Allegation Received Begin and End Dates or Disqualification Begin and End Dates']);
            validaity = false;
        } else if(!$A.util.isEmpty(beginDateDis) && !$A.util.isEmpty(endDateDis)) {
            component.set("v.message",'error');
            component.set("v.recordError",['Must provide either Allegation Received Begin and End Dates or Disqualification Begin and End Dates']);
            validaity = false;
        }
        return validaity;
    },

    // Added by Rishav for CCCAP-6604
    /* *** CCCAP-12937 ***
    checkRE229CustomValidations: function(component){
        var isValid = true;
        if(!$A.util.isEmpty(component.get('v.beginDate'))){
            var selectedBeginDate = this.getDateInUTC(new Date(component.get('v.beginDate')));
            var defaultBeginDate = this.getDateInUTC(new Date($A.get("$Label.c.RE229_Default_beginDate")));
            var formattedDefaultBeginDate = (defaultBeginDate.getMonth()+1) + '/' + defaultBeginDate.getDate() + '/' + defaultBeginDate.getFullYear();
            if(selectedBeginDate < defaultBeginDate) {
                var errorText = "The begin date must be on or after the effective date of change " + formattedDefaultBeginDate + ".";
                component.find("beginInputDate").set("v.errors",[{"message":errorText}]);
                isValid = false;
            } else {
                component.find("beginInputDate").set("v.errors",[]);
            }
        }
        return isValid;
    }*/
})