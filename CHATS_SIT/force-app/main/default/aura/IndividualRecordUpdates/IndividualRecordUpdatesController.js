({
    recordUpdated : function(component, event, helper) {
        let eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            component.set('v.existingValue',component.get("v.currentRecord.CDE_ATTENDING_SCHOOL1__c"));
            helper.doInitHlp(component,event,helper);
        }else if(eventParams.changeType === "CHANGED") {
            let errorType='warning';
            let indivRecord = component.get("v.currentRecord");
            let existingValue = component.get('v.existingValue');
            component.set('v.existingValue',indivRecord.CDE_ATTENDING_SCHOOL1__c);
            if(indivRecord.DTE_DOB__c)
            {
                var age;
                var birthDate = new Date(indivRecord.DTE_DOB__c);
                var today = new Date();
                age = today.getFullYear() - birthDate.getFullYear();
                var m = today.getMonth() - birthDate.getMonth();
                if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
                    age--;
                }
                if(age>=5 && age<18  && existingValue == 'Y' && indivRecord.CDE_ATTENDING_SCHOOL1__c =='N'){
                    let toastMessage = "The answer to the Kindergarten and Above question has been changed to No. Please update the Care Level screen accordingly.";
                    helper.showToast(component,event,toastMessage,errorType);
                }else if(age<5 && existingValue != indivRecord.CDE_ATTENDING_SCHOOL1__c){
                    let toastMessage;
                    if(existingValue =='Y' &&  indivRecord.CDE_ATTENDING_SCHOOL1__c == 'Unknown')
                    {
                        let dob = new Date(indivRecord.DTE_DOB__c);
                        let SAdate = new Date(dob.setMonth(dob.getMonth() + 60));
                        let individualCareWrap = component.get('v.individualCareWrap');
                        individualCareWrap.forEach(val=>{
                            if(val.indCareLvlObj.cde_level_care__c == '8'){
                            val.indCareLvlObj.dte_begin_effv__c = SAdate.toISOString().split('T')[0];
                        }
                                                   });
                        component.set('v.individualCareWrap',individualCareWrap);
                        toastMessage = "The School Age begin effective date has been changed. Please ensure this is correct and revisit the affected authorizations and update the rate types as needed. Provider payment will be impacted.";
                        helper.checkCustomValidations(component,event,helper);
                    }else if(existingValue == 'Y' && indivRecord.CDE_ATTENDING_SCHOOL1__c =='N'){
                        toastMessage = 'The answer to the Kindergarten and Above question has been changed to No. Please update the Care Level screen accordingly.';
                    }else if((existingValue == 'N' && indivRecord.CDE_ATTENDING_SCHOOL1__c =='Y') ||
                             (existingValue == 'Unknown' && indivRecord.CDE_ATTENDING_SCHOOL1__c =='Y')
                            ){
                        toastMessage = 'The answer to the Kindergarten and Above question has been changed to Yes. Please update the Care Level screen accordingly.';
                    }
                    if(toastMessage)
                    {
                        helper.showToast(component,event,toastMessage,errorType);                        
                    }
                }
            }
        }
    }
})