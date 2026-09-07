({    
    searchByAuthIdCtrl : function(component, event, helper) {
        component.set("v.subPaymentSearchLst",[]);
        component.set("v.selectedSubPayment","");
        component.set("v.searchByAuthId",true);
        component.set("v.searchByChilName",false);
        component.set("v.searchBySlotCntId",false);
        component.set("v.caseId",'');
        component.set("v.slotCntId",'');
        //component.set("v.slotCntcheckbox", false);
    },
    searchByChildNameCtrl : function(component, event, helper) {
        component.set("v.subPaymentSearchLst",[]);
        component.set("v.selectedSubPayment","");
        component.set("v.searchByAuthId",false);
        component.set("v.searchByChilName",true);
        component.set("v.searchBySlotCntId",false);
        component.set("v.authId",'');
        component.set("v.slotCntId",'');
        //component.set("v.slotCntcheckbox", false);
    },
    searchBySlotCntrtIdCtrl : function(component, event, helper) {
        component.set("v.subPaymentSearchLst",[]);
        component.set("v.selectedSubPayment","");
        component.set("v.searchByAuthId",false);
        component.set("v.searchByChilName",false);
        component.set("v.searchBySlotCntId",true);
        component.set("v.caseId",'');
        component.set("v.authId",'');
        //component.set("v.slotCntcheckbox", true);
    },
    handleNext: function(component,event,helper){
        var currentPageNo= component.get("v.currentPageNumber");
        currentPageNo=currentPageNo+1;
        var subPaymentSearchLstPage=[];
        var subPaymentSearchLst= component.get("v.subPaymentSearchLst");
        var size=subPaymentSearchLst.length;
        var i=currentPageNo*50;
        var maxLength=(currentPageNo+1)*50;
        if(maxLength>size){
           maxLength=size; 
        }
        for(i;i<maxLength;i++){
            subPaymentSearchLstPage.push(subPaymentSearchLst[i]);
        }
        component.set('v.pageNavigated',true);
        component.set("v.subPaymentSearchLstPage",subPaymentSearchLstPage);
        currentPageNo=component.get("v.currentPageNumber");
        component.set("v.currentPageNumber",currentPageNo+1);
    },
    handlePrevious: function(component,even,helper){
        var currentPageNo= component.get("v.currentPageNumber");
        currentPageNo=currentPageNo-1;
        var subPaymentSearchLstPage=[];
        var subPaymentSearchLst= component.get("v.subPaymentSearchLst");
        for(var i=currentPageNo*50;i<(currentPageNo+1)*50;i++){
            subPaymentSearchLstPage.push(subPaymentSearchLst[i]);
        }
        component.set('v.pageNavigated',true);
        component.set("v.subPaymentSearchLstPage",subPaymentSearchLstPage);
        currentPageNo=component.get("v.currentPageNumber");
        component.set("v.currentPageNumber",currentPageNo-1);
    },
    pagination: function(component,event,helper){
        var subPaymentSearchLst= event.getParam("value");
        var subPaymentSearchLstPage=[];
        if(null!=subPaymentSearchLst && undefined!=subPaymentSearchLst&&subPaymentSearchLst.length>0){
            var size=subPaymentSearchLst.length;
            if(size>50){
                component.set("v.hasOnePage",false);
                for(var i=0;i<50;i++){
                    subPaymentSearchLstPage.push(subPaymentSearchLst[i]);
                }
                var numberOfPages=parseInt(size/50);
                if(size%50==0){
                    component.set("v.numberOfPages",numberOfPages);
                }
                else{
                    component.set("v.numberOfPages",numberOfPages+1);
                }
                component.set("v.subPaymentSearchLstPage",subPaymentSearchLstPage);
            }else{
                component.set("v.hasOnePage",true);
                component.set("v.numberOfPages",1);
                component.set("v.subPaymentSearchLstPage",subPaymentSearchLst);
            }
            if(component.get('v.pageNavigated') == false){
                component.set("v.currentPageNumber",0);
            }
        }else{
            component.set("v.currentPageNumber",0);
            component.set("v.hasOnePage",true);
            component.set("v.subPaymentSearchLstPage",[]);
            component.set("v.numberOfPages",0);
        }
        component.set('v.pageNavigated',false);
    }
	
})