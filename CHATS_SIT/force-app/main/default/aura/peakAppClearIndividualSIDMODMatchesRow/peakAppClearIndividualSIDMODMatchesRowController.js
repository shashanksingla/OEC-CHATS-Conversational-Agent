({
	doInit : function(component, event, helper) {
        //commenting this logic for SIDMOD changes , CCCAP-7695, DOB received now is YYYY-MM-DD earlier it was YYYYMMDD
        /*var individual = component.get("v.individual");
        if(!$A.util.isEmpty(individual.dateOfBirth)){
	        individual.dateOfBirth = individual.dateOfBirth.substring(0,4)+'-'+individual.dateOfBirth.substring(4,6)+'-'+individual.dateOfBirth.substring(6,8);
	        component.set("v.individual",individual);
        }*/
    },
	onIndividualMatchOptionSelection : function(component, event, helper) {
	    var evt = $A.get("e.c:peakAppUpdateParentComponentAttribute");
        evt.setParams({'attributeName':'stateID'});
        evt.setParams({'attributeValue':component.get("v.individual").stateId});
        evt.setParams({'firstNameSIDMOD':component.get("v.individual").firstName});
        evt.setParams({'lastNameSIDMOD':component.get("v.individual").lastName});
        evt.setParams({'middleInitialSIDMOD':component.get("v.individual").middleName});
        evt.setParams({'dobSIDMOD':component.get("v.individual").dateOfBirth});
        evt.setParams({'ssnSIDMOD':component.get("v.individual").ssn});
        evt.setParams({'genderSIDMOD':component.get("v.individual").gender});
        evt.setParams({'dateOfDeathSIDMOD':component.get("v.individual").dateOfDeath});
        evt.setParams({'dataFromSidmod':true});
        evt.fire();
	}
})