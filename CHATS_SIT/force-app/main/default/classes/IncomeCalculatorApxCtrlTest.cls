@isTest
public class IncomeCalculatorApxCtrlTest {
    
    public static testmethod void testGetCountyDataMethod(){
        TestClassUtility.createCounty('County1', 'Dept1', 10, true);
        TestClassUtility.createCountyPlan('PEN', false); 
        LightningServerResponse lsr = IncomeCalculatorApxCtrl.getCountyData(10);
        IncomeCalculatorApxCtrl.parentFeeDataAll(10, 10, 10, 10, 10);
        IncomeCalculatorApxCtrl.parentFeeDataAll(10, 110, 10, 10, 11);
        System.assertEquals(true, lsr.isSuccessful, 'Not record selected from County plan');
    }
    
    public static testmethod void testGetFPGValues(){
        LightningServerResponse lsr = IncomeCalculatorApxCtrl.getFPGValues();
        System.assertEquals(true, lsr.isSuccessful, 'isSuccessful should not be false');
    }
    
}