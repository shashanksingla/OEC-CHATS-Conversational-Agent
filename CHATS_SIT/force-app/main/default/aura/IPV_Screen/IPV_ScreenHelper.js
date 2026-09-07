({
	checkCustomValidations : function(cmp,helper){
        var isValid = this.verifyReceivedDate(cmp,helper)&& 
            this.verifyStatusDate(cmp,helper)&& 
            this.verifyResultDeterminationDate(cmp,helper); 
            
        return isValid;        
    },
    handleSaveRecord : function(cmp,helper) {
        var ipvRec = cmp.get("v.ipvRec");
        var recordId = cmp.get("v.recordId");
        if(cmp.get("v.sObjectName")=='IPV_Information__c'){
            ipvRec.Id = recordId;
        }else{
            ipvRec.Individual_ID__c = recordId;
        }
        helper.callServer(cmp,"c.upsertRecordsFinal", 
                                            function(response){
                                               helper.fireToast("dismissible", "success","Success","Record successfully saved, please enter an IPV Information Note to further document the record"); 
                                               helper.redirectToRecord(recordId);
                                                
                                            }, {'lstSObject':[ipvRec],
                                                "isFinalStep":true
                                               }, false);
        
    },
    initializeNewRecord : function(cmp) {
        var ipvRec = cmp.get("v.ipvRec");
        var recordId = cmp.get("v.recordId");
        if(cmp.get("v.sObjectName")=='IPV_Information__c'){
           ipvRec.Id = recordId; 
        }
        else{
            ipvRec.Individual_ID__c = recordId;
        }
    },
    verifyReceivedDate : function(cmp,helper){
        var isValid = true;
        var isReadOnly = cmp.get("v.isReadOnly");
        if(!isReadOnly){
            var ipvRec = cmp.get("v.ipvRec");
            if (this.getDateInUTC(ipvRec.Allegation_Received_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Allegation_Received_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Allegation_Received_Date__c").set("v.message",'');
                isValid = true;
            }
            return isValid;
        }
    },
    verifyStatusDate : function(cmp,helper){
        var isValid = true;
        var isReadOnly = cmp.get("v.isReadOnly");
        if(!isReadOnly){
            var ipvRec = cmp.get("v.ipvRec");
            if (this.getDateInUTC(ipvRec.Allegation_Status_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Allegation_Status_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Allegation_Status_Date__c").set("v.message",'');
                isValid = true;
            }
            return isValid;
        }
    },
    verifyResultDeterminationDate : function(cmp,helper){
        var isValid = true;
        var isReadOnly = cmp.get("v.isReadOnly");
        if(!isReadOnly){
            var ipvRec = cmp.get("v.ipvRec");
            if (this.getDateInUTC(ipvRec.Allegation_Result_Determination_Date__c) > this.getDateInUTC(new Date()) ){
                cmp.find("IPV_Information__c-Allegation_Result_Determination_Date__c").set("v.message",'Date cannot be in the future');
                isValid = false;
            }else{
                cmp.find("IPV_Information__c-Allegation_Result_Determination_Date__c").set("v.message",'');
                isValid = true;
            }
            if(isValid){
                if(ipvRec.Allegation_Result_Determination_Date__c != null &&
                   ipvRec.Allegation_Result_Determination_Date__c != undefined &&
                   ipvRec.Allegation_Result_Determination_Date__c!=''&&
                   ipvRec.Allegation_Result_Determination_Date__c < ipvRec.Allegation_Received_Date__c){
                    cmp.find("IPV_Information__c-Allegation_Result_Determination_Date__c").set("v.message",'Cannot be prior to Allegation Received Date');
                    isValid = false; 
                }
                else{
                    cmp.find("IPV_Information__c-Allegation_Result_Determination_Date__c").set("v.message",'');
                    isValid = true;
                }
            }
            return isValid;
        }
    }
})