/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/02/2017                                                          
*  @description    Test class for countyPlanFlowController class                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 2-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
@isTest
private class countyPlanFlowController_Test {
   
    static testMethod void testgetCountyPlanRecord() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_PLAN__c countyRatePlan=TestClassUtility.createCountyPlan('PEN',false); 
        countyRatePlan.CDE_COUNTY__c = county.Id;
        countyRatePlan.CDE_COUNTY_PLAN_TEMPLT__c = '1';
        countyRatePlan.DTE_BEGIN_EFFEV__c=System.today().addMonths(1).toStartOfMonth();
        insert countyRatePlan;
        LightningServerResponse  lightserresobj= countyPlanFlowController.getCountyPlanRecord(countyRatePlan.Id);
        system.assertEquals(true,lightserresobj.isSuccessful,'It should be successful');
        system.assertEquals('Success',lightserresobj.successMessage ,'It should be success');
        system.debug(lightserresobj.objectData.get('countyRatePlanRecord'));
        system.assert(String.valueOf(lightserresobj.objectData.get('countyPlanRecord')).Contains(countyRatePlan.Id),'It should not return null');
              
        //Exception scenario
        LightningServerResponse  lightserresobj2= countyPlanFlowController.getCountyPlanRecord(county.Id);
        system.assertEquals(false,lightserresobj2.isSuccessful,'It should be successful');
        system.assertEquals(null,lightserresobj2.objectData,'It is not returning NULL where in it supposed to return NULL');    
    }
      
    static testMethod void testgetCountyPlanRecordForTemplate() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_PLAN__c countyRatePlan=TestClassUtility.createCountyPlan('PEN',false); 
        countyRatePlan.CDE_COUNTY__c = county.Id;
        countyRatePlan.CDE_COUNTY_PLAN_TEMPLT__c = '1';
        countyRatePlan.IND_COUNTY_PLAN_TEMPLT__c =true;
        countyRatePlan.DTE_BEGIN_EFFEV__c=System.today().addMonths(1).toStartOfMonth();
        user u =[Select id from User where UserName='newuserchats@testorg.com'];
        system.runAs(u){
            insert countyRatePlan;
        }
        LightningServerResponse  lightserresobj= countyPlanFlowController.getCountyPlanRecordForTemplate(countyRatePlan.CDE_COUNTY_PLAN_TEMPLT__c,countyRatePlan.CDE_COUNTY__c);
        system.assertEquals(true,lightserresobj.isSuccessful,'It should be successful');
        system.assertEquals('Success',lightserresobj.successMessage ,'It should be success');
        system.debug(lightserresobj.objectData.get('countyRatePlanRecord'));
    
        //Exception scenario
        LightningServerResponse  lightserresobj2= countyPlanFlowController.getCountyPlanRecordForTemplate('error',countyRatePlan.Id);
        map<String, Object> respMap = countyPlanFlowController.ownerCountyValidation(county.Id, true);
        Boolean contyMatched = (Boolean)respMap.get('countyMatched');
        system.assertEquals(true,contyMatched);
        respMap = countyPlanFlowController.ownerCountyValidation(countyRatePlan.Id, false);
        Boolean contyMatched2 = (Boolean)respMap.get('countyMatched');
        system.assertEquals(true,contyMatched2);
        //system.assertEquals(false,lightserresobj2.isSuccessful,'It should be successful');
        //system.assertEquals(null,lightserresobj2.objectData,'It is not returning NULL where in it supposed to return NULL');    
    }
    
    static testMethod void tesGetCountyValidatedForNewCountyPlan() {        
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_PLAN__c countyPlan = TestClassUtility.createCountyPlan('PEN',false); 
        T_COUNTY_PLAN__c returnedCountyPlan= countyPlanFlowController.getCountyValidatedForNewCountyPlan(county.Id);
        system.assertEquals(null,returnedCountyPlan.Id,'County plan has no reocrds');
        countyPlan.CDE_COUNTY__c = county.Id;
        insert countyPlan;
        T_COUNTY_PLAN__c returnedCountyPlan1= countyPlanFlowController.getCountyValidatedForNewCountyPlan(county.Id);
        system.assertEquals(countyPlan.Id,returnedCountyPlan1.Id,'County plan has reocrds');
    }
    
    @TestSetup
    public static void testDataSetup(){
        CHATSUtility.createTemplateUser();
    }
}