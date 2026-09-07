({
	getPicklistValues : function(component, picklistType, picklistMap) {
		var action = component.get('c.getPicklistValues');
        action.setParams({
            'picklistType' : picklistType,
            'keyParams' : picklistMap
        });
        action.setCallback(this, function(response) {
        var state = response.getState();
        if(state == 'SUCCESS'){
            var returnedPicklistValues = response.getReturnValue();
            var value = component.get('v.value');
            if($A.util.isEmpty(value)) {
                value = returnedPicklistValues.find(function(v) {
                    return v.isDefaultValue;
                });
                    
                value = value ? value.value : null;
            }
            
            var opts=[];
            if(!component.get('v.required') || component.get('v.showNone')) {
                opts.push({
                	'label' : '--None--',
                    'value' : ' ',
                    'class' : 'optionClass',
                    'selected' : value==null?true:false
                });
                value = value==null?' ':value;
            } else if (component.get('v.required') || component.get('v.showNone')) {
                opts.push({
                	'label' : '--None--',
                    'value' : ' ',
                    'class' : 'optionClass',
                    'selected' : value==null?true:false
                });
                value = value==null?' ':value;
            }
            opts = opts.concat(returnedPicklistValues.map(function(v) {
            	return {
                	'label' : v.label,
                    'value' : v.value,
                    'class' : 'optionClass'
                };
            }));
            component.set('v.value', value);
            /*for(var i=0;i< response.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: response.getReturnValue()[i], value: response.getReturnValue()[i]});
            }*/
          	var picklist = component.find('picklist');//component.find("{!v.picklistId}")    
        	picklist.set("v.options", opts);
        }else {
           
        }    
    });
    $A.enqueueAction(action);
    },
    getGlobalPicklistValues : function (component, event, helper) {
        var picklistMap = {};
        var picklistType = component.get('v.picklistType');
        picklistMap = Object.assign({},{'objectName': component.get('v.objectName')});
        picklistMap = Object.assign(picklistMap,{'fieldName': component.get('v.fieldName')});
        helper.getPicklistValues(component, picklistType, picklistMap);
	},
    getTablePicklistValues : function (component, event, helper) {
        var picklistType = component.get('v.picklistType');
        var picklistMap = {};
        picklistMap = Object.assign({},{'keyColName': component.get('v.keyColName')});
        picklistMap = Object.assign(picklistMap,{'keyValueName': component.get('v.valueColName')});
        picklistMap = Object.assign(picklistMap,{'method': component.get('v.method')});
        picklistMap = Object.assign(picklistMap,{'userRestriction': component.get('v.userRestriction')});
        helper.getPicklistValues(component, picklistType, picklistMap);
    }
})