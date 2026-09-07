/***************************************************
Class Name	    - CR110DataLoader_Test
Apex Class	    - CR110DataLoader
Description     - test class for CR110DataLoader
Author          - Rishav Maji
Created Date    - 27-Jan-2021
JIRA Ticket     - CCCAP-2213
****************************************************/
@isTest
public class CR110DataLoader_Test {
    static testmethod void testCR108Dataloader(){
        string corspdName= 'CR110';
        string caseId = '626262626';
        integer providerId = 123;
        string corrId = 'CR110_123';
        string corrLang ='ENG';
        string clientId='567';
        test.startTest();
        CR110DataLoader CR110 = new CR110DataLoader(corspdName, caseId, providerId, corrId, corrLang, clientId);
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        system.assert(string.valueOf(CR110.getxmldata()).contains('<?xml version="1.0" encoding="US-ASCII"?>'),'Should contain xml content');
        CR110.setCorspdInfo(xmlWrtr);
        CR110.setKeyParameters(xmlWrtr);
        CR110.setProviderInfo(xmlWrtr);
        CR110.setResponsiblePartyProviderInfo(xmlWrtr);
        CR110.setAdjmtCountyInfo(xmlWrtr,'C');
        test.stopTest();
    }
}