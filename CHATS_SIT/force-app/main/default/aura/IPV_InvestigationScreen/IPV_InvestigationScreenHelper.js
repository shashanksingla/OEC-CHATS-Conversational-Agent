({
    doInit : function(cmp, evt, hlp){
        var isReadOnly = cmp.get("v.isReadOnly");
        if(isReadOnly){
            cmp.find('forceRecordCmpInv').reloadRecord(true);
        }
    },
    checkCustomValidations : function(cmp){
        var isValid = this.verifyInvStatusDate(cmp,helper)&& 
            this.verifyInvBeginDate(cmp,helper)&& 
            this.verifyInvEndDate(cmp,helper)&&
            this.verifyInvResultDate(cmp,helper);
        return isValid;        
    },
    handleSaveRecord : function(cmp,helper) {
        var recordId = cmp.get("v.recordId");
        var ipvRec = cmp.get("v.ipvRec");
        ipvRec.Investigation_Created__c= true;
        cmp.set("v.ipvRec", ipvRec);
        cmp.set("v.showSpinner", true);
        cmp.find("forceRecordCmpInv").saveRecord($A.getCallback(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                console.log("Save completed successfully.");
                cmp.set("v.showSpinner", false);
                helper.fireToast("dismissible", "success","Success","Record successfully saved, please enter an IPV Information Note to further document the record");
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
    verifyInvStatusDate : function(cmp,helper){
        var isValid = true;
        var isReadOnly = cmp.get("v.isReadOnly");
        if(!isReadOnly){
            var ipvRec = cmp.get("v.ipvRec");
            if (this.getDateInUTC(ipvRec.Investigation_Status_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Investigation_Status_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Investigation_Status_Date__c").set("v.message",'');
                isValid = true;
            }
            if(isValid){
                if(ipvRec.Investigation_Status_Date__c < ipvRec.Allegation_Result_Determination_Date__c){
                    cmp.find("IPV_Information__c-Investigation_Status_Date__c").set("v.message",'Cannot be prior to Allegation Result Determination Date which is '+ ipvRec.Allegation_Result_Determination_Date__c);
                    isValid = false; 
                }
                else{
                    cmp.find("IPV_Information__c-Investigation_Status_Date__c").set("v.message",'');
                    isValid = true;
                }
            }
            
            return isValid;
        }
    },
    verifyInvBeginDate : function(cmp, helper){
        var isValid = true;
        var isReadOnly = cmp.get("v.isReadOnly");
        if(!isReadOnly){
            var ipvRec = cmp.get("v.ipvRec");
            if (this.getDateInUTC(ipvRec.Investigation_Begin_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Investigation_Begin_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Investigation_End_Date__c").set("v.message",'');
                isValid = true;
            }
            if(isValid){
                if(ipvRec.Investigation_Begin_Date__c < ipvRec.Allegation_Result_Determination_Date__c){
                    cmp.find("IPV_Information__c-Investigation_Begin_Date__c").set("v.message",'Cannot be prior to Allegation Result Determination Date which is '+ ipvRec.Allegation_Result_Determination_Date__c);
                    isValid = false; 
                }
                else{
                    cmp.find("IPV_Information__c-Investigation_Begin_Date__c").set("v.message",'');
                    isValid = true;
                }
            }
            if(isValid){
            this.verifyInvEndDate(cmp,helper);
        }
            
        }        
        return isValid;
    },
    verifyInvEndDate : function(cmp, helper){
        var isValid = true;
        var isReadOnly = cmp.get("v.isReadOnly");
        if(!isReadOnly){
            var ipvRec = cmp.get("v.ipvRec");
            if (this.getDateInUTC(ipvRec.Investigation_End_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Investigation_End_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Investigation_End_Date__c").set("v.message",'');
                isValid = true;
            }
            if(isValid){
                if(ipvRec.Investigation_End_Date__c!='' && ipvRec.Investigation_End_Date__c!=undefined && ipvRec.Investigation_End_Date__c!=null && ipvRec.Investigation_End_Date__c < ipvRec.Investigation_Begin_Date__c){
                    cmp.find("IPV_Information__c-Investigation_End_Date__c").set("v.message",'Cannot be prior to Investigation Begin Date');
                    isValid = false; 
                }
                else{
                    cmp.find("IPV_Information__c-Investigation_End_Date__c").set("v.message",'');
                    isValid = true;
                }
            }
            
        }
        return isValid;
    },
    verifyInvResultDate : function(cmp, helper){
        var isValid = true;
        var isReadOnly = cmp.get("v.isReadOnly");
        if(!isReadOnly){
            var ipvRec = cmp.get("v.ipvRec");
            if (this.getDateInUTC(ipvRec.Investigation_Result_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Investigation_Result_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Investigation_Result_Date__c").set("v.message",'');
                isValid = true;
            }
            if(isValid){
                if(ipvRec.Investigation_Result_Date__c < ipvRec.Investigation_Begin_Date__c){
                    cmp.find("IPV_Information__c-Investigation_Result_Date__c").set("v.message",'Cannot be prior to Investigation Begin Date');
                    isValid = false; 
                }
                else{
                    cmp.find("IPV_Information__c-Investigation_Result_Date__c").set("v.message",'');
                    isValid = true;
                }
                
            }
            
        }
        return isValid;
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    }
})