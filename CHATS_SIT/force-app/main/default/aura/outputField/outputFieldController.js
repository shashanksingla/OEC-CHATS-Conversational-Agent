({
    doInit : function(component, event, helper) {
        if(component.get("v.usePlainValue")==false && (component.get("v.type")=='DECIMAL' || component.get("v.type")=='DOUBLE')){
            if($A.util.isEmpty(component.get("v.type"))){
                component.set("v.updatedValue",0);
            }else{
                
                var value = component.get("v.value");
                try{
                    var decimalValue = parseFloat(value); 
                    decimalValue = decimalValue.toFixed(2);
                    component.set("v.updatedValue",decimalValue);
                }catch(ex){
                   
                }
            }
        }else if(component.get("v.convertTime")==true && component.get("v.type")=='DATE'){
            var dateWithTime = component.get("v.value");
            if(!$A.util.isEmpty(dateWithTime)){
                // Provides locale information
                var format = $A.get("$Locale.timeFormat");
                format = format.replace(":ss", "");
                var langLocale = $A.get("$Locale.langLocale");
                var timezone = $A.get("$Locale.timezone");
                $A.localizationService.UTCToWallTime(new Date(dateWithTime), timezone, function(walltime) {
                    
                    
                    var dd = walltime.getDate();
                    var MM = walltime.getMonth()+1;
                    var yyyy = walltime.getFullYear();
                    if(dd<10){
                        dd='0'+dd;
                    } 
                    if(MM<10){
                        MM='0'+MM;
                    } 
                    var onlyDate = MM+'/'+dd+'/'+yyyy;
                    component.set("v.updatedValue",onlyDate);
                });                
            }            
        }
        
        if(!$A.util.isEmpty(component.get("v.suffix")) && !$A.util.isEmpty(component.get("v.updatedValue"))){
            component.set("v.updatedValue",component.get("v.updatedValue")+component.get("v.suffix"));          
        }
        if(!$A.util.isEmpty(component.get("v.suffix")) && !$A.util.isEmpty(component.get("v.value"))){
            component.set("v.value",component.get("v.value")+component.get("v.suffix"));          
        }
        
    }
})