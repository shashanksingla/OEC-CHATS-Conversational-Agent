({
    updateRadioButtons : function(cmp, ev) {
        
        var val = cmp.get("v.val");
        var toggleBody = cmp.find("body");
        if(cmp.get("v.type")=='PICKLIST'){
            if(val == "Y"){
                cmp.find("Radio_Yes").set("v.checked", true);          
                cmp.find("Radio_No").set("v.checked", false);
                cmp.find("Radio_Unknown").set("v.checked", false);
            }else if(val == "N"){
                cmp.find("Radio_No").set("v.checked", true);
                cmp.find("Radio_Yes").set("v.checked", false); 
                cmp.find("Radio_Unknown").set("v.checked", false);
            }else if(val == "U"){
                cmp.find("Radio_No").set("v.checked", false);
                cmp.find("Radio_Yes").set("v.checked", false); 
                cmp.find("Radio_Unknown").set("v.checked", true);
            }else{
	        }      
        }else if(cmp.get("v.type")=='BOOLEAN'){
            if(val==true){
                cmp.find("Radio_No").set("v.checked", false);
                cmp.find("Radio_Yes").set("v.checked", true);     
                cmp.find("Radio_Unknown").set("v.checked", false);
            }else if(val==false){
                cmp.find("Radio_No").set("v.checked", true);
                cmp.find("Radio_Yes").set("v.checked", false);  
                cmp.find("Radio_Unknown").set("v.checked", false);
            }else{
                cmp.find("Radio_No").set("v.checked", false);
                cmp.find("Radio_Yes").set("v.checked", false);
				cmp.find("Radio_Unknown").set("v.checked", false);                
	        }
        }
    },
    showHideTextArea : function(cmp, ev) {
        
        var val = cmp.find(ev.getSource().getLocalId()).get('v.value');
        if(cmp.get("v.type")=='PICKLIST'){
            cmp.set("v.val", val);
        }else if(cmp.get("v.type")=='BOOLEAN'){
            if(val=='Y'){
                cmp.set("v.val", true);
            }else if(val=='N'){
                cmp.set("v.val", false);
            }else{
                cmp.set("v.val", null);
            }
        }
    }
    
})