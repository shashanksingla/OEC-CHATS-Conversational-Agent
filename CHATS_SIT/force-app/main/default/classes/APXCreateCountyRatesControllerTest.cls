/********************************************************************************************
* NAME         : APXCreateCountyRatesControllerTest
* DESCRIPTION  : THIS TEST CLASS IS USED TO TEST THE FUNCTIONALITY IMPLEMENTED IN THE APXCreateCountyRatesController APEX CLASS.
* @AUTHOR SHUBHAM JAIN
* @DATE 09/25/2017
*
*
* MODIFICATION LOG:
* DEVELOPER                         DATE                               DESCRIPTION
* ----------------------------------------------------------------------------                 
********************************************************************************************/
@isTest
public class APXCreateCountyRatesControllerTest {
    
    Final static String DAY_CARE_HOME = 'HOM';
    
    Final static String DAY_CARE_CENTER = 'CEN';
    
    /********************************************************
    METHOD NAME  : getCountyRateTest
    DESCRIPTION    : This method tests the functionality implmented in getCountyRate method.
    RETURN TYPE    : VOID
    PARAMETER      : 
    **********************************************************/
    public static testMethod void getCountyRateTest(){
        LightningServerResponse lsr = APXCreateCountyRatesController.getCountyRateWithCountyRateAmounts(null, DAY_CARE_HOME);
        System.assertEquals(false,lsr.isSuccessful,'lsr.isSuccessful should be false');


        List<T_COUNTY_RATE__c> lstCountyRate= [SELECT Id,
                                               IDN_COUNTY__c,
                                               IDN_COUNTY__r.Name, 
                                               CDE_RATE_PLAN_TEMPLT__c,
                                               CDE_STATUS__c,
                                               DTE_BEGIN_EFFV_RATE__c FROM T_COUNTY_RATE__c];
        System.assertNotEquals(true, lstCountyRate.isEmpty(), 'lstCountyRate should not be empty');
        
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmountDayCareHome = [SELECT Id FROM T_COUNTY_RATE_AMT__c WHERE CDE_PROVR_TYPE__c = :DAY_CARE_HOME];
        lsr = APXCreateCountyRatesController.getCountyRateWithCountyRateAmounts(lstCountyRate.get(0).Id, DAY_CARE_HOME);
        System.assertEquals(true,lsr.isSuccessful,'lsr.isSuccessful should be true');
        System.assertEquals(true, lsr.objectData.containsKey('countyRateWithCountyRateAmounts'), 'objectData should contain countyRateWithCountyRateAmounts as a key');
        T_COUNTY_RATE__c returnedCountyRateWithCountyRateAmounts = (T_COUNTY_RATE__c)lsr.objectData.get('countyRateWithCountyRateAmounts');
        System.assertEquals(returnedCountyRateWithCountyRateAmounts.IDN_COUNTY__r.Name, lstCountyRate.get(0).IDN_COUNTY__r.Name, 'County Name should match');
        System.assertEquals(returnedCountyRateWithCountyRateAmounts.DTE_BEGIN_EFFV_RATE__c, lstCountyRate.get(0).DTE_BEGIN_EFFV_RATE__c, 'DTE_BEGIN_EFFV_RATE__c should match');
        System.assertEquals(returnedCountyRateWithCountyRateAmounts.CDE_STATUS__c, lstCountyRate.get(0).CDE_STATUS__c, 'CDE_STATUS__c should match');
        
    }
    
    /********************************************************
    METHOD NAME  : testSaveLstCountyRateAmount
    DESCRIPTION    : This method tests the functionality implmented in saveLstCountyRateAmount method.
    RETURN TYPE    : VOID
    PARAMETER      : 
    **********************************************************/
    public static testMethod void testSaveLstCountyRateAmount(){
        List<T_COUNTY_RATE__c> lstCountyRate= [SELECT Id,
                                               IDN_COUNTY__c,
                                               IDN_COUNTY__r.Name, 
                                               CDE_RATE_PLAN_TEMPLT__c,
                                               CDE_STATUS__c,
                                               DTE_BEGIN_EFFV_RATE__c FROM T_COUNTY_RATE__c];
        System.assertNotEquals(true, lstCountyRate.isEmpty(), 'lstCountyRate should not be empty');
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmount = new List<T_COUNTY_RATE_AMT__c>();
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmountDayCareHome = [SELECT Id FROM T_COUNTY_RATE_AMT__c WHERE CDE_PROVR_TYPE__c = :DAY_CARE_HOME];
        System.assertNotEquals(true, lstCountyRateAmountDayCareHome.isEmpty(), 'lstCountyRateAmountDayCareHome should not be empty');
        lstCountyRateAmount.add(new T_COUNTY_RATE_AMT__c(Id = lstCountyRateAmountDayCareHome.get(0).Id,
                                                         NBR_AMOUNT__c = 128
                                                        ));
        lstCountyRateAmount.add(new T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 123,
            CDE_UNIT__c = '3',
            IDN_COUNTY_RATE__c = lstCountyRate.get(0).Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = DAY_CARE_HOME,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='1'
        ));        
        
