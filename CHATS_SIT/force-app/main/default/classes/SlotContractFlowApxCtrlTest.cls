@isTest
public class SlotContractFlowApxCtrlTest {
     
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
        
        T_AUTH__c authSame =TestClassUtility.createAuthorization(true, system.today().addMonths(3), system.today(), county.id, prvder.id);        
    }
    
    public static testMethod void runTestgetInitData(){
        LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
       
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        T_AUTH__c authSame =[SELECT Id, Name FROM T_AUTH__c limit 1];
        String slot='';
        Test.startTest();
        
        System.runAs(pwUser){            
            //slotRec.authVal=null;
            slotRec.avaVal=true;
            slotRec.beginDate=system.today();         
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(10);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slot=JSON.serialize(slotRec);
            
            response = SlotContractFlowApxCtrl.saveData(slot);
            System.assertEquals(response.isSuccessful,true);
            response= SlotContractFlowApxCtrl.getInitData(prvder.id);
            System.assertEquals(response.isSuccessful,true);
            
            response = SlotContractFlowApxCtrl.getRateTypeByBegin(slot);
            System.assertEquals(response.isSuccessful,true);      
            
            SlotContractFlowApxCtrl.SlotWrapper slotRecSame=slotRec.clone(); 
            slotRecSame.authVal=authSame.id;
            slot=JSON.serialize(slotRecSame);
            response= SlotContractFlowApxCtrl.saveData(slot);
          //  System.assertEquals(response.isSuccessful,true);   
        }
        Test.stopTest();
    }
    
    public static testMethod void scenarion1(){
      	LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        String slot='';
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        T_AUTH__c authSame =[SELECT Id, Name FROM T_AUTH__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        Test.startTest();
        
        System.runAs(pwUser){
            slotRec.authVal=authSame.id;
            slotRec.avaVal=true;
            slotRec.beginDate=system.today().addMonths(-5);     
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(4);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slot=JSON.serialize(slotRec);
            
            LightningServerResponse resp1 = SlotContractFlowApxCtrl.saveData(slot);
            System.assertEquals(resp1.isSuccessful,true);  
        }
        Test.stopTest();
    }

    public static testMethod void scenarion2(){
        LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        String slot='';
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        T_AUTH__c authSame =[SELECT Id, Name FROM T_AUTH__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        Test.startTest();
        System.runAs(pwUser){
            slotRec.authVal=authSame.id;
            slotRec.avaVal=true;
            slotRec.beginDate=system.today()-10;     
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(1);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slot=JSON.serialize(slotRec);
            
            response = SlotContractFlowApxCtrl.saveData(slot);
            System.assertEquals(response.isSuccessful,true);  
            slotRec.beginDate=system.today()+40;
            slotRec.endDate=system.today().addMonths(2);
            slotRec.authVal=authSame.id;
            
            slot=JSON.serialize(slotRec);
            
            response = SlotContractFlowApxCtrl.saveData(slot);
            //System.assertEquals(response.isSuccessful,true);  
        }
        Test.stopTest();
    }
    
    public static testMethod void scenarion3(){
        LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        String slot='';
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        T_AUTH__c authSame =[SELECT Id, Name FROM T_AUTH__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        Test.startTest();
        System.runAs(pwUser){
           
            slotRec.authVal=authSame.id;
            slotRec.avaVal=true;
            slotRec.beginDate=system.today().addMonths(4);     
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(5);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slot=JSON.serialize(slotRec);
            
            response = SlotContractFlowApxCtrl.saveData(slot);
            System.assertEquals(response.isSuccessful,false);  
         
            slotRec.beginDate=system.today().addMonths(-4);
            slotRec.endDate=system.today().addMonths(-1);
            slotRec.authVal=authSame.id;
            
            slot=JSON.serialize(slotRec);
            
            response = SlotContractFlowApxCtrl.saveData(slot);
            System.assertEquals(response.isSuccessful,false);  
            
            slotRec.beginDate=system.today();
            slotRec.endDate=system.today().addMonths(3);
            slotRec.authVal=authSame.id;
            
            slot=JSON.serialize(slotRec);
            
            response = SlotContractFlowApxCtrl.saveData(slot);
            System.assertEquals(response.isSuccessful,true);
            
            T_SLOT_CONTRACT__c sc = [select id, name from T_SLOT_CONTRACT__c where IDN_AUTH__c!=null limit 1];
            
            response = SlotContractUtility.getSlotContractHistory(sc.id);
            System.assertEquals(response.isSuccessful,true);
            
			SlotContractUtility.ALLOW_DELETE = true;      
            
            delete sc;
        }
        Test.stopTest();
    }
    
    public static testMethod void scenarion4(){
        LightningServerResponse response;
        SlotContractFlowApxCtrl.SlotWrapper slotRec =new SlotContractFlowApxCtrl.SlotWrapper(); 
        String slot='';
        T_CHATS_PROVR_STATUS__c prvder=[SELECT Id, Name FROM T_CHATS_PROVR_STATUS__c limit 1];
        T_AUTH__c authSame =[SELECT Id, Name FROM T_AUTH__c limit 1];
        id profId=[SELECT Id FROM Profile WHERE Name = 'CHATS System Administrator'].Id;
        User pwUser=TestClassUtility.createUser(profId, 'myTestLast', 'myTestFirst', 'puser000@amamama.com', 'puser000@amamama.com' + System.currentTimeMillis(), 'myAlias');
        pwUser.Owner_County__c='1';
        insert pwUser;
        T_COUNTY__c county=[select id , name from T_COUNTY__c limit 1];
        Test.startTest();
        System.runAs(pwUser){           
            slotRec.authVal=authSame.id;
            slotRec.avaVal=true;
            slotRec.beginDate=system.today().addMonths(1);     
            slotRec.countyVal=county.id;
            slotRec.endDate=system.today().addMonths(5);
            slotRec.noDays=5;
            slotRec.provdId=prvder.id;
            slotRec.scdesc='testttt';
            slotRec.weekData = new List<string>();
            slotRec.weekData.add('Monday');
            slotRec.weekData.add('Tuesday');
            slot=JSON.serialize(slotRec);
            
            response = SlotContractFlowApxCtrl.saveData(slot);
            System.assertEquals(response.isSuccessful,true);           
        }
        Test.stopTest();
    }
}