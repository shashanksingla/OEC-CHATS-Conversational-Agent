({
    calculateTotalAmount : function(nonAdjustmentDetailLst, cmp) {
        var totalAmount=0;
        for(var i=0;i<nonAdjustmentDetailLst.length;i++) {
                totalAmount = totalAmount + parseFloat(nonAdjustmentDetailLst[i].AMT_DETAIL_ADJMT__c);
            }
        cmp.set("v.adjustmentObj.AMT_ADJMT__c",totalAmount);    
    }
})