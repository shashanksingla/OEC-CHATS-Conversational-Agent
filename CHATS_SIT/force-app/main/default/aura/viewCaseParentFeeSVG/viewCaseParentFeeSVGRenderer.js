({
    afterRender: function(component, helper) {
        debugger;
        var svg = component.find("svg_content");
        if(typeof svg === "array"){
            for (var i = 0; i < svg.length; i++) {
                var value =  svg[i].getElement().innerText;
                value = value.replace("<![CDATA[", "").replace("]]>", "");
                svg[i].getElement().innerHTML = value;
            }
        }
        else{
            var value =  svg.getElement().innerText;
            value = value.replace("<![CDATA[", "").replace("]]>", "");
            svg.getElement().innerHTML = value;
        }  
    }
})