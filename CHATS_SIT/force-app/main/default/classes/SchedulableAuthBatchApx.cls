global without sharing class SchedulableAuthBatchApx implements schedulable
{
    global void execute(SchedulableContext sc)
    {
    AuthorizationBatchApxCtrl b = new AuthorizationBatchApxCtrl(); 
      database.executebatch(b,10);
    }
}