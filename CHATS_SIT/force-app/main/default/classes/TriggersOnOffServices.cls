public class TriggersOnOffServices {
    public static Boolean triggerStatus(String triggerName){ 
        Triggers_On_Off_Settings__c triggerOnOffRecord = Triggers_On_Off_Settings__c.getValues(triggerName);
        if(triggerOnOffRecord!=null && !triggerOnOffRecord.Active__c) {
            return true;           
        }
        return false;
    }
}