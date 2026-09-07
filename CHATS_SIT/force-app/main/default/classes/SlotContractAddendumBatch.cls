global with sharing class SlotContractAddendumBatch implements Database.Batchable<sObject>, schedulable {
	
    public final String CLOSED_STATUS = 'CLS';
    public final String OPEN_STATUS = 'OPN';
    public final String FINALIZED_STATUS = 'FIN';
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, Name, CDE_STATUS__c, DTE_BEGIN_ADDENDUM__c, DTE_END_ADDENDUM__c,IDN_FISCAL_AGREEMENT__c, CDE_COUNTY__c, CDE_COUNTY__r.Name, IDN_FISCAL_AGREEMENT__r.OwnerId FROM T_SLOT_CONTRACT_ADDENDUM__c WHERE CDE_STATUS__c != :CLOSED_STATUS');       
    }
    
    global void execute(Database.BatchableContext BC, List<T_SLOT_CONTRACT_ADDENDUM__c> scope){
         Date dateToday =  System.today();
        Date next45Days = dateToday.addDays(45);
        String day = System.now().format('EEEE'); 
        set<id>addIds = new set<id>();
         set<id> fiscalAgreeIds=new set<id>();
         Map<String, Set<String>> fiscalAgreeIdDesrip = new Map<String, Set<String>>();
        Integer daysToAdd = day == 'Saturday' ? 13 : (day == 'Sunday' ? 12 : 14);
        List<T_SLOT_CONTRACT_ADDENDUM__c> lstSARecords = new List<T_SLOT_CONTRACT_ADDENDUM__c>();
        list<Task> taskToCreate = new list<Task>();

        for(T_SLOT_CONTRACT_ADDENDUM__c saRecord : scope){
            if(saRecord.DTE_END_ADDENDUM__c < dateToday){
                saRecord.CDE_STATUS__c = CLOSED_STATUS;
                lstSARecords.add(saRecord); 
            }
            if(saRecord.DTE_BEGIN_ADDENDUM__c <= dateToday && saRecord.CDE_STATUS__c == FINALIZED_STATUS){
                saRecord.CDE_STATUS__c = OPEN_STATUS;
                lstSARecords.add(saRecord); 
            }
            fiscalAgreeIds.add(saRecord.IDN_FISCAL_AGREEMENT__c);
        }

        for(Task taskRec : [Select Id, Subject, WhatId, Description from Task where WhatId IN :fiscalAgreeIds AND Subject ='T217 - Slot Contract Addendum is closing in 45 days']){
            if(!fiscalAgreeIdDesrip.containsKey(taskRec.WhatId) ){ 
                fiscalAgreeIdDesrip.put(taskRec.WhatId, new Set<String>());
            }
            fiscalAgreeIdDesrip.get(taskRec.WhatId).add(taskRec.Description);
        }
                for(T_SLOT_CONTRACT_ADDENDUM__c sc : scope) {
                
                if(sc.DTE_END_ADDENDUM__c >= dateToday && sc.DTE_END_ADDENDUM__c < next45Days){
                    Task tsk = new Task();
                    
                    tsk.Subject = 'T217 - Slot Contract Addendum is closing in 45 days';
                    tsk.Status = 'Open';                    
                    tsk.Description = 'Slot Contract Addendum ' + sc.Name
                        +' ('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_SLOT_CONTRACT_ADDENDUM__c/'+sc.Id+'/view)'+' that is currently open with ' + sc.CDE_COUNTY__r.Name 
                        +' ('+ URL.getOrgDomainUrl().toExternalForm() +'/lightning/r/T_COUNTY__c/'+sc.CDE_COUNTY__c+'/view)'+' County is going to end in 45 days and there is no future finalized Addendum. Please take appropriate action.';
                    
                    
                  if(fiscalAgreeIdDesrip.get(sc.IDN_FISCAL_AGREEMENT__c) == Null || !fiscalAgreeIdDesrip.get(sc.IDN_FISCAL_AGREEMENT__c).contains(tsk.Description)){
                   
                    tsk.WhatId = sc.IDN_FISCAL_AGREEMENT__c;
                    tsk.ActivityDate = dateToday.addDays(daysToAdd);
                    tsk.OwnerId = sc.IDN_FISCAL_AGREEMENT__r.OwnerId;
                    taskToCreate.add(tsk);
                  }
                }
             }
        
        //Database.DMLOptions dm = new Database.DMLOptions();
        //dm.EmailHeader.triggerUserEmail = true;
        //dm.optAllOrNone = false;
        
        if(!taskToCreate.isEmpty()){
            //GenericDMLHandler.insertRecordsWithEmailTrigger(taskToCreate,dm,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'SlotContractAddendumBatch'});
            GenericDMLHandler.insertRecords(taskToCreate,false,new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'SlotContractAddendumBatch'});
            //Database.insert(taskToCreate, dm);
        }

        if(!lstSARecords.isEmpty()){
        	GenericDMLHandler.updateRecords(lstSARecords, false, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'SlotContractAddendumBatch'});
        }
    }
    global void execute(SchedulableContext sc){
        database.executebatch(new SlotContractAddendumBatch(), 200);
    }
    
    global void finish(Database.BatchableContext BC){}
}