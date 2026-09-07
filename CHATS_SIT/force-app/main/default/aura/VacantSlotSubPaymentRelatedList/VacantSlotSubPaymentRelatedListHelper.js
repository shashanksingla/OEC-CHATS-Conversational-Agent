({
	getSubPmtRecords : function(component) {
		var action = component.get('c.getVacantSlotSubPmtRecords');
		action.setParams({"pmtId":component.get("v.recordId")});
		action.setCallback(this, function(response) {
            var returnValue = response.getReturnValue();
            
            if(returnValue!=null && response.getState() === 'SUCCESS'){
                
                var sbPmtLst = returnValue;
                
                if(sbPmtLst.length<=0){
                	component.set('v.showTable', false);
            		component.set('v.recCount', '0');
                }
                else{
                	component.set('v.recCount', (sbPmtLst.length).toString());
                	component.set('v.showTable', true);
                	component.set('v.subPmtRecLst', sbPmtLst);
                }
            }else if(returnValue!=null && response.getState() === 'ERROR' ){
                var errors = action.getError();
               
                component.set('v.showTable', false);
            	component.set('v.recCount', '0');
            }
            else if(returnValue==null){
            	
            	component.set('v.showTable', false);
            	component.set('v.recCount', '0');
            }
            else{
            	var errors = action.getError();
                
            	component.set('v.showTable', false);
            	component.set('v.recCount', '0');
            }
        });
        $A.enqueueAction(action);
	}
})