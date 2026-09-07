/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/22/2017                                                          
*  @description    Test class for Payment Plan Trigger                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 22-Nov-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/

@isTest
private class PaymentPlanServices_Test {
    @testSetup static void setup() {
        List<T_CHATS_PROVR_STATUS__c> providerList = new List<T_CHATS_PROVR_STATUS__c >();
        List<T_PMT_PLAN__c> paymntList = new List<T_PMT_PLAN__c>();
        
        for(Integer i=0;i<201;i++) {
            providerList.add(new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'abc'));
        }
    
        insert providerList;
        
        for(Integer i=0;i<201;i++) {
            paymntList.add((T_PMT_PLAN__c)TestClassUtility.createPaymentPlan(false,providerList[i].Id,null,10,10));
        }
    
        insert paymntList;       

    }    
    static testMethod void testEndPreviousStatus() {
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'abc');
        insert provider;
        
        Test.startTest();
        T_PMT_PLAN__c paymentplan1 = TestClassUtility.createPaymentPlan(true,provider.Id,null,10,10);
        T_PMT_PLAN__c paymentplan2 = TestClassUtility.createPaymentPlan(true,provider.Id,null,20,10);
        system.assertEquals(false,[Select IND_ACTIVE__c from T_PMT_PLAN__c where Id=:paymentplan1.Id].IND_ACTIVE__c,'Previous Payment Plan is not deactivated');

        system.assertEquals(true,[Select IND_ACTIVE__c from T_PMT_PLAN__c where Id=:paymentplan2.Id].IND_ACTIVE__c,'New Payment Plan is not activated');

        Test.stopTest();
    }

    static testMethod void testEndPreviousStatusBulk() {
        List<T_PMT_PLAN__c> paymntList = new List<T_PMT_PLAN__c>();
        for(T_CHATS_PROVR_STATUS__c provider:[Select Id from T_CHATS_PROVR_STATUS__c Limit 210]) {
            paymntList.add((T_PMT_PLAN__c)TestClassUtility.createPaymentPlan(false,provider.Id,null,10,10));
            
        }
        Test.startTest();
        insert paymntList; 
        PaymentPlanServices.activePaymentPlanCheck(paymntList);
        PaymentPlanServices.deactivatePreviousPlan(paymntList);
        PaymentPlanServices.countyCheck(paymntList,true);
        
        Test.stopTest();
        for(T_PMT_PLAN__c paymentPl:[Select IND_ACTIVE__c from T_PMT_PLAN__c where Id NOT IN:paymntList Limit 210]) {
            system.assertEquals(false,paymentPl.IND_ACTIVE__c,'Previous Payment Plan is not deactivated');
        } 
        
        for(T_PMT_PLAN__c paymentPl:[Select IND_ACTIVE__c from T_PMT_PLAN__c where Id IN:paymntList Limit 210]) {
            system.assertEquals(true,paymentPl.IND_ACTIVE__c,'New Payment Plan is not activated');
        }
    }
}