        Map<String,Object> objectData = APXCreateCountyRatesController.saveLstCountyRateAmount(lstCountyRateAmount, lstCountyRate.get(0).Id, DAY_CARE_HOME);
        System.assertEquals(true, objectData.get('isSuccessful'), 'isSuccessful should be true');
        lstCountyRateAmount.clear();
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmountDayCareCenter = [SELECT Id FROM T_COUNTY_RATE_AMT__c WHERE CDE_PROVR_TYPE__c = :DAY_CARE_CENTER];
        System.assertNotEquals(true, lstCountyRateAmountDayCareCenter.isEmpty(), 'lstCountyRateAmountDayCareCenter should not be empty');
        
        lstCountyRateAmount.add(new T_COUNTY_RATE_AMT__c(Id = lstCountyRateAmountDayCareCenter.get(0).Id,
                                                         NBR_AMOUNT__c = 123
                                                        ));
        objectData = APXCreateCountyRatesController.saveLstCountyRateAmount(lstCountyRateAmount, lstCountyRate.get(0).Id, DAY_CARE_CENTER);
        System.assertEquals(true, objectData.get('isSuccessful'), 'isSuccessful should be true');
        
        lstCountyRateAmount.clear();
        lstCountyRateAmount.add(new T_COUNTY_RATE_AMT__c(NBR_AMOUNT__c=123));        
        objectData = APXCreateCountyRatesController.saveLstCountyRateAmount(lstCountyRateAmount, lstCountyRate.get(0).Id, DAY_CARE_CENTER);
        System.assertEquals(true, objectData.get('isSuccessful'), 'isSuccessful should be true');
    }
    
    /********************************************************
METHOD NAME  : testCreateCountyRateAmountRecords
DESCRIPTION    : This method tests the functionality implmented in testCreateCountyRateAmountRecords method.
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/
    public static testMethod void testCreateCountyRateAmountRecords(){
        
        //Removed unused variable on 5/13/2018 BG      
        Map<String,List<String>> mapProviderTypeTierValues = new Map<String,List<String>>{
            'CEN'=>new List<String>{'2','3','4','5','6'},
                'HOM'=>new List<String>{'2','3','4','5','6'},
                    'EXE'=>new List<String>{'1'}                
        };
        List<String> lstAgeGroup = CountyRatePlanServices.getPicklistValues(T_COUNTY_RATE_AMT__c.CDE_AGE_GROUP__c.getDescribe());        
        List<String> lstRateTypes = CountyRatePlanServices.getPicklistValues(T_COUNTY_RATE_AMT__c.CDE_RATE_TYPE__c.getDescribe());  
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Test County', 'Test County Department', 10, true);
        T_COUNTY__c countyRec1 = TestClassUtility.createCounty('Test County1', 'Test County Department1', 9, true);
        T_COUNTY__c countyRec2 = TestClassUtility.createCounty('Test County2', 'Test County Department2', 8, true);
        List<T_COUNTY__c> lstCounty = [SELECT Id FROM T_COUNTY__c limit 1000];
       
        System.assertNotEquals(true, lstCounty.isEmpty(), 'lstCounty should not be empty');
        T_COUNTY_RATE__c testCountyRate = new T_COUNTY_RATE__c(
            //IDN_COUNTY__c = lstCounty.get(0).Id,
            IDN_COUNTY__c = countyRec.Id,
            CDE_STATUS__c = 'PEN',
            DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(3).toStartOfMonth(),
            CDE_RATE_PLAN_TEMPLT__c = '1',
            IND_RATE_PLAN_TEMPLT__c = true
        );
        
        T_COUNTY_RATE__c testCountyRate2 = new T_COUNTY_RATE__c(
            //IDN_COUNTY__c = lstCounty.get(1).Id,
            IDN_COUNTY__c = countyRec1.Id,
            CDE_RATE_PLAN_TEMPLT__c = '1',
            CDE_STATUS__c = 'PEN',
            DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(2).toStartOfMonth()
        );
        
        List<T_COUNTY_RATE__c> lstCountyRate = new List<T_COUNTY_RATE__c>();
        lstCountyRate.add(testCountyRate);
        lstCountyRate.add(testCountyRate2);
        user u =[Select id from User where UserName='newuserchats@testorg.com'];
        system.runAs(u){
            insert lstCountyRate;}
        //Removed unused variable on 5/13/2018 BG   
        List<T_COUNTY_RATE__c> lstFilteredCountyRatePlan = CountyRatePlanServices.filterCountyRatePlanTemplateRecords(lstCountyRate);
        System.assertEquals(1, lstFilteredCountyRatePlan.size(), 'Size of lstFilteredCountyRatePlan should be 1.');
        List<T_COUNTY_RATE_AMT__c> lstCountyRateAmount = [SELECT Id FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c = :lstFilteredCountyRatePlan.get(0).Id AND CDE_UNIT__c='3'];
        
        Integer totalNumberOfRecords = lstAgeGroup.size()*
            lstRateTypes.size()*
            (mapProviderTypeTierValues.get('CEN').size()+
             mapProviderTypeTierValues.get('HOM').size()+
             mapProviderTypeTierValues.get('EXE').size());
       // System.assertEquals(totalNumberOfRecords, lstCountyRateAmount.size(), 'totalNumberOfRecords should be equal to size of lstCountyRateAmount');    
        
        
        T_COUNTY_RATE__c testCountyRate3 = new T_COUNTY_RATE__c(
            //IDN_COUNTY__c = lstCounty.get(0).Id,
            IDN_COUNTY__c = countyRec2.Id,
            CDE_RATE_PLAN_TEMPLT__c = '1',
            CDE_STATUS__c = 'PEN',
            DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(4).toStartOfMonth(),
            RATE_TYPE__c = '1;31'
            //IND_RATE_PLAN_TEMPLT__c = true
        );
        insert testCountyRate3;
        
        lstCountyRateAmount = [SELECT Id FROM T_COUNTY_RATE_AMT__c WHERE IDN_COUNTY_RATE__c = :testCountyRate3.Id];
        totalNumberOfRecords = lstAgeGroup.size()*
            lstRateTypes.size()*
            (mapProviderTypeTierValues.get('CEN').size()
             +mapProviderTypeTierValues.get('HOM').size()
             +mapProviderTypeTierValues.get('EXE').size()
            )*4;// as FTFT,PT,PTFT will be created on FT records insertion
       // System.assertEquals(totalNumberOfRecords, lstCountyRateAmount.size(), 'totalNumberOfRecords should be equal to size of lstCountyRateAmount');    
        
        
    }
    
    
    
    
    @TestSetup
    public static void testDataSetup(){
    	CHATSUtility.createTemplateUser();
        T_COUNTY__c testCounty = new T_COUNTY__c(
            CDE_COUNTY__c = 12,
            CNTY_DEPT_NAME__c = 'Test County'
        );
        insert testCounty;
        
        T_COUNTY_RATE__c testCountyRate = new T_COUNTY_RATE__c(
            IDN_COUNTY__c = testCounty.Id,
            CDE_RATE_PLAN_TEMPLT__c = '1',
            CDE_STATUS__c = 'PEN',
            DTE_BEGIN_EFFV_RATE__c = System.today().addMonths(1).toStartOfMonth()
        );
        
        insert testCountyRate;
        
        T_COUNTY_RATE_AMT__c testCountyRateAmount = new T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 123,
            CDE_UNIT__c = '3',
            IDN_COUNTY_RATE__c = testCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = DAY_CARE_HOME,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='3'
        );
        
        T_COUNTY_RATE_AMT__c testCountyRateAmount2 = new T_COUNTY_RATE_AMT__c(
            CDE_AGE_GROUP__c = '1',
            NBR_AMOUNT__c = 123,
            CDE_UNIT__c = '3',
            IDN_COUNTY_RATE__c = testCountyRate.Id,
            CDE_RATE_TEMPLT__c = '1',
            CDE_PROVR_TYPE__c = DAY_CARE_CENTER,
            CDE_RATE_TYPE__c = '1',
            CDE_TIER__c ='3'
        );
        
        insert new List<T_COUNTY_RATE_AMT__c>{testCountyRateAmount,testCountyRateAmount2};
            }
    
}