({
    doInit : function(component, event, helper) {
        var fiscalSchedule = component.get("v.fiscalSchedule");
        
        var lstRateTypes = [];
        var rateTypes = component.get("v.lstRateTypesSelected");
        
        var mapRateTypes = component.get("v.mapRateTypes");
        var ageGroup = component.get("v.lstAgeGroup");
        for(var i=0;i<rateTypes.length;i++){
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
        component.set("v.lstRateTypes",lstRateTypes);
    }
})