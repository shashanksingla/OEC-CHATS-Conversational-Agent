@isTest
public class EditSlotContractFlowApxCtrlTest {
    
    @testSetup static void setup() {
        
        T_COUNTY__c county=TestClassUtility.createCounty('Denver', 'test', 1, true);
        T_CHATS_PROVR_STATUS__c prvder=TestClassUtility.createProvider(true, 'Level 2');
        
        T_PROVR_FISCAL_AGREMENT__c fa=TestClassUtility.createFiscaAgreement(true, 'Test FA', system.today()-10, county.id);
        fa.ID_SERVICE__c=prvder.id;
        fa.DTE_BEGIN_AGRMT__c= system.today()-5;
        fa.DTE_END_AGRMT__c = system.today().addYears(3);
        // fa.CDE_TYPE_STATUS__c='FIN';
        update fa;
        
        T_SLOT_CONTRACT_ADDENDUM__c adde=new T_SLOT_CONTRACT_ADDENDUM__c();
        adde.CDE_COUNTY__c=county.id;
        adde.CNT_SLOT_CONTRACTS__c=6;
        adde.IDN_FISCAL_AGREEMENT__c=fa.id;
        adde.CDE_STATUS__c='FIN';
        adde.DTE_BEGIN_ADDENDUM__c=system.today().addYears(-1);
        adde.DTE_END_ADDENDUM__c=system.today().addYears(3);
        
        insert adde;
        
        T_FISCAL_SCH__c rate=new T_FISCAL_SCH__c();
        rate.DTE_BEGIN_EFFV__c=system.today()-2;
        rate.IDN_AGRMT_FISCAL__c=fa.id;
        rate.CDE_RATE_TYPE__c='1;19;31';
        insert rate;
        T_AUTH__c authSame=TestClassUtility.createAuthorization(true, system.today().addMonths(1), system.today(), county.id, prvder.id);
        T_AUTH__c authN=TestClassUtility.createAuthorization(true, system.today().addMonths(3), system.today().addMonths(2), county.id, prvder.id);
        T_AUTH__c authN1=TestClassUtility.createAuthorization(true, system.today().addMonths(5), system.today().addMonths(4), county.id, prvder.id);

        T_SLOT_CONTRACT__c slotV=new T_SLOT_CONTRACT__c();
        slotV.IDN_ADDENDUM__c=adde.id;
        slotV.CNT_DAYS_OF_MONTH__c=8;
        slotV.CDE_COUNTY__c=county.id;
        slotV.IDN_PROVIDER__c=prvder.id;
        slotV.CNT_DAYS_OF_WEEK__c='Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday';
        slotV.CDE_CARE_LEVEL__c='3';
        slotV.CDE_CARE_UNIT__c='4';
        slotV.CDE_PRG_TYPE__c='LI';
        slotV.CDE_RATE_TYPE__c='43';
        slotV.DTE_BEGIN_SLOT__c=system.today();
        slotV.DTE_END_SLOT__c=system.today().addMonths(1);
        slotV.SLOT_CONTRACT_DESCRIPTION__c='test first';
       	slotV.IND_AVAILABLE__c=true;
        insert slotV;
    }
    
