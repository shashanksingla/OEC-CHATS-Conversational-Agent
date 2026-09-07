({
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