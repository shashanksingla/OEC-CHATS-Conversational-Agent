@isTest
public class CR107DataLoaderTest {
    
    static testmethod void testCR107Dataloader(){
       	string corspdName= 'CR107';
        string caseId = 'CA-1';
        integer providerId = 123;
        String corrId = 'Adams';
        
        test.startTest();
       	CR107DataLoader CR107 = new CR107DataLoader(corspdName, caseId, providerId, corrId, 'ENG');
        CR107DataLoader CR107_SPN = new CR107DataLoader(corspdName, caseId, providerId, corrId, 'SPN');       	
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        
        system.assert(string.valueOf(CR107.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR107_SPN.getxmldata();
        CR107.setCorspdInfo(xmlWrtr);
        CR107.setKeyParameters(xmlWrtr);
        test.stopTest();
    } 

}