/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/08/2017                                                          
*  @description   Test class for Correspondance and Language Preference  Handler                           
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 09-Nov-2017                                                             
*  * Author: Shubham Khandelwal                                                      
*  * Description: Initial version                                                 
*                                                                                 
*********************************************************************************************/

@isTest()
public class CorrespondanceAndLangPrefService_Test {
    
    private static String EMAIL = '2';
    private static String MAIL = '1';
    private static String ENGLISH = 'ENG';
    private static String POLISH = 'POL';
    private static String OTHER = 'OTH';
    
    
    static T_PROVR_PREF__c corresAndlangfPref;
    
    static void createTestData(){
        
        List<T_PROVR_PREF__c> lstCorresAndlangfPref = new List<T_PROVR_PREF__c>();
        T_PROVR_PREF__c activeCorresAndlangfPref1 = TestClassUtility.createCorrespondanceAndLanguagePref(true,EMAIL,ENGLISH);
        T_PROVR_PREF__c activeCorresAndlangfPref2 = TestClassUtility.createCorrespondanceAndLanguagePref(true,MAIL,POLISH);
        T_PROVR_PREF__c inactiveCorresAndlangfPref3 = TestClassUtility.createCorrespondanceAndLanguagePref(false,MAIL,POLISH);
        corresAndlangfPref = TestClassUtility.createCorrespondanceAndLanguagePref(true,MAIL,POLISH);
        
        lstCorresAndlangfPref.add(activeCorresAndlangfPref1);
        lstCorresAndlangfPref.add(activeCorresAndlangfPref2);
        lstCorresAndlangfPref.add(inactiveCorresAndlangfPref3);
        
        if(lstCorresAndlangfPref.size() > 0){
        	insert lstCorresAndlangfPref;
        }
            
        
    }
    
    static testmethod  void testBeforeTriggerCorresAndLanPref(){
        
        createTestData();
        
        Test.startTest();
        
        List<T_PROVR_PREF__c> lstActiveCorresAndlangfPref = [Select Id,IND_ACTIVE__c,CDE_PREF_CORR_PROVR__c,CDE_PREF_LANG_PROVR__c 
                                                             from T_PROVR_PREF__c where IND_ACTIVE__c = true ];
        
        System.assert(lstActiveCorresAndlangfPref.size() > 0,'Correspondence and Language Preferences cannot be empty');
        
        if(corresAndlangfPref != null){
           insert corresAndlangfPref;	
        }
         
        
        List<T_PROVR_PREF__c> lstAfterInsert = [Select Id,IND_ACTIVE__c,CDE_PREF_CORR_PROVR__c,CDE_PREF_LANG_PROVR__c 
                                                from T_PROVR_PREF__c where IND_ACTIVE__c = true and id =:corresAndlangfPref.id];
        
        System.assertEquals(1, lstAfterInsert.size(),'Should have one Correspondence and Language Preferences record');
        
        List<T_PROVR_PREF__c> lstInactiveCorresAndlangfPref = [Select Id,IND_ACTIVE__c,CDE_PREF_CORR_PROVR__c,CDE_PREF_LANG_PROVR__c 
                                                               from T_PROVR_PREF__c where IND_ACTIVE__c = false ];
        
        System.assert(lstInactiveCorresAndlangfPref.size() > 0,'Correspondence and Language Preferences cannot be empty');
        
        test.stopTest();
   
    }
    
    public static testMethod void testProcessSaveResult(){
        T_PROVR_PREF__c corresAndlangfPref = TestClassUtility.createCorrespondanceAndLanguagePref(true,MAIL,POLISH);
        corresAndlangfPref.CDE_PREF_LANG_PROVR__c = 'SOME_RANDOM_PICKLIST_VALUE';
        CorrespondanceAndLangPrefService.processSaveResult(new List<SObject>{corresAndlangfPref});     
        system.assertEquals('SOME_RANDOM_PICKLIST_VALUE',corresAndlangfPref.CDE_PREF_LANG_PROVR__c ,'Should match the value');         
    }
    
}