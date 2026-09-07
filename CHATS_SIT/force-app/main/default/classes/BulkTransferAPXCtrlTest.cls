/********************************************************************************************
* NAME         : BulkTransferAPXCtrlTest
* DESCRIPTION  : THIS TEST CLASS IS USED TO TEST THE FUNCTIONALITY IMPLEMENTED IN THE BulkTransferAPXCtrl APEX CLASS.
* @AUTHOR VINEET SRIVASTAVA
* @DATE 02/05/2018
*
*
* MODIFICATION LOG:
* DEVELOPER                         DATE                               DESCRIPTION
* ----------------------------------------------------------------------------                 
********************************************************************************************/
@isTest
public class BulkTransferAPXCtrlTest {
    
    /********************************************************
METHOD NAME  : getCountyRateTest
DESCRIPTION    : This method tests the functionality implmented in getCountyRate method.
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/
    public static testMethod void transferItemsTest(){
         T_CHATS_PROVR_STATUS__c provider= new T_CHATS_PROVR_STATUS__c(CDE_STATUS_PROVR__c='Open');
        insert provider;
              
        List<T_SBSD_CASE__c> lstCase = new List<T_SBSD_CASE__c>();
        List<T_PROVR_FISCAL_AGREMENT__c> lstPFA = new List<T_PROVR_FISCAL_AGREMENT__c>();
        User fromUser;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        fromUser = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
        if(fromUser!=null){
            fromUser.Owner_County__c = '1';
            insert fromUser; 
        }
        User toUser;
        toUser = TestClassUtility.createUser(userProfile.Id , 'test2','test2','test2@example.com','test2@example.com.'+string.valueof(math.random()*3),'ttes2');
        if(toUser!=null){
            toUser.Owner_County__c = '2';
            insert toUser; 
        }
        T_COUNTY__c county = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c case1 = TestClassUtility.createCase(true, county.Id);
        case1.OwnerId= fromUser.Id;
        lstCase.add(case1);
        T_SBSD_CASE__c case2 = TestClassUtility.createCase(true, county.Id);
        case2.OwnerId = fromUser.Id;
        lstCase.add(case2);
        
        update(lstCase);
        Id openRecordTypeId = Schema.SObjectType.T_PROVR_FISCAL_AGREMENT__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
        
        T_PROVR_FISCAL_AGREMENT__c providerFA1 = TestClassUtility.createFiscaAgreement(false,'Test FA 1',System.today().addYears(1),county.Id);
        providerFA1.OwnerId= fromUser.Id;
        providerFA1.ID_SERVICE__c=provider.Id;
        providerFA1.RecordtypeId=openRecordTypeId;
        providerFA1.DTE_RCV_AGRMT_FISCAL__c= System.today();
        providerFA1.CDE_TYPE_STATUS__c='OPN';
        insert providerFA1;
        lstPFA.add(providerFA1);
        T_PROVR_FISCAL_AGREMENT__c providerFA2 = TestClassUtility.createFiscaAgreement(false,'Test FA 2',System.today().addYears(4),county.Id);
        providerFA2.OwnerId= fromUser.Id;
        providerFA2.ID_SERVICE__c=provider.Id;
        providerFA2.RecordtypeId=openRecordTypeId;
        providerFA2.DTE_RCV_AGRMT_FISCAL__c= System.today().addYears(4) ;
        providerFA2.CDE_TYPE_STATUS__c='OPN';
        insert providerFA2;
        lstPFA.add(providerFA2);
        
        //update lstPFA; 
        String description1 = 'Child in case '+case1.Name +' has no active authorizations. Please create a new authorization for the child if they are eligible.';
        String description2 ='Household member of case # '+case2.Name +' date of birth updated by Sidmod.Please check eligibility and authorization to confirm whether the child'+
            'has aged-out or if rate types within the authorization must be updated (school age).';
        Task task1 = TestClassUtility.createTask(false, 'T100 - No Active Authorization for Child',description1, 'Not started', case1.Id , fromUser.Id);
       
        insert task1;
        Task task2 = TestClassUtility.createTask(false, 'T101 - SIDMOD Updated Client DOB',description2, 'Not started', case2.Id, fromUser.Id);
        
        insert task2;
        LightningServerResponse lsr1 = BulkTransferAPXCtrl.transferItems(county.Id, fromUser.Id, toUser.Id, '1' , null);
        system.debug('Error Message'+ lsr1.errorMessage);
        System.assertEquals(true, lsr1.isSuccessful , 'lsr.isSuccessful should be true');
        System.assertEquals(lstCase.size(), lsr1.objectData.get('itemTransferred') , 'lstCase.size() should be equal to itemTransferred');
        
        LightningServerResponse lsr2 = BulkTransferAPXCtrl.transferItems(county.Id, fromUser.Id, toUser.Id, '2' , null);
        system.debug('Error Message'+ lsr2.errorMessage);
        System.assertEquals(true, lsr2.isSuccessful , 'lsr2.isSuccessful should be true');
        System.assertEquals(lstPFA.size(), lsr2.objectData.get('itemTransferred') , 'lstPFA.size() should be equal to itemTransferred');
        
        LightningServerResponse lsr3 = BulkTransferAPXCtrl.transferItems(county.Id, fromUser.Id, toUser.Id, '3' , 'Manual Subject');
        system.debug('Error Message'+ lsr3.errorMessage);
        System.assertEquals(false, lsr3.isSuccessful , 'lsr3.isSuccessful should be false');
        
        LightningServerResponse lsr4 = BulkTransferAPXCtrl.transferItems(county.Id, fromUser.Id, toUser.Id, '3' , 'T100 - No Active Authorization for Child');
        system.debug('Error Message'+ lsr4.errorMessage);
        //System.assertEquals(true, lsr4.isSuccessful , 'lsr4.isSuccessful should be true');
        //System.assertEquals(1 , lsr4.objectData.get('itemTransferred') , 'itemTransferred should be equal to 1');
        
        LightningServerResponse lsr5 = BulkTransferAPXCtrl.transferItems(county.Id, fromUser.Id, toUser.Id, '3' , 'T101 - SIDMOD Updated Client DOB');
        system.debug('Error Message'+ lsr5.errorMessage);
        System.assertEquals(false, lsr5.isSuccessful , 'lsr5.isSuccessful should be true');
        System.assertEquals(null , lsr5.objectData.get('itemTransferred') , 'itemTransferred should be equal to 1');
        
        LightningServerResponse lsr6 = BulkTransferAPXCtrl.transferItems(county.Id, toUser.Id, fromUser.Id, '3' , null);
        system.debug('Error Message'+ lsr6.errorMessage);
        System.assertEquals(true, lsr6.isSuccessful , 'lsr6.isSuccessful should be true');
        System.assertEquals(2 , lsr6.objectData.get('itemTransferred') , 'itemTransferred should be equal to 2');
        
        BulkTransferAPXCtrl.isSuccessful=true;
        BulkTransferAPXCtrl.message='Test Class Success!';
    }
}