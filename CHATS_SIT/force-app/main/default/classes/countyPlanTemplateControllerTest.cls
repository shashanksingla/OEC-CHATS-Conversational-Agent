@isTest
public class countyPlanTemplateControllerTest {
    
    static testmethod void testcountyPlanTemplateController(){
        test.startTest(); 
        TestClassUtility.createCounty('countyName', 'countyDepartmentName', 01, true);
        T_COUNTY_PLAN__c countyPlan = TestClassUtility.createCountyPlan('PEN', false);
        countyPlan.DTE_BEGIN_EFFEV__c =  System.today().addDays(10) ;
        insert countyPlan;
        
        PageReference pageRef = Page.countyPlanTemplate;
        //Removed unused variable on 5/14/2018 BG  
        ApexPages.currentPage().getParameters().put('countyPlanId', countyPlan.Id);
        system.assertEquals('No',countyPlanTemplateController.getCountyPlan().CCCAP_Q1__c,'County plan CCCAP_Q1 should be null');
        system.assertEquals(true,countyPlanTemplateController.getJsActivated(),'JS Activation should be true');
        system.assertEquals(true,countyPlanTemplateController.getTTANFRemoved(),'TTANF Rmoved should be true');
        test.stopTest();        
    }

}