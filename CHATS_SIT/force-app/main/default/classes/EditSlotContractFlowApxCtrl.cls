/*
Author : Pooja Pramod Aher
Description : Class for Creation of Edit slot contract functionality.
Test Class : EditSlotContractFlowApxCtrlTest.apxc
*/
public with sharing class EditSlotContractFlowApxCtrl {
    
    //method to get initial details
    @AuraEnabled
    public static LightningServerResponse getInitData(string recordid)
    {
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message;  
        
        T_SLOT_CONTRACT__c slotData=[select id,CDE_COUNTY__c,CDE_COUNTY__r.name,IDN_PROVIDER__c,
                                     IDN_ADDENDUM__c,CDE_CARE_LEVEL__c,CDE_RATE_TYPE__c,CDE_CARE_UNIT__c,
                                     IDN_AUTH__c,CNT_DAYS_OF_MONTH__c,DTE_END_SLOT__c,DTE_BEGIN_SLOT__c,
                                     IND_AVAILABLE__c,CNT_DAYS_OF_WEEK__c,CDE_PRG_TYPE__c,SLOT_CONTRACT_DESCRIPTION__c from T_SLOT_CONTRACT__c where id=:recordid];
        LightningServerResponse resp=SlotContractFlowApxCtrl.getInitData(slotData.IDN_PROVIDER__c);
        List<string> weekval=slotData.CNT_DAYS_OF_WEEK__c.split(';');
        
        SlotContractFlowApxCtrl.SlotWrapper slotRec=new SlotContractFlowApxCtrl.SlotWrapper();
        slotRec.beginDate = slotData.DTE_BEGIN_SLOT__c;
        slotRec.countyVal = slotData.CDE_COUNTY__c;
        slotRec.provdId = slotData.IDN_PROVIDER__c;
        
        String slot=JSON.serialize(slotRec);
        LightningServerResponse resp1=getRateTypeByBegin(slot);
        resp.objectData.put('newRate',  resp1.objectData.get('rtype'));
        resp.objectData.put('weekval', weekval);
        resp.objectData.put('slotData', slotData);
        
        List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String MyProflieName = PROFILE[0].Name;
        //Replaced using custom permission CCCAP-14993
        if(FeatureManagement.checkPermission('Eligibility_Worker') || FeatureManagement.checkPermission('Eligibility_Worker_Supervisor') || FeatureManagement.checkPermission('Fiscal_Worker') || FeatureManagement.checkPermission('Fiscal_Worker_Supervisor') || FeatureManagement.checkPermission('Read_Only_User'))
        {
            resp.objectData.put('profileCheck', false);
            resp.objectData.put('profileName', MyProflieName);
        }
        
        return resp;
    }
    @AuraEnabled
    public static LightningServerResponse getRateTypeByBegin(string recordData)
    {
        Map<String, Object> objectData = new map<String, Object>(); 
        Map<string,string> fValues=new Map<string,string>();
        Boolean isSuccessful;
        String message;  
        Set<string> pValues=new Set<string>();
        SlotContractFlowApxCtrl.SlotWrapper slotRec=(SlotContractFlowApxCtrl.SlotWrapper)System.JSON.deserialize(recordData,SlotContractFlowApxCtrl.SlotWrapper.class); 
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
                            if(slotRec.beginDate >=rSched.DTE_BEGIN_EFFV__c && (rSched.DTE_END_EFFV__c==null || (slotRec.beginDate<=rSched.DTE_END_EFFV__c )))
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
        //system.debug('fValues '+fValues);
        objectData.put('rtype', fValues);
        isSuccessful = true;
        message='success';
        return new LightningServerResponse(isSuccessful,message,objectData);
        
    }
    //this method will be called on save click
    @AuraEnabled
    public static LightningServerResponse updateData(string recordData,string recordid,boolean occCheck)
    {
        Map<String, Object> objectData = new map<String, Object>();    
        Boolean isSuccessful;
        String message;  
        id authidtoremove;
        boolean removeAuth=false;
        id eId;
        try{
            SlotContractFlowApxCtrl.SlotWrapper slotRec=(SlotContractFlowApxCtrl.SlotWrapper)System.JSON.deserialize(recordData,SlotContractFlowApxCtrl.SlotWrapper.class); 
            
            T_SLOT_CONTRACT__c scObToUpdate=[select id,CDE_COUNTY__c,CDE_COUNTY__r.name,IDN_PROVIDER__c,IDN_ADDENDUM__c,
                                             CDE_CARE_LEVEL__c,CDE_RATE_TYPE__c,CDE_CARE_UNIT__c,IDN_AUTH__c,CNT_DAYS_OF_MONTH__c,
                                             DTE_END_SLOT__c,DTE_BEGIN_SLOT__c,IND_AVAILABLE__c,CNT_DAYS_OF_WEEK__c,CDE_PRG_TYPE__c,
                                             SLOT_CONTRACT_DESCRIPTION__c from T_SLOT_CONTRACT__c where id=:recordid];
            Boolean andInToday=false;
            eId=scObToUpdate.id;
            if(string.isnotblank(scObToUpdate.IDN_AUTH__c) && (string.isBlank(slotRec.authVal) ||  scObToUpdate.IDN_AUTH__c!=slotRec.authVal) )
            {
                authidtoremove=scObToUpdate.IDN_AUTH__c;
                removeAuth=true;
            }
            if(slotRec.beginDate >= system.today()-9  && slotRec.beginDate <= system.today())
            {
                andInToday=true;
            }
            
            //|| andInToday 
            
            if(occCheck==true)
            {
                scObToUpdate.IDN_AUTH__c=null;  
                scObToUpdate.DTE_END_SLOT__c=slotRec.beginDate-1;
                
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                T_SLOT_CONTRACT__c scObToInsert2=getSlotRecord(slotRec,scObToUpdate);
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert2},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert2;
                
                T_AUTH__c auth=[select id ,DTE_BEGIN_SLOT__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,IDN_SLOT_CONTRACT__r.DTE_END_SLOT__c, IDN_SLOT_CONTRACT__c from T_AUTH__c where id=:slotRec.authVal];
                
                auth.IDN_SLOT_CONTRACT__c=scObToInsert2.id;
                auth.DTE_BEGIN_SLOT__c = scObToInsert2.DTE_BEGIN_SLOT__c;
                GenericDMLHandler.updateRecords(new List<T_AUTH__c>{auth},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update auth;
                isSuccessful = true;
                message ='success';
                
                
            }
            else if(scObToUpdate.DTE_BEGIN_SLOT__c==slotRec.beginDate && ( scObToUpdate.IDN_AUTH__c==slotRec.authVal ||  string.isBlank(slotRec.authVal)))
            {
                // scObToUpdate.DTE_BEGIN_SLOT__c=slotRec.beginDate;
                scObToUpdate.CNT_DAYS_OF_MONTH__c=slotRec.noDays;
                if(string.isNotBlank(scObToUpdate.IDN_AUTH__c) &&string.isBlank(slotRec.authVal) )
                {
                    scObToUpdate.IDN_AUTH__c=null;  
                }
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
                
                scObToUpdate.CNT_DAYS_OF_WEEK__c=finWeek;
                scObToUpdate.CDE_CARE_LEVEL__c=slotRec.clevelVal;
                scObToUpdate.CDE_RATE_TYPE__c=slotRec.rtypeVal;
                
                //scObToUpdate.IND_AVAILABLE__c=slotRec.avaVal;
                scObToUpdate.CDE_PRG_TYPE__c=slotRec.progTyp;
                scObToUpdate.CDE_CARE_UNIT__c=slotRec.cunitVal;   
                
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                isSuccessful = true;
                message ='success';
                
                
            }
            else if(scObToUpdate.DTE_BEGIN_SLOT__c!=slotRec.beginDate  && (scObToUpdate.IDN_AUTH__c==slotRec.authVal || string.isBlank(slotRec.authVal) ))
            {
                T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,scObToUpdate);
                scObToUpdate.DTE_END_SLOT__c = slotRec.beginDate -1;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert;
                
                isSuccessful = true;
                message ='success';
            }
            else{ //create new record in any case
                
                /* if(scObToUpdate.DTE_BEGIN_SLOT__c!=slotRec.beginDate  && scObToUpdate.IDN_AUTH__c==slotRec.authVal)
{
T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,scObToUpdate);
scObToUpdate.DTE_END_SLOT__c = slotRec.beginDate -1;

update scObToUpdate;

insert scObToInsert;

isSuccessful = true;
message ='success';

}else{*/
                string authMsg ;
                authMsg = checkForAuthorization(slotRec);
                if(authMsg !='true')
                {
                    if(authMsg =='authFalse')
                    { 
                        isSuccessful=false;
                        message='Record creation failed. Authorization End Date is less than Slot Contract Begin Date';
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
                    
                }else{
                    Boolean issucces =  updateRecordAndAuth(slotRec,scObToUpdate,andInToday);
                    if(issucces)
                    {
                        isSuccessful=true;
                        message='Success';
                        objectData.put('updateError',true);
                    }
                    else{
                        isSuccessful=false;
                        message='Error occurred !';
                        objectData.put('updateError',false);
                    }
                }
                
                // }
            }
            
            
        }catch(Exception e){
            isSuccessful = false;
            message = e.getMessage();
            objectData.put('updateError',false);
            system.debug('exception '+ e.getMessage()+' ggg '+e.getLineNumber());
        }
        
        if(isSuccessful && removeAuth)
        {
            T_AUTH__c auth=[select id ,DTE_BEGIN_SLOT__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,IDN_SLOT_CONTRACT__r.DTE_END_SLOT__c, IDN_SLOT_CONTRACT__c from T_AUTH__c where id=:authidtoremove];
            if(auth.IDN_SLOT_CONTRACT__c==eId)
            {
                auth.IDN_SLOT_CONTRACT__c=null;
                auth.DTE_BEGIN_SLOT__c = null;
            }
            GenericDMLHandler.updateRecords(new List<T_AUTH__c>{auth},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
            //update auth;
        }
        return new LightningServerResponse(isSuccessful,message,objectData);
    }    
    public static boolean updateRecordAndAuth(SlotContractFlowApxCtrl.SlotWrapper slotRec,T_SLOT_CONTRACT__c scObToUpdate,boolean andInToday)
    {
        Boolean isSuccess;
        
        T_AUTH__c auth=[select id ,DTE_BEGIN_SLOT__c,DTE_BEGIN_EFFV_AUTH__c, DTE_END_EFFV_AUTH__c,IDN_SLOT_CONTRACT__r.DTE_END_SLOT__c, IDN_SLOT_CONTRACT__c from T_AUTH__c where id=:slotRec.authVal];
        
        // T_SLOT_CONTRACT__c sc=[select id , DTE_BEGIN_SLOT__c,DTE_END_SLOT__c,Name,SLOT_CONTRACT_DESCRIPTION__c,IDN_AUTH__c,IND_AVAILABLE__c,IND_FUTURE_VACANT__c,IND_OCCUPIED__c from T_SLOT_CONTRACT__c where id=:earlObj.id];
        Id finSCId;
        Date finDate;
        id sobjectid=scObToUpdate.id;
        
        if(slotRec.beginDate==scObToUpdate.DTE_BEGIN_SLOT__c )
        {
            if(slotRec.beginDate >=auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate <= auth.DTE_END_EFFV_AUTH__c  )
            {
                scObToUpdate =getSlotRecord(slotRec,scObToUpdate);
                scObToUpdate.IDN_AUTH__c = auth.Id;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                finSCId=scObToUpdate.Id;
                finDate=scObToUpdate.DTE_BEGIN_SLOT__c;
                isSuccess=true;
            }else if(slotRec.beginDate >= auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate > auth.DTE_END_EFFV_AUTH__c)
            {
                scObToUpdate =getSlotRecord(slotRec,scObToUpdate);
                scObToUpdate.IDN_AUTH__c = auth.Id;
                scObToUpdate.DTE_END_SLOT__c = auth.DTE_END_EFFV_AUTH__c;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                finSCId=scObToUpdate.Id;
                finDate=scObToUpdate.DTE_BEGIN_SLOT__c;
                
                T_SLOT_CONTRACT__c scObToInsert2=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert2.DTE_BEGIN_SLOT__c = auth.DTE_END_EFFV_AUTH__c+1;
                scObToInsert2.IDN_AUTH__c=null;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert2},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert2;
                isSuccess=true;
            }else if(slotRec.beginDate < auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate > auth.DTE_END_EFFV_AUTH__c)
            {
                scObToUpdate =getSlotRecord(slotRec,scObToUpdate);
                scObToUpdate.IDN_AUTH__c=null;
                scObToUpdate.DTE_END_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c-1;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                T_SLOT_CONTRACT__c scObToInsert2=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert2.DTE_BEGIN_SLOT__c =auth.DTE_BEGIN_EFFV_AUTH__c;
                scObToInsert2.IDN_AUTH__c=auth.Id;
                scObToInsert2.DTE_END_SLOT__c=auth.DTE_END_EFFV_AUTH__c;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert2},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert2;   
                
                T_SLOT_CONTRACT__c vcsobject=getSlotRecord(slotRec,scObToUpdate);
                vcsobject.DTE_BEGIN_SLOT__c =auth.DTE_END_EFFV_AUTH__c+1;
                vcsobject.IDN_AUTH__c=null;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{vcsobject},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert vcsobject;
                
                finSCId=scObToInsert2.Id;
                finDate=scObToInsert2.DTE_BEGIN_SLOT__c;
                isSuccess=true;
            }else if(slotRec.beginDate < auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate <= auth.DTE_END_EFFV_AUTH__c)
            { 
                scObToUpdate =getSlotRecord(slotRec,scObToUpdate);
                scObToUpdate.IDN_AUTH__c=null;
                scObToUpdate.DTE_END_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c-1;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                T_SLOT_CONTRACT__c scObToInsert2=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert2.IDN_AUTH__c=auth.id;
                scObToInsert2.DTE_BEGIN_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert2},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert2;
                finSCId=scObToInsert2.Id;
                finDate=scObToInsert2.DTE_BEGIN_SLOT__c;
                isSuccess=true;
            }
            
        }else{
            if(slotRec.beginDate >=auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate <= auth.DTE_END_EFFV_AUTH__c  )
            {
                
                scObToUpdate.DTE_END_SLOT__c = slotRec.beginDate -1;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert.IDN_AUTH__c=auth.Id;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert;
                
                finSCId=scObToInsert.Id;
                finDate=scObToInsert.DTE_BEGIN_SLOT__c;
                isSuccess=true;
            }else if(slotRec.beginDate >= auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate > auth.DTE_END_EFFV_AUTH__c)
            {
                scObToUpdate.DTE_END_SLOT__c = slotRec.beginDate -1;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,scObToUpdate);
                
                scObToInsert.IDN_AUTH__c=auth.Id;
                scObToInsert.DTE_END_SLOT__c = auth.DTE_END_EFFV_AUTH__c;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert;
                
                finSCId=scObToInsert.Id;
                finDate=scObToInsert.DTE_BEGIN_SLOT__c;
                
                T_SLOT_CONTRACT__c scObToInsert2=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert2.DTE_BEGIN_SLOT__c = auth.DTE_END_EFFV_AUTH__c+1;
                scObToInsert2.IDN_AUTH__c=null;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert2},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert2;
                isSuccess=true;
            }else if(slotRec.beginDate < auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate > auth.DTE_END_EFFV_AUTH__c)
            {
                scObToUpdate.DTE_END_SLOT__c = slotRec.beginDate -1;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert.IDN_AUTH__c=null;
                scObToInsert.DTE_END_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c-1;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert;
                
                T_SLOT_CONTRACT__c scObToInsert2=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert2.DTE_BEGIN_SLOT__c =auth.DTE_BEGIN_EFFV_AUTH__c;
                scObToInsert2.IDN_AUTH__c=auth.Id;
                scObToInsert2.DTE_END_SLOT__c=auth.DTE_END_EFFV_AUTH__c;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert2},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert2;   
                
                T_SLOT_CONTRACT__c vcsobject=getSlotRecord(slotRec,scObToUpdate);
                vcsobject.DTE_BEGIN_SLOT__c =auth.DTE_END_EFFV_AUTH__c+1;
                vcsobject.IDN_AUTH__c=null;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{vcsobject},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert vcsobject;
                
                finSCId=scObToInsert2.Id;
                finDate=scObToInsert2.DTE_BEGIN_SLOT__c;
                isSuccess=true;
            }else if(slotRec.beginDate < auth.DTE_BEGIN_EFFV_AUTH__c && slotRec.endDate <= auth.DTE_END_EFFV_AUTH__c)
            {
                scObToUpdate.DTE_END_SLOT__c = slotRec.beginDate -1;
                scObToUpdate.id=sobjectid;
                GenericDMLHandler.updateRecords(new List<T_SLOT_CONTRACT__c>{scObToUpdate},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
                //update scObToUpdate;
                
                T_SLOT_CONTRACT__c scObToInsert=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert.IDN_AUTH__c=null;
                scObToInsert.DTE_END_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c-1;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert;
                
                T_SLOT_CONTRACT__c scObToInsert2=getSlotRecord(slotRec,scObToUpdate);
                scObToInsert2.IDN_AUTH__c=auth.id;
                scObToInsert2.DTE_BEGIN_SLOT__c=auth.DTE_BEGIN_EFFV_AUTH__c;
                GenericDMLHandler.insertRecords(new List<T_SLOT_CONTRACT__c>{scObToInsert2},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'});
                //insert scObToInsert2;
                finSCId=scObToInsert2.Id;
                finDate=scObToInsert2.DTE_BEGIN_SLOT__c;
                isSuccess=true;
            }
        }
        
        auth.DTE_BEGIN_SLOT__c=finDate;
        auth.IDN_SLOT_CONTRACT__c =finSCId;
        GenericDMLHandler.updateRecords(new List<T_AUTH__c>{auth},new Map<String,Object>{'Method__c'=>'updateData','Class__c'=>'EditSlotContractFlowApxCtrl'}); 
        //update auth;
        return isSuccess;
    }
    //method to check if auth is present and if auth date is less
    public static string checkForAuthorization(SlotContractFlowApxCtrl.SlotWrapper slotRec)
    {    
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
    
    public static T_SLOT_CONTRACT__c getSlotRecord(SlotContractFlowApxCtrl.SlotWrapper slotRec,T_SLOT_CONTRACT__c earlObj){
        
        T_SLOT_CONTRACT__c scObToInsert =new T_SLOT_CONTRACT__c();
        scObToInsert.SLOT_CONTRACT_DESCRIPTION__c =slotRec.scdesc;
        scObToInsert.IDN_ADDENDUM__c=earlObj.IDN_ADDENDUM__c;
        scObToInsert.IDN_PROVIDER__c=slotRec.provdId;
        scObToInsert.CDE_COUNTY__c=earlObj.CDE_COUNTY__c;
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
}