/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           3/17/2022                                                          
*  @description    Individual batch class test for auto update individual record to sync age with postgres database                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 17-Mar-2022                                                           
*  * Author: Diya Chaudhary                                                      
*  * Description: Initial version                   
*********************************************************************************************/
@isTest
public class UpdateIndivOnBirthDayBatchApxCtrl_Test {
    static testMethod void testMethod1() 
    {
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today(),'firstName','1','lastName','123','CC');
        Test.startTest();
        UpdateIndivOnBirthDayBatchApxCtrl obj = new UpdateIndivOnBirthDayBatchApxCtrl();
        DataBase.executeBatch(obj); 
        //system.assertEquals(10,[select Id from T_SBSD_INDIV__c limit 100].size(),'Query should return 10 Auth records');      
        Test.stopTest();
    }
    
}