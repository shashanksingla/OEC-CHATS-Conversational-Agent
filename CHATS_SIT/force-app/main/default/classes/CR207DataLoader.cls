public class CR207DataLoader extends AbstractCorspdDataLoader {
    public CR207DataLoader(String corspdName, String caseId, Integer providerId, String corrId, String cntySfid, String adjustmentId, Boolean isCase, Boolean isProvider, String clientId){
        this.corspdName = corspdName;
        this.caseId = caseId;
        this.providerId = providerId;
        this.corrId = corrId;
        this.cntySfid = cntySfid;
        this.adjustmentId = adjustmentId;
        this.isCase = isCase;
        this.isProvider = isProvider;
        this.clientId = clientId;
    }
    
    public override String getxmldata() {
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
        xmlWrtr.writeStartDocument(null, '1.0" encoding="US-ASCII');
        xmlWrtr.writeStartElement(null, 'Correspondence', null);
        if(isCase == true) {
            setClientHeaderInfo(xmlWrtr);
        }
        if(isProvider == true) {
            setProviderHeaderAdjmtCntyInfo(xmlWrtr);
        }
        setKeyParameters(xmlWrtr);
        setFlags(xmlWrtr);
        xmlWrtr.writeEndElement(); 
        xmlWrtr.writeEndDocument();
        xmldata = xmlWrtr.getXmlString();
        xmlWrtr.close();
        return xmldata;
    }
    
    public override void setCorspdInfo(XmlStreamWriter xmlWrtr) {
        createElement(xmlWrtr, 'Template_Name', this.corspdName);
        createElement(xmlWrtr, 'Reason_Code', 'CR0005');
        createElement(xmlWrtr, 'CORSPD_Effective_Date', '2017-10-18');
        createElement(xmlWrtr, 'REPRINT_SW', 'N');
        createElement(xmlWrtr, 'lang_cd', 'EN');
    }
    
    public override void setKeyParameters(XmlStreamWriter xmlWrtr) {
        String providerIds = String.valueOf(this.providerId);
        List<T_SBSD_CASE_INDIV_ROLE__c> caseStateId = new List<T_SBSD_CASE_INDIV_ROLE__c>();
        List<T_ADJMT__c> adjustmentdetails=new List<T_ADJMT__c>();
        adjustmentdetails=[select id,Name,AMT_ADJMT__c from T_ADJMT__c where id=:adjustmentId limit 1];
        xmlWrtr.writeStartElement(null, 'KeyParameter', null);
        createElement(xmlWrtr, 'CorrespondenceId', this.corrId);
        if(isCase==true) {
            createElement(xmlWrtr, 'CaseNumber','Case #                        : '+ this.caseId);
        }
        if(isProvider==true) {
            createElement(xmlWrtr, 'CaseNumber','Provider Id                  : '+ providerIds);
        }
        Date dt = system.today();
        String dateRequested = dt.month() + '/' + dt.day() + '/' + dt.year();
        createElement(xmlWrtr, 'CreationDate', 'Date                            : '+dateRequested);
        
        if(adjustmentdetails.size() == 1) {
            createElement(xmlWrtr, 'AdjustmentNum','Adjustment #               : '+ adjustmentdetails[0].Name);
        } else {
            createElement(xmlWrtr, 'AdjustmentNum','');
        }
        
        if(adjustmentdetails.size() == 1) {
            createElement(xmlWrtr, 'BalanceOwed', 'Current Balance Owed: $'+String.valueOf(adjustmentdetails[0].AMT_ADJMT__c));
        } else {
            createElement(xmlWrtr, 'BalanceOwed', '');
        }
        xmlWrtr.writeEndElement();
    }
    
    public void setFlags(XmlStreamWriter xmlWrtr){
        xmlWrtr.writeStartElement(null, 'Flags' , null);
        createElement(xmlWrtr, 'isClient', 'true');
        createElement(xmlWrtr, 'isClientDeclaration', 'true');
        createElement(xmlWrtr, 'isHeader1', 'true');
        createElement(xmlWrtr, 'isHeader2', 'false');
        createElement(xmlWrtr, 'isProvider', 'false');
        createElement(xmlWrtr, 'isProviderDeclaration', 'false');
        xmlWrtr.writeEndElement();
    }
}