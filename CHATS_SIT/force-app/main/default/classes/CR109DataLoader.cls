public with sharing class CR109DataLoader extends AbstractCorspdDataLoader{
    
    public CR109DataLoader(string corspdName, string caseId, integer providerId, string corrId ){
        this.corspdName = corspdName;
        this.caseId = caseId;
        this.providerId = providerId;
        this.corrId = corrId;
    }
    public override string getxmldata(){
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
	    xmlWrtr.writeStartDocument(null, '1.0" encoding="US-ASCII');
        xmlWrtr.writeStartElement(null, 'Correspondence', null); 

        //setCorspdInfo(xmlWrtr);
        
        setClientHeaderInfo(xmlWrtr);
        setKeyParameters(xmlWrtr);
        setSignatureInfo(xmlWrtr, 'C',this.caseId, null, null);
        
        xmlWrtr.writeEndElement(); 
        xmlWrtr.writeEndDocument();
		xmldata = xmlWrtr.getXmlString();
		xmlWrtr.close();
        return xmldata;
    }
    public override void setCorspdInfo(XmlStreamWriter xmlWrtr){
        createElement(xmlWrtr, 'Template_Name', this.corspdName);
        createElement(xmlWrtr, 'Reason_Code', 'CR0005');
        createElement(xmlWrtr, 'CORSPD_Effective_Date', '2017-10-18');
        createElement(xmlWrtr, 'REPRINT_SW', 'N');
        createElement(xmlWrtr, 'lang_cd', 'EN');
    }    
    public override void setKeyParameters(XmlStreamWriter xmlWrtr){
        List<T_SBSD_CASE_INDIV_ROLE__c> caseStateId = new List<T_SBSD_CASE_INDIV_ROLE__c>();
        xmlWrtr.writeStartElement(null, 'KeyParameter', null);
        createElement(xmlWrtr, 'CorrespondenceId', this.corrId);
        createElement(xmlWrtr, 'CaseNumber', this.caseId);
        Date dt = system.today();
        String dateRequested = dt.month() + '/' + dt.day() + '/' + dt.year();
        createElement(xmlWrtr, 'CreationDate', dateRequested);
        //Added order by to fetch latest active PC CCCAP-15253
        caseStateId = [	Select IDN_CASE_INDIV__r.IDN_CASE__c, IDN_CASE_INDIV__r.IDN_STATE__c, IDN_CASE_INDIV__r.IND_CRTKR__c 
                       	from T_SBSD_CASE_INDIV_ROLE__c 
                       	where IDN_CASE_INDIV__r.IDN_CASE__r.Name = :this.caseId
                       	and IDN_CASE_INDIV__r.IND_CRTKR__c = true
                        and CDE_ROLE_CASE__c = 'HOH' order by IDN_CASE_INDIV__r.DTE_END_EFFV__c Desc
                        limit 1];
        if(caseStateId.size() == 1) {
            createElement(xmlWrtr, 'StateId', caseStateId[0].IDN_CASE_INDIV__r.IDN_STATE__c );
        } else {
            createElement(xmlWrtr, 'StateId', '');
        }
        xmlWrtr.writeEndElement();
    }
}