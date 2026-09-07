@isTest
public class CR212DataLoaderTest {
static testmethod void CR212DataLoaderTest(){
        string corspdName= 'CR212';
        string caseId = 'CA-1';
        integer providerId = 123;
        String corrId = 'Adams';
        test.startTest();
       	CR212DataLoader CR212 = new CR212DataLoader(corspdName, caseId, providerId, corrId, 'ENG');
        CR212DataLoader CR212_SPN = new CR212DataLoader(corspdName, caseId, providerId, corrId, 'SPN');       	
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        
        system.assert(string.valueOf(CR212.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR212.setCorspdInfo(xmlWrtr);
        CR212.setKeyParameters(xmlWrtr);
        test.stopTest();
         
     }
}