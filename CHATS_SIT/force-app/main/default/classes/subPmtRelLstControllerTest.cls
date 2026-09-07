@isTest
public class subPmtRelLstControllerTest {
    testMethod static void testGetSubPmtRecords() {
        Test.startTest();
        system.assertEquals(null,subPmtRelLstController.getSubPmtRecords(''),'Should return null');
        Test.stopTest();
    }
}