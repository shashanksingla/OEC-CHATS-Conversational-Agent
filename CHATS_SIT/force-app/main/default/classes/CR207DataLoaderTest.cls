@isTest
public class CR207DataLoaderTest {
    static testmethod void CR207DataLoaderTest(){
        String corspdName = 'CR207';
        String caseId = 'CA-1';
        Integer providerId;
        String adjustmentId = '234';
        String corrId = 'Adams';
        String cntySfid;
        Boolean isCase = true;
        Boolean isProvider = false;
        String clientId = 'INDIV-1';
        test.startTest();
        CR207DataLoader CR207 = new CR207DataLoader(corspdName, caseId, providerId, corrId, cntySfid, adjustmentId, isCase, isProvider, clientId);
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        System.assert(String.valueOf(CR207.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR207.setCorspdInfo(xmlWrtr);
        CR207.setFlags(xmlWrtr);
        CR207.setKeyParameters(xmlWrtr);
        test.stopTest();
    }
}