({
    doInit :  function(component, event, helper) {
        var individual = component.get("v.individual");
        var mapIndivSequenceToRelationship = component.get("v.mapIndivSequenceToRelationship");
        console.log(mapIndivSequenceToRelationship);
        var mapIndivToRelationship = component.get("v.mapIndivToRelationship");
        
        console.log('mapIndivToRelationship--'+JSON.stringify(mapIndivToRelationship));
        if(component.get("v.isCBMSFlow")){
           if(!$A.util.isEmpty(mapIndivToRelationship)){
            console.log("RelationshipType;"+mapIndivToRelationship[individual.IDN_SEQ_INDIV__c]);
            component.set("v.relationshipType",mapIndivToRelationship[individual.IDN_EXTNL__c]);
        } 
        }else{
        if(!$A.util.isEmpty(mapIndivSequenceToRelationship) && !$A.util.isEmpty(individual.IDN_SEQ_INDIV__c)){
			//helper.convertRelationshipCodeToType(component, applicationIndividual);
            console.log("sequence number:"+individual.IDN_SEQ_INDIV__c);
            console.log("RelationshipType;"+mapIndivSequenceToRelationship[individual.IDN_SEQ_INDIV__c]);
            component.set("v.relationshipType",mapIndivSequenceToRelationship[individual.IDN_SEQ_INDIV__c]);
        }
        }
    },
    onIndividualSelection : function(component, event, helper) {
		component.set("v.individualForClearance",component.get("v.individual"));        
	}
})