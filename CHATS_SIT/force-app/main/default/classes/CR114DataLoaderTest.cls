@isTest
public class CR114DataLoaderTest {
static testmethod void testCR114Dataloader(){
         string corspdName= 'CR114';
         string caseId = 'CA-1';
         integer providerId = 123;
         string corrId = 'Adams';
		 string clientId='567';
    	 string corrLang ='EN';
         test.startTest();
       	 CR114DataLoader CR114 = new CR114DataLoader(corspdName, caseId, providerId, corrId,corrLang,clientId);
         XmlStreamWriter xmlWrtr = new XmlStreamWriter();
         system.assert(string.valueOf(CR114.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
         CR114.setCorspdInfo(xmlWrtr);
         CR114.setKeyParameters(xmlWrtr);
         test.stopTest();
         
     }
}