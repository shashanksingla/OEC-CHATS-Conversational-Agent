@isTest(seeAllData=false)
public class CountyRateServices_Test {
    
    static final String CENTER='CEN';
    static final String FT = '3'; 
    static final String PT = '2'; 
    static final String FTPT = '4';
    static final String FTFT = '5'; 
    
    private static T_COUNTY_RATE__c aCountyRate ;
    
    public static Map<String, Decimal> unitTypeToMultiplicationFactor{
        get{
            if(unitTypeToMultiplicationFactor == null){
                unitTypeToMultiplicationFactor = new Map<String, Decimal>();
                //query metadata and populate
                for(County_Rate_Unit_Amount_Calculation__mdt  rateAmtMultiplication:[Select Multiplication_Factor__c, Rate_Unit_Type__c from County_Rate_Unit_Amount_Calculation__mdt limit 1000]){
                    	unitTypeToMultiplicationFactor.put(rateAmtMultiplication.Rate_Unit_Type__c, rateAmtMultiplication.Multiplication_Factor__c);	
                }
                
            }
            
            return unitTypeToMultiplicationFactor;
        }set;
    }
    
    @TestSetup
    public static void userSetup(){
        CHATSUtility.createTemplateUser();
    }
    
    public static void testDataSetup(){
    	
        T_COUNTY__c aCounty=TestClassUtility.createCounty('Test County', 'Test County Department', 11, true);
        
        aCountyRate = TestClassUtility.createCountyRatePlan('APV', false);
        
        aCountyRate.IDN_COUNTY__c=aCounty.Id;
        aCountyRate.CDE_RATE_PLAN_TEMPLT__c='1';
        aCountyRate.IND_RATE_PLAN_TEMPLT__c=true;
        aCountyRate.DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(1).toStartOfMonth();
        
        user u =[Select id from User where UserName='newuserchats@testorg.com'];
        system.runAs(u){
            insert aCountyRate;}
        
        T_COUNTY_RATE_AMT__c countyRateWithFTCareUnit=new  T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 123,
            CDE_UNIT__c = FT,
            IDN_COUNTY_RATE__c = aCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = CENTER,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='4'
            
        );
        
