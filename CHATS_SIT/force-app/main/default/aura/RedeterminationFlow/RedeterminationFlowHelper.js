({
    convertDateIntoUTC : function(date) {
        var date = new Date(date);
        return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
    },
    checkValidData : function(component, event, helper) {
        
        var caseRec = component.get("v.caseRec");
        var caseCopy = component.get("v.caseCopy");
        var packetSentDate ;
        var packetSentOldDate;
        var packetReceivedDate ;
        var packetReceivedOldDate;
        var cseRedeterDate ;
        var validationPass = true;
        if(!$A.util.isEmpty(caseRec.DTE_SENT_PACKET_REDET__c)){
            packetSentDate= helper.convertDateIntoUTC(caseRec.DTE_SENT_PACKET_REDET__c);
            packetSentOldDate = helper.convertDateIntoUTC(caseCopy.DTE_SENT_PACKET_REDET__c);
        }
        if(!$A.util.isEmpty(caseRec.DTE_RCVD_PACKET_REDET__c)){
            packetReceivedDate= helper.convertDateIntoUTC(caseRec.DTE_RCVD_PACKET_REDET__c);
            packetReceivedOldDate = helper.convertDateIntoUTC(caseCopy.DTE_RCVD_PACKET_REDET__c);
        }
        if(!$A.util.isEmpty(caseRec.DTE_REDET_CASE__c)){
            cseRedeterDate = helper.convertDateIntoUTC(caseRec.DTE_REDET_CASE__c);
        }
        console.log('cseRedeterDate--'+cseRedeterDate);
        console.log('packetSentDate--'+packetSentDate);
        console.log('packetSentOldDate--'+packetSentOldDate);
        console.log('packetReceivedDate--'+packetReceivedDate);
        if(!$A.util.isEmpty(caseRec) && !$A.util.isEmpty(caseCopy)){
            //  if(caseRec.DTE_RCVD_PACKET_REDET__c!=caseCopy.DTE_RCVD_PACKET_REDET__c){
            if(packetSentDate <packetSentOldDate){
                debugger;
                var recordError1 =[];
                var message1 = 'The update Re-determination packet sent date cannot be prior to the system determined Re-determination packet sent date.';
                recordError1.push(message1);
                component.set("v.message",'error');
                component.set("v.recordError",recordError1);
                validationPass = false;
            }else  if(!$A.util.isEmpty(caseRec.DTE_RCVD_PACKET_REDET__c) && packetReceivedDate < packetSentDate){
                debugger;
                var recordError2 =[];
                var message2 = 'The updated Re-determination packet sent date cannot be greater than Date Re-determination packet Returned.';
                recordError2.push(message2);
                component.set("v.message",'error');
                component.set("v.recordError",recordError2);
                validationPass = false;
            }else if(cseRedeterDate < packetSentDate){
                debugger;
                var recordError3 =[];
                var message3 = 'The updated Re-determination packet sent date cannot be greater than Case Re-determination Date.';
                recordError3.push(message3);
                component.set("v.message",'error');
                component.set("v.recordError",recordError3);
                validationPass = false;
            }else if($A.util.isEmpty(packetSentDate)){
                debugger;
                var recordError4 =[];
                var message4 = 'The Re-determination packet sent date cannot be blank.';
                recordError4.push(message4);
                component.set("v.message",'error');
                component.set("v.recordError",recordError4);
                validationPass = false;
            }
        }
        console.log('validationPass'+validationPass);
        return validationPass;       
    },
    updateRec:function(component,event,helper){
        component.find("recordLoader").saveRecord($A.getCallback(function(saveResult) {
        })); 
    }
})