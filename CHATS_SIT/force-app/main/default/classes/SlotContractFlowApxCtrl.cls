public with sharing class SlotContractFlowApxCtrl {
    
    //method to get initial details
    @AuraEnabled
    public static LightningServerResponse getInitData(string recordid)
    {
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message;  
        
        List<T_CHATS_PROVR_STATUS__c> provider=[SELECT Id ,name,NAM_FACILITY__c,(select id,CDE_COUNTY__r.name,CDE_TYPE_STATUS__c from Provider_Fiscal_Agreements__r where CDE_TYPE_STATUS__c !='CLS' order by CDE_COUNTY__r.name) from T_CHATS_PROVR_STATUS__c where id= :recordid];
        
        Map<id,string> countySet=new Map<id,string>();
        
        if(provider[0].Provider_Fiscal_Agreements__r!=null && !provider[0].Provider_Fiscal_Agreements__r.isEmpty())
        {
            for(T_PROVR_FISCAL_AGREMENT__c indiFA : provider[0].Provider_Fiscal_Agreements__r)
            {
                if(!countySet.containsKey(indiFA.CDE_COUNTY__c))
                {
                    countySet.put(indiFA.CDE_COUNTY__c,indiFA.CDE_COUNTY__r.name );
                }
            }
        }
        
        Map<string,string> plValues = getPicklistDetails('T_SLOT_CONTRACT__c','CNT_DAYS_OF_WEEK__c');
        Map<string,string> cLevel =getPicklistDetails('T_SLOT_CONTRACT__c','CDE_CARE_LEVEL__c');
        Map<string,string> cUnit = getPicklistDetails('T_SLOT_CONTRACT__c','CDE_CARE_UNIT__c');
        Map<string,string> rType =getPicklistDetails('T_SLOT_CONTRACT__c','CDE_RATE_TYPE__c');
        Map<string,string> pType = getPicklistDetails('T_SLOT_CONTRACT__c','CDE_PRG_TYPE__c');
        
        List<T_SLOT_CONTRACT__c> scList=[select id , Name from T_SLOT_CONTRACT__c order by Name  desc limit 1];
        
        if(scList!=null && !scList.isEmpty())
        {
            Integer original,nowle,diff;
            String seq=String.valueof(Integer.valueOf(scList[0].Name)+1);
            original=String.valueOf(scList[0].Name).length();
            nowle=String.valueOf(Integer.valueOf(scList[0].Name)).length();
            diff=original-nowle;
            
            objectData.put('sequence', seq.leftPad(diff, '0'));
        }else
        {
            objectData.put('sequence','000001');
        }
        
        objectData.put('providername', provider[0].name);
        objectData.put('provdName',provider[0].NAM_FACILITY__c);
        objectData.put('weekdays', plValues);
        objectData.put('careLevel', cLevel);
        objectData.put('careUnit', cUnit);
        objectData.put('rateType', rType);
        objectData.put('progType', pType);
        objectData.put('countySet', countySet);
        isSuccessful = true;
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    public static Map<string,string> getPicklistDetails(String objectName,String fieldName)
    {
        Map<string,string> pValues=new Map<string,string>();
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get(fieldName).getDescribe();
        List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
        
        //Add the picklist values to list.
        for(Schema.PicklistEntry plv: picklistvalues) {
            if(plv.isActive())
            {
                pValues.put(plv.getLabel(),plv.getValue());
            }
        }
        return pValues;
    }
    
    //this method will be called on save click
    @AuraEnabled
    public static LightningServerResponse saveData(string recordData)
    {
        // Setting savepoint to rollback the transaction is case of any failures. CCCAP-15551
        savepoint Sp = database.setsavepoint();
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message;  
        String authMsg;
        try{
            SlotWrapper slotRec=(SlotWrapper)System.JSON.deserialize(recordData,SlotWrapper.class);  
            
            authMsg =checkForAuthorization(slotRec);
            //check if user county different than selected county
            if(!CHATSUtility.checkCountyWithUserCounty(slotRec.countyVal))
            {
                isSuccessful=false;
                message='User County not matching with selected county';
                objectData.put('countyCheck',false);
            }
            else if(authMsg !='true')
            {
                if(authMsg =='authFalse')
                { 
                    isSuccessful=false;
                    message='User County not matching with selected county';
                    objectData.put('authDate',false);
                    
                }else if(authMsg =='slotBeFalse')
                {
                    isSuccessful=false;
                    message='User County not matching with selected county';
                    objectData.put('slotBeFalse',false);
                }else if(authMsg =='authPrFalse'){
                    isSuccessful=false;
                    message='User County not matching with selected county';
                    objectData.put('authPrFalse',false);
                }else if(authMsg =='existSlot'){
                    isSuccessful=false;
                    message='User County not matching with selected county';
                    objectData.put('existSlot',false);
                }else{
                    isSuccessful=false;
                    message='User County not matching with selected county';
                    objectData.put('authCounty',false);
                }
                
            }
            else
            {
                //using provider id and county id get the latest addendum record
                List<T_SLOT_CONTRACT_ADDENDUM__c> indiAdd=getFinalAddendumRecord(slotRec);
                
                if(indiAdd!=null && !indiAdd.isEmpty())
                {
                    //if no addendum records
                    if(slotRec.endDate > indiAdd[0].DTE_END_ADDENDUM__c)
                    {
                        isSuccessful=false;
                        message='No Addendum record found ';
                        objectData.put('addendumEndCheck',false);
                    }
                    else //check if allowed to create more slot records
                    {
                        List<AggregateResult> sCList=[select COUNT_DISTINCT(SLOT_CONTRACT_DESCRIPTION__c )dtnct from T_SLOT_CONTRACT__c where IDN_PROVIDER__c =: slotRec.provdId and CDE_COUNTY__c =:slotRec.countyVal and IDN_ADDENDUM__c=:indiAdd[0].id];
                        
                        Integer extSlot =Integer.valueOf(sCList[0].get('dtnct'));
                        if(extSlot<indiAdd[0].CNT_SLOT_CONTRACTS__c)
                        {
                            
                            //method to finally create slot records
                            Response fResp = createSlotContracts(slotRec,indiAdd[0]);
                            Boolean issucces=fResp.succ;
                            string sno;
                            string sid;
                            if(issucces)
                            {
                                sno=fResp.sno;
                                sid=fResp.sid;
                                isSuccessful=true;
                                message='Success';
                                objectData.put('createError',true);
                                objectData.put('sno',sno);
                                objectData.put('sid',sid);
                            }
                            else{
                                isSuccessful=false;
                                message='Error occurred !';
                                objectData.put('createError',false);
                            }
                        }else{
                            isSuccessful=false;
                            message='count error';
                            objectData.put('addendumCountCheck',false);
                        }
                    }
                    
                }else{
                    isSuccessful=false;
                    message='No Addendum record found for selected county and provider';
                    objectData.put('addendumcheck',false);
                }
                
                
            }
        }catch(Exception e){
            database.rollback(sp);
            isSuccessful = false;
            message = e.getMessage();
            objectData.put('createError',false);
        }
        
        
        return new LightningServerResponse(isSuccessful,message,objectData);
    }
    @AuraEnabled
    public static LightningServerResponse getRateTypeByBegin(string recordData)
    {
        Map<String, Object> objectData = new map<String, Object>(); 
        Map<string,string> fValues=new Map<string,string>();
        Boolean isSuccessful;
        String message;  
        Set<string> pValues=new Set<string>();
        SlotWrapper slotRec=(SlotWrapper)System.JSON.deserialize(recordData,SlotWrapper.class); 
        
        List<T_PROVR_FISCAL_AGREMENT__c> fas=[SELECT Id ,DTE_BEGIN_AGRMT__c,DTE_END_AGRMT__c,CDE_COUNTY__c,ID_SERVICE__c
                                              ,(select id,DTE_BEGIN_EFFV__c,DTE_END_EFFV__c,toLabel(CDE_RATE_TYPE__c) from Rate_Schedules__r )
                                              from T_PROVR_FISCAL_AGREMENT__c where CDE_TYPE_STATUS__c !='CLS' and CDE_COUNTY__c= :slotRec.countyVal  and ID_SERVICE__c=: slotRec.provdId];
        
        if(fas!=null && !fas.isEmpty())
        {
            for(T_PROVR_FISCAL_AGREMENT__c indiObj : fas)
            {
                if(slotRec.beginDate >=indiObj.DTE_BEGIN_AGRMT__c)
                {
                    if(indiObj.Rate_Schedules__r!=null && !indiObj.Rate_Schedules__r.isEmpty())
                    {
                        for(T_FISCAL_SCH__c rSched : indiObj.Rate_Schedules__r)
                        {
                            if(slotRec.beginDate >=rSched.DTE_BEGIN_EFFV__c && (rSched.DTE_END_EFFV__c==null || (slotRec.beginDate<=rSched.DTE_END_EFFV__c )) )
                            {
                                List<string> tmpStrings=rSched.CDE_RATE_TYPE__c.split(';');
                                for(String indiS : tmpStrings)
                                {
                                    pValues.add(indiS);            
                                }
                                Schema.SObjectType objType = Schema.getGlobalDescribe().get('T_SLOT_CONTRACT__c');
                                Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
                                Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get('CDE_RATE_TYPE__c').getDescribe();
                                List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
                                
                                //Add the picklist values to list.
                                for(Schema.PicklistEntry plv: picklistvalues) {
                                    if(pValues.contains(plv.getLabel()))
                                    {
                                        fValues.put(plv.getLabel(),plv.getValue());
                                    }
                                }
                                break;
                            }
                        }
                        break;
                    }
                }
            }
        }
        
        objectData.put('rtype', fValues);
        isSuccessful = true;
        message='success';
        return new LightningServerResponse(isSuccessful,message,objectData);
        
    }
    //method to get addendum against county and provider
    public static List<T_SLOT_CONTRACT_ADDENDUM__c> getFinalAddendumRecord(SlotWrapper slotRec) {
        List<T_SLOT_CONTRACT_ADDENDUM__c> finAde=new List<T_SLOT_CONTRACT_ADDENDUM__c>();
        
        List<T_SLOT_CONTRACT_ADDENDUM__c> addendumList=[select id,DTE_BEGIN_ADDENDUM__c,DTE_END_ADDENDUM__c,IDN_FISCAL_AGREEMENT__c,IDN_FISCAL_AGREEMENT__r.ID_SERVICE__c ,CDE_COUNTY__c ,CNT_SLOT_CONTRACTS__c,CDE_STATUS__c from T_SLOT_CONTRACT_ADDENDUM__c where
                                                        IDN_FISCAL_AGREEMENT__r.ID_SERVICE__c=:slotRec.provdId and CDE_COUNTY__c=:slotRec.countyVal and CDE_STATUS__c  in ('FIN','OPN')  order by CDE_STATUS__c  asc];
        
        if(addendumList!=null && !addendumList.isEmpty())
        {
            for(T_SLOT_CONTRACT_ADDENDUM__c indiObj : addendumList)
            {
                if(slotRec.beginDate >=indiObj.DTE_BEGIN_ADDENDUM__c && slotRec.beginDate<=indiObj.DTE_END_ADDENDUM__c)
                {
                    finAde.add(indiObj);
                    break;
                }
            }
        }  
        return finAde;
    }
    //method to check if auth is present and if auth date is less
    public static string checkForAuthorization(SlotWrapper slotRec){
        String finResult='true';
        if(string.isNotBlank(slotRec.authVal)){
            T_AUTH__c auth=[select id,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c,CDE_COUNTY__c,IDN_PROVR__c,IDN_SLOT_CONTRACT__c from T_AUTH__c where id=:slotRec.authVal];
            if(slotRec.countyVal == auth.CDE_COUNTY__c){
                if(slotRec.provdId == auth.IDN_PROVR__c){
                    if(auth.DTE_END_EFFV_AUTH__c<slotRec.beginDate ){
                        finResult='authFalse';
                    }
                    if(auth.DTE_BEGIN_EFFV_AUTH__c > slotRec.endDate){
                        finResult = 'slotBeFalse';
                    }
                    if(finResult=='true'){
                        /*if(string.isNotBlank(auth.IDN_SLOT_CONTRACT__c)){
                            List<T_SLOT_CONTRACT__c> allSlots = [select id, name,SLOT_CONTRACT_DESCRIPTION__c, DTE_BEGIN_SLOT__c,DTE_END_SLOT__c  from T_SLOT_CONTRACT__c where id=:auth.IDN_SLOT_CONTRACT__c];
							if(allSlots.size()>1)
                            {
                                for(T_SLOT_CONTRACT__c indiSlot : allSlots)
                                {
                                    if(slotRec.beginDate>=indiSlot.DTE_BEGIN_SLOT__c && slotRec.beginDate<=indiSlot.DTE_END_SLOT__c && slotRec.endDate>=indiSlot.DTE_BEGIN_SLOT__c && slotRec.endDate<=indiSlot.DTE_END_SLOT__c )
                                    {
                                        finResult='existSlot';
                                    }
                                }
                            }
                        }*/
                        date beginDate;
                        Integer betDays = slotRec.beginDate.daysBetween(slotRec.endDate);
                        List<T_SLOT_CONTRACT__c> allSlots = [select id, NAME, SLOT_CONTRACT_DESCRIPTION__c, DTE_BEGIN_SLOT__c, DTE_END_SLOT__c FROM T_SLOT_CONTRACT__c WHERE IDN_AUTH__c =:auth.Id];
                        for(T_SLOT_CONTRACT__c indiSlot : allSlots){
                            beginDate=slotRec.beginDate;
                            for(integer i=0;i<=betDays;i++)
							{
                                 if(beginDate>= indiSlot.DTE_BEGIN_SLOT__c && beginDate<= indiSlot.DTE_END_SLOT__c)
                                 {
                                	finResult='existSlot';
                            	}
                                beginDate=beginDate+1;
                            }
                           
                        }
                    }
                }
                else{
                    finResult='authPrFalse';
                }
            }else{
                finResult='countyFalse';
            }
                         
        }
        
        return finResult;
    }
    //method to create slot contract
    public static Response createSlotContracts(SlotWrapper slotRec,T_SLOT_CONTRACT_ADDENDUM__c indiAdd)
    {
        Response resp=new  Response();
        Boolean issuccess=false;
        string scno;
        String scId;
        
        T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,indiAdd);
        
        Database.SaveResult sr = Database.insert(scObToInsert, false);
        
        if (sr.isSuccess()) {
            scId=sr.getId();
            scno=[select id, name from T_SLOT_CONTRACT__c where id = :scId].name;
            updateDesc(scId);
            if(string.isNotBlank(slotRec.authVal)){
                furtherOperations(slotRec,scId,indiAdd);
            }
            
            issuccess=true; 
            
        }else{
            issuccess=false; 
        }
        
        resp.succ=issuccess;
        resp.sno=scno;
        resp.sid=scId;
        return resp;
    }
    public static void furtherOperations(SlotWrapper slotRec,id scId,T_SLOT_CONTRACT_ADDENDUM__c indiAdd)
    {
        T_AUTH__c auth=[select id ,DTE_BEGIN_SLOT__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,IDN_SLOT_CONTRACT__r.DTE_END_SLOT__c, IDN_SLOT_CONTRACT__c from T_AUTH__c where id=:slotRec.authVal];
        
        T_SLOT_CONTRACT__c sc=[select id , DTE_BEGIN_SLOT__c,DTE_END_SLOT__c,Name,SLOT_CONTRACT_DESCRIPTION__c,IDN_AUTH__c,IND_AVAILABLE__c,IND_FUTURE_VACANT__c,IND_OCCUPIED__c from T_SLOT_CONTRACT__c where id=:scID];
        Id finSCId;
        Date finDate;

        if(slotRec.beginDate >=auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate <= auth.DTE_END_EFFV_AUTH__c  )
        {
            sc.IDN_AUTH__c=auth.Id;
            finSCId=sc.Id;
            finDate=sc.DTE_BEGIN_SLOT__c;

            GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{sc},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
            
        }else if(slotRec.beginDate >= auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate > auth.DTE_END_EFFV_AUTH__c)
        {
            sc.IDN_AUTH__c=auth.Id;
            sc.DTE_END_SLOT__c = auth.DTE_END_EFFV_AUTH__c;
            finSCId=sc.Id;
            finDate=sc.DTE_BEGIN_SLOT__c;
            
            GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{sc},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
            
            T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,indiAdd);
            scObToInsert.DTE_BEGIN_SLOT__c = auth.DTE_END_EFFV_AUTH__c+1;
            scObToInsert.SLOT_CONTRACT_DESCRIPTION__c = sc.SLOT_CONTRACT_DESCRIPTION__c;
            scObToInsert.IDN_AUTH__c=null;
  
            GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
            
        }else if(slotRec.beginDate < auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate > auth.DTE_END_EFFV_AUTH__c)
        {
            sc.IDN_AUTH__c=null;
            sc.DTE_END_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c-1;
            
            GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{sc},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
      
            
            T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,indiAdd);
            scObToInsert.DTE_BEGIN_SLOT__c =auth.DTE_BEGIN_EFFV_AUTH__c;
            scObToInsert.IDN_AUTH__c=auth.Id;
            scObToInsert.SLOT_CONTRACT_DESCRIPTION__c = sc.SLOT_CONTRACT_DESCRIPTION__c;
            scObToInsert.DTE_END_SLOT__c=auth.DTE_END_EFFV_AUTH__c;
            
            GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});   
            
            T_SLOT_CONTRACT__c vcsobject=getSlotRecord(slotRec,indiAdd);
            vcsobject.DTE_BEGIN_SLOT__c =auth.DTE_END_EFFV_AUTH__c+1;
            vcsobject.IDN_AUTH__c=null;
            vcsobject.SLOT_CONTRACT_DESCRIPTION__c = sc.SLOT_CONTRACT_DESCRIPTION__c;

            GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{vcsobject},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
            
            finSCId=scObToInsert.Id;
            finDate=scObToInsert.DTE_BEGIN_SLOT__c;
        }else if(slotRec.beginDate < auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate <= auth.DTE_END_EFFV_AUTH__c)
        {
            sc.IDN_AUTH__c=null;
            sc.DTE_END_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c-1;

            GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{sc},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
            
            T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,indiAdd);
            scObToInsert.IDN_AUTH__c=auth.id;
            scObToInsert.DTE_BEGIN_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c;
            scObToInsert.SLOT_CONTRACT_DESCRIPTION__c = sc.SLOT_CONTRACT_DESCRIPTION__c;

            GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
            
            finSCId=scObToInsert.Id;
            finDate=scObToInsert.DTE_BEGIN_SLOT__c;
        }
        auth.DTE_BEGIN_SLOT__c=finDate;
        auth.IDN_SLOT_CONTRACT__c =finSCId;
        GenericDMLHandler.updateRecords(new List<T_AUTH__c>{auth},new Map<String,Object>{'Method__c'=>'furtherOperations','Class__c'=>'SlotContractFlowApxCtrl'});
        
    }
    public static void updateDesc(Id scID){
        String tmpDsc;
        T_SLOT_CONTRACT__c sc=[select id , Name,SLOT_CONTRACT_DESCRIPTION__c from T_SLOT_CONTRACT__c where id=:scID];
        tmpDsc = sc.SLOT_CONTRACT_DESCRIPTION__c.substringBeforeLast('_');
        sc.SLOT_CONTRACT_DESCRIPTION__c=tmpDsc+'_'+sc.Name;

        GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{sc},new Map<String,Object>{'Method__c'=>'updateDesc','Class__c'=>'SlotContractFlowApxCtrl'});
    }
    
    public static T_SLOT_CONTRACT__c  getSlotRecord(SlotWrapper slotRec,T_SLOT_CONTRACT_ADDENDUM__c indiAdd){
        
        T_SLOT_CONTRACT__c scObToInsert =new T_SLOT_CONTRACT__c();
        scObToInsert.SLOT_CONTRACT_DESCRIPTION__c =slotRec.scdesc;
        scObToInsert.IDN_ADDENDUM__c=indiAdd.id;
        scObToInsert.IDN_PROVIDER__c=slotRec.provdId;
        scObToInsert.CDE_COUNTY__c=slotRec.countyVal;
        scObToInsert.DTE_BEGIN_SLOT__c=slotRec.beginDate;
        scObToInsert.DTE_END_SLOT__c=slotRec.endDate;
        scObToInsert.CNT_DAYS_OF_MONTH__c=slotRec.noDays;
        
        String finWeek;
        for(String indiS : slotRec.weekData)
        {        
            if(string.isBlank(finWeek))
            {
                finWeek=indiS+';';
            }else
            {
                finWeek=finWeek+indiS+';';
            }
            
        }
        //system.debug('finWeek '+finWeek);
        
        scObToInsert.CNT_DAYS_OF_WEEK__c=finWeek;
        scObToInsert.CDE_CARE_LEVEL__c=slotRec.clevelVal;
        scObToInsert.CDE_RATE_TYPE__c=slotRec.rtypeVal;
        scObToInsert.IDN_AUTH__c=slotRec.authVal;
        scObToInsert.IND_AVAILABLE__c=slotRec.avaVal;
        scObToInsert.CDE_PRG_TYPE__c=slotRec.progTyp;
        scObToInsert.CDE_CARE_UNIT__c=slotRec.cunitVal;        
        return scObToInsert;
        
    }
    public class Response{
        @AuraEnabled
        public boolean succ {get;set;}
        @AuraEnabled
        public String sno {get;set;}
        @AuraEnabled
        public String sid {get;set;}
    }
    public class SlotWrapper{
        @AuraEnabled
        public boolean avaVal {get;set;}
        @AuraEnabled
        public String progTyp {get;set;}
        @AuraEnabled
        public String provdId {get;set;}
        @AuraEnabled
        public String countyVal {get;set;}
        @AuraEnabled
        public String rtypeVal {get;set;}
        @AuraEnabled
        public String clevelVal {get;set;}
        @AuraEnabled
        public String cunitVal {get;set;}        
        @AuraEnabled
        public Integer noDays {get;set;}
        @AuraEnabled
        public Date beginDate {get;set;}
        @AuraEnabled
        public Date endDate {get;set;}
        @AuraEnabled
        public String authVal {get;set;}
        @AuraEnabled
        public String scdesc {get;set;}
        @AuraEnabled
        public List<String> weekData {get;set;}
    }
}