({
    checkCustomValidations : function(cmp){
        //should be implemented in child component if there are any custom validations.
        
        
        var isValid= true;
        var effectiveBeginDate= cmp.get('v.effectiveBeginDate');
        var effectiveBeginDateReadOnly= cmp.get('v.effectiveBeginDateReadOnly');
        var currentDate =  this.getCurrentSystemDate();
        var effectiveEndDateFA = cmp.get('v.providerFiscalAgreementRec').DTE_END_AGRMT__c; 
        var day = new Date (effectiveBeginDate).getUTCDate();
       
        if(effectiveBeginDateReadOnly == false && (effectiveEndDateFA < effectiveBeginDate))
        {
        	cmp.find('effectiveBeginDate').set('v.message',$A.get("$Label.c.Effective_Begin_Date_RS") ) ;
            isValid = false;
        }
        else if(effectiveBeginDateReadOnly == false && (effectiveBeginDate < currentDate || day!='01') && ($A.get("$Label.c.skipRSBeginDateValidation") =='N')) 
        {
        	cmp.find('effectiveBeginDate').set('v.message', $A.get("$Label.c.Effective_Begin_Date_RS1")) ;
            isValid = false;
        }
        
        if(cmp.get("v.selectedRateTypes")== null || cmp.get("v.selectedRateTypes")==''){
            cmp.find('selectedRateTypes').set('v.message' , 'Please select atleast one Rate Type.');
            isValid = false;
        }else{
            cmp.find('selectedRateTypes').set('v.message', '') ; 
        }
        return isValid;
        
    },getCurrentSystemDate : function(addDays, addMonths){
        
        var today = new Date();
        if(addDays && addDays != null){
        today = today + addDays;
        }
        if (addMonths && addMonths!=null){
           today = today.setMonth(today.getMonth()+addMonths); 
        }
        var dd = today.getDate();
        var MM = today.getMonth()+1;
        var yyyy = today.getFullYear();
        if(dd<10){
            dd='0'+dd;
        } 
        if(MM<10){
            MM='0'+MM;
        } 
        return yyyy+'-'+MM+'-'+dd;
    },
    handleRateTypeHelpText : function(cmp){
        var mapRateDescription = cmp.get("v.mapRateDescription");
        var rateTypeOptions = cmp.get("v.rateTypeOptions");
        var rateTypeHelpText='';
        if(rateTypeOptions!= null && rateTypeOptions !=undefined){
            for(var i=0;i<rateTypeOptions.length;i++){
                if(mapRateDescription[rateTypeOptions[i].value] != null && mapRateDescription[rateTypeOptions[i].value] != undefined ){ 
                    var rateDescription = mapRateDescription[rateTypeOptions[i].value]; 
                    rateTypeHelpText += rateDescription.MasterLabel+': ' + rateDescription.Description__c +'\n\n' ;
                }
            }
            if(rateTypeHelpText!= null && rateTypeHelpText!=''&& rateTypeHelpText!= undefined){
                cmp.set("v.rateTypeHelpText", rateTypeHelpText);
            }
        }
    }
}
)