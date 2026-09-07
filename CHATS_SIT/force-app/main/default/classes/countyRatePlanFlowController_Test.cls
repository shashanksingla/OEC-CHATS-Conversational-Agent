/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           12/02/2017                                                          
*  @description    Test class for countyRatePlanFlowController class                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 2-Dec-2017                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/
@isTest
private class countyRatePlanFlowController_Test {
  
    static testMethod void testgetCountyRatePlanRecord() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_RATE__c countyRatePlan=TestClassUtility.createCountyRatePlan('PEN',false); 
        countyRatePlan.IDN_COUNTY__c = county.Id;
        countyRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        insert countyRatePlan;
        LightningServerResponse  lightserresobj= countyRatePlanFlowController.getCountyRatePlanRecord(countyRatePlan.Id);
        system.assertEquals(true,lightserresobj.isSuccessful,'It should be successful');
        system.assertEquals('Success',lightserresobj.successMessage ,'It should be success');
        system.debug(lightserresobj.objectData.get('countyRatePlanRecord'));
        system.assert(String.valueOf(lightserresobj.objectData.get('countyRatePlanRecord')).Contains(countyRatePlan.Id),'It should not return null');
      
        //Exception scenario
        LightningServerResponse  lightserresobj2= countyRatePlanFlowController.getCountyRatePlanRecord(county.Id);
        system.assertEquals(false,lightserresobj2.isSuccessful,'It should be successful');
        system.assertEquals(null,lightserresobj2.objectData,'It is not returning NULL where in it supposed to return NULL');    
    }
    
     static testMethod void testgetCountyRatePlanRecordForTemplate() {
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_RATE__c countyRatePlan=TestClassUtility.createCountyRatePlan('PEN',false); 
        countyRatePlan.IDN_COUNTY__c = county.Id;
        countyRatePlan.CDE_RATE_PLAN_TEMPLT__c = '1';
        countyRatePlan.IND_RATE_PLAN_TEMPLT__c =true;
        user u =[Select id from User where UserName='newuserchats@testorg.com'];
        system.runAs(u){
            insert countyRatePlan;
        }
        LightningServerResponse  lightserresobj = countyRatePlanFlowController.getCountyRatePlanRecordForTemplate(countyRatePlan.CDE_RATE_PLAN_TEMPLT__c,countyRatePlan.IDN_COUNTY__c);
        system.assertEquals(true,lightserresobj.isSuccessful,'It should be successful');
        system.assertEquals('Success',lightserresobj.successMessage ,'It should be success');
        
        map<String, Object> respMap = CountyRatePlanFlowController.ownerCountyValidation(county.Id, true);
        Boolean contyMatched = (Boolean)respMap.get('countyMatched');
        system.assertEquals(true,contyMatched);
        respMap = CountyRatePlanFlowController.ownerCountyValidation(countyRatePlan.Id, false);
        Boolean contyMatched2 = (Boolean)respMap.get('countyMatched');
        system.assertEquals(true,contyMatched2);
         
        //Exception scenario
        LightningServerResponse  lightserresobj2= countyRatePlanFlowController.getCountyRatePlanRecordForTemplate('error',countyRatePlan.Id);
        system.assertEquals(false,lightserresobj2.isSuccessful,'It should be successful');
        system.assertEquals(new T_COUNTY_RATE__c(),lightserresobj2.objectData.get('countyRatePlanRecord'),'It is not returning NULL where in it supposed to return NULL');    
    }
    
    static testMethod void testGetCountyValidatedForNewCountyRatePlan() {        
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_COUNTY_RATE__c countyRatePlan = TestClassUtility.createCountyRatePlan('PEN',false); 
        T_COUNTY_RATE__c returnedCountyRatePlan= CountyRatePlanFlowController.getCountyValidatedForNewRatePlan(county.Id);
        system.assertEquals(null,returnedCountyRatePlan.Id ,'County Rate Plan has no records');
        countyRatePlan.IDN_COUNTY__c = county.Id;
        insert countyRatePlan;
        T_COUNTY_RATE__c returnedCountyRatePlan1= CountyRatePlanFlowController.getCountyValidatedForNewRatePlan(county.Id);
        system.assertEquals(countyRatePlan.Id,returnedCountyRatePlan1.Id ,'County Rate Plan has records');
    }
    
    @TestSetup
    public static void testDataSetup(){
        CHATSUtility.createTemplateUser();
    }
}