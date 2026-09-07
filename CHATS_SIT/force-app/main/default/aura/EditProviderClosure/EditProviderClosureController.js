({
    doInit : function(component, event, helper){
         helper.callModal(component,"warningModalProfile");
    },
	actionOnCancelProf : function(component, event, helper){
          var recordId = component.get("v.recordId");
       // helper.goToRecord(recordId,'detail');
        window.history.back();
    }
})