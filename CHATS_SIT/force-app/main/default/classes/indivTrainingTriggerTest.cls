/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/17/2018                                                          
*  @description    Adjustment Payment Detail Trigger Test  
*  * Version: 1.0                                                                             
*  * Date: 02/17/2018                                                             
*  * Author: Gaurav Dharra                                                 
*  * Description: Initial version
*********************************************************************************************/
@isTest
public class indivTrainingTriggerTest {
    public static testMethod void testStampSalesforceIdToExternalId(){
        T_SBSD_INDIV__c indivObj = TestClassUtility.createIndividual(true, Date.newInstance(2000, 02, 02), 'firstName', '1', 'lastName', '01234567', 'CC');
        T_INDIV_TRAIN__c indivTraining = new T_INDIV_TRAIN__c (IDN_CLIENT__c = indivObj.Id,
                                                              	Ignore__c = true,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = System.today()+31);
        Test.startTest();
        insert indivTraining;
        T_INDIV_TRAIN__c IndivTrain =[Select Id, IDN_EXTNL__c from T_INDIV_TRAIN__c where Id=:indivTraining.Id];
        T_INDIV_TRAIN_INFO__c indivTraining1 = new T_INDIV_TRAIN_INFO__c (IDN_TRAIN_INDIV__c = IndivTrain.Id,
                                                              	DTE_BEGIN_EFFV__c = System.today(),
                                                              	DTE_END_EFFV__c = System.today()+31);
        insert indivTraining1;
        ParentTrainingBreakBatch obj = new ParentTrainingBreakBatch();
        DataBase.executeBatch(obj); 
         system.assertEquals(IndivTrain.Id,IndivTrain.IDN_EXTNL__c,'External Id is not matching with record Id');
        Test.stopTest();
        
    }
}