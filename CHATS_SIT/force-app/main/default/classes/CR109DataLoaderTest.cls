@isTest
public class CR109DataLoaderTest {
     static testmethod void testCR109Dataloader(){
         string corspdName= 'CR109';
         string caseId = 'CA-1';
         integer providerId = 123;
         String corrId = 'Adams';
        
         test.startTest();
       	 CR109DataLoader CR109 = new CR109DataLoader(corspdName, caseId, providerId, corrId);
         XmlStreamWriter xmlWrtr = new XmlStreamWriter();
         system.assert(string.valueOf(CR109.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
         CR109.setCorspdInfo(xmlWrtr);
         CR109.setKeyParameters(xmlWrtr);
         test.stopTest();
         
     }
}