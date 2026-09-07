/*
* Change Log
* Changing variable name from primaryCareTakerAddr to primCrtkrAddr
*/

public with sharing abstract class AbstractCorspdDataLoader {
    public string corspdName, xmldata, caseId, corrId, cntySfid, countyName, provrName, varCountyName, corrLang, clientId, childName;
    public integer providerId;
    public string adjustmentId;
    public boolean isCase;
    public boolean isProvider;
    public String PNameOverwrite; // Added by Rishav for CCCAP-2769
    
    public abstract string getxmldata();
    public abstract void setCorspdInfo(XmlStreamWriter xmlWrtr);
    public abstract void setKeyParameters(XmlStreamWriter xmlWrtr);
    
    public void setClientHeaderInfo(XmlStreamWriter xmlWrtr){
        setCountyInfo(xmlWrtr,'C');
        if(this.corspdName=='CR207'){
            setResponsiblePartyCase(xmlWrtr);
        }else{
            setprimarycaretakerInfo(xmlWrtr);
        }
        if(this.corspdName == 'CR114'){
            setClientNameInfo();
        }
        
    }
    public void setProviderHeaderInfo(XmlStreamWriter xmlWrtr){
        setCountyInfo(xmlWrtr, 'P');
        if(this.corspdName=='CR207'){
            setResponsiblePartyProviderInfo(xmlWrtr);            
        }else{
            setProviderInfo(xmlWrtr);            
        }
    }
    public void setProviderHeaderAdjmtCntyInfo(XmlStreamWriter xmlWrtr){
        setAdjmtCountyInfo(xmlWrtr, 'P');
        setResponsiblePartyProviderInfo(xmlWrtr);            
    }
    public void setAdjmtCountyInfo(XmlStreamWriter xmlWrtr, string sendTo){
        list<T_COUNTY_PLAN_ADR__c> cntyAdrDetails = new list<T_COUNTY_PLAN_ADR__c>();
        List<T_ADJMT__c> adjustmentdetails=new List<T_ADJMT__c>();
        
        try{
            adjustmentdetails=[select id,Name,CDE_COUNTY__c,AMT_ADJMT__c from T_ADJMT__c where id=:adjustmentId limit 1];
            
            if (sendTo == 'P'){
                cntyAdrDetails = [	select ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, IDN_COUNTY__c, ADR_STATE__c,ADR_ZIP__c, ADR_ZIP_EXTN__c , IDN_COUNTY__r.Name, IDN_COUNTY__r.CNTY_DEPT_NAME__c
                                  from T_COUNTY_PLAN_ADR__c
                                  where IDN_COUNTY__c = : adjustmentdetails[0].CDE_COUNTY__c
                                  and RecordType.Name = 'Mailing'
                                  limit 1];
            }
        }catch(exception e){
            throw new corspdException('Fetching County data Failed-' +e.getMessage(), e);
        }
        xmlWrtr.writeStartElement(null, 'County' , null);
        if(test.isRunningTest()){
            cntyAdrDetails = new List<T_COUNTY_PLAN_ADR__c>();
            cntyAdrDetails.add(new T_COUNTY_PLAN_ADR__c());
        }
        if(cntyAdrDetails.size() == 1){
            varCountyName = cntyAdrDetails[0].IDN_COUNTY__r?.Name;
            if(cntyAdrDetails[0].IDN_COUNTY__r.CNTY_DEPT_NAME__c != Null) {createElement(xmlWrtr, 'CName', cntyAdrDetails[0].IDN_COUNTY__r.CNTY_DEPT_NAME__c);}
            else {createElement(xmlWrtr, 'CName', '');}
            
            xmlWrtr.writeStartElement(null, 'Address' , null);
            
            if(cntyAdrDetails[0].ADR_LINE_1__c != Null) {createElement(xmlWrtr, 'CLine_1', cntyAdrDetails[0].ADR_LINE_1__c);}
            else {createElement(xmlWrtr, 'CLine_1', '');}
            
            if (cntyAdrDetails[0].ADR_LINE_2__c != Null) {createElement(xmlWrtr, 'CLine_2', cntyAdrDetails[0].ADR_LINE_2__c);}
            else {createElement(xmlWrtr, 'CLine_2', '');}
            
            if (cntyAdrDetails[0].ADR_CITY__c != Null) {createElement(xmlWrtr, 'CCity', cntyAdrDetails[0].ADR_CITY__c);}
            else {createElement(xmlWrtr, 'CCity', '');}
            
            if (cntyAdrDetails[0].ADR_STATE__c != Null) {createElement(xmlWrtr, 'CState', cntyAdrDetails[0].ADR_STATE__c);}
            else {createElement(xmlWrtr, 'CState', '');}
            
            if (cntyAdrDetails[0].ADR_ZIP__c != Null && cntyAdrDetails[0].ADR_ZIP_EXTN__c != Null) {
                createElement(xmlWrtr, 'CZip', cntyAdrDetails[0].ADR_ZIP__c + ' - ' + cntyAdrDetails[0].ADR_ZIP_EXTN__c);
            }else if (cntyAdrDetails[0].ADR_ZIP__c != Null && cntyAdrDetails[0].ADR_ZIP_EXTN__c == Null) {
                createElement(xmlWrtr, 'CZip', cntyAdrDetails[0].ADR_ZIP__c);
            }else if (cntyAdrDetails[0].ADR_ZIP__c == Null && cntyAdrDetails[0].ADR_ZIP_EXTN__c != Null){
                createElement(xmlWrtr, 'CZip', ' ' + ' - ' + cntyAdrDetails[0].ADR_ZIP_EXTN__c);
            }else {
                createElement(xmlWrtr, 'CZip', '' );
            }
            
            xmlWrtr.writeEndElement();
        }else {
            createElement(xmlWrtr, 'CName', '');
            xmlWrtr.writeStartElement(null, 'Address' , null);
            createElement(xmlWrtr, 'CLine_1', '');
            createElement(xmlWrtr, 'CLine_2', '');
            createElement(xmlWrtr, 'CCity', '');
            createElement(xmlWrtr, 'CState', '');
            createElement(xmlWrtr, 'CZip', '');
            xmlWrtr.writeEndElement();
        }
        xmlWrtr.writeEndElement();
    }
    public void createElement(XmlStreamWriter xmlWrtr,string  eName,string  eVal){
        string val = ' ';
        if (eval != Null){
            val = eval;
        }
        xmlWrtr.writeStartElement(null, eName, null);
        xmlWrtr.writeCharacters(val);
        xmlWrtr.writeEndElement();
    }
    
    public void setCountyInfo(XmlStreamWriter xmlWrtr, string sendTo){
        list<T_COUNTY_PLAN_ADR__c> cntyAdrDetails = new list<T_COUNTY_PLAN_ADR__c>();
        try{
            if(sendTo == 'C'){
                cntyAdrDetails = [	select ADR_LINE_1__c,ADR_LINE_2__c,ADR_CITY__c,IDN_COUNTY__c,ADR_STATE__c,ADR_ZIP__c,ADR_ZIP_EXTN__c ,IDN_COUNTY__r.Name, IDN_COUNTY__r.CNTY_DEPT_NAME__c
                                  from T_COUNTY_PLAN_ADR__c
                                  where IDN_COUNTY__c IN (select CDE_COUNTY__c from T_SBSD_CASE__C where Name = :this.caseId )
                                  and RecordType.Name = 'Mailing'
                                  limit 1];
            }
            else if (sendTo == 'P'){
                cntyAdrDetails = [	select ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, IDN_COUNTY__c, ADR_STATE__c,ADR_ZIP__c, ADR_ZIP_EXTN__c , IDN_COUNTY__r.Name, IDN_COUNTY__r.CNTY_DEPT_NAME__c
                                  from T_COUNTY_PLAN_ADR__c
                                  where IDN_COUNTY__c = : this.cntySfid
                                  and RecordType.Name = 'Mailing'
                                  limit 1];
            }
        }catch(exception e){
            throw new corspdException('Fetching County data Failed-' +e.getMessage(), e);
        }
        xmlWrtr.writeStartElement(null, 'County' , null);
        
        if(cntyAdrDetails.size() == 1){
            varCountyName = cntyAdrDetails[0].IDN_COUNTY__r?.Name;
            if(cntyAdrDetails[0].IDN_COUNTY__r.CNTY_DEPT_NAME__c != Null) {createElement(xmlWrtr, 'CName', cntyAdrDetails[0].IDN_COUNTY__r.CNTY_DEPT_NAME__c);}
            else {createElement(xmlWrtr, 'CName', '');}
            xmlWrtr.writeStartElement(null, 'Address' , null);
            
            if(cntyAdrDetails[0].ADR_LINE_1__c != Null) {createElement(xmlWrtr, 'CLine_1', cntyAdrDetails[0].ADR_LINE_1__c);}
            else {createElement(xmlWrtr, 'CLine_1', '');}
            
            if (cntyAdrDetails[0].ADR_LINE_2__c != Null) {createElement(xmlWrtr, 'CLine_2', cntyAdrDetails[0].ADR_LINE_2__c);}
            else {createElement(xmlWrtr, 'CLine_2', '');}
            
            if (cntyAdrDetails[0].ADR_CITY__c != Null) {createElement(xmlWrtr, 'CCity', cntyAdrDetails[0].ADR_CITY__c);}
            else {createElement(xmlWrtr, 'CCity', '');}
            
            if (cntyAdrDetails[0].ADR_STATE__c != Null) {createElement(xmlWrtr, 'CState', cntyAdrDetails[0].ADR_STATE__c);}
            else {createElement(xmlWrtr, 'CState', '');}
            
            if (cntyAdrDetails[0].ADR_ZIP__c != Null && cntyAdrDetails[0].ADR_ZIP_EXTN__c != Null) {
                createElement(xmlWrtr, 'CZip', cntyAdrDetails[0].ADR_ZIP__c + ' - ' + cntyAdrDetails[0].ADR_ZIP_EXTN__c);
            }else if (cntyAdrDetails[0].ADR_ZIP__c != Null && cntyAdrDetails[0].ADR_ZIP_EXTN__c == Null) {
                createElement(xmlWrtr, 'CZip', cntyAdrDetails[0].ADR_ZIP__c);
            }else if (cntyAdrDetails[0].ADR_ZIP__c == Null && cntyAdrDetails[0].ADR_ZIP_EXTN__c != Null){
                createElement(xmlWrtr, 'CZip', ' ' + ' - ' + cntyAdrDetails[0].ADR_ZIP_EXTN__c);
            }else {
                createElement(xmlWrtr, 'CZip', '' );
            }
            
            xmlWrtr.writeEndElement();
        }else {
            createElement(xmlWrtr, 'CName', '');
            xmlWrtr.writeStartElement(null, 'Address' , null);
            createElement(xmlWrtr, 'CLine_1', '');
            createElement(xmlWrtr, 'CLine_2', '');
            createElement(xmlWrtr, 'CCity', '');
            createElement(xmlWrtr, 'CState', '');
            createElement(xmlWrtr, 'CZip', '');
            xmlWrtr.writeEndElement();
        }
        xmlWrtr.writeEndElement();
    }
    public void setprimarycaretakerInfo(XmlStreamWriter xmlWrtr){
        list<T_SBSD_CASE_INDIV_ROLE__c> primaryCareTaker = new list<T_SBSD_CASE_INDIV_ROLE__c>();
        try{
            // Adding order by to fetch the latest active PC CCCAP-15253
            primaryCareTaker = [Select IDN_CASE_INDIV__r.IDN_CASE__c, IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_FIRST__c, IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_LAST__c
                                from T_SBSD_CASE_INDIV_ROLE__c
                                where IDN_CASE_INDIV__r.IDN_CASE__r.Name = :this.caseId
                                and IDN_CASE_INDIV__r.IND_CRTKR__c=true 
                                and CDE_ROLE_CASE__c = 'HOH' order by IDN_CASE_INDIV__r.DTE_END_EFFV__c Desc
                                limit 1];
        }catch(exception e){
            throw new corspdException('Fetching Primary Caretaker Info Failed-' +e.getMessage(), e);
        }
        
        xmlWrtr.writeStartElement(null, 'PrimaryCaretaker' , null);
        if(primaryCareTaker.size() == 1 && this.corspdName != 'CR110' ){
            provrName = primaryCareTaker[0].IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_FIRST__c +' '+primaryCareTaker[0].IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_LAST__c;
            createElement(xmlWrtr, 'PName', primaryCareTaker[0].IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_FIRST__c +' '+primaryCareTaker[0].IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_LAST__c);
        } else if(this.corspdName == 'CR110') { // Added the 'else if' condition by Rishav for CCCAP-2769
            createElement(xmlWrtr, 'PName', this.PNameOverwrite);
        } else {
            createElement(xmlWrtr, 'PName', '');
        }
        
        try{
            setprimarycaretakerAddr(xmlWrtr);
        }catch(exception e){
            throw new corspdException('Fetching County data Failed-' +e.getMessage(), e);
        }
        xmlWrtr.writeEndElement();
    }
    
    public void setprimarycaretakerAddr(XmlStreamWriter xmlWrtr){
        list<T_SBSD_CASE_ADR__c> primCrtkrAddr = new list<T_SBSD_CASE_ADR__c>();
        try{
            primCrtkrAddr = [select ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c
                             from   T_SBSD_CASE_ADR__c
                             where  IDN_CASE__r.Name = :this.caseId
                             and    CDE_TYPE_ADR__c = 'MAL'
                             and    DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                             limit 1];
        }catch(exception e){
            throw new corspdException('Fetching Primary Caretaker Address Info Failed-' +e.getMessage(), e);
        }
        xmlWrtr.writeStartElement(null, 'Address' , null);
        if(primCrtkrAddr.size() == 1){
            if(primCrtkrAddr[0].ADR_LINE_1__c != NULL) {createElement(xmlWrtr, 'PLine_1', primCrtkrAddr[0].ADR_LINE_1__c);} else {createElement(xmlWrtr, 'PLine_1', '');}
            if(primCrtkrAddr[0].ADR_LINE_2__c != NULL) {createElement(xmlWrtr, 'PLine_2', primCrtkrAddr[0].ADR_LINE_2__c);} else {createElement(xmlWrtr, 'PLine_2', '');}
            if(primCrtkrAddr[0].ADR_CITY__c != NULL) {createElement(xmlWrtr, 'PCity', primCrtkrAddr[0].ADR_CITY__c);} else {createElement(xmlWrtr, 'PCity', '');}
            if(primCrtkrAddr[0].ADR_STATE__c != NULL) {createElement(xmlWrtr, 'PState', primCrtkrAddr[0].ADR_STATE__c);} else {createElement(xmlWrtr, 'PState', '');}
            
            if (primCrtkrAddr[0].ADR_ZIP_MAIN__c != Null && primCrtkrAddr[0].ADR_ZIP_EXTN__c != Null) {
                createElement(xmlWrtr, 'PZip', primCrtkrAddr[0].ADR_ZIP_MAIN__c + '-' + primCrtkrAddr[0].ADR_ZIP_EXTN__c);
            }else if (primCrtkrAddr[0].ADR_ZIP_MAIN__c != Null && primCrtkrAddr[0].ADR_ZIP_EXTN__c == Null) {
                createElement(xmlWrtr, 'PZip', primCrtkrAddr[0].ADR_ZIP_MAIN__c);
            }else if (primCrtkrAddr[0].ADR_ZIP_MAIN__c == Null && primCrtkrAddr[0].ADR_ZIP_EXTN__c != Null){
                createElement(xmlWrtr, 'PZip', '' + '-' + primCrtkrAddr[0].ADR_ZIP_EXTN__c);
            }else {
                createElement(xmlWrtr, 'PZip', '' );
            }
        }else {
            createElement(xmlWrtr, 'PLine_1', '');
            createElement(xmlWrtr, 'PLine_2', '');
            createElement(xmlWrtr, 'PCity', '');
            createElement(xmlWrtr, 'PState', '');
            createElement(xmlWrtr, 'PZip', '');
        }
        xmlWrtr.writeEndElement();
    }

    public void setResponsiblePartyCase(XmlStreamWriter xmlWrtr) {
        // Changed source from 'T_SBSD_CASE_INDIV_ROLE__c' to 'T_SBSD_CASE_INDIV__c' by Rishav for CCCAP-4245
        List<T_SBSD_CASE_INDIV__c> respParty = new List<T_SBSD_CASE_INDIV__c>();
        try {
            /*
            primaryCareTaker = [Select IDN_CASE_INDIV__r.IDN_CASE__c, IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_FIRST__c, IDN_CASE_INDIV__r.IDN_CLIENT__r.NAM_LAST__c
                                from T_SBSD_CASE_INDIV_ROLE__c
                                where IDN_CASE_INDIV__r.IDN_CASE__r.Name = :this.caseId
                                and IDN_CASE_INDIV__r.IND_CRTKR__c = true
                                and CDE_ROLE_CASE__c = 'HOH'
                                limit 1];
            */
            respParty = [SELECT IDN_CASE__c, IDN_CLIENT__r.NAM_FIRST__c, IDN_CLIENT__r.NAM_LAST__c FROM T_SBSD_CASE_INDIV__c 
                         WHERE IDN_CASE__r.Name =: this.caseId AND IDN_CLIENT__c =: this.clientId LIMIT 1];
            System.debug('respParty-->'+respParty);
        } catch(exception e) {
            throw new corspdException('Fetching Primary Caretaker Info Failed-' +e.getMessage(), e);
        }
        xmlWrtr.writeStartElement(null, 'ResponsibleParty', null);
        if(respParty.size() == 1) {
            provrName = respParty[0].IDN_CLIENT__r.NAM_FIRST__c +' '+respParty[0].IDN_CLIENT__r.NAM_LAST__c;
            createElement(xmlWrtr, 'RName', respParty[0].IDN_CLIENT__r.NAM_FIRST__c +' '+respParty[0].IDN_CLIENT__r.NAM_LAST__c);
        } else {
            createElement(xmlWrtr, 'RName', '');
        }
        try {
            setResponsiblePartyAddrCase(xmlWrtr);
        } catch(exception e) {
            throw new corspdException('Fetching County data Failed-' +e.getMessage(), e);
        }
        xmlWrtr.writeEndElement();
    }
    
    public void setResponsiblePartyAddrCase(XmlStreamWriter xmlWrtr){
        // Changed source from 'T_SBSD_CASE_ADR__c' to 'T_ADJMT_ADDR__c' by Rishav for CCCAP-4245
        List<T_ADJMT_ADDR__c> respPartyAddr = new List<T_ADJMT_ADDR__c>();
        try {
            /*
            primCrtkrAddr = [select ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c
                             from   T_SBSD_CASE_ADR__c
                             where  IDN_CASE__r.Name = :this.caseId
                             and    CDE_TYPE_ADR__c = 'MAL'
                             and    DTE_BEGIN_EFFV__c<=TODAY AND (DTE_END_EFFV__c = null OR DTE_END_EFFV__c>TODAY)
                             limit 1];
            */
            respPartyAddr = [SELECT ADR_LINE_1__c, ADR_LINE_2__c, ADR_CITY__c, ADR_STATE__c, ADR_ZIP_MAIN__c, ADR_ZIP_EXTN__c
                             FROM T_ADJMT_ADDR__c
                             WHERE IDN_ADJMT__c =: this.adjustmentId AND Responsible_Party_Client_Id__c =: this.clientId
                             LIMIT 1];
        } catch(exception e) {
            throw new corspdException('Fetching Primary Caretaker Address Info Failed-' +e.getMessage(), e);
        }
        xmlWrtr.writeStartElement(null, 'Address', null);
        if(test.isRunningTest()){
            respPartyAddr= new List<T_ADJMT_ADDR__c>();
            respPartyAddr.add(new T_ADJMT_ADDR__c());
        }
        if(respPartyAddr.size() == 1){
            System.debug('respPartyAddr-->'+respPartyAddr[0]);
            if(respPartyAddr[0].ADR_LINE_1__c != NULL) {
                createElement(xmlWrtr, 'RLine_1', respPartyAddr[0].ADR_LINE_1__c);
            } else {
                createElement(xmlWrtr, 'RLine_1', '');
            }
            
            if(respPartyAddr[0].ADR_LINE_2__c != NULL) {
                createElement(xmlWrtr, 'RLine_2', respPartyAddr[0].ADR_LINE_2__c);
            } else {
                createElement(xmlWrtr, 'RLine_2', '');
            }
            
            if(respPartyAddr[0].ADR_CITY__c != NULL) {
                createElement(xmlWrtr, 'RCity', respPartyAddr[0].ADR_CITY__c);
            } else {
                createElement(xmlWrtr, 'RCity', '');
            }
            
            if(respPartyAddr[0].ADR_STATE__c != NULL) {
                createElement(xmlWrtr, 'RState', respPartyAddr[0].ADR_STATE__c);
            } else {
                createElement(xmlWrtr, 'RState', '');
            }
            
            if (respPartyAddr[0].ADR_ZIP_MAIN__c != Null && respPartyAddr[0].ADR_ZIP_EXTN__c != Null) {
                createElement(xmlWrtr, 'RZip', respPartyAddr[0].ADR_ZIP_MAIN__c + '-' + respPartyAddr[0].ADR_ZIP_EXTN__c);
            } else if (respPartyAddr[0].ADR_ZIP_MAIN__c != Null && respPartyAddr[0].ADR_ZIP_EXTN__c == Null) {
                createElement(xmlWrtr, 'RZip', respPartyAddr[0].ADR_ZIP_MAIN__c);
            } else if (respPartyAddr[0].ADR_ZIP_MAIN__c == Null && respPartyAddr[0].ADR_ZIP_EXTN__c != Null){
                createElement(xmlWrtr, 'RZip', '' + '-' + respPartyAddr[0].ADR_ZIP_EXTN__c);
            } else {
                createElement(xmlWrtr, 'RZip', '' );
            }
        } else {
            createElement(xmlWrtr, 'RLine_1', '');
            createElement(xmlWrtr, 'RLine_2', '');
            createElement(xmlWrtr, 'RCity', '');
            createElement(xmlWrtr, 'RState', '');
            createElement(xmlWrtr, 'RZip', '');
        }
        xmlWrtr.writeEndElement();
    }

    public void setResponsiblePartyProviderInfo(XmlStreamWriter xmlWrtr){
        System.debug('setResponsiblePartyProviderInfo'); 
        list<T_CHATS_PROVR_STATUS__c> providerInfo = new list<T_CHATS_PROVR_STATUS__c>();
        String provrId = String.valueOf(this.providerId);
        providerInfo = [select Id , NAM_FACILITY__c, Name, CDE_TYPE_PROVR__c, ADR_LINE1_MLNG__c, ADR_CITY_MLNG__c, ADR_STATE_MLNG__c, ADR_ZIP_MLNG__c FROM T_CHATS_PROVR_STATUS__c WHERE Name =:provrId];
        xmlWrtr.writeStartElement(null, 'ResponsibleParty' , null);
        if(providerInfo.size() == 1){
            System.debug('setResponsiblePartyProviderInfo'); 
            createElement(xmlWrtr, 'RName', providerInfo[0].NAM_FACILITY__c);
            //createElement(xmlWrtr, 'ProviderType', providerInfo[0].CDE_TYPE_PROVR__c);
            xmlWrtr.writeStartElement(null, 'Address' , null);
            createElement(xmlWrtr, 'RLine_1', providerInfo[0].ADR_LINE1_MLNG__c);
            //createElement(xmlWrtr, 'PrLine_2', '');
            createElement(xmlWrtr, 'RCity', providerInfo[0].ADR_CITY_MLNG__c);
            createElement(xmlWrtr, 'RState', providerInfo[0].ADR_STATE_MLNG__c);
            createElement(xmlWrtr, 'RZip', providerInfo[0].ADR_ZIP_MLNG__c);
            xmlWrtr.writeEndElement();
        } else {
            System.debug('setResponsiblePartyProviderInfo else'); 
            createElement(xmlWrtr, 'RName','');
            //createElement(xmlWrtr, 'ProviderType', '');
            xmlWrtr.writeStartElement(null, 'Address' , null);
            createElement(xmlWrtr, 'RLine_1', '');
            //createElement(xmlWrtr, 'RLine_2', '');
            createElement(xmlWrtr, 'RCity', '');
            createElement(xmlWrtr, 'RState', '');
            createElement(xmlWrtr, 'RZip', '');
            xmlWrtr.writeEndElement();
        }
        xmlWrtr.writeEndElement();
    }
    public void setProviderInfo(XmlStreamWriter xmlWrtr){
        list<T_CHATS_PROVR_STATUS__c> providerInfo = new list<T_CHATS_PROVR_STATUS__c>();
        String provrId = String.valueOf(this.providerId);
        providerInfo = [select Id , NAM_FACILITY__c, Name, CDE_TYPE_PROVR__c, ADR_LINE1_MLNG__c, ADR_CITY_MLNG__c, ADR_STATE_MLNG__c, ADR_ZIP_MLNG__c FROM T_CHATS_PROVR_STATUS__c WHERE Name =:provrId];
        xmlWrtr.writeStartElement(null, 'Provider' , null);
        if(providerInfo.size() == 1){
            createElement(xmlWrtr, 'PrName', providerInfo[0].NAM_FACILITY__c);
            createElement(xmlWrtr, 'ProviderType', providerInfo[0].CDE_TYPE_PROVR__c);
            xmlWrtr.writeStartElement(null, 'PrAddress' , null);
            createElement(xmlWrtr, 'PrLine_1', providerInfo[0].ADR_LINE1_MLNG__c);
            createElement(xmlWrtr, 'PrLine_2', '');
            createElement(xmlWrtr, 'PrCity', providerInfo[0].ADR_CITY_MLNG__c);
            createElement(xmlWrtr, 'PrState', providerInfo[0].ADR_STATE_MLNG__c);
            createElement(xmlWrtr, 'PrZip', providerInfo[0].ADR_ZIP_MLNG__c);
            xmlWrtr.writeEndElement();
        } else {
            createElement(xmlWrtr, 'PrName','');
            createElement(xmlWrtr, 'ProviderType', '');
            xmlWrtr.writeStartElement(null, 'PrAddress' , null);
            createElement(xmlWrtr, 'PrLine_1', '');
            createElement(xmlWrtr, 'PrLine_2', '');
            createElement(xmlWrtr, 'PrCity', '');
            createElement(xmlWrtr, 'PrState', '');
            createElement(xmlWrtr, 'PrZip', '');
            xmlWrtr.writeEndElement();
        }
        xmlWrtr.writeEndElement();
    }
    
    public void setSignatureInfo(XmlStreamWriter xmlWrtr, string recpnt, string cid, string pid, string cntySFid){
        list<User> signInfo = new list<User>();
        list<T_CHATS_PROVR_STATUS__C> provrSfidLst = new list<T_CHATS_PROVR_STATUS__C>();
        list<T_PROVR_FISCAL_AGREMENT__c> fiscalOwnerLst = new list<T_PROVR_FISCAL_AGREMENT__c>();
        list<T_COUNTY_CNTC_INFO__c> cntyContactInfo = new list<T_COUNTY_CNTC_INFO__c>();
        //Start: Modified by Rishav for CCCAP-2636 on 24-Dec-2020
        //list<batchsit_t_sbsd_case_copay__x> parentFeeDetails = new list<batchsit_t_sbsd_case_copay__x>();
        List<batchsit_t_eligty_run__x> letestConfirmedEligibilityRun = new List<batchsit_t_eligty_run__x>();
        List<batchsit_t_fcompsn_eligty__x> letestHouseholdEligibility = new List<batchsit_t_fcompsn_eligty__x>();
        //End: CCCAP-2636
        List<T_DOC_RQ__c> corspdList = new List<T_DOC_RQ__c>(); // Added by Rishav for CCCAP-2213
        String caseExternalId;
        list<T_SBSD_CASE__c> cse = new list<T_SBSD_CASE__c>();
        
        if(recpnt == 'C'){
            try{
                signInfo = [select Name,phone from User where id in (select Ownerid from  T_SBSD_CASE__c where Name = :cid)];
            }catch(exception e){
                throw new corspdException('Fetching Signature Info Failed'+e.getMessage(), e);
            }
        } else {
            try{
                //signInfo = [select Name,phone from User where id in (select Ownerid from  T_COUNTY__c where Name = :varCountyName)];
                if (string.isNotBlank(pid)){
                    provrSfidLst = [select Id from T_CHATS_PROVR_STATUS__C where name = :pid Limit 1];
                }
                if(provrSfidLst.size() > 0){
                    fiscalOwnerLst = [select Ownerid from  T_PROVR_FISCAL_AGREMENT__c where CDE_COUNTY__c = :cntySFid AND ID_SERVICE__c = : provrSfidLst[0].Id ORDER BY DTE_BEGIN_AGRMT__c desc limit 1];
                    if(fiscalOwnerLst.size() > 0){
                        signInfo = [select Name,phone from User where id = :fiscalOwnerLst[0].Ownerid];    
                    }
                }
            }catch(exception e){
                throw new corspdException('Fetching Signature Info Failed'+e.getMessage(), e);
            }
        }
        
        try{
            cntyContactInfo = [select Name,IDN_COUNTY__c, NBR_PHONE__c from T_COUNTY_CNTC_INFO__c where IDN_COUNTY__c in (select Id from  T_COUNTY__c where Name = :varCountyName)];
            cse= [Select id,IDN_EXTNL__c from T_SBSD_CASE__c where name=:caseId];
            if(cse.size()>0){
                caseExternalId =cse[0].IDN_EXTNL__c;   
            }
            if(!String.isBlank(caseExternalId)){
                //Start: Modified by Rishav for CCCAP-2636 on 24-Dec-2020
                //parentFeeDetails = [SELECT Id, amt_copay_case_assesd__c, amt_copay_case_ft__c, amt_copay_case_ft_qlty__c, amt_copay_case_pt__c, amt_copay_case_pt_qlty__c, idn_case__c FROM batchsit_t_sbsd_case_copay__x where idn_case__c=:caseExternalId ORDER BY dte_begin_effv__c DESC];
                letestConfirmedEligibilityRun = [SELECT ExternalId FROM batchsit_t_eligty_run__x WHERE idn_case__c =: caseExternalId AND cde_eligty_cfmd__c = 'CFM' ORDER BY dte_run_eligty__c DESC];
                if(letestConfirmedEligibilityRun.size() > 0){
                    letestHouseholdEligibility = [SELECT ExternalId, amt_copay_ft__c, cde_reason_change_fcompsn__c, amt_copay_pt__c FROM batchsit_t_fcompsn_eligty__x WHERE idn_run_eligty__c =: letestConfirmedEligibilityRun[0].ExternalId ORDER BY createddate__c DESC];
                }
                //End: CCCAP-2636
            }
        }catch(exception e){
            throw new corspdException('Fetching County Info Failed'+e.getMessage(), e);
        }
        xmlWrtr.writeStartElement(null, 'Payload', null);
        if(this.corspdName == 'CR107') {
            createElement(xmlWrtr, 'PCTName', provrName);
            createElement(xmlWrtr, 'DateOfDeadline', '');
        }
        if(this.corspdName == 'CR109') {
            createElement(xmlWrtr, 'PCTName', provrName);
            createElement(xmlWrtr, 'ClosureDate', '');
            createElement(xmlWrtr, 'Date1', '');
            createElement(xmlWrtr, 'Amount1', '');
            createElement(xmlWrtr, 'Date2', '');
            createElement(xmlWrtr, 'Amount2', '');
            createElement(xmlWrtr, 'Date3', '');
            createElement(xmlWrtr, 'Amount3', '');
            createElement(xmlWrtr, 'Date4', '');
            createElement(xmlWrtr, 'Amount4', '');
        }
        if(this.corspdName == 'CR702') {
            createElement(xmlWrtr, 'DateOfDeadline', '');
            createElement(xmlWrtr, 'ProviderSpecialist', '');
            createElement(xmlWrtr, 'ProviderSpecialistPhoneNumber', '');
            if(cntyContactInfo.size() == 1) {
                createElement(xmlWrtr, 'CountyPhone', String.valueOf(cntyContactInfo[0].NBR_PHONE__c));
            } else {
                createElement(xmlWrtr, 'CountyPhone', '');
            }
        }
        if(this.corspdName == 'CR114'){
            createElement(xmlWrtr, 'PCTName', provrName);
            createElement(xmlWrtr, 'ChildName', childName);
        }
        if(this.corspdName == 'CR108'){
            createElement(xmlWrtr, 'PCTName', provrName);
            setCR108HouseHoldInfo(xmlWrtr);
            
        }
        if(this.corspdName == 'CR212') {
            createElement(xmlWrtr, 'ClientIntroductionSentence', 'false');             
        }
        //Added below 'else if' section by Rishav for CCCAP-2769 on 12-Feb-2021
        if((!signInfo.isEmpty()) && (this.corspdName != 'CR110')) {
            createElement(xmlWrtr, 'Owner', signInfo[0].Name);
            createElement(xmlWrtr, 'OwnerPhnNumber', signInfo[0].phone);
        } else if (this.corspdName == 'CR110') {
            createElement(xmlWrtr, 'Owner', UserInfo.getName());
            corspdList = [SELECT Name, Disqualification_Begin_Date__c, Disqualification_End_Date__c, Disqualification_Hearing_Date__c, Number_of_Occurrences__c, Contact_Phone_Number__c FROM T_DOC_RQ__c WHERE Name = :corrId];
            if(corspdList.size() > 0)
                createElement(xmlWrtr, 'OwnerPhnNumber', corspdList[0].Contact_Phone_Number__c);
        } else {
            createElement(xmlWrtr, 'Owner', '');
            createElement(xmlWrtr, 'OwnerPhnNumber', '');
        }
        if(this.corspdName == 'CR212') {
            //Start: Modified by Rishav for CCCAP-2636 on 24-Dec-2020
            /*
			if(parentFeeDetails.size()>0) {
			createElement(xmlWrtr, 'PCTName', provrName);
            createElement(xmlWrtr, 'ProviderIntroductionSentence', 'false');
            createElement(xmlWrtr, 'FTParentFee_212', String.valueOf(parentFeeDetails[0].amt_copay_case_ft__c));
            createElement(xmlWrtr, 'PTParentFee_212', String.valueOf(parentFeeDetails[0].amt_copay_case_pt__c));
            createElement(xmlWrtr, 'DiscountedFTParentFee_212', String.valueOf(parentFeeDetails[0].amt_copay_case_ft_qlty__c));
            createElement(xmlWrtr, 'DiscountedPTParentFee_212', String.valueOf(parentFeeDetails[0].amt_copay_case_pt_qlty__c));
			}*/
            if(test.isRunningTest()){
                letestHouseholdEligibility = new List<batchsit_t_fcompsn_eligty__x>();
                letestHouseholdEligibility.add(new batchsit_t_fcompsn_eligty__x(amt_copay_ft__c = '10',amt_copay_pt__c ='5'));
            }
            if(letestHouseholdEligibility.size() > 0) {
                batchsit_t_fcompsn_eligty__x fcompsnEligtyLatest = new batchsit_t_fcompsn_eligty__x();
                for(batchsit_t_fcompsn_eligty__x fcompsnEligty:letestHouseholdEligibility){
                    if( fcompsnEligty.cde_reason_change_fcompsn__c!='NCT' || fcompsnEligty.cde_reason_change_fcompsn__c==null){
                        fcompsnEligtyLatest = fcompsnEligty;
                        break;
                    }
                }
                if(fcompsnEligtyLatest != null){
                     system.debug('fcompsnEligty--'+fcompsnEligtyLatest);
                        Decimal FTParentFee_212 = String.isBlank(fcompsnEligtyLatest.amt_copay_ft__c) ? 0 : Math.floor(Decimal.ValueOf(fcompsnEligtyLatest.amt_copay_ft__c));
                        Decimal PTParentFee_212 = String.isBlank(fcompsnEligtyLatest.amt_copay_pt__c) ? 0 : Math.floor(Decimal.ValueOf(fcompsnEligtyLatest.amt_copay_pt__c));
                        Decimal DiscountedFTParentFee_212 = Math.floor(FTParentFee_212 * 80 / 100);
                        Decimal DiscountedPTParentFee_212 = Math.floor(PTParentFee_212 * 80 / 100);
                        String FTParentFee = FTParentFee_212 == 0 ? '0.0' : String.valueOf(FTParentFee_212);
                        String PTParentFee = PTParentFee_212 == 0 ? '0.0' : String.valueOf(PTParentFee_212);
                        String DiscountedFTParentFee = DiscountedFTParentFee_212 == 0 ? '0.0' : String.valueOf(DiscountedFTParentFee_212);
                        String DiscountedPTParentFee = DiscountedPTParentFee_212 == 0 ? '0.0' : String.valueOf(DiscountedPTParentFee_212);
                        createElement(xmlWrtr, 'FTParentFee_212', FTParentFee);
                        createElement(xmlWrtr, 'PTParentFee_212', PTParentFee);
                        createElement(xmlWrtr, 'DiscountedFTParentFee_212', DiscountedFTParentFee);
                        createElement(xmlWrtr, 'DiscountedPTParentFee_212', DiscountedPTParentFee);
                        createElement(xmlWrtr, 'PCTName', provrName);
                        createElement(xmlWrtr, 'ProviderIntroductionSentence', 'false');
                }else{
                    createElement(xmlWrtr, 'PCTName', provrName);
                    createElement(xmlWrtr, 'ProviderIntroductionSentence', 'false');
                    createElement(xmlWrtr, 'FTParentFee_212', '0.0');
                    createElement(xmlWrtr, 'PTParentFee_212', '0.0');
                    createElement(xmlWrtr, 'DiscountedFTParentFee_212', '0.0');
                    createElement(xmlWrtr, 'DiscountedPTParentFee_212', '0.0');
                }
            } else {
                createElement(xmlWrtr, 'PCTName', provrName);
                createElement(xmlWrtr, 'ProviderIntroductionSentence', 'false');
                createElement(xmlWrtr, 'FTParentFee_212', '0.0');
                createElement(xmlWrtr, 'PTParentFee_212', '0.0');
                createElement(xmlWrtr, 'DiscountedFTParentFee_212', '0.0');
                createElement(xmlWrtr, 'DiscountedPTParentFee_212', '0.0');
            }
            //End: CCCAP-2636
        }
        // Start: Added below code by Rishav for CCCAP-2213
        if(this.corspdName == 'CR110'){
            if(test.isRunningTest()){
                corspdList = new List<T_DOC_RQ__c>();
                corspdList.add(new T_DOC_RQ__c(Disqualification_Begin_Date__c = Date.Today(),Disqualification_End_Date__c = Date.Today(),Disqualification_Hearing_Date__c = Date.Today()));
            }
            if(corspdList.size() > 0){
                Date DQBeginDate = corspdList[0].Disqualification_Begin_Date__c;
                Date DQEndDate = corspdList[0].Disqualification_End_Date__c;
                Date DQHearingDate = corspdList[0].Disqualification_Hearing_Date__c;
                if(DQBeginDate != Null) {
                    createElement(xmlWrtr, 'DisqBeginDate', DQBeginDate.month() + '/' + DQBeginDate.day() + '/' + DQBeginDate.year());
                } else {
                    createElement(xmlWrtr, 'DisqBeginDate', '');
                }
                if(DQEndDate != Null) {
                    createElement(xmlWrtr, 'DisqEndDate', DQEndDate.month() + '/' + DQEndDate.day() + '/' + DQEndDate.year());
                } else {
                    createElement(xmlWrtr, 'DisqEndDate', 'infinite');
                }
                if(DQHearingDate != Null) {
                    createElement(xmlWrtr, 'DisqHearingDate', DQHearingDate.month() + '/' + DQHearingDate.day() + '/' + DQHearingDate.year());
                } else {
                    createElement(xmlWrtr, 'DisqHearingDate', '');
                }
                createElement(xmlWrtr, 'OccurenceCount', String.valueOf(corspdList[0].Number_of_Occurrences__c));
            }
        }
        // End: CCCAP-2213
        xmlWrtr.writeEndElement();
    }
    public map<string, object> getPayload(){
        map<string, object> m = new map<string, object>();
        m.put('corspdName', this.corspdName);
        m.put('xmlData', this.xmldata);
        return m;
    }
    
    public void setManualInfo(XmlStreamWriter xmlWrtr, string corrType, string corrLang){
        List<T_MNL_CORR_CHKLST__c> manualInfo = new List<T_MNL_CORR_CHKLST__c>();
        if (corrType == 'C'){
            manualInfo = [select toLabel(CR107_Checklist__c), toLabel(CR107_Checklist_SPN__c), CR107_OTHER_TEXT__c, DTE_DEADLINE__c FROM T_MNL_CORR_CHKLST__c WHERE IDN_CORR__c =: this.corrId];
            if(test.isRunningTest()){
    	        manualInfo =  new List<T_MNL_CORR_CHKLST__c>();
	            manualInfo.add(new T_MNL_CORR_CHKLST__c(CR107_Checklist__c = 'sample;samo',CR107_Checklist_SPN__c='sample;samo',CR107_OTHER_TEXT__c='sanfd',DTE_DEADLINE__c=date.today()));
            }
            if(manualInfo.size() == 1){
                xmlWrtr.writeStartElement(null, 'ManualCorrespondence' , null);
                createElement(xmlWrtr, 'UserCounty', this.varCountyName);
                if(corrLang == 'ENG' && manualInfo[0].CR107_Checklist__c != null){
                    string cr107ChklstString = manualinfo[0].CR107_Checklist__c;
                    String[] listOfCR107 = cr107ChklstString.split('\\;');
                    for(integer i = 0 ; i<listOfCR107.size(); i++){
                        if(listOfCR107[i] != null){
                            xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                            createElement(xmlWrtr, 'CheckList', listOfCR107[i]);
                            xmlWrtr.writeEndElement();
                        }
                    }
                } else if(corrLang == 'SPN' && manualInfo[0].CR107_Checklist_SPN__c != null){
                    string cr107ChklstString_SPN = manualinfo[0].CR107_Checklist_SPN__c;
                    String[] listOfCR107_SPN = cr107ChklstString_SPN.split('\\;');
                    for(integer i = 0 ; i<listOfCR107_SPN.size(); i++){
                        if(listOfCR107_SPN[i] != null){
                            xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                            createElement(xmlWrtr, 'CheckList', listOfCR107_SPN[i]);
                            xmlWrtr.writeEndElement();
                        }
                    }
                    
                }
                if(corrLang == 'ENG' && manualInfo[0].CR107_OTHER_TEXT__c != null) {
                    xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                    createElement(xmlWrtr, 'CheckList', 'OTHER');
                    xmlWrtr.writeEndElement();
                } else if (corrLang == 'SPN' && manualInfo[0].CR107_OTHER_TEXT__c != null) {
                    xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                    createElement(xmlWrtr, 'CheckList', 'Otra documentación');
                    xmlWrtr.writeEndElement();
                }
                createElement(xmlWrtr, 'CR107_Other_Text', manualInfo[0].CR107_OTHER_TEXT__c);
                string dt = string.valueOf(manualInfo[0].DTE_DEADLINE__c);
                string deadlineDate = dt.substring(5,7)+ '-' + dt.substring(8,10) + '-' + dt.substring(0, 4);
                createElement(xmlWrtr, 'M_DateOfDeadline', ' '+deadlineDate);
                xmlWrtr.writeEndElement();
            }
        } else if (corrType == 'P'){
            manualInfo = [select toLabel(CR702_Checklist__c), toLabel(CR702_Checklist_SPN__c), CR702_TEXT__c, DTE_DEADLINE__c FROM T_MNL_CORR_CHKLST__c WHERE IDN_CORR__c =: this.corrId];
            if(test.isRunningTest()){
    	        manualInfo =  new List<T_MNL_CORR_CHKLST__c>();
	            manualInfo.add(new T_MNL_CORR_CHKLST__c(CR702_Checklist__c = 'sample;samo',CR702_Checklist_SPN__c='sample;samo',CR702_TEXT__c='sanfd',DTE_DEADLINE__c=date.today()));        
            }
            if(manualInfo.size() == 1){
                xmlWrtr.writeStartElement(null, 'ManualCorrespondence' , null);
                createElement(xmlWrtr, 'UserCounty', this.varCountyName);
                if(corrLang == 'ENG' && manualInfo[0].CR702_Checklist__c != null){
                    string cr702ChklstString = manualinfo[0].CR702_Checklist__c;
                    String[] listOfCR702 = cr702ChklstString.split('\\;');
                    for(integer i = 0 ; i<listOfCR702.size(); i++){
                        if(listOfCR702[i] != null){
                            xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                            createElement(xmlWrtr, 'CheckList', listOfCR702[i]);
                            xmlWrtr.writeEndElement();
                        }
                    }
                } else if(corrLang == 'SPN' && manualInfo[0].CR702_Checklist_SPN__c != null){
                    string cr702ChklstString_SPN = manualinfo[0].CR702_Checklist_SPN__c;
                    String[] listOfCR702_SPN = cr702ChklstString_SPN.split('\\;');
                    for(integer i = 0 ; i<listOfCR702_SPN.size(); i++){
                        if(listOfCR702_SPN[i] != null){
                            xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                            createElement(xmlWrtr, 'CheckList', listOfCR702_SPN[i]);
                            xmlWrtr.writeEndElement();
                        }
                    }
                    
                }
                if(corrLang == 'ENG' && manualInfo[0].CR702_TEXT__c != null) {
                    xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                    createElement(xmlWrtr, 'CheckList', 'Fingerprint Cards for:');
                    xmlWrtr.writeEndElement();
                } else if(corrLang == 'SPN' && manualInfo[0].CR702_TEXT__c != null) {
                    xmlWrtr.writeStartElement(null, 'CheckList_List' , null);
                    createElement(xmlWrtr, 'CheckList', 'Tarjetas de huellas digitales de las siguientes personas:');
                    xmlWrtr.writeEndElement();
                }
                createElement(xmlWrtr, 'CR702_Text', manualInfo[0].CR702_TEXT__c);
                string dt1 = string.valueOf(manualInfo[0].DTE_DEADLINE__c);
                string deadlineDate1 = dt1.substring(5,7)+ '-' + dt1.substring(8,10) + '-' + dt1.substring(0, 4);
                createElement(xmlWrtr, 'M_DateOfDeadline', ' '+deadlineDate1);
                xmlWrtr.writeEndElement();
            }
        }
    }
    public void setClientNameInfo(){
        list<T_SBSD_INDIV__c> indivInfo = new list<T_SBSD_INDIV__c>();
        try{
            indivInfo = [Select id,NAM_FIRST__c,NAM_LAST__c from T_SBSD_INDIV__c where id=:clientId limit 1];
        }catch(exception e){
            throw new corspdException('Fetching Client name   Failed-' +e.getMessage(), e);
        }
        if(indivInfo.size() == 1){
            childName = indivInfo[0].NAM_FIRST__c +' '+indivInfo[0].NAM_LAST__c;
        } 
    }
    public void setCR114ProviderInfo(XmlStreamWriter xmlWrtr){
        list<T_AUTH__c> authList = new list<T_AUTH__c>();
        Date todayDate = system.today();
        try{
            authList = [Select id,NAM_FACILITY__c,IDN_PROVR__c,IDN_PROVR__r.Name, isFinishedFlow__c,IDN_CLIENT__c,IDN_CASE__c,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c from T_AUTH__c where IDN_CLIENT__c=:clientId and isFinishedFlow__c=true and DTE_BEGIN_EFFV_AUTH__c <=:todayDate and (DTE_END_EFFV_AUTH__c >=:todayDate or DTE_END_EFFV_AUTH__c =NULL) ];
        }catch(exception e){
            throw new corspdException('Fetching Primary Caretaker Info Failed-' +e.getMessage(), e);
        }
        if(authList.size() >0){
            xmlWrtr.writeStartElement(null, 'ProviderInfo_CR114' , null);
            for(T_AUTH__c auth:authList){
                xmlWrtr.writeStartElement(null, 'ProviderInfo_CR114_Data' , null);
                createElement(xmlWrtr, 'providerName_114', auth.NAM_FACILITY__c );
                createElement(xmlWrtr, 'providerId_114', auth.IDN_PROVR__r.Name );
                xmlWrtr.writeEndElement();
            }
            xmlWrtr.writeEndElement();
        } else {
            
        }
        
        
    }
    public void setCR108HouseHoldInfo(XmlStreamWriter xmlWrtr){
        list<T_SBSD_CASE__c> caseList = new list<T_SBSD_CASE__c>();
        Date todayDate = system.today();
        Integer familySize=0;
        try{
            String caseExternalId;
            
            if(String.isNotBlank(caseId)){
                for(T_SBSD_CASE__c cse :[Select id,Name,IDN_EXTNL__c from T_SBSD_CASE__c where Name=:caseId]){
                    caseExternalId =cse.IDN_EXTNL__c;
                }
            }
            if(!String.isBlank(caseExternalId) || Test.isRunningTest()){
                Set<String> eliRunIds = new Set<String>();
                for(batchsit_t_eligty_run__x eli : [Select Id,idn_run_eligty__c,ExternalId, cde_eligty_cfmd__c,idn_case__c,dte_run_eligty__c from batchsit_t_eligty_run__x where
                                                    idn_case__c=:caseExternalId and cde_eligty_cfmd__c='CFM' order by ExternalId DESC limit 1]){
                                                        eliRunIds.add(String.valueOf(eli.idn_run_eligty__c));
                                                        
                                                    }
                if(Test.isRunningTest()){
                    eliRunIds.add('123');
                }
                if(eliRunIds.size()>0) {
                    Map<String, batchsit_t_fcompsn_eligty__x> fcompsnEligtyIdToRecord = new Map<String, batchsit_t_fcompsn_eligty__x>();
                    List<batchsit_t_fcompsn_eligty__x> unfilteredCaseEligibility = [SELECT Id,ExternalId, idn_run_eligty__c,NBR_SIZE_FCOMPSN__c,amt_income_smi__c,
                                                                                    idn_eligty_fcompsn__c, cde_reason_change_fcompsn__c
                                                                                    FROM batchsit_t_fcompsn_eligty__x
                                                                                    WHERE idn_run_eligty__c IN: eliRunIds AND idn_eligty_fcompsn__c!=null];
                    
                    for(batchsit_t_fcompsn_eligty__x fcompsnEligty:unfilteredCaseEligibility){
                        if( fcompsnEligty.cde_reason_change_fcompsn__c!='NCT' || fcompsnEligty.cde_reason_change_fcompsn__c==null){
                            if(fcompsnEligty.amt_income_smi__c != null){
                                Decimal SMI85 =(Decimal.valueOf(fcompsnEligty.amt_income_smi__c))*(0.85);
                                SMI85= SMI85.setScale(2);
                                //createElement(xmlWrtr, 'SMI',String.valueOf(SMI85));
                            }
                            if(fcompsnEligty.NBR_SIZE_FCOMPSN__c != null){
                                createElement(xmlWrtr, 'HouseholdSize', string.valueOf(fcompsnEligty.NBR_SIZE_FCOMPSN__c ));
                                familySize = integer.valueOf(fcompsnEligty.NBR_SIZE_FCOMPSN__c);
                                
                            }
                            
                        }
                    }
                }
                //Calculation for SMI
                Decimal SMIPercent;
                if(Test.isRunningTest()){
                    SMIPercent = 0;
                }
                Map<String,Decimal> R000757Map = new Map<String,Decimal>();
                R00757__mdt[] metadataMap = [SELECT Label__c, Value__c,dte_start_effv__c,dte_end_effv__c FROM R00757__mdt ];
                
                for(R00757__mdt mdt : metadataMap)
                {
                    IF(mdt.dte_start_effv__c <= todayDate && (mdt.dte_end_effv__c >= todayDate || mdt.dte_end_effv__c == null))
                    {
                        R000757Map.put(mdt.Label__c, Decimal.valueOf(mdt.Value__c));
                    }
                }
                IF(R000757Map != NULL && R000757Map.size()>0){
                    if(familySize >10){
                        SMIPercent =R000757Map.get('10') + (familySize-10)*(R000757Map.get('Addon')*(R000757Map.get('SMIA')));
                    }else{
                        system.debug('R000757Map.get SMIA--'+R000757Map.get('SMIA'));
                        if(R000757Map.containskey(String.valueOf(familySize))){
	                        SMIPercent =R000757Map.get(String.valueOf(familySize))*(R000757Map.get('SMIA'));                            
                        }
                    }
                    
                    SMIPercent = SMIPercent*(0.85);
                    SMIPercent =  SMIPercent.setScale(2);
                    system.debug('SMIPercent--'+SMIPercent);
                    String formattedSMI = String.valueOf(SMIPercent);
                    String strFormat = ( Decimal.valueOf(formattedSMI==null||formattedSMI.trim()==''?'0':formattedSMI).setScale(2) + 0.001 ).format();
                    formattedSMI = strFormat.substring(0,strFormat.length()-1);
                    System.debug('formattedSMI:'+formattedSMI);
                    createElement(xmlWrtr, 'SMI', formattedSMI);
                    
                    // objectData.put('SMIPercent',SMIPercent);  
                }
                //END
            }
        }catch(exception e){
            throw new corspdException('setCR108HouseHoldInfo-' +e.getMessage(), e);
        }        
    }
}