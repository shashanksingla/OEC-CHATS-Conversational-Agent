/**********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/26/2018                                                          
*  @description    Authorization Class Test  
*  * Version: 1.0                                                                             
*  * Date:  02/26/2018                                                            
*  * Author: Diya Chaudhary                                               
*  * Description: Initial version
*********************************************************************************************/
@isTest(seeAllData=false)
public class AuthorizationNotesController_Test {
    static testmethod  void testgetAuthorizationNotesStatus(){
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_SBSD_CASE__c sbsdcase =TestClassUtility.createCase(true,county.Id);
        T_SBSD_INDIV__c sbsdIndiv = TestClassUtility.createIndividual(true,date.newInstance(1983, 7, 15),'firstName','1','lastName','1','CC');
        T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert provider;
        
        
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        Date enddate = begindate.addDays(25);
        begindate = begindate.addDays(21);
        
        Test.startTest();
        T_AUTH__c authorization=TestClassUtility.createAuthorization(false,enddate,begindate,county.Id,provider.Id);
        authorization.IDN_CASE__c=sbsdcase.Id;
        authorization.IDN_CLIENT__c=sbsdIndiv.Id;
        authorization.isFinishedFlow__c=true;
        insert authorization;
        //Removed unused variable on 5/13/2018 BG  
        batchsit_t_auth_notes__x batch = new batchsit_t_auth_notes__x();
        String authId =authorization.Id;
        //Removed unused variable on 5/13/2018 BG  
        AuthorizationNotesController.getAuthorizationNotesStatus(authId,true,false);
        AuthorizationNotesController.getAuthorizationNotesStatus(authId,true,true);
        AuthorizationNotesController.getAuthorizationNotesStatus(authId,false,false);
        AuthorizationNotesController.fetchLoggedInUserId();
        AuthorizationNotesController.getSobjectName(authorization.Id);
        String userId = UserInfo.getUserId();
        //Removed unused variable on 5/13/2018 BG  
        AuthorizationNotesController.authNoteWrapper wrap1 = new AuthorizationNotesController.authNoteWrapper(false,batch,userId,authorization,authorization.Id,false);
        system.assertEquals(userinfo.getUserId(),wrap1.loggedInUserId,'Should return logged in user');
        AuthorizationNotesController.CR213Corr(authId);
        Test.stopTest();
    }
}