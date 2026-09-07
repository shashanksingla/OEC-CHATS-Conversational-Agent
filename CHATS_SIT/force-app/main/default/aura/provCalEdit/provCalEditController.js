({
    doInit : function(component, event, helper) {
        var map = component.get("v.map");
        var day = component.get("v.day");
        component.set("v.provClosListClone",component.get("v.provClosList"));
        var nineDaysAgo=$A.localizationService.formatDate(new Date((new Date()).valueOf() - 1000*60*60*24*9), "YYYY-MM-DD"); // Added as part of CCCAP-10618
        var newDt;
        if(day && day.Day){
            var dt =day.Day;
            newDt=$A.localizationService.formatDate(dt, "YYYY-MM-DD");
            var key = dt.getFullYear()+'-'+(dt.getMonth()+1)+'-'+dt.getDate();
            key = key.replace(/-0+/g, '-');
            component.set("v.key", key);
            
            var map = component.get("v.map");
            var isReadOnly = component.get("v.isReadOnly");
            var comVal;
            
            component.get("v.provClosList").filter(function (el) {                
                if(el.newbeginDate == key){ 
                  //  comVal=el.comment;
                     component.set("v.commVal",el.comment); 
                     component.set("v.cbValue",el.checked);
                }
            });
            
            var fiscalStartDate = component.get("v.faStartDate");
            var fiscalEndDate = component.get("v.faEndDate");
            
            if(component.get("v.isReadOnly")==true){
                component.set("v.isCheckReadonly",true);
            } else if(newDt<nineDaysAgo){
                component.set("v.isCheckReadonly",true);
            }else if(newDt > fiscalEndDate || newDt < fiscalStartDate){
                component.set("v.isCheckReadonly",true);
            }
            
            var holidayList = component.get("v.countyHolidays");
            //console.log('holidayList -- '+holidayList);
            holidayList.filter(function(hl) {                
                if(hl == newDt){ 
                	component.set("v.isCheckReadonly",true);
                }
            });
            component.set("v.dayInCalendar", dt.getDate());
        }
    },
    markItDirty : function(component, event, helper) {
        var originalCheck;
        var originalComment;
        var newCheck=component.get("v.cbValue");
        var newComm=component.get("v.commVal");
        var key= component.get("v.key");
        var recExist=false;
        
        if(component.get("v.updatedSuccessfully")=='true'){
            component.set("v.updatedSuccessfully", '');
        }
        component.set("v.provClosListClone",component.get("v.provClosList"));
        component.get("v.provClosListClone").filter(function (el) {            
            if(el.newbeginDate == key){ 
                originalCheck=el.checked;
                originalComment= el.comment;
                recExist=true;
            }
        });

        if(originalCheck!=newCheck){
            component.set("v.isDirty", 'true');
        }
     
        if(originalComment!=newComm){           
            component.set("v.isDirty", 'true');
        }
        
        if((originalCheck==newCheck || ($A.util.isUndefinedOrNull(originalCheck) && newCheck==false)) &&
           (originalComment==newComm || ($A.util.isUndefinedOrNull(originalComment) && $A.util.isEmpty(newComm)))){
            component.set("v.isDirty", 'false');
        }  
        
        //below code to update in map        
        var keyExxist=false;
        
        component.get("v.updatedList").filter(function (el) {            
            if(el.newbeginDate == key){ 
                el.comment=newComm;
                el.checked=newCheck;
                keyExxist=true; 
            }            
        });
        if(keyExxist==false){
            component.get("v.updatedList").push({
                newbeginDate :key,
                comment : newComm,
                checked : newCheck,
            });
        }
        //add error if user only updated comment
     /*   if (newCheck==false && !$A.util.isEmpty(newComm) && recExist==false )
        {
            component.set("v.updatedSuccessfully", 'false');
            component.set("v.recordError",'Cannot add comment without selecting Care Not Offered.');
            component.set("v.ifError",'false');
        }else{
            component.set("v.updatedSuccessfully", '');
            component.set("v.recordError",'');
            component.set("v.ifError",'true');
        }*/
    }
})