({
    doInit: function(component, event, helper) {
        setTimeout(function() {
            component.set("v.showLWC", true);
        }, 100);
    }
})