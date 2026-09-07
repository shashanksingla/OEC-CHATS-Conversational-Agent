({
    doInit : function(component, event, helper){
        
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set("v.today",today);
        var dateCal=new Date(today);
        
        dateCal.setDate(dateCal.getDate() - 9);
        dateCal=  $A.localizationService.formatDate(dateCal, "YYYY-MM-DD");
        component.set("v.beginDateMin",dateCal);	
        
        var action = component.get("c.getInitData");
        action.setParams({ recordid : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            console.log('resultvv '+JSON.stringify(result));
            
            if(result.isSuccessful == true) 
            {
                if(result.objectData.profileCheck==false)
                {
                var authError = 'Your profile '+result.objectData.profileName+' does not have access to edit Slot Contract records.';
                component.set("v.messageText", authError);           
                helper.callModal(component,"warningModalProfile");
            	}
                else{
                var pset = result.objectData.weekdays;
                var plValues = [];
                for(var key in pset){
                    plValues.push({
                        label: key ,
                        value: pset[key]
                    });
                }
                component.set("v.weekOpt", plValues);
                
                var clset = result.objectData.careLevel;
                var clValues = [];
                for(var key in clset){
                    clValues.push({
                        label: key ,
                        value: clset[key]
                    });
                }
                component.set("v.clevelOrg", clValues);
                    
                var cuset = result.objectData.careUnit;
                var cuValues = [];
                for(var key in cuset){
                    cuValues.push({
                        label: key ,
                        value: cuset[key]
                    });
                }
                component.set("v.cunitOpt", cuValues);  
                
                var ptSet = result.objectData.progType;
                var ptValues = [];
                for(var key in ptSet){
                    ptValues.push({
                        label: key ,
                        value: ptSet[key]
                    });
                }
                component.set("v.ptypOpt", ptValues);
                
                
                var cntVal = [];
                var cntSet = result.objectData.countySet;
                for(var key in cntSet){
                    
                    cntVal.push({
                        label: key ,
                        value: cntSet[key]
                    });
                }
                
                component.set("v.countyOpt",cntVal);
                component.set("v.slotContract.countyVal", result.objectData.slotData.CDE_COUNTY__r.Name);
                component.set("v.slotContract.clevelVal", result.objectData.slotData.CDE_CARE_LEVEL__c);
                component.set("v.slotContract.rtypeVal", result.objectData.slotData.CDE_RATE_TYPE__c);
                component.set("v.slotContract.cunitVal", result.objectData.slotData.CDE_CARE_UNIT__c);
                component.set("v.slotContract.noDays", result.objectData.slotData.CNT_DAYS_OF_MONTH__c);
                component.set("v.slotContract.beginDate", result.objectData.slotData.DTE_BEGIN_SLOT__c);
                component.set("v.slotContract.provdName", result.objectData.providername);
                component.set("v.slotContract.avaVal",result.objectData.slotData.IND_AVAILABLE__c);
                component.set("v.slotContract.endDate",result.objectData.slotData.DTE_END_SLOT__c);
                component.set("v.slotContract.progTyp",result.objectData.slotData.CDE_PRG_TYPE__c);
                component.set("v.slotContract.scdesc",result.objectData.slotData.SLOT_CONTRACT_DESCRIPTION__c);
                component.set("v.slotContract.provdId", result.objectData.slotData.IDN_PROVIDER__c);
                component.set("v.slotContract.authVal", result.objectData.slotData.IDN_AUTH__c);
				component.set("v.weekValue", result.objectData.weekval);                
                
                //original data 
                component.set("v.slotContractClone.countyVal", result.objectData.slotData.CDE_COUNTY__c);
                component.set("v.slotContractClone.clevelVal", result.objectData.slotData.CDE_CARE_LEVEL__c);
                component.set("v.slotContractClone.rtypeVal", result.objectData.slotData.CDE_RATE_TYPE__c);
                component.set("v.slotContractClone.cunitVal", result.objectData.slotData.CDE_CARE_UNIT__c);
                component.set("v.slotContractClone.noDays", result.objectData.slotData.CNT_DAYS_OF_MONTH__c);
                component.set("v.slotContractClone.beginDate", result.objectData.slotData.DTE_BEGIN_SLOT__c);
                component.set("v.slotContractClone.provdName", result.objectData.providername);
                component.set("v.slotContractClone.avaVal",result.objectData.slotData.IND_AVAILABLE__c);
                component.set("v.slotContractClone.endDate",result.objectData.slotData.DTE_END_SLOT__c);
                component.set("v.slotContractClone.progTyp",result.objectData.slotData.CDE_PRG_TYPE__c);
                component.set("v.slotContractClone.scdesc",result.objectData.slotData.SLOT_CONTRACT_DESCRIPTION__c);
                component.set("v.slotContractClone.provdId", result.objectData.slotData.IDN_PROVIDER__c);
                component.set("v.slotContractClone.authVal", result.objectData.slotData.IDN_AUTH__c);
                component.set("v.orgWeek", result.objectData.weekval);
                component.set("v.orgCounty",result.objectData.slotData.CDE_COUNTY__r.Name);
                var rtyset = result.objectData.newRate;
                var rtValues = [];
                 for(var key in rtyset){
                     
                    rtValues.push({
                        label: key,
                        value: rtyset[key]
                    });
                   
                }
                component.set("v.rtypeOpt", rtValues);
                }
                helper.rateTypeChange(component, event, helper);
                
            }
        });
        $A.enqueueAction(action);
    },
    handleCancelClick : function(component, event, helper){
        
        helper.callModal(component,'confirmationModalOnCancel');
    },
    actionOnCancelYesButton: function(component, event, helper){
        var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    actionOnCancel : function(component, event, helper){
         var modalCall = component.find("warningModal");
        modalCall.hideConfirmModal();
    },
    actionOnCancelProf : function(component, event, helper){
          var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    actiononNo : function(component, event, helper){
         var recordId = component.get("v.recordId");
        helper.goToRecord(recordId,'detail');
    },
    actionOnYes : function(component, event, helper){
        var modalCall = component.find("warningMsgModal");
        var chng=component.get("v.tmpcheckChangeProg");
        var chngauth=component.get("v.tmpcheckChangeAuth");
        if(chng=='false')
        {
              component.set("v.checkChangeProg",'false');
        }
        if(chngauth=='false')
        {
               component.set("v.checkChangeAuth",'false');
        }
        modalCall.hideConfirmModal();
	component.set("v.spinner", false);
    },
    rateTypIn : function(component, event, helper){
         component.set("v.slotContract.clevelVal",undefined);
       helper.rateTypeChange(component, event, helper);
    },
    handleChange: function(component, event, helper){
       
        var val=component.get("v.slotContract.authVal");
      
        if(val!=null || val!=='')
        {
            component.set("v.slotContract.avaVal",false);
        }
        if(val==null || val=='')
        {
            component.set("v.slotContract.avaVal",true);
            component.set("v.slotContract.authVal",undefined);
        }
    },handleBegin : function(component, event, helper){
       if(component.get("v.slotContract.beginDate") != null)
       { 
           component.set("v.beginTrue", true); 
       }
        
         helper.getRateType(component, event, helper);
    
	},
    handleSaveClick : function(component, event, helper){
       component.set("v.spinner", true);         
       helper.checkValidity(component,helper);
    },
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    }
})