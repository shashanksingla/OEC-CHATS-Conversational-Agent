@isTest
public class CR108DataLoaderTest {
static testmethod void testCR108Dataloader(){
         string corspdName= 'CR108';
         string caseId = 'CA-1';
         integer providerId = 123;
         string corrId = 'Adams';
    	 string corrLang ='ENG';
         test.startTest();
       	 CR108DataLoader CR108 = new CR108DataLoader(corspdName, caseId, providerId, corrId,corrLang);
         XmlStreamWriter xmlWrtr = new XmlStreamWriter();
         system.assert(string.valueOf(CR108.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
         CR108.setCorspdInfo(xmlWrtr);
         CR108.setKeyParameters(xmlWrtr);
         test.stopTest();
         
     }
}