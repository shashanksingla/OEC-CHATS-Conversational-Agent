({
    doInit : function(component, event, helper) {
        console.log('responsibleParties---'+JSON.stringify(component.get("v.responsibleParties")));
    },
    handleValidateCurrentPage : function(component, event, helper) {
        var resultFromThisPage = helper.validateCurrentPage(component);
        var resultFromAdjustmentResponsibleParty = true;
        var responsiblePartyList = component.get("v.responsiblePartyList");
        if(!$A.util.isEmpty(responsiblePartyList)){
            if(!$A.util.isEmpty(responsiblePartyList.length) && responsiblePartyList.length>1){
                component.find("adjustmentResponsiblePartyFlow").forEach(function(adjustmentResponsiblePartyObj){
                    var validSoFar = adjustmentResponsiblePartyObj.callValidateCurrentPage();
                    if(!validSoFar){
                        debugger;
                        resultFromAdjustmentResponsibleParty = validSoFar;
                        return  validSoFar;
                    }
                });
            }else{
                var validSoFar = component.find("adjustmentResponsiblePartyFlow").callValidateCurrentPage();
                if(!validSoFar){
                    debugger;
                    resultFromAdjustmentResponsibleParty = validSoFar;
                    return  validSoFar;
                }
            }
            
        }
        console.log('resultFromAdjustmentResponsibleParty--'+resultFromAdjustmentResponsibleParty);
        return resultFromThisPage && resultFromAdjustmentResponsibleParty;
    },
    handlecreateRespParties:function(component, event, helper) {
        var responsiblePartyObj = event.getParam("responsiblePartyObj");
        var responsiblePartyList = event.getParam("responsiblePartyList");
        var mapkey =   event.getParam("key");
        var selectedRec =   event.getParam("selectedRec");
        console.log('event handled--'+JSON.stringify(responsiblePartyObj));
        console.log('event handled-responsiblePartyList-'+JSON.stringify(responsiblePartyList));
        console.log('event handled mapkey--'+JSON.stringify(mapkey));
        var map = {};
        var respPartyMap= component.get("v.respPartyMap"); 
        if(respPartyMap!= null){
            for (var p in respPartyMap) {
                map[p]= respPartyMap[p];
                if( respPartyMap.hasOwnProperty(p) ) {
                    if(p==mapkey){
                        if(selectedRec){
                            map[p]= respPartyMap[p];
                        }else{
                            //map.delete(mapkey);
                            delete map[mapkey];
                        }
                        
                    }
                } 
            }   
            if(selectedRec){
                map[mapkey]= responsiblePartyObj;
            }else{
                
            }
            component.set("v.respPartyMap",map); 
        }else{
            if(selectedRec){
                map[mapkey]=responsiblePartyObj;
            }
            component.set("v.respPartyMap",map); 
        }
    }
})