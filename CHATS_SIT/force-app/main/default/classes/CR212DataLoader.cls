public class CR212DataLoader extends AbstractCorspdDataLoader{
public CR212DataLoader(string corspdName, string caseId, integer providerId, string corrId, string corrLang){
        this.corspdName = corspdName;
        this.corrId = corrId;
        this.caseId = caseId;
        this.providerId = providerId;
        this.corrLang = corrLang;
    }
    public override string getxmldata(){
    try{
        XmlStreamWriter xmlWrtr = new XmlStreamWriter();
		xmlWrtr.writeStartDocument(null, '1.0" encoding="US-ASCII');
        xmlWrtr.writeStartElement(null, 'Correspondence', null); 
        setClientHeaderInfo(xmlWrtr);
        setKeyParameters(xmlWrtr);
        setSignatureInfo(xmlWrtr,'C',this.caseId, null, null);
        setManualInfoCR212(xmlWrtr, 'C', this.corrLang);
        xmlWrtr.writeEndElement(); 
        xmlWrtr.writeEndDocument();
		xmldata = xmlWrtr.getXmlString();
		xmlWrtr.close();
        
    }catch(exception e){
        ExceptionLoggingServices.captureExceptionLog(e, new Map<String,Object>{'Class__c'=>'CR107DataLoader','Method__c'=>'getxmldata'});
        throw new corspdException('CR107 Data Loader Failed'+e.getMessage(), e);
    }
    return xmldata;
    }
    
    public override void setCorspdInfo(XmlStreamWriter xmlWrtr){
        createElement(xmlWrtr, 'Template_Name', this.corspdName);
        createElement(xmlWrtr, 'Reason_Code', 'CR0004');
        createElement(xmlWrtr, 'CORSPD_Effective_Date', '2017-10-18');
        createElement(xmlWrtr, 'REPRINT_SW', 'N');
        createElement(xmlWrtr, 'lang_cd', 'EN');
    } 
	
    public override void setKeyParameters(XmlStreamWriter xmlWrtr){
        List<T_SBSD_CASE_INDIV_ROLE__c> caseStateId = new List<T_SBSD_CASE_INDIV_ROLE__c>();
        //Added order by to fetch latest active PC CCCAP-15253
        caseStateId = [	Select IDN_CASE_INDIV__r.IDN_CASE__c, IDN_CASE_INDIV__r.IDN_STATE__c, IDN_CASE_INDIV__r.IND_CRTKR__c 
                       	from T_SBSD_CASE_INDIV_ROLE__c 
                       	where IDN_CASE_INDIV__r.IDN_CASE__r.Name = :this.caseId
                       	and IDN_CASE_INDIV__r.IND_CRTKR__c = true
                        and CDE_ROLE_CASE__c = 'HOH' order by IDN_CASE_INDIV__r.DTE_END_EFFV__c Desc
                        limit 1];
        xmlWrtr.writeStartElement(null, 'KeyParameter', null);
        createElement(xmlWrtr, 'CorrespondenceId', this.corrId);
        createElement(xmlWrtr, 'CaseNumber', this.caseId);
        if(caseStateId.size() == 1) {
            createElement(xmlWrtr, 'StateId', caseStateId[0].IDN_CASE_INDIV__r.IDN_STATE__c );
        } else {
            createElement(xmlWrtr, 'StateId', '');
        }
        Date dt = system.today();
        String dateRequested = dt.month() + '/' + dt.day() + '/' + dt.year();
        createElement(xmlWrtr, 'CreationDate', dateRequested);
        caseStateId = [	Select IDN_CASE_INDIV__r.IDN_CASE__c, IDN_CASE_INDIV__r.IDN_STATE__c, IDN_CASE_INDIV__r.IND_CRTKR__c 
                       	from T_SBSD_CASE_INDIV_ROLE__c 
                       	where IDN_CASE_INDIV__r.IDN_CASE__r.Name = :this.caseId
                       	and IDN_CASE_INDIV__r.IND_CRTKR__c = true
                        and CDE_ROLE_CASE__c = 'HOH'
                        limit 1];
        
        xmlWrtr.writeEndElement();
    } 
    public void setManualInfoCR212(XmlStreamWriter xmlWrtr, string corrType, string corrLang){
        List<T_MNL_CORR_CHKLST__c> manualInfo = new List<T_MNL_CORR_CHKLST__c>();
        if (corrType == 'C'){
            manualInfo = [select toLabel(CR107_Checklist__c), toLabel(CR212_Checklist__c), toLabel(CR212_Checklist_SPN__c), toLabel(CR107_Checklist_SPN__c), CR107_OTHER_TEXT__c, DTE_DEADLINE__c FROM T_MNL_CORR_CHKLST__c WHERE IDN_CORR__c =: this.corrId];
            if(manualInfo.size() == 1){
                xmlWrtr.writeStartElement(null, 'ManualCorrespondence' , null);
                if(corrLang == 'ENG' && manualInfo[0].CR212_Checklist__c != null){
                    string cr212checklist=manualinfo[0].CR212_Checklist__c;
                    String[] listOfCR212 = cr212checklist.split('\\;');
                    for(integer i = 0 ; i<listOfCR212.size(); i++){
                        if(listOfCR212[i] != null){
                            xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                            createElement(xmlWrtr, 'CheckList', listOfCR212[i]);
                            xmlWrtr.writeEndElement();
                        }
                    } 
                    
                } else if(corrLang == 'SPN' && manualInfo[0].CR212_Checklist_SPN__c != null){
                    string cr212checklist_SPN=manualinfo[0].CR212_Checklist_SPN__c;
                    String[] listOfCR212_SPN = cr212checklist_SPN.split('\\;');
                    for(integer i = 0 ; i<listOfCR212_SPN.size(); i++){
                        if(listOfCR212_SPN[i] != null){
                            xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                            createElement(xmlWrtr, 'CheckList', listOfCR212_SPN[i]);
                            xmlWrtr.writeEndElement();
                        }
                    }
                    
                }
                
                xmlWrtr.writeEndElement();
            }
        }
    }
}