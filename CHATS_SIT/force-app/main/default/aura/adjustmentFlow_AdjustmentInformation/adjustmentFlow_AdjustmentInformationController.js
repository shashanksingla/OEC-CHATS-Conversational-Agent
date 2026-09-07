({
    handleValidateCurrentPage : function(component, event, helper) {
        var resultFromAdjustmentAddress = true;
        if(!$A.util.isEmpty(component.find("adjustmentAddress"))){
            resultFromAdjustmentAddress = component.find("adjustmentAddress").callValidateCurrentPage();
        }
        var resultFromAdjustmentResponsibleParty = true;
        var resultFromAdjustmentResponsiblePartyAddr = true; 
        if(component.get("v.adjustment").CDE_TYPE_ADJMT__c == 'Recovery' && component.get("v.adjustment").IDN_CASE__c != null && component.get("v.adjustment").IDN_CASE__c != undefined){
            resultFromAdjustmentResponsibleParty = component.find("adjustmentResponsibleParty").callValidateCurrentPage();
        }
        var resultFromThisComponent = helper.validateCurrentPage(component);
        console.log('resultFromAdjustmentResponsibleParty-test--'+resultFromAdjustmentResponsibleParty);
        console.log('resultFromThisComponent---'+resultFromThisComponent);
        //NEW Changes for resp address
        var respPartyMap = component.get("v.respPartyMap");
        var adjustmentAddressRespPartyId = component.find("adjustmentAddressRespParty");
        if(!$A.util.isEmpty(component.find("adjustmentAddressRespParty"))){
            if(!$A.util.isEmpty(adjustmentAddressRespPartyId)){
                console.log('respPartyMap.size-size-'+adjustmentAddressRespPartyId.length);
                console.log('respPartyMap.--'+JSON.stringify(respPartyMap));
                if(adjustmentAddressRespPartyId.length == undefined){
                    resultFromAdjustmentResponsiblePartyAddr =  component.find("adjustmentAddressRespParty").callValidateCurrentPage();
                } else {
                    component.find("adjustmentAddressRespParty").forEach(function(adjustmentAddressRespPartyObj){
                        var validSoFar = adjustmentAddressRespPartyObj.callValidateCurrentPage();
                        if(!validSoFar){
                            resultFromAdjustmentResponsiblePartyAddr = validSoFar;
                            return validSoFar;
                        }
                    });  
                }
            }
        }
        // End
        return resultFromAdjustmentAddress && resultFromAdjustmentResponsibleParty && resultFromThisComponent && resultFromAdjustmentResponsiblePartyAddr;
    },
    
    handleAddRespParties : function(component, event, helper) {
        var mapkey = event.getParam("key");
        var selectedRec = event.getParam("selectedRec");
        var responsiblePartiesAddressListClone = component.get("v.responsiblePartiesAddressListClone");
        var respPartyMap = component.get("v.respPartyMap"); 
        var responsiblePartiesAddressListTemp = [];
        console.log('handleAddRespParties--'+mapkey);
        console.log('respPartyMap---'+respPartyMap);
        console.log('respPartyMap---'+JSON.stringify(respPartyMap));
        if(!$A.util.isEmpty(respPartyMap)){
            if(!$A.util.isEmpty(responsiblePartiesAddressListClone)){
                for(var i=0;i<responsiblePartiesAddressListClone.length;i++) {
                    if(respPartyMap.hasOwnProperty(responsiblePartiesAddressListClone[i].Responsible_Party_Client_Id__c)){
                        console.log('mapkey---'+mapkey);
                        console.log('respPartyMap---'+respPartyMap);
                        if(responsiblePartiesAddressListClone[i].Responsible_Party_Client_Id__c == mapkey){
                            if(selectedRec){
                                responsiblePartiesAddressListTemp.push(responsiblePartiesAddressListClone[i]); 
                            }
                        } else {
                            responsiblePartiesAddressListTemp.push(responsiblePartiesAddressListClone[i]);
                        }  
                    }
                }
            }
            component.set("v.responsiblePartiesAddressList",responsiblePartiesAddressListTemp);
        }else{
            component.set("v.responsiblePartiesAddressList",null); // to clear the resp party address list if all the resp parties are removed CCCAP-14858 issue 1
        }
    },
     
    // Added by Rishav for CCCAP-6051
    validateClassificationType : function(component, event) {
        var oldValue = event.getParam("oldValue");
        var newValue = event.getParam("value");
        if(component.get("v.adjustment").CDE_TYPE_ADJMT__c == 'Recovery' && oldValue != 'Other Recoveries' && newValue == '5'){
            var modalCall = component.find('classificationTypeModal');
            if(modalCall){
                modalCall.openModal();
            }
        }
    },
    
    // Added by Rishav for CCCAP-6051
    confirmOK : function(component) {
        var modalCall = component.find('classificationTypeModal');
        if(modalCall){
            modalCall.hideConfirmModal();
        }
    }
})