        T_COUNTY_RATE_AMT__c countyRateWithPTCareUnit=new  T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 0,
            CDE_UNIT__c = PT,
            IDN_COUNTY_RATE__c = aCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = CENTER,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='4'
            
        );
        
        T_COUNTY_RATE_AMT__c countyRateWithFTFTCareUnit=new  T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 0,
            CDE_UNIT__c = FTFT,
            IDN_COUNTY_RATE__c = aCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = CENTER,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='4'
            
        ); 
        
        T_COUNTY_RATE_AMT__c countyRateWithFTPTCareUnit=new  T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 0,
            CDE_UNIT__c = FTPT,
            IDN_COUNTY_RATE__c = aCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = CENTER,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='4'
            
        ); 
        
        List<T_COUNTY_RATE_AMT__c> lstCountyRates = new List<T_COUNTY_RATE_AMT__c>{countyRateWithFTCareUnit,countyRateWithPTCareUnit,countyRateWithFTFTCareUnit,countyRateWithFTPTCareUnit};
            insert lstCountyRates ;
       
    }
    
    static testmethod  void testCountyRateAmountAfterUpdateTrigger(){
        testDataSetup();
        
        Test.startTest();
        T_COUNTY_RATE_AMT__c countyRateAmountForFT = [Select Id, NBR_AMOUNT__c,CDE_UNIT__c from T_COUNTY_RATE_AMT__c where CDE_UNIT__c=:FT and IDN_COUNTY_RATE__c =:aCountyRate.Id AND CDE_RATE_TYPE__c = '1' AND CDE_AGE_GROUP__c = '1' AND CDE_PROVR_TYPE__c = :CENTER AND NBR_AMOUNT__c!=0]; 
        countyRateAmountForFT.NBR_AMOUNT__c=100;
        update countyRateAmountForFT;
        
        List<T_COUNTY_RATE_AMT__c> lstCountyRate = [Select Id, NBR_AMOUNT__c,CDE_UNIT__c from T_COUNTY_RATE_AMT__c where IDN_COUNTY_RATE__c =:aCountyRate.Id];
        T_COUNTY_RATE_AMT__c countyRateAmountFT = [Select Id, NBR_AMOUNT__c,CDE_UNIT__c from T_COUNTY_RATE_AMT__c where CDE_UNIT__c=:FT and IDN_COUNTY_RATE__c =:aCountyRate.Id AND CDE_RATE_TYPE__c = '1' AND CDE_AGE_GROUP__c = '1' AND CDE_PROVR_TYPE__c = :CENTER AND NBR_AMOUNT__c!=0]; 
            
        for(T_COUNTY_RATE_AMT__c countyRate : lstCountyRate ){
            if(countyRate.CDE_UNIT__c != FT && countyRate.CDE_UNIT__c == countyRateAmountFT.CDE_UNIT__c){
                    System.assertEquals(countyRate.NBR_AMOUNT__c,  countyRateAmountFT.NBR_AMOUNT__c * unitTypeToMultiplicationFactor.get(countyRate.CDE_UNIT__c),'County Rate Amount should be match'); 
                }
            }
 
        Test.stopTest();
    }
    
    public static testMethod void testUpdateCountyRates(){
        testDataSetup();
        Test.startTest();
        T_COUNTY_RATE_AMT__c countyRateAmountForFT = [Select Id, NBR_AMOUNT__c,CDE_UNIT__c,CDE_PROVR_TYPE__c,CDE_RATE_TYPE__c,CDE_AGE_GROUP__c,CDE_TIER__c,IDN_COUNTY_RATE__c from T_COUNTY_RATE_AMT__c where CDE_UNIT__c=:FT and IDN_COUNTY_RATE__c =:aCountyRate.Id AND CDE_RATE_TYPE__c = '1' AND CDE_AGE_GROUP__c = '1' AND CDE_PROVR_TYPE__c = :CENTER AND NBR_AMOUNT__c!=0]; 
        //countyRateAmountForFT.PAYMENT_Q17__c='SomeRandomValue';
                String key = countyRateAmountForFT.CDE_PROVR_TYPE__c + '_' +
                    countyRateAmountForFT.CDE_RATE_TYPE__c + '_' + countyRateAmountForFT.CDE_AGE_GROUP__c+'_'+
                    countyRateAmountForFT.CDE_TIER__c + '_' + countyRateAmountForFT.IDN_COUNTY_RATE__c;            
        CountyRateServices.updateCountyRates(new List<T_COUNTY_RATE_AMT__c>{countyRateAmountForFT}, new Map<String, T_COUNTY_RATE_AMT__c>{key=>countyRateAmountForFT});
        System.assertNotEquals(null, [Select Id from T_COUNTY_RATE_AMT__c where CDE_UNIT__c=:FT and IDN_COUNTY_RATE__c =:countyRateAmountForFT.Id AND CDE_RATE_TYPE__c = '1' AND CDE_AGE_GROUP__c = '1' AND CDE_PROVR_TYPE__c = :CENTER AND NBR_AMOUNT__c!=0 LIMIT 1],'Query should return Coynty Rate records');
        Test.stopTest();
    }
      
    //[SJ 7/3/18: Added new test method to cover negetive scenario for UpdateCountyRates method]
    public static testMethod void testUpdateCountyRatesNegetive(){
        testDataSetup();
        Test.startTest();
        T_COUNTY_RATE_AMT__c countyRateAmountForFTToBeUpdated = [Select Id, NBR_AMOUNT__c,CDE_UNIT__c,CDE_PROVR_TYPE__c,CDE_RATE_TYPE__c,CDE_AGE_GROUP__c,CDE_TIER__c,IDN_COUNTY_RATE__c from T_COUNTY_RATE_AMT__c where CDE_UNIT__c=:FT and IDN_COUNTY_RATE__c =:aCountyRate.Id AND CDE_RATE_TYPE__c = '1' AND CDE_AGE_GROUP__c = '1' AND CDE_PROVR_TYPE__c = :CENTER AND NBR_AMOUNT__c!=0]; 
        countyRateAmountForFTToBeUpdated.CDE_AGE_GROUP__c='SOMEJUNKVALLUE';
        T_COUNTY_RATE_AMT__c countyRateAmountForFTToBeInserted = new T_COUNTY_RATE_AMT__c();
        countyRateAmountForFTToBeInserted.CDE_PROVR_TYPE__c = '1';
        countyRateAmountForFTToBeInserted.CDE_RATE_TYPE__c = '1';
        countyRateAmountForFTToBeInserted.CDE_AGE_GROUP__c = '1';
        countyRateAmountForFTToBeInserted.CDE_TIER__c = '1';
        countyRateAmountForFTToBeInserted.CDE_UNIT__c = FT;
        countyRateAmountForFTToBeInserted.IDN_COUNTY_RATE__c = countyRateAmountForFTToBeUpdated.IDN_COUNTY_RATE__c;
        String key = countyRateAmountForFTToBeUpdated.CDE_PROVR_TYPE__c + '_' +
            countyRateAmountForFTToBeUpdated.CDE_RATE_TYPE__c + '_' + countyRateAmountForFTToBeUpdated.CDE_AGE_GROUP__c+'_'+
            countyRateAmountForFTToBeUpdated.CDE_TIER__c + '_' + countyRateAmountForFTToBeUpdated.IDN_COUNTY_RATE__c;  
        String key2 = countyRateAmountForFTToBeInserted.CDE_PROVR_TYPE__c + '_' +
            countyRateAmountForFTToBeInserted.CDE_RATE_TYPE__c + '_' + countyRateAmountForFTToBeInserted.CDE_AGE_GROUP__c+'_'+
            countyRateAmountForFTToBeInserted.CDE_TIER__c + '_' + countyRateAmountForFTToBeInserted.IDN_COUNTY_RATE__c;  
        
        CountyRateServices.updateCountyRates(new List<T_COUNTY_RATE_AMT__c>{countyRateAmountForFTToBeUpdated,countyRateAmountForFTToBeInserted}, new Map<String, T_COUNTY_RATE_AMT__c>{key=>countyRateAmountForFTToBeUpdated, key2=>countyRateAmountForFTToBeInserted});
        System.assertNotEquals(null, [Select Id from T_COUNTY_RATE_AMT__c where CDE_UNIT__c=:FT and IDN_COUNTY_RATE__c =:countyRateAmountForFTToBeUpdated.Id AND CDE_RATE_TYPE__c = '1' AND CDE_AGE_GROUP__c = '1' AND CDE_PROVR_TYPE__c = :CENTER AND NBR_AMOUNT__c!=0 LIMIT 1],'Query should not return County Rate records');
        Test.stopTest();
    }
    
}