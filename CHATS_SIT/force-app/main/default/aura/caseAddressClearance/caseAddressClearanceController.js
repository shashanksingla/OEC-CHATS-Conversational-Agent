({
    updateAddressSobject :  function(component, event, helper)
    {
        helper.setAddressType(component);
        var skipUpdate = component.get("v.skipUpdate");
        
        if(!skipUpdate)
        {
            if(!$A.util.isEmpty(component.get("v.selectedAddress"))){
                helper.doUpdate(component);
                helper.navigateToSource(component);
            }
            else{
                helper.navigateToSource(component);
            }
        }
        else{
            /*var multipleAddress = component.get("v.multipleAddress");
            if(!multipleAddress){
            	$A.get("e.force:closeQuickAction").fire();
            	var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({mode: 'sticky',message: 'Address Updated Successfully', title: 'Success!' , type: 'success'});
                toastEvent.fire();
                }
                else{
                    component.set("v.updateSuccess", component.get("v.addressType")+' Address Updated Successfully')
                }*/
            helper.navigateToSource(component);
            component.set("v.showUpdate",false);
                
        }
    },
    unvalidatedSelected  : function(component, event, helper){
        component.set("v.skipUpdate", true);
    },
    setAddressType  : function(component, event, helper){
        helper.setAddressType(component);
    },
    updateAddrClearance : function(component){
        component.set("v.selectedValidAddress", "Yes");
    }
})