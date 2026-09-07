({
	doInit : function(component, event, helper) {
		var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
        var applicationIndividual = component.get("v.applicationIndividual");
        for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
            if(lstSelectedApplicationIndividuals[i].Id == applicationIndividual.Id){
                component.find("checkbox").set("v.checked",true);
            }
        }
        var mapIndivSequenceToRelationship = component.get("v.mapIndivSequenceToRelationship");
        var mapIndivToRelationship = component.get("v.mapIndivToRelationship");
        console.log(mapIndivSequenceToRelationship);
        if(component.get("v.isCBMSFlow")){
            if(!$A.util.isEmpty(mapIndivToRelationship)){
             console.log("RelationshipType;"+mapIndivToRelationship[applicationIndividual.IDN_SEQ_INDIV__c]);
             component.set("v.relationshipType",mapIndivToRelationship[applicationIndividual.IDN_EXTNL__c]);
         } 
         }else{
            if(!$A.util.isEmpty(mapIndivSequenceToRelationship)){
                console.log("sequence number:"+applicationIndividual.IDN_SEQ_INDIV__c);
                console.log("RelationshipType;"+mapIndivSequenceToRelationship[applicationIndividual.IDN_SEQ_INDIV__c]);
                component.set("v.relationshipType",mapIndivSequenceToRelationship[applicationIndividual.IDN_SEQ_INDIV__c]);
            }
         }
        
	},
    onCheckboxSelection : function(component, event, helper) {
		var lstSelectedApplicationIndividuals = component.get("v.lstSelectedApplicationIndividuals");
        var applicationIndividual = component.get("v.applicationIndividual");
        var isAlreadySelected = false;
        var index = -1;
        for(var i=0;i<lstSelectedApplicationIndividuals.length;i++){
            if(lstSelectedApplicationIndividuals[i].Id == applicationIndividual.Id){
                isAlreadySelected = true;
                index = i;
                break;
            }
        }
        if(component.find("checkbox").get("v.checked") && !isAlreadySelected){
            lstSelectedApplicationIndividuals.push(applicationIndividual);
        }else if(!component.find("checkbox").get("v.checked") && isAlreadySelected){
            lstSelectedApplicationIndividuals.splice(index, 1);
        }
        component.set("v.lstSelectedApplicationIndividuals",lstSelectedApplicationIndividuals);
    }
})