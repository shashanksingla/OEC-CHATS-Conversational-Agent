({
    performTheRequiredAction : function(component,eventParams) {
        var callApexOrLaunchComponent = component.get("v.callApexOrLaunchComponent").toLowerCase();
        if(callApexOrLaunchComponent == 'component'){
            var loadingType = component.get("v.componentLoadType").toLowerCase();
            if(loadingType == 'modal'){
                this.showComponentInModal(component);
            }else if(loadingType == 'redirect'){
                this.redirectToComponent(component);
            }   
        }else if(callApexOrLaunchComponent == 'apex'){
            var apexMethodName = "c."+component.get("v.apexMethodName");
            this.callApexMethod(component, apexMethodName, 'EXECUTE_APEX');
        }else if(callApexOrLaunchComponent == 'event'){
            var eventToBeFired = $A.get(component.get("v.eventName"));
            eventToBeFired.setParams(JSON.parse(eventParams));
            eventToBeFired.fire();
        } else if(callApexOrLaunchComponent == 'flow'){ //added by Nikita for CCCAP-13170
            component.set("v.isFlow", true);
            this.showComponentInModal(component);
        }
            else{
                
                var windowHash = window.location.hash;
                var windowHref = window.location.href;
                var createRecordEvent = $A.get("e.force:createRecord");
                var parentField = component.get("v.recordIdAttribute").toString();
                if (parentField == 'IPV_Information__c'){
                    createRecordEvent.setParams({
                        "entityApiName": component.get("v.objectAPIName"),
                        "defaultFieldValues": {
                            'IPV_Information__c' : component.get("v.recordId")
                        },
                        "navigationLocation": "LOOKUP",
                        "panelOnDestroyCallback": function(event){
                            window.location.hash = windowHash;
                            $A.get('e.force:refreshView').fire();
                        }
                    });
                }
                else if (parentField == 'Individual_ID__c'){
                    createRecordEvent.setParams({
                        "entityApiName": component.get("v.objectAPIName"),
                        "defaultFieldValues": {
                            'Individual_ID__c' : component.get("v.recordId")
                        },
                        "navigationLocation": "LOOKUP",
                        "panelOnDestroyCallback": function(event){
                            window.location.hash = windowHash;
                            $A.get('e.force:refreshView').fire();
                        }
                    });
                }
                createRecordEvent.fire();
            }
    },
    callApexMethod: function(component, apexMethodName, checkConditionalConfirm){
        
        var methodAttributes = {};
        methodAttributes[component.get("v.recordIdAttribute")] = component.get("v.recordId");
        this.callServer(component, apexMethodName, 
                        function(response){
                            var callApexOrLaunchComponent = component.get("v.callApexOrLaunchComponent");
                            if(checkConditionalConfirm == 'CHECK_CONFIRM'){
                                if(!response.isSuccessful){
                                    this.fireToast("error","Error!",response.errorMessage);                                        
                                }else{
                                    if(response.objectData.showConfirmMessage && response.objectData.showConfirmMessage == true){
                                        this.showConfirmModal(component);
                                    }else{
                                        this.performTheRequiredAction(component); 
                                    }
                                }
                            }else if(checkConditionalConfirm == 'CHECK_REDIRECT'){
                                if(response.objectData && response.objectData.redirect == true){
                                    var eventParams;
                                    if(response.objectData && response.objectData.eventParams){
                                        eventParams = response.objectData.eventParams;
                                    }
                                    this.performTheRequiredAction(component, eventParams); 
                                    if(apexMethodName == 'c.deleteSlotContractAddendum' && response.isSuccessful == true){
                                        $A.get('e.force:refreshView').fire();
                                        this.fireToast("success", "Success!", response.successMessage);
                                    }
                                }else{
                                    this.fireToast("error","Error!",response.errorMessage);    
                                }
                            }else{
                                if(response.isSuccessful == true){
                                    if(response.objectData){
                                        if(response.objectData.showButton!= null){
                                            component.set("v.showButton", response.objectData.showButton);
                                        }
                                    }
                                    else{
                                        $A.get('e.force:refreshView').fire();
                                        this.fireToast("success", "Success!", response.successMessage);
                                    }
                                }else{
                                    this.fireToast("error", "Error!", response.errorMessage);                                    
                                }
                            }
                        }
                        , methodAttributes, false);
    },
    fireToast : function(type, title, message){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "mode": 'sticky',
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    showComponentInModal: function(component) {
        
        var modalBody;
        var componentAttributes = {};
        var ComponentAttributesPassed= component.get("v.componentAttributes");
        var lstComponentAttributesPassed={};
        if(ComponentAttributesPassed && ComponentAttributesPassed != null)
        {
            lstComponentAttributesPassed = ComponentAttributesPassed.split(":");
        }
        var ComponentAttributesValuesPassed = component.get("v.componentAttributesValues");
        var lstComponentAttributesValuesPassed;
        if(ComponentAttributesValuesPassed && ComponentAttributesValuesPassed !=null){
            lstComponentAttributesValuesPassed= ComponentAttributesValuesPassed.split(":");
        }
        componentAttributes['sObjectName'] = component.get("v.sObjectName");
        if(lstComponentAttributesPassed.length > 0 && lstComponentAttributesPassed.length == lstComponentAttributesValuesPassed.length)
            for(var i=0;i<lstComponentAttributesPassed.length;i++){
                componentAttributes[lstComponentAttributesPassed[i]] = lstComponentAttributesValuesPassed[i];
            }
        var componentName = '';//"c:revisitCountyRatePlan"
        var params;
        if(component.get("v.isFlow") == true){
            componentName = "c:submitFlowModalWrapper";
            params = {"recordId": component.get("v.recordId"),
                    "flowAPIName": component.get("v.flowName")};
        } else{
            componentName = component.get("v.componentName");
            params = {"recordId": component.get("v.recordId"),
                      "componentAttributes": componentAttributes};
        }
        var modalHeader=component.get("v.modalHeader");
        if($A.util.isEmpty(modalHeader))
            modalHeader=component.get("v.buttonLabel");
        if(componentName){
            var modalWidthCss = "slds-modal_large";
            if(modalHeader == 'Upload Files'){
                modalWidthCss = "slds-modal_medium";
            }
            $A.createComponent(componentName, params,
                               function(content, status) {
                                   if (status === "SUCCESS") {
                                       modalBody = content;
                                       component.find('modalOverlay').showCustomModal({
                                           header: modalHeader,
                                           body: modalBody,
                                           showCloseButton: true,
                                           cssClass: modalWidthCss,
                                           closeCallback: function() {
                                               $A.get('e.force:refreshView').fire();
                                           }
                                       }).then(function(modalRef){
                                            modalBody.set("v.modalRef", modalRef);
                                        });
                                   }
                               });
        }
    },
    redirectToComponent: function(component) {
        var evt = $A.get("e.force:navigateToComponent");
        var componentAttributes = {};
        var ComponentAttributesPassed= component.get("v.componentAttributes");
        var lstComponentAttributesPassed={};
        if(ComponentAttributesPassed && ComponentAttributesPassed != null)
        {
            lstComponentAttributesPassed = ComponentAttributesPassed.split(":");
        }
        var ComponentAttributesValuesPassed = component.get("v.componentAttributesValues");
        var lstComponentAttributesValuesPassed;
        if(ComponentAttributesValuesPassed && ComponentAttributesValuesPassed !=null){
            lstComponentAttributesValuesPassed= ComponentAttributesValuesPassed.split(":");
        }
        componentAttributes[component.get("v.recordIdAttribute")] = component.get("v.recordId");
        componentAttributes['sObjectName'] = component.get("v.sObjectName");
        if(lstComponentAttributesPassed.length > 0 && lstComponentAttributesPassed.length == lstComponentAttributesValuesPassed.length)
            for(var i=0;i<lstComponentAttributesPassed.length;i++){
                componentAttributes[lstComponentAttributesPassed[i]] = lstComponentAttributesValuesPassed[i];
            }
        
        evt.setParams({
            componentDef : component.get("v.componentName"),
            componentAttributes: componentAttributes
        });
        evt.fire();            
    },
    showConfirmModal: function(component){  
        $A.util.addClass(component.find('confirmMsgModal'), 'slds-fade-in-open');
        $A.util.addClass(component.find('backDrop'), 'slds-backdrop--open');
    },
    hideConfirmModal: function(component){
        $A.util.removeClass(component.find('backDrop'),'slds-backdrop--open');
        $A.util.removeClass(component.find('confirmMsgModal'), 'slds-fade-in-open');        
    }
})