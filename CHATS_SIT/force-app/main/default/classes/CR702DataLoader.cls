public class CR702DataLoader extends AbstractCorspdDataLoader{
    
    public CR702DataLoader(string corspdName, string caseId, integer providerId, string corrId, string cntySfid, string corrLang ){
        this.corspdName = corspdName;
        this.caseId = caseId;
        this.providerId = providerId;
        this.corrId = corrId;
        this.cntySfid = cntySfid;
        this.corrlang = corrLang;
    }
     public override string getxmldata(){
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
		xmlWrtr.writeStartDocument(null, '1.0" encoding="US-ASCII');
        xmlWrtr.writeStartElement(null, 'Correspondence', null); 

        //setCorspdInfo(xmlWrtr);
        
        setProviderHeaderInfo(xmlWrtr);
        setKeyParameters(xmlWrtr);
        setSignatureInfo(xmlWrtr,'P',this.caseId, string.valueOf(this.providerId), this.cntySfid);
        setManualInfo(xmlWrtr, 'P', this.corrlang);
       
        xmlWrtr.writeEndElement(); 
        xmlWrtr.writeEndDocument();
		xmldata = xmlWrtr.getXmlString();
		xmlWrtr.close();
        return xmldata;
    }
        public override void setCorspdInfo(XmlStreamWriter xmlWrtr){
        createElement(xmlWrtr, 'Template_Name', this.corspdName);
        createElement(xmlWrtr, 'Reason_Code', 'CR0013');
        createElement(xmlWrtr, 'CORSPD_Effective_Date', '2017-10-17');
        createElement(xmlWrtr, 'REPRINT_SW', 'N');
        createElement(xmlWrtr, 'lang_cd', 'EN');
    }    
    public override void setKeyParameters(XmlStreamWriter xmlWrtr){
        xmlWrtr.writeStartElement(null, 'KeyParameter', null);
        string providerId = string.valueOf(this.providerId);
        createElement(xmlWrtr, 'CorrespondenceId', this.corrId);
        Date dt = system.today();
        String dateRequested = dt.month() + '/' + dt.day() + '/' + dt.year();
        createElement(xmlWrtr, 'CreationDate', dateRequested);
        createElement(xmlWrtr, 'ProviderId', providerId);
        xmlWrtr.writeEndElement();
    }

}