    public static testMethod void runTestgetInitData(){
        LightningServerResponse response;
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        boolean oc=false;
        insert pwUser;
        T_SLOT_CONTRACT__c slotcr=[select id ,name from T_SLOT_CONTRACT__c limit 1];
        Test.startTest();     
        System.runAs(pwUser){
            response = EditSlotContractFlowApxCtrl.getInitData(slotcr.id);
            System.assertEquals(response.isSuccessful,true);
        }
        Test.stopTest();
    }
    public static testMethod void scenario1and2(){
       	LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        boolean oc=false;
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        String slot='';
        T_SLOT_CONTRACT__c slotv=[select id ,name ,IDN_AUTH__c from T_SLOT_CONTRACT__c limit 1];
    
        Test.startTest();     
        System.runAs(pwUser){
            slotRec.avaVal=true;
            slotRec.beginDate=system.today();         
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(1);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slot=JSON.serialize(slotRec);
                
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
            slotRec.beginDate=system.today()+10;
            slotRec.noDays=10;
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
        }
        Test.stopTest();
    }
    public static testMethod void scenario345(){
       	LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        boolean oc=false;
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        String slot='';
        T_SLOT_CONTRACT__c slotv=[select id ,name ,IDN_AUTH__c,DTE_BEGIN_SLOT__c from T_SLOT_CONTRACT__c limit 1];
        
        List<T_AUTH__c> authList =[SELECT Id, Name,DTE_BEGIN_EFFV_AUTH__c FROM T_AUTH__c];
       
        T_AUTH__c authSame=new T_AUTH__c();//=TestClassUtility.createAuthorization(true, system.today().addMonths(1), system.today(), county.id, prvder.id);
        T_AUTH__c authN=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(3), system.today().addMonths(2), county.id, prvder.id);
        T_AUTH__c authN1=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(5), system.today().addMonths(4), county.id, prvder.id);
        
        for(T_AUTH__c indi :authList)
        {
            if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today())
            {
                authSame=indi;
            }
            else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(2))
            {
                authN=indi;
            }else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(4))
            {
                authN1=indi;
            }
        }
        
        Test.startTest();     
        System.runAs(pwUser){
            slotRec.avaVal=true;
            slotRec.beginDate=slotv.DTE_BEGIN_SLOT__c;         
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(1);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slotRec.authVal=authSame.id;    
            slot=JSON.serialize(slotRec);
                
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
            slotRec.authVal=authN.id;    
            slotRec.endDate=system.today().addMonths(5);
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
           slotRec.authVal=authN1.id;    
            slotRec.endDate=system.today().addMonths(3);
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,false);
          
        }
        Test.stopTest();
    }
    
    public static testMethod void scenario45(){
       	LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        boolean oc=false;
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        String slot='';
        T_SLOT_CONTRACT__c slotv=[select id ,name ,IDN_AUTH__c,DTE_BEGIN_SLOT__c from T_SLOT_CONTRACT__c limit 1];
        
        List<T_AUTH__c> authList =[SELECT Id, Name,DTE_BEGIN_EFFV_AUTH__c FROM T_AUTH__c];
       
        T_AUTH__c authSame=new T_AUTH__c();//=TestClassUtility.createAuthorization(true, system.today().addMonths(1), system.today(), county.id, prvder.id);
        T_AUTH__c authN=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(3), system.today().addMonths(2), county.id, prvder.id);
        T_AUTH__c authN1=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(5), system.today().addMonths(4), county.id, prvder.id);
        
        for(T_AUTH__c indi :authList)
        {
            if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today())
            {
                authSame=indi;
            }
            else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(2))
            {
                authN=indi;
            }else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(4))
            {
                authN1=indi;
            }
        }
        authSame.IDN_SLOT_CONTRACT__c=null;
        update authSame;
        slotv.IDN_AUTH__c=null;
        update slotv;
        
        Test.startTest();     
        System.runAs(pwUser){
            slotRec.avaVal=true;
            slotRec.beginDate=slotv.DTE_BEGIN_SLOT__c;         
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(2);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slotRec.authVal=authSame.id;    
            slot=JSON.serialize(slotRec);
                
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
            slotRec.authVal=authN.id;    
            slotRec.endDate=system.today().addMonths(3);
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
         
        }
        Test.stopTest();
    }
      public static testMethod void scenarioB1(){
       	LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        boolean oc=false;
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        String slot='';
        T_SLOT_CONTRACT__c slotv=[select id ,name ,IDN_AUTH__c,DTE_BEGIN_SLOT__c from T_SLOT_CONTRACT__c limit 1];
        
        List<T_AUTH__c> authList =[SELECT Id, Name,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c FROM T_AUTH__c];
       
        T_AUTH__c authSame=new T_AUTH__c();//=TestClassUtility.createAuthorization(true, system.today().addMonths(1), system.today(), county.id, prvder.id);
        T_AUTH__c authN=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(3), system.today().addMonths(2), county.id, prvder.id);
        T_AUTH__c authN1=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(5), system.today().addMonths(4), county.id, prvder.id);
        
        for(T_AUTH__c indi :authList)
        {
            if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today())
            {
                authSame=indi;
            }
            else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(2))
            {
                authN=indi;
            }else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(4))
            {
                authN1=indi;
            }
        }
        authSame.IDN_SLOT_CONTRACT__c=null;
        update authSame;
        slotv.IDN_AUTH__c=null;
        update slotv;
        
        Test.startTest();     
        System.runAs(pwUser){
            slotRec.avaVal=true;
            slotRec.beginDate=slotv.DTE_BEGIN_SLOT__c+10;         
            slotRec.countyVal=county.id;
            slotRec.endDate=authSame.DTE_END_EFFV_AUTH__c;
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slotRec.authVal=authSame.id;    
            slot=JSON.serialize(slotRec);
                
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
            slotRec.authVal=authN.id; 
            slotRec.beginDate=authN.DTE_BEGIN_EFFV_AUTH__c;
            slotRec.endDate=authN.DTE_END_EFFV_AUTH__c+25;
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
         
        }
        Test.stopTest();
    }
        public static testMethod void scenarioB2(){
       	LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        boolean oc=false;
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        String slot='';
        T_SLOT_CONTRACT__c slotv=[select id ,name ,IDN_AUTH__c,DTE_BEGIN_SLOT__c from T_SLOT_CONTRACT__c limit 1];
        
        List<T_AUTH__c> authList =[SELECT Id, Name,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c FROM T_AUTH__c];
       
        T_AUTH__c authSame=new T_AUTH__c();//=TestClassUtility.createAuthorization(true, system.today().addMonths(1), system.today(), county.id, prvder.id);
        T_AUTH__c authN=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(3), system.today().addMonths(2), county.id, prvder.id);
        T_AUTH__c authN1=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(5), system.today().addMonths(4), county.id, prvder.id);
        
        for(T_AUTH__c indi :authList)
        {
            if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today())
            {
                authSame=indi;
            }
            else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(2))
            {
                authN=indi;
            }else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(4))
            {
                authN1=indi;
            }
        }
        
        slotv.IDN_AUTH__c=null;
        update slotv;
        
        Test.startTest();     
        System.runAs(pwUser){
            slotRec.avaVal=true;
            slotRec.beginDate=authSame.DTE_BEGIN_EFFV_AUTH__c-15;         
            slotRec.countyVal=county.id;
            slotRec.endDate=authSame.DTE_END_EFFV_AUTH__c+15;
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slotRec.authVal=authSame.id;    
            slot=JSON.serialize(slotRec);
                
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
            slotRec.authVal=authN.id; 
            slotRec.endDate=authN.DTE_END_EFFV_AUTH__c;
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
        	
        }
        Test.stopTest();
    }
        public static testMethod void scenarioB3(){
       	LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        boolean oc=true;
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        String slot='';
        T_SLOT_CONTRACT__c slotv=[select id ,name ,IDN_AUTH__c,DTE_BEGIN_SLOT__c from T_SLOT_CONTRACT__c limit 1];
         
        List<T_AUTH__c> authList =[SELECT Id, Name,DTE_BEGIN_EFFV_AUTH__c,DTE_END_EFFV_AUTH__c FROM T_AUTH__c];
       
        T_AUTH__c authSame=new T_AUTH__c();//=TestClassUtility.createAuthorization(true, system.today().addMonths(1), system.today(), county.id, prvder.id);
        T_AUTH__c authN=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(3), system.today().addMonths(2), county.id, prvder.id);
        T_AUTH__c authN1=new T_AUTH__c();//TestClassUtility.createAuthorization(true, system.today().addMonths(5), system.today().addMonths(4), county.id, prvder.id);
        
        for(T_AUTH__c indi :authList)
        {
            if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today())
            {
                authSame=indi;
            }
            else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(2))
            {
                authN=indi;
            }else if(indi.DTE_BEGIN_EFFV_AUTH__c==system.today().addMonths(4))
            {
                authN1=indi;
            }
        }  
        slotv.IDN_AUTH__c=null;
        update slotv;
        Test.startTest();     
        System.runAs(pwUser){
            slotRec.avaVal=false;
            slotRec.beginDate=authSame.DTE_BEGIN_EFFV_AUTH__c;
            slotRec.countyVal=county.id;
            slotRec.endDate=authSame.DTE_END_EFFV_AUTH__c;
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slotRec.authVal=authSame.id;
                
            slot=JSON.serialize(slotRec);
            response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
            
            slotRec.beginDate=slotv.DTE_BEGIN_SLOT__c+10; 
            oc=true;
          	response = EditSlotContractFlowApxCtrl.updateData(slot,slotv.id,oc);
            System.assertEquals(response.isSuccessful,true);
        }
        Test.stopTest();
    }
  
}