@isTest
public class SlotContractUpdateBatchTest {
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
        T_AUTH__c authSame=TestClassUtility.createAuthorization(true, system.today().addDays(20), system.today(), county.id, prvder.id);
        T_AUTH__c authN=TestClassUtility.createAuthorization(true, system.today().addDays(25), system.today().addDays(21), county.id, prvder.id);
        T_AUTH__c authN1=TestClassUtility.createAuthorization(true, system.today().addDays(29), system.today().addDays(27), county.id, prvder.id);

     
        
        List<T_SLOT_CONTRACT__c> slotList=new  List<T_SLOT_CONTRACT__c>();
        Boolean to=false;
        for(integer i=0;i<8;i++)
        {
			T_SLOT_CONTRACT__c sloto23=new T_SLOT_CONTRACT__c();
        	sloto23.IDN_ADDENDUM__c=adde.id;
        	sloto23.CNT_DAYS_OF_MONTH__c=8;
        	sloto23.CDE_COUNTY__c=county.id;
        	sloto23.IDN_PROVIDER__c=prvder.id;
        	sloto23.CNT_DAYS_OF_WEEK__c='Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday';
        	sloto23.CDE_CARE_LEVEL__c='3';
        	sloto23.CDE_CARE_UNIT__c='4';
        	sloto23.CDE_PRG_TYPE__c='LI';
        	sloto23.CDE_RATE_TYPE__c='43';
        	sloto23.DTE_BEGIN_SLOT__c=to? system.today() : system.today().addDays(16) ;
        	sloto23.DTE_END_SLOT__c=to ? system.today().addDays(15) : system.today().addDays(26);
        	sloto23.SLOT_CONTRACT_DESCRIPTION__c='test first';
       		sloto23.IND_AVAILABLE__c=true;
            if(i==2 || i==3)
            {
                sloto23.IDN_AUTH__c=authSame.id; 
            }
            
            if(i==4)
            {
                sloto23.IDN_AUTH__c=authN.id; 
            }
            if(i==6)
            {
                sloto23.IDN_AUTH__c=authN1.id;
                sloto23.DTE_BEGIN_SLOT__c=system.today().addDays(27);
        		sloto23.DTE_END_SLOT__c=system.today().addDays(29);
                sloto23.SLOT_CONTRACT_DESCRIPTION__c='Expiring';
                
            }
            if(i==7)
            {
               // sloto23.IDN_AUTH__c=authN1.id;
                sloto23.DTE_BEGIN_SLOT__c=system.today().addDays(30);
        		sloto23.DTE_END_SLOT__c=system.today().addDays(35);
                sloto23.SLOT_CONTRACT_DESCRIPTION__c='Expiring';
                
            }
            if(to==false)
            {
                to=true;
            }else{
                 to=false;
            }
           
            slotList.add(sloto23);
        }
        insert slotList;
    }

    public static testMethod void testSCAddendumBatch(){
        Test.startTest();
       
        Database.executeBatch(new SlotContractUpdateBatch(),200);
        Test.stopTest();
        

    }
}