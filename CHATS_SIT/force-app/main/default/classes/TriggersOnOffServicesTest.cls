@isTest
public class TriggersOnOffServicesTest {
    public static testMethod void testTriggerStatus(){
        System.assertEquals(false, TriggersOnOffServices.triggerStatus('test'), 'trigger should not be skipped');
        Triggers_On_Off_Settings__c triggerOnOffRec= new Triggers_On_Off_Settings__c(Name='TriggerA',Active__c=false);
        insert triggerOnOffRec;
        System.assertEquals(true, TriggersOnOffServices.triggerStatus('TriggerA'), 'trigger should be skipped');
    }
}