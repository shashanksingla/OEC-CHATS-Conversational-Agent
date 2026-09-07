({
	doInit : function(component, event, helper) {
		var countyRatePlan = component.get("v.countyRatePlan");
        var lstRateTypes = [];
        var rateTypes = countyRatePlan.RATE_TYPE__c.split(";");
        var mapTierGroup = component.get("v.mapTierGroup");
        component.set("v.lstTierGroup",mapTierGroup[component.get("v.providerType")]);
		var mapRateTypes = component.get("v.mapRateTypes");
        var ageGroup = component.get("v.lstAgeGroup");
        var exempt5plusAgeGroupvalue =$A.get("$Label.c.exempt5plusAgeGroupvalue");
        for(var i=0;i<rateTypes.length;i++){
            if(component.get("v.providerType")=='EXE'){
                    lstRateTypes.push({"rateType":{'key':rateTypes[i],'value':mapRateTypes[rateTypes[i]]},
                                       "ageGroupValue":"1",
                                       "ageGroupLabel":"<5 years",
                                      });
                    lstRateTypes.push({"rateType":{'key':rateTypes[i],'value':mapRateTypes[rateTypes[i]]},
                                       "ageGroupValue": exempt5plusAgeGroupvalue,
                                       "ageGroupLabel":"5+ years",
                                      });
            }else{
                for(var j=0;j<ageGroup.length;j++){
                    if(rateTypes[i]=='1' || rateTypes[i]=='31' || rateTypes[i]=='37' ||
                      rateTypes[i]=='43' || rateTypes[i]=='55'||rateTypes[i]=='91' ||
                      ((rateTypes[i]=='13' ||rateTypes[i]=='19' || rateTypes[i]=='25') && ageGroup[j].ageGroupValue=='8')){
                        lstRateTypes.push({"rateType":{'key':rateTypes[i],'value':mapRateTypes[rateTypes[i]]},
                                           "ageGroupValue":ageGroup[j].ageGroupValue,
                                           "ageGroupLabel":ageGroup[j].ageGroupLabel,
                                          });
                    }
                }
            }
        }
        component.set("v.lstRateTypes",lstRateTypes);
    }
})