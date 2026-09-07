({  
    checkCustomValidations : function(cmp,helper){
        var isValid = this.verifyBeginDate(cmp,helper)&&
            this.verifyDeterminationDate(cmp,helper);
        return isValid;        
    },
    getInitData : function(cmp){
        var isReadOnly = cmp.get("v.isReadOnly");
        if(isReadOnly){
            cmp.find('forceRecordCmpDis').reloadRecord(true);
        }
        if(!cmp.get("v.isReadOnly")){	
            if(!$A.util.isEmpty(cmp.get("v.recordId"))){
                var action = cmp.get("c.getDisqualificationInitData");
                action.setParams({  recordId : cmp.get("v.recordId")});
                // Add callback behavior for when response is received
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var ipvRec = cmp.get("v.ipvRec");
                        if(!ipvRec.Disqualification_Created__c){
                            ipvRec.Number_of_occurrences__c =response.getReturnValue().objectData.occurences.toString();
                            cmp.set("v.occurences",response.getReturnValue().objectData.occurences.toString());
                            cmp.set("v.occurencesEdited",response.getReturnValue().objectData.occurences.toString());    
                            cmp.set("v.ipvRec",ipvRec);
                        }else{
                            cmp.set("v.occurences", ipvRec.Number_of_occurrences__c);
                            cmp.set("v.occurencesEdited", ipvRec.Number_of_occurrences__c);
                            cmp.set("v.endDate",ipvRec.Disqualification_End_Date__c);
                            cmp.set("v.beginDate",ipvRec.Disqualification_Begin_Date__c);    
                        }
                        cmp.set("v.lastOccurenceEndDate", response.getReturnValue().objectData.lastOccurenceEndDate);
                        cmp.set("v.isInitialised", true);
                        var lstInvestigatoryFindings = response.getReturnValue().objectData.lstInvestigatoryFindings;
                        cmp.set("v.lstInvestigatoryFindings",lstInvestigatoryFindings);
                        cmp.set("v.mapInvInfoValuetoLabel",response.getReturnValue().objectData.mapInvInfoValuetoLabel);
                        cmp.set("v.mapOccurredValuetoLabel",response.getReturnValue().objectData.mapOccurredValuetoLabel);
                        cmp.set("v.mapInvInfoLabelToValue",response.getReturnValue().objectData.mapInvInfoLabelToValue);
                        cmp.set("v.mapOccurredLabelToValue",response.getReturnValue().objectData.mapOccurredLabelToValue);
                    }
                    else{
                        cmp.set("v.recordError", response.getReturnValue().message);
                    }
                });
                // Send action off to be executed
                $A.enqueueAction(action);
            }
        }
        else{
            if(!$A.util.isEmpty(cmp.get("v.recordId"))){
                var action = cmp.get("c.getDisqualificationInitData");
                action.setParams({  recordId : cmp.get("v.recordId")});
                // Add callback behavior for when response is received
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        cmp.set("v.lstInvestigatoryFindings",response.getReturnValue().objectData.lstInvestigatoryFindings);
                    }
                    else{
                        cmp.set("v.recordError", response.getReturnValue().message);
                    }
                });
                // Send action off to be executed
                $A.enqueueAction(action);
            }
        }
        this.setColumnHeaders(cmp);
    },
    handleSaveRecord : function(cmp,helper) {
        var recordId = cmp.get("v.recordId");
        var ipvRec = cmp.get("v.ipvRec");
        ipvRec.Disqualification_End_Date__c = cmp.get("v.endDate");
        ipvRec.Disqualification_Begin_Date__c = cmp.get("v.beginDate");
        ipvRec.Disqualification_Created__c= true;
        ipvRec.Number_of_occurrences__c = cmp.get("v.occurencesEdited");
        cmp.set("v.ipvRec", ipvRec);
        cmp.set("v.showSpinner", true);
        cmp.find("forceRecordCmpDis").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "success","Success","Record Saved Successfully");
                helper.redirectToRecord(recordId);
            } else if (saveResult.state === "INCOMPLETE") {
                console.log("User is offline, device doesn't support drafts.");
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "error","Error","User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                console.log('Problem saving record, error: ' +
                            JSON.stringify(saveResult.error));
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "error","Error",'Problem saving record, error: ' +JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "error","Error",'Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },
    verifyBeginDate : function(cmp,helper){
        if(!cmp.get("v.isReadOnly") && cmp.get("v.isInitialised")){
            var isValid = true;   
            var beginDate = cmp.get("v.beginDate");
            var ipvRec = cmp.get("v.ipvRec");
            if (beginDate!=undefined && beginDate!=null && beginDate!=''
                &&( ipvRec.Investigation_Status__c !='4' || !ipvRec.Number_of_CCCAP_Reviews__c>0)){
                cmp.find("IPV_Information__c-Disqualification_Begin_Date__c").set("v.message",'Disqualification Begin Date cannot be created before Investigation Status is Completed');
                isValid = false;
            }
            else{
                cmp.find("IPV_Information__c-Disqualification_Begin_Date__c").set("v.message",'');
                isValid = true;
            }
            if(isValid){
                var lastOccurenceEndDate = cmp.get("v.lastOccurenceEndDate");
                if(lastOccurenceEndDate!=null && lastOccurenceEndDate!='' && lastOccurenceEndDate!=undefined && beginDate <= lastOccurenceEndDate ){
                    cmp.find("IPV_Information__c-Disqualification_Begin_Date__c").set("v.message",'Cannot Be Prior to Last Occurence End Date');
                    isValid = false;  
                }else{
                    cmp.find("IPV_Information__c-Disqualification_Begin_Date__c").set("v.message",'');
                    isValid = true; 
                }
            }
            if(isValid && helper!=undefined){
                this.calculateEndDate(cmp,helper);
            }
            return isValid;
        }
    },
    calculateEndDate : function(cmp,helper){
        var ipvRec = cmp.get("v.ipvRec");
        var endDate = cmp.get("v.endDate");
        var beginDate = cmp.get("v.beginDate");
        var occurence = cmp.get("v.occurencesEdited")
        if (beginDate !=null && beginDate !='' && beginDate !=undefined
            && occurence !=null
            && occurence !=''
            && occurence !=undefined){
            if(occurence =='1'){
                endDate = helper.handleDate(helper.getDateInUTC(beginDate),0,0,1);
            }else if(occurence =='2'){
                endDate = helper.handleDate(helper.getDateInUTC(beginDate),0,0,2);
            }else {
                endDate = null;
            }
            cmp.set("v.endDate", endDate);
        }
    },
    verifyDeterminationDate : function(cmp,evt,hlp){
        var isValid = true;
        if(!cmp.get("v.isReadOnly") && cmp.get("v.isInitialised")){
            var ipvRec = cmp.get("v.ipvRec");
            if (ipvRec.Disqualification_determination_Date__c!=undefined && this.getDateInUTC(ipvRec.Disqualification_determination_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Disqualification_determination_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Disqualification_determination_Date__c").set("v.message",'');
                isValid = true;
            }            
        }
        return isValid;
    },
    calculateBeginDate: function(cmp) {
        var ipvRec = cmp.get("v.ipvRec");
        if(cmp.get("v.isInitialised") && ipvRec.Disqualification_determination_Date__c !=undefined && ipvRec.Disqualification_determination_Date__c!='' && ipvRec.Disqualification_determination_Date__c!=null){
            var deterDate= new Date(ipvRec.Disqualification_determination_Date__c);
            var month =deterDate.getUTCMonth();
            var year = deterDate.getUTCFullYear();
            if(month==11){
                month=1;
                year= year+1;
            }else{
                month=month+2;
            }
            var beginDate = year +'-'+ month +'-'+ 1;
            cmp.set("v.beginDate",beginDate);
        }
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    createInvestigatoryInfo : function(cmp, evt, hlp){
        debugger;
        var invInfoRec =evt.getParam("invInfoRec");
        if(invInfoRec != null && invInfoRec!=undefined){
            var lstInvestigatoryFindings = cmp.get("v.lstInvestigatoryFindings");
            if(lstInvestigatoryFindings==undefined){
                lstInvestigatoryFindings=[];
            }
            var isInsert = true;
            for(var i=0;i<lstInvestigatoryFindings.length;i++){
                if(invInfoRec.Id ==lstInvestigatoryFindings[i].Id){
                    lstInvestigatoryFindings[i] =  this.getPicklistLabels(cmp,invInfoRec);
                    isInsert = false;
                    break;
                }
            }
            if(isInsert){
                lstInvestigatoryFindings.push(this.getPicklistLabels(cmp,invInfoRec));
            }
            cmp.set("v.lstInvestigatoryFindings",lstInvestigatoryFindings);
        }
        if(cmp.get('v.modalInv')!=null){
            cmp.get('v.modalInv').then(
                function (modal) {
                    modal.close();
                }
            );
        }
        
    },
    createInvestigatoryFinding : function(cmp,evt,hlp){
        var modalBody;
        var componentName = "c:IPV_InvestigatoryInfo";
        var params = {"recordId": cmp.get("v.recordId")};
        if(componentName){
            $A.createComponent(componentName, params,
                               function(content, status) {
                                   if (status === "SUCCESS") {
                                       modalBody = content;
                                       var modalInv =cmp.find('overlayLib').showCustomModal({
                                           header:"Investigatory Information",
                                           body: modalBody,
                                           showCloseButton: true,
                                           cssClass: "slds-modal_small"
                                       })
                                       cmp.set("v.modalInv", modalInv);
                                   }
                               });
        }
    },
    deleteInvestigatoryInformations : function(cmp,helper){
        var ipvRec = cmp.get("v.ipvRec");
        var lstInvestigatoryFindings = cmp.get("v.lstInvestigatoryFindings");
        if (!ipvRec.Disqualification_Created__c && lstInvestigatoryFindings!= undefined && lstInvestigatoryFindings.length>0){
            helper.callServer(cmp,"c.deleteRecords", 
                              function(response){
                                  
                              }, {'deleteObjects':lstInvestigatoryFindings,
                                  "isFinalStep":true
                                 }, false);
        }
    }, setColumnHeaders : function(cmp){
        var timezone = $A.get("$Locale.timezone");
        var actions = [{ label: 'Edit', name: 'edit' },{ label: 'Delete', name: 'delete' }];
        var lstColumn =[
            {
                label: 'Investigatory Finding', fieldName: 'Investigatory_Finding__c',type: 'picklist', typeAttributes: {options:[{label:'Label 5', value:'5'},{label:'Label 1', value:'2'},{label:'Label 2', value:'Label 3'},{label:'Label 4', value:'4'}]}
            },
            { 
                label: 'Occurred', fieldName: 'Occurred__c', type: 'text'
            },
            {
                label: 'Date', fieldName: 'Date__c', type: 'date-local',typeAttributes: { timezone: timezone }
            }
        ];
        if(!cmp.get("v.isReadOnly")){
            lstColumn.push({ 
                label: 'Actions' ,type: 'action', typeAttributes: { rowActions: actions } 
            })
        }
        cmp.set('v.columns',lstColumn);
    },
    handleRowAction : function(cmp,evt,hlp){
        var rows= cmp.get("v.lstInvestigatoryFindings");
        var action = evt.getParam( 'action' );
        var row = evt.getParam('row');
        var recId = row.Id;
        
        switch (action.name) {
            case 'edit':{
                var modalBody;
                var componentName = "c:IPV_InvestigatoryInfo";
                var params = {"recordId": cmp.get("v.recordId"),
                              "invInfoRec":this.getPicklistApiNames(cmp,row) };
                if(componentName){
                    $A.createComponent(componentName, params,
                                       function(content, status) {
                                           if (status === "SUCCESS") {
                                               modalBody = content;
                                               var modalInv =cmp.find('overlayLib').showCustomModal({
                                                   header:"Investigatory Information",
                                                   body: modalBody,
                                                   showCloseButton: true,
                                                   cssClass: "slds-modal_small"
                                               })
                                               cmp.set("v.modalInv", modalInv);
                                           }
                                       });
                }
                break;
            }
            case 'delete':{
                hlp.callServer(cmp,"c.deleteRecords", 
                               function(response){
                                   var mapInvestigatoryFindings = cmp.get("v.mapInvestigatoryFindings");
                                   var lstInvestigatoryFindings = cmp.get("v.lstInvestigatoryFindings");
                                   var lstInvestigatoryFindingsUpdated=[];
                                   for(var i=0;i<lstInvestigatoryFindings.length;i++){
                                       if(lstInvestigatoryFindings[i].Id !=recId){
                                           lstInvestigatoryFindingsUpdated.push(lstInvestigatoryFindings[i]); 
                                       }
                                   }
                                   cmp.set("v.lstInvestigatoryFindings",lstInvestigatoryFindingsUpdated);
                                   hlp.fireToast("dismissible", "success","Success","Record successfully deleted");    
                                   
                               }, {'deleteObjects':[row],
                                   "isFinalStep":true
                                  }, false);
                break;
            }
        }
    },
    getPicklistLabels : function(cmp,invInfoRec){
        if(invInfoRec!=null && invInfoRec!=undefined){
            var mapInvInfoValuetoLabel = cmp.get("v.mapInvInfoValuetoLabel");
            var mapOccurredValuetoLabel = cmp.get("v.mapOccurredValuetoLabel");
            if(invInfoRec.Investigatory_Finding__c!=null && 
               invInfoRec.Investigatory_Finding__c!=undefined&&
                mapInvInfoValuetoLabel!=null && mapInvInfoValuetoLabel !=undefined)
            {
              invInfoRec.Investigatory_Finding__c = mapInvInfoValuetoLabel[invInfoRec.Investigatory_Finding__c];  
            }
            if(invInfoRec.Occurred__c!=null && 
               invInfoRec.Occurred__c!=undefined&&
                mapOccurredValuetoLabel!=null && mapOccurredValuetoLabel !=undefined)
            {
              invInfoRec.Occurred__c = mapOccurredValuetoLabel[invInfoRec.Occurred__c];  
            }
        }
        return invInfoRec;
    },
    getPicklistApiNames : function(cmp,invInfoRec){
        if(invInfoRec!=null && invInfoRec!=undefined){
            var mapInvInfoLabelToValue = cmp.get("v.mapInvInfoLabelToValue");
            var mapOccurredLabelToValue = cmp.get("v.mapOccurredLabelToValue");
            if(invInfoRec.Investigatory_Finding__c!=null && 
               invInfoRec.Investigatory_Finding__c!=undefined&&
                mapInvInfoLabelToValue!=null && mapInvInfoLabelToValue !=undefined)
            {
              invInfoRec.Investigatory_Finding__c = mapInvInfoLabelToValue[invInfoRec.Investigatory_Finding__c];  
            }
            if(invInfoRec.Occurred__c!=null && 
               invInfoRec.Occurred__c!=undefined&&
                mapOccurredLabelToValue!=null && mapOccurredLabelToValue !=undefined)
            {
              invInfoRec.Occurred__c = mapOccurredLabelToValue[invInfoRec.Occurred__c];  
            }
        }
        return invInfoRec;
    }
})