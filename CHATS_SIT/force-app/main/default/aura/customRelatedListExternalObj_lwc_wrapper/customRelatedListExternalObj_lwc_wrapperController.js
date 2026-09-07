({
    doInit: function(component, event, helper) {
        // Handle navigation state parameters from Lightning navigation
        var pageReference = component.get("v.pageReference");
        if (pageReference && pageReference.state) {
            var state = pageReference.state;
            
            // Map state parameters to component attributes
            if (state.c__sortAscDsc) component.set("v.sortAscDsc", state.c__sortAscDsc);
            if (state.c__orderByField) component.set("v.orderByField", state.c__orderByField);
            if (state.c__relatedListHeader) component.set("v.relatedListHeader", state.c__relatedListHeader);
            if (state.c__parentObjIdentifier) component.set("v.parentObjIdentifier", state.c__parentObjIdentifier);
            if (state.c__childApiName) component.set("v.childApiName", state.c__childApiName);
            if (state.c__pickListTypeFields) component.set("v.pickListTypeFields", state.c__pickListTypeFields);
            if (state.c__componentAttributesValues) component.set("v.componentAttributesValues", state.c__componentAttributesValues);
            if (state.c__componentAttributes) component.set("v.componentAttributes", state.c__componentAttributes);
            if (state.c__componentAttributesTypes) component.set("v.componentAttributesTypes", state.c__componentAttributesTypes);
            if (state.c__recordId) component.set("v.recordId", state.c__recordId);
            if (state.c__isNavigateToCmp !== undefined) component.set("v.isNavigateToCmp", state.c__isNavigateToCmp);
            if (state.c__showMore !== undefined) component.set("v.showMore", state.c__showMore);
            if (state.c__navigationKey) component.set("v.navigationKey", state.c__navigationKey);
            if (state.c__returnBackToCaseCommentsList !== undefined) component.set("v.returnBackToCaseCommentsList", state.c__returnBackToCaseCommentsList);
        }
    }
})