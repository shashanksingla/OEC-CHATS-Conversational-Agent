@isTest
public class GenericDataSaverExternalObjTest {
    //Added on 23/04
    public static testmethod void testinsertExternalObjRecords(){
        Test.startTest();
        batchsit_t_eligty_run__x rec = TestClassUtility.createEligibilityRunRecord(false,null);
        List<Sobject> list1= new List<Sobject>();
        list1.add(rec);
        
        LightningServerResponse lsr1 = GenericDataSaverApxCtrl.insertExternalObjRecords(list1, true);
        Test.stopTest();
        system.assertEquals(true,lsr1.isSuccessful,'isSuccessful is true');
        
    }
    
    
    public static testmethod void testupdateExternalObjRecords(){
        Test.startTest();
        batchsit_t_eligty_run__x rec = TestClassUtility.createEligibilityRunRecord(true,null);
        List<Sobject> list1= new List<Sobject>();
        list1.add(rec);
        
        LightningServerResponse lsr1 = GenericDataSaverApxCtrl.updateExternalObjRecords(list1, true);
        Test.stopTest();
        system.assertEquals(true,lsr1.isSuccessful,'isSuccessful is true');
    }    
}