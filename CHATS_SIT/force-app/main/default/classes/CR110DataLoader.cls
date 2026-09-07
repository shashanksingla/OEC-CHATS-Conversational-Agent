/*************************************************************
Class Name	    - CR110DataLoader
Test Class	    - CR110DataLoader_Test
Called From     - ManualCorrespondenceController
Description     - Used for creating <KeyParameter> tag in xml
Author          - Rishav Maji
Created Date    - 19-Jan-2021
JIRA Ticket     - CCCAP-2213, CCCAP-2769
**************************************************************/
public with sharing class CR110DataLoader extends AbstractCorspdDataLoader {
    
    public static List<T_SBSD_INDIV__c> indivInfo = new List<T_SBSD_INDIV__c>();
    
    public CR110DataLoader(string corspdName, string caseId, integer providerId, string corrId, string corrLang, string clientId) {
        this.corspdName = corspdName;
        this.corrId = corrId;
        this.caseId = caseId;
        this.providerId = providerId;
        this.corrLang = corrLang;
        this.clientId = clientId;
    }
    
    public override string getxmldata() {
        try {
            XmlStreamWriter xmlWrtr = new XmlStreamWriter();
            xmlWrtr.writeStartDocument(null, '1.0" encoding="US-ASCII');
            xmlWrtr.writeStartElement(null, 'Correspondence', null);
            
            fetchIndivInfo(clientId);
            setClientHeaderInfo(xmlWrtr);
            setKeyParameters(xmlWrtr);
            setSignatureInfo(xmlWrtr,'C',this.caseId, null, null);
            setManualInfo(xmlWrtr, 'C', this.corrLang);
            
            xmlWrtr.writeEndElement(); 
            xmlWrtr.writeEndDocument();
            xmldata = xmlWrtr.getXmlString();
            xmlWrtr.close();
            
        } catch(exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'CR110DataLoader','Method__c'=>'getxmldata'});
            throw new corspdException('CR110 Data Loader Failed'+e.getMessage(), e);
        }
        return xmldata;
    }
    
    public override void setCorspdInfo(XmlStreamWriter xmlWrtr) {
        createElement(xmlWrtr, 'Template_Name', this.corspdName);
        createElement(xmlWrtr, 'Reason_Code', 'CR0022');
        createElement(xmlWrtr, 'CORSPD_Effective_Date', '2021-01-19');
        createElement(xmlWrtr, 'REPRINT_SW', 'N');
        createElement(xmlWrtr, 'lang_cd', 'EN');
    } 
    
    public override void setKeyParameters(XmlStreamWriter xmlWrtr) {
        xmlWrtr.writeStartElement(null, 'KeyParameter', null);
        createElement(xmlWrtr, 'CorrespondenceId', this.corrId);
        createElement(xmlWrtr, 'CaseNumber', this.caseId);
        Date dt = system.today();
        String dateRequested = dt.month() + '/' + dt.day() + '/' + dt.year();
        createElement(xmlWrtr, 'CreationDate', dateRequested);
        if(indivInfo.size() > 0) {
            createElement(xmlWrtr, 'StateId', indivInfo[0].IDN_STATE__c);
            createElement(xmlWrtr, 'SSN', indivInfo[0].NBR_SSN__c);
        } else {
            createElement(xmlWrtr, 'StateId', '');
            createElement(xmlWrtr, 'SSN', '');
        }
        xmlWrtr.writeEndElement();
    }
    
    public void fetchIndivInfo(String clientId) {
        try {
            indivInfo = [Select id, NAM_FIRST__c, NAM_LAST__c, IDN_STATE__c, NBR_SSN__c from T_SBSD_INDIV__c where Id=:clientId limit 1];
            if(indivInfo.size() > 0)
                this.PNameOverwrite = indivInfo[0].NAM_FIRST__c +' '+indivInfo[0].NAM_LAST__c;
        } catch(exception e) {
            ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'CR110DataLoader','Method__c'=>'fetchIndivInfo'});
            throw new corspdException('CR110 Data Loader Failed'+e.getMessage(), e);
        }
    }
}