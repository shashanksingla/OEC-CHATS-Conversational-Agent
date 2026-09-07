({
    doInit : function(component, event, helper) {
        helper.doGetMatchedIndividuals(component, event);
        
    },
    
    doHideWarningPopup : function(component, event, helper){
        component.find("warningOnMultipleStateIDsAbove96").hideConfirmModal();
        component.set("v.countOfSIDMODMatchesAbove96Percent",0);
    },
    
    doUpdateComponentAttribute : function(component, event, helper) {    
        console.log("inside doUpdateComponentAttribute with values"+event.getParam("attributeName")+","+event.getParam("attributeValue"))
        component.set("v."+event.getParam("attributeName"),event.getParam("attributeValue"));
        if(event.getParam("attributeName")=='stateID'){
            component.set("v.anyIndividualSelected",true);
        }
        var individualFromSIDMOD = component.get("v.individualFromSIDMOD");
        var individual = component.get("v.individual");
        if(event.getParam("dataFromSidmod") == true){
            component.set('v.sidmodSelection',true); // added for CCCAP-10315 for SIDMOD Notify Feature
            individualFromSIDMOD.NAM_FIRST__c = event.getParam("firstNameSIDMOD");
        	individualFromSIDMOD.NAM_LAST__c = event.getParam("lastNameSIDMOD");
            individualFromSIDMOD.NAM_MI__c = !$A.util.isEmpty(event.getParam("middleInitialSIDMOD"))?event.getParam("middleInitialSIDMOD").substring(0,1):event.getParam("middleInitialSIDMOD");
            individualFromSIDMOD.DTE_DOB__c = event.getParam("dobSIDMOD");
            individualFromSIDMOD.DTE_Death__c = event.getParam("dateOfDeathSIDMOD"); // added for CCCAP-7695 by Shashank
            individualFromSIDMOD.CDE_GENDER__c = event.getParam("genderSIDMOD");
            individualFromSIDMOD.NBR_SSN__c = event.getParam("ssnSIDMOD");
        } else {
            component.set('v.sidmodSelection',false); // added for CCCAP-10315 for SIDMOD Notify Feature
            individualFromSIDMOD.NAM_FIRST__c = individual.NAM_FIRST__c;
        	individualFromSIDMOD.NAM_LAST__c = individual.NAM_LAST__c;
            individualFromSIDMOD.NAM_MI__c = individual.NAM_MI__c;
            individualFromSIDMOD.DTE_DOB__c = individual.DTE_DOB__c;
            individualFromSIDMOD.CDE_GENDER__c = individual.CDE_GENDER__c;
            individualFromSIDMOD.NBR_SSN__c = individual.NBR_SSN__c;
        }
        console.log(JSON.stringify(individualFromSIDMOD));
        component.set("v.individualFromSIDMOD",individualFromSIDMOD);
    },
    doFinish : function(component, event, helper){
        debugger;
        if(component.get("v.anyIndividualSelected")==true){
            var stateID = component.get("v.stateID");
            if(stateID == 'SID Req'){
                var sidmodMatchedIndividuals = component.get("v.lstSIDMODMatchedIndividuals");
                if(sidmodMatchedIndividuals != undefined){
                    var tempScore = '0';
                    for(var i= 0 ; i<sidmodMatchedIndividuals.length; i++){
                        if(tempScore < sidmodMatchedIndividuals[i].score) {
                            tempScore = sidmodMatchedIndividuals[i].score;
                        }
                    }
                    if(tempScore >= 96){
                        component.set("v.pageMessages",[" Override failed: SSN already exists. State ID set for " +sidmodMatchedIndividuals[0].lastName + " , " + sidmodMatchedIndividuals[0].firstName]);
                        component.set("v.messageType","error");
                    }else if (tempScore >=60 && tempScore < 96) {
                        var individual = component.get("v.individual");
                        console.log("stateID="+stateID);
                        individual.IDN_STATE__c = stateID;
                        helper.doOverrideClearance(component, event, individual);
                        component.set("v.pageMessages",["Request will be processed in 24 hours."]);
                        component.set("v.messageType","success");
                    }else if (tempScore < 60) {
                        helper.assignStateId(component, event, helper);    
                    }
                } else {
                    helper.assignStateId(component, event, helper);
                }
            }else {
            	helper.callServerAndHandleError(component, "c.checkStateIdExisting",
                        function(response) {
                            console.log(response);
                            if(response.objectData.stateIdExisting==true){
                                //component.find("existingIndividualSelected").openModal();
                                helper.checkIPVDisqualification(component,event,response.objectData.existingIndividualId);
                            }else{
                                var individual = component.get("v.individual");
                                var individualFromSIDMOD = component.get("v.individualFromSIDMOD");
                                if(!$A.util.isEmpty(individualFromSIDMOD.NAM_FIRST__c)){
                                    individual.NAM_FIRST__c = individualFromSIDMOD.NAM_FIRST__c;
                                }
                                if(!$A.util.isEmpty(individualFromSIDMOD.NAM_LAST__c)){
                                    individual.NAM_LAST__c = individualFromSIDMOD.NAM_LAST__c;
                                }
                                if(!$A.util.isEmpty(individualFromSIDMOD.NAM_MI__c)){
                                    individual.NAM_MI__c = individualFromSIDMOD.NAM_MI__c;
                                } else{
                                	individual.NAM_MI__c = individualFromSIDMOD.NAM_MI__c;
                                }
                                if(!$A.util.isEmpty(individualFromSIDMOD.DTE_DOB__c)){
                                    individual.DTE_DOB__c = individualFromSIDMOD.DTE_DOB__c;
                                }
                                if(!$A.util.isEmpty(individualFromSIDMOD.CDE_GENDER__c)){
                                    individual.CDE_GENDER__c = individualFromSIDMOD.CDE_GENDER__c;
                                }
                                if(!$A.util.isEmpty(individualFromSIDMOD.NBR_SSN__c)){
                                    individual.NBR_SSN__c = individualFromSIDMOD.NBR_SSN__c;
                                } else{
                                	individual.NBR_SSN__c = individualFromSIDMOD.NBR_SSN__c;
                                }
                                // added for CCCAP-7695 by Shashank
                                if(individualFromSIDMOD.DTE_Death__c){
                                    individual.DTE_Death__c = individualFromSIDMOD.DTE_Death__c; 
                                }
                                console.log("stateID="+stateID);
                                individual.IDN_STATE__c = stateID;
                                helper.doUpdateRecords(component, event, individual,false);
                            }
                        }, {'stateId': stateID}, false, null);
            }
        }else{
            component.set("v.pageMessages",["Please select at least one option to proceed."]);
            component.set("v.messageType","error");
        }
    },
    doCancel : function(component, event, helper){
        if($A.util.isEmpty(component.get("v.caseId"))){
            helper.goToRecord(component.get("v.recordId"),'detail');
        }else{
            helper.callServerAndDeleteRecords(component, function(response){
                helper.goToRecord(component.get("v.caseId"),'detail');
            }, [component.get("v.individual")]);            
        }
    },
    doHideExistingIndividualSelectedPopup : function(component, event, helper){
        component.find("existingIndividualSelected").hideConfirmModal();
        var stateID = component.get("v.stateID");
        var individual = component.get("v.individual");
        var individualFromSIDMOD = component.get("v.individualFromSIDMOD");
        if(!$A.util.isEmpty(individualFromSIDMOD.NAM_FIRST__c)){
            individual.NAM_FIRST__c = individualFromSIDMOD.NAM_FIRST__c;
        }
        if(!$A.util.isEmpty(individualFromSIDMOD.NAM_LAST__c)){
            individual.NAM_LAST__c = individualFromSIDMOD.NAM_LAST__c;
        }
        if(!$A.util.isEmpty(individualFromSIDMOD.NAM_MI__c)){
            individual.NAM_MI__c = individualFromSIDMOD.NAM_MI__c;
        } else{
        	individual.NAM_MI__c = individualFromSIDMOD.NAM_MI__c;
        }
        if(!$A.util.isEmpty(individualFromSIDMOD.DTE_DOB__c)){
            individual.DTE_DOB__c = individualFromSIDMOD.DTE_DOB__c;
        }
        if(!$A.util.isEmpty(individualFromSIDMOD.CDE_GENDER__c)){
            individual.CDE_GENDER__c = individualFromSIDMOD.CDE_GENDER__c;
        }
        if(!$A.util.isEmpty(individualFromSIDMOD.NBR_SSN__c)){
            individual.NBR_SSN__c = individualFromSIDMOD.NBR_SSN__c;
        } else{
        	individual.NBR_SSN__c = individualFromSIDMOD.NBR_SSN__c;
        }
        // added for CCCAP-7695 by Shashank
        if(individualFromSIDMOD.DTE_Death__c){
            individual.DTE_Death__c = individualFromSIDMOD.DTE_Death__c; 
        }
        console.log("stateID="+stateID);
        individual.IDN_STATE__c = stateID;
        helper.doUpdateRecords(component, event, individual,false);
    },
    doHideIPVDisqualificationPopup : function(component, event, helper){
        component.find("activeIPVDisqualification").hideConfirmModal();
        component.find("existingIndividualSelected").openModal();
    }
})