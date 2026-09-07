/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/26/2018                                                          
*  @description    Authorization Class Test  
*  * Version: 1.0                                                                             
*  * Date:  02/26/2018                                                            
*  * Author: Diya Chaudhary                                               
*  * Description: Initial version
*********************************************************************************************/
@isTest(seeAllData=false)
public class ParentFeeDelinquencyCntrlTest {
    
    static testmethod  void testsaveParentFeeDelinq(){
        Test.startTest();
        batchsit_t_auth_copay__x authCopay = new batchsit_t_auth_copay__x();
        T_COPAY_DELINQC__c copayDelinq = new T_COPAY_DELINQC__c();
        ParentFeeDelinquencyCntrl.saveParentFeeDelinq(copayDelinq);
        ParentFeeDelinquencyCntrl.getDoInit('');
        String userId = UserInfo.getUserId();
        ParentFeeDelinquencyCntrl.authCopayWrapper wrap = new ParentFeeDelinquencyCntrl.authCopayWrapper();
        system.assertEquals(null,wrap.loggedInUserId,'should return null');
        ParentFeeDelinquencyCntrl.authCopayWrapper wrap1 = new ParentFeeDelinquencyCntrl.authCopayWrapper(authCopay,userId,copayDelinq,userId,'','');
        system.assertEquals(userinfo.getUserID(),wrap1.loggedInUserId,'should be matching with logged in user');
        Test.stopTest();
    }
}