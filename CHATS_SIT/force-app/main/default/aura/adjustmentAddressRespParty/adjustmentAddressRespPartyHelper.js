({
	 fireEventHlp :function(component, event, helper) {
        var responsiblePartyObj = component.get("v.responsiblePartyObj");
        console.log('responsiblePartyObj@@ -'+JSON.stringify(responsiblePartyObj));
        var responsiblePartyList = component.get("v.responsiblePartyList");
        var IPVRecordId = component.get("v.IPVRecordId");
        var adjustment = component.get("v.adjustment");
        if(responsiblePartyObj.Selected__c){
            if(adjustment.CDE_TYPE_CLSFN__c =='1'){
                component.set("v.IPVRecordReq",true);
            }else{
             component.set("v.IPVRecordReq",false);   
            }
            if($A.util.isEmpty(responsiblePartyObj.IPV_Info__c) && (adjustment.CDE_TYPE_CLSFN__c =='1')){
                component.find("IPVRecordId").set("v.message","Investigation Record ID is a required field when Classification Type is Fraud/IPV.");
            }else{
                component.find("IPVRecordId").set("v.message","");
                
                // new code for validation
                if(component.get("v.adjustment").CDE_TYPE_ADJMT__c=='Recovery' && component.get("v.adjustment").IDN_CASE__c!=null && component.get("v.adjustment").IDN_CASE__c!=undefined){
                    if(!$A.util.isEmpty(responsiblePartyObj.IPV_Info__c)){
                        this.getIPVRecord(component,event,helper);
                    }else{
                        component.find("IPVRecordId").set("v.message","");
            component.set("v.IPVRecordReq",false);
                        var appEvent = $A.get("e.c:createRespParty");
                                appEvent.setParams({ "selectedRec":responsiblePartyObj.Selected__c,"responsiblePartyObj" : responsiblePartyObj ,"key":responsiblePartyObj.IDN_CLIENT__c, "responsiblePartyList" : responsiblePartyList });
                                appEvent.fire();
                    }
                }
                // end
                
            }
        }
        else{
            component.find("IPVRecordId").set("v.message","");
            component.set("v.IPVRecordReq",false);
            var appEvent = $A.get("e.c:createRespParty");
            appEvent.setParams({ "selectedRec":responsiblePartyObj.Selected__c,"responsiblePartyObj" : responsiblePartyObj ,"key":responsiblePartyObj.IDN_CLIENT__c, "responsiblePartyList" : responsiblePartyList });
            appEvent.fire(); 
            
        }
        
    },
    checkCustomValidations : function(component, event, helper) {
         var address = component.get("v.address");
         console.log('---'+JSON.stringify(address));
         if(!$A.util.isEmpty(address)){
             var zipCodeExt = address.ADR_ZIP_EXTN__c;
             if(!$A.util.isEmpty(zipCodeExt) && zipCodeExt.length >4){
                 component.find("T_ADJMT__c-ADR_ZIP_EXTN__c").set("v.message","Zip Code(Extn) cannot be greater than 4 characters");
                 return false;
             }else{
                 component.find("T_ADJMT__c-ADR_ZIP_EXTN__c").set("v.message","");
                 return true;
             }
         }
         return true;
	},
    divideZipCodeHelper : function(component, event, helper) {
        var address = component.get("v.address");
        console.log('-divideZipCodeHelper--'+JSON.stringify(address));
        if(!$A.util.isEmpty(address)){
            var zipCode = address.ADR_ZIP_MAIN__c;
            var zipCodeExt = address.ADR_ZIP_EXTN__c;
            if(!$A.util.isEmpty(zipCode)){
                if(zipCode.includes("-")){
                    zipCode = zipCode.toLowerCase().replace(/[\W_]+/g,'');
                }
            }
            if(!$A.util.isEmpty(zipCodeExt)){
                if(zipCodeExt.includes("-")){
                zipCodeExt = zipCodeExt.toLowerCase().replace(/[\W_]+/g,'');
                }
            }
            if(!$A.util.isEmpty(zipCode) && zipCode.length >5){
                if(!$A.util.isEmpty(zipCodeExt) && zipCodeExt.length >0){
                }else{
                    address.ADR_ZIP_EXTN__c = zipCode.substring(5,zipCode.length);
                }
                address.ADR_ZIP_MAIN__c = zipCode.substring(0,5);
            }
            else if(!$A.util.isEmpty(zipCode) && zipCode.length ==5){
                if(!$A.util.isEmpty(zipCodeExt) && zipCodeExt.length >0){
                }else{
                    address.ADR_ZIP_EXTN__c = '0000';
                }
            }
            component.set("v.address",address);
        }
    },
})