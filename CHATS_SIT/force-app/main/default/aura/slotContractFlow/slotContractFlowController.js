({
    doInit : function(component, event, helper){
        
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set("v.today",today);
        var dateCal=new Date(today);
        
        dateCal.setDate(dateCal.getDate() - 9);
        dateCal=  $A.localizationService.formatDate(dateCal, "YYYY-MM-DD");
        component.set("v.beginDateMin",dateCal);	
        
        var tod=new Date(today);
        var endd = new Date(tod.setMonth(tod.getMonth()+12));
        component.set("v.endDateMax",endd);
        
        component.set("v.endDateMin",today);
        var action = component.get("c.getInitData");
        action.setParams({ recordid : component.get("v.recordId") });
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            // console.log('resultvv '+JSON.stringify(result));
            
            if(result.isSuccessful == true) 
            {
                
                var pset = result.objectData.weekdays;
                var plValues = [];
                for(var key in pset){
                    plValues.push({
                        label: key,
                        value: pset[key] 
                    });
                }
                component.set("v.weekOpt", plValues);
                
                var clset = result.objectData.careLevel;
                var clValues = [];
                for(var key in clset){
                    clValues.push({
                        label: key,
                        value: clset[key] 
                    });
                }
                component.set("v.clevelOpt", clValues);
                component.set("v.clevelOrg", clValues);
                
                var cuset = result.objectData.careUnit;
                var cuValues = [];
                for(var key in cuset){
                    cuValues.push({
                        label: key,
                        value:  cuset[key]
                    });
                }
                component.set("v.cunitOpt", cuValues);  
                
                var rtyset = result.objectData.rateType;
                var rtValues = [];
                for(var key in rtyset){
                    rtValues.push({
                        label: key,
                        value: rtyset[key]
                    });
                }
                //   component.set("v.rtypeOpt", rtValues);
                
                var ptSet = result.objectData.progType;
                var ptValues = [];
                for(var key in ptSet){
                    ptValues.push({
                        label: key,
                        value: ptSet[key]
                    });
                }
                component.set("v.ptypOpt", ptValues);
                
                
                var cntVal = [];
                var cntSet = result.objectData.countySet;
                for(var key in cntSet){
                    
                    cntVal.push({
                        label: cntSet[key],
                        value: key
                    }); 
                }
                
                component.set("v.countyOpt",cntVal);
                component.set("v.slotContract.provdName", result.objectData.providername);
                component.set("v.slotContract.avaVal",true);
                component.set("v.slotContract.progTyp","LI");
                component.set("v.slotContract.provdId", component.get("v.recordId"));
                component.set("v.provdName",result.objectData.provdName);
                component.set("v.sequence",result.objectData.sequence);
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
    rateTypeChange : function(component, event, helper){
        component.set("v.slotContract.clevelVal",undefined);
        var newR=component.get("v.slotContract.rtypeVal");
        var clValues=component.get("v.clevelOrg");
        var newClSet=[];
        if(newR==13 || newR==19 || newR==25)
        {
            clValues.filter(function (el) {
                
                if(el.value == 8)
                { 
                    newClSet.push({
                        label:el.label,
                        value:el.value
                    });
                }
              //  return newClSet ;
            });
            component.set("v.clevelOpt", newClSet);
        }else{
            component.set("v.clevelOpt",clValues);
            //   component.set("v.clevelOrg", clValues);
        }
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
        
    },
    handleCountyChange : function(component, event, helper){
        var val=component.get("v.slotContract.countyVal");
        var cntSet=component.get("v.countyOpt");
        var finCounty;
        const result = cntSet.filter(function (el) {
            
            if(el.value == val)
            {
                finCounty = el.label;
            }
            return finCounty ;
        });
        
        var desc = finCounty+'_'+component.get("v.provdName")+'_'+component.get("v.sequence");
        component.set("v.slotContract.scdesc",desc);
        if(component.get("v.slotContract.countyVal") != null)
        {
            component.set("v.countyTrue", true);
        }
        helper.getRateType(component, event, helper);
    },
    handleBeginDate : function(component, event, helper){
        var val=component.get("v.slotContract.beginDate");
        var tod=new Date(val);
        var newMax=new Date(tod.setMonth(tod.getMonth()+12));
        component.set("v.endDateMax",newMax);
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