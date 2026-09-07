({
    checkCustomValidations : function(cmp,helper){
        var isValid = this.verifyDate(cmp); 
        
        return isValid;        
    },
    handleSaveRecord : function(cmp,helper) {
        var invInfoRec = cmp.get("v.invInfoRec");
        var recordId = cmp.get("v.recordId");
        if(invInfoRec.IPV_Information__c == null || invInfoRec.IPV_Information__c==undefined ||invInfoRec.IPV_Information__c==''){
            invInfoRec.IPV_Information__c = recordId;
        }
        helper.callServer(cmp,"c.upsertRecordsFinal", 
                          function(response){
                              if(response.isSuccessful){
                                  helper.fireToast("dismissible", "success","Success","Record successfully saved"); 
                                  var appEvent = $A.get("e.c:createInvestigatoryInfo");
                                  appEvent.setParam("invInfoRec", response.objectData.upsertedRecords[0]);
                                  appEvent.fire();
                              }else{
                                  helper.fireToast("dismissible", "error","Error","There was a error saving the record. "+response.message);
                              }
                              
                          }, {'lstSObject':[invInfoRec],
                              "isFinalStep":true
                             }, false);
        
    },
    handleCancel : function (cmp, hlp, evt) {
        var appEvent = $A.get("e.c:createInvestigatoryInfo");
        appEvent.fire(); 
    },
    verifyDate: function(cmp){
        var isValid = true;
        var invInfoRec = cmp.get("v.invInfoRec");
        if (invInfoRec.Date__c!=undefined && this.getDateInUTC(invInfoRec.Date__c) > this.getDateInUTC(new Date()) ){
            cmp.find("Investigatory_Finding__c-Date__c").set("v.message",'Date cannot be in the future');
            isValid = false;
        }else{
            cmp.find("Investigatory_Finding__c-Date__c").set("v.message",'');
            isValid = true;
        } 
        return isValid;
    },
    getDateInUTC: function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    }   
})