@isTest(seeAllData=false)
public class CountyDropInDaysBatchApxCtrl_Test {
public static T_COUNTY_PLAN__c aCountyPlan=null;
    static final String CENTER='CEN';
    static final String FT = '3'; 
    static final String PT = '2'; 
    static final String FTPT = '4';
    static final String FTFT = '5'; 
    public static User user;
    public static final String COUNTY_RATE_PLAN_APPROVAL_PROCESS = 'County_Rate_Plan_Approval_Process';
    public static T_COUNTY__c aCounty;
    public static T_COUNTY_RATE__c aCountyRateForApprovalProcess;
    public static T_COUNTY_RATE__c aCountyRatePlan=null; 
    public static T_COUNTY_RATE__c aCountyRatePlan1=null; 
    public static T_COUNTY_RATE__c aCountyRatePlan2=null; 
    
    static void createTestData(){
        aCounty =TestClassUtility.createCounty('County','Dept',10,true);
        T_COUNTY__c county2 =TestClassUtility.createCounty('County2','Dept2',9,true);
        T_COUNTY__c county1 =TestClassUtility.createCounty('County11','Dept11',10,true);
        aCountyRatePlan=TestClassUtility.createCountyRatePlan('PEN',false);
        //aCounty=[Select Id from T_COUNTY__c Limit 1];
        aCountyRatePlan.CDE_RATE_PLAN_TEMPLT__c='1';
        aCountyRatePlan.IND_RATE_PLAN_TEMPLT__c=false;
        aCountyRatePlan.DTE_BEGIN_EFFV_RATE__c=System.today().addMonths(3).toStartOfMonth();
        aCountyRatePlan.IDN_COUNTY__c=county1.id;
        
        aCountyRatePlan1=TestClassUtility.createCountyRatePlan('PEN',false);
        aCountyRatePlan1.CDE_RATE_PLAN_TEMPLT__c='1';
        aCountyRatePlan1.IND_RATE_PLAN_TEMPLT__c=true;
        aCountyRatePlan1.DTE_BEGIN_EFFV_RATE__c=System.today().addMonths(4).toStartOfMonth();
        aCountyRatePlan1.IDN_COUNTY__c=county2.id;
        
        
        aCountyRateForApprovalProcess = TestClassUtility.createCountyRatePlan('PEN',false);
        aCountyRateForApprovalProcess.IDN_COUNTY__c = aCounty.Id;
        aCountyRateForApprovalProcess.CDE_RATE_PLAN_TEMPLT__c = '1';
        aCountyRateForApprovalProcess.IND_RATE_PLAN_TEMPLT__c=false;
        aCountyRateForApprovalProcess.DTE_BEGIN_EFFV_RATE__c=System.today().addMonths(2).toStartOfMonth();
        aCountyRateForApprovalProcess.Flow_Completed__c=true;
        
        if(aCountyRateForApprovalProcess!=null){
            insert aCountyRateForApprovalProcess;
        }
            T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(NAM_FACILITY__c = 'Provider Test', TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        T_AUTH__c acc = new T_AUTH__c();
            acc.DTE_END_EFFV_AUTH__c = system.today();
            acc.DTE_BEGIN_EFFV_AUTH__c = System.today();
            acc.IDN_PROVR__c = provider.Id;
        acc.CDE_COUNTY__c = county1.Id;
        insert acc;
        
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.uesername','ttes');
        
        if(user!=null){
            List<User> users = [SELECT Owner_County__c FROM User WHERE id = :UserInfo.getUserId()];
            if(!users.isEmpty()){
                user.Owner_County__c  = users.get(0).Owner_County__c;
            }
            insert user; 
        }
    }

    static testmethod void testCountyRatePlanTrigger(){
        Boolean expectedExceptionThrown;
        createTestData();
        
        Test.startTest();
        //try{
            insert aCountyRatePlan;
      /*  user u =[Select id from User where UserName='newuserchats@testorg.com'];
        system.runAs(u){
            insert aCountyRatePlan1;}*/
        /*}catch(Exception e){
            expectedExceptionThrown =  e.getMessage().contains('You can not add multiple draft version of County Rate Plan') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true);
        }*/
        aCountyRatePlan.RATE_TYPE__c = '13';
        update aCountyRatePlan;
        aCountyRatePlan.RATE_TYPE__c ='1';
        update aCountyRatePlan;
        //insert aCountyRatePlan1;
        aCountyRatePlan.CDE_STATUS__c = CountyRatePlanServices.APPROVED;
        aCountyRatePlan.DTE_BEGIN_EFFV_RATE__c = system.today();
        aCountyRatePlan.DTE_END_EFFV_RATE__c = system.today().addDays(10);
        aCountyRatePlan.IND_RATE_PLAN_TEMPLT__c = false;
        
            
        try{
            update aCountyRatePlan;
            CountyDropInDaysBatchApxCtrl obj = new CountyDropInDaysBatchApxCtrl();
            DataBase.executeBatch(obj); 
        }
        catch(Exception e){
           // expectedExceptionThrown =  e.getMessage().contains('Template already exists for County') ? true : false;
        }
        Test.stopTest(); 
    }
}