@isTest
public class CR702DataLoaderTest {
	static testmethod void testCR702Dataloader(){
       	string corspdName= 'CR702';
        string caseId = 'CA-1';
        integer providerId = 123;
        String corrId = 'Adams';
        string cntySfid;
        test.startTest();        
       	CR702DataLoader CR702 = new CR702DataLoader(corspdName, caseId, providerId, corrId, cntySfid, 'ENG');
       	CR702DataLoader CR702_SPN = new CR702DataLoader(corspdName, caseId, providerId, corrId, cntySfid, 'SPN');
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        
        system.assert(string.valueOf(CR702.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR702_SPN.getxmldata();
        CR702.setCorspdInfo(xmlWrtr);
        CR702.setKeyParameters(xmlWrtr);
        test.stopTest();
     }
}