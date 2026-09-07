@isTest
public class sidmodIntegrationwebservicesTest {
    @isTest 
    static void testprocessCorspdPrint() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new getClientClearanceMockTest());
        
        List<object> rtrn = sidmodIntegrationWebservices.GetClientClearance('ABCD EFG$', 'XYZ','M','2010-01-01','762364379','2');
        system.assertEquals(true,rtrn.size()>0,'Should return a list');
        List<object> rtrn_GC1 = sidmodIntegrationWebservices.GetClientClearance('ABCD EFGH', 'XYZ','','2010-01-01','','1');
        system.assertEquals(true,rtrn_GC1.size()>0,'Should return a list');
        List<object> rtrn_GC2 = sidmodIntegrationWebservices.GetClientClearance('ABCD EFGH', 'XYZ','','2010-01-01','','3');
        system.assertEquals(true,rtrn_GC2.size()>0,'Should return a list');
        test.stopTest();
    }
    @isTest 
    static void testprocessCorspdPrint1() {
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new assignStateIdMockTest());
        List<object> rtrn1 = sidmodIntegrationWebservices.assignStateId('ABCDEFGH', 'XYZ','M','2010-01-01','675654387','2');
        system.assertEquals(true,rtrn1.size()>0,'Should return a list');
        List<object> rtrn_a1 = sidmodIntegrationWebservices.assignStateId('ABCDEFGH', 'XYZ','','2010-01-01','','1');
        system.assertEquals(true,rtrn_a1.size()>0,'Should return a list');
        List<object> rtrn_a2 = sidmodIntegrationWebservices.assignStateId('ABCDEFGH', 'XYZ','','2010-01-01','','3');
        system.assertEquals(true,rtrn_a2.size()>0,'Should return a list');
        
        test.stopTest();
    }
}