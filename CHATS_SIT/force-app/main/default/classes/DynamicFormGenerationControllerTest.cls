@isTest
public class DynamicFormGenerationControllerTest {
    public static testMethod void testCheckCountyWithUserCounty(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Adams','Adams',2,true);
            LightningServerResponse lsr = DynamicFormGenerationController.checkCountyWithUserCounty(countyRec.Id);
            System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        }
    }

        public static testMethod void testfiscalCountyValidation(){
         User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserWithPS(userProfile.Id ,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
        T_COUNTY__c county=TestClassUtility.createCounty('County1','Dept1',10,true);
        T_PROVR_FISCAL_AGREMENT__c fisagrec = TestClassUtility.createFiscaAgreement(true,'Testing',system.today().addYears(-1),county.Id);
        DynamicFormGenerationController.fiscalCountyValidation(fisagrec.Id);
        }        
}  
       public static testMethod void testvalidateIndivAge(){
         User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUserWithPS(userProfile.Id ,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            update user; 
        }
        System.runAs(user){
        List<T_SBSD_CASE_INDIV__c>caseindicrec=new List<T_SBSD_CASE_INDIV__c>();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(true, countyRec.Id);
        T_SBSD_INDIV__c individual = TestClassUtility.createIndividual(true,system.today().addYears(-15),'firstName','1','lastName','123','CC');
        T_SBSD_CASE_INDIV__c caseIndiv = TestClassUtility.createCaseIndividual(true, caseRec.Id, individual.Id,true);
        caseindicrec.add(caseIndiv);   
        DynamicFormGenerationController.validateIndivAge(caseindicrec);
        }        
} 
    
    public static testMethod void testCheckCountyWithOwnerCounty(){
        User user;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        if(user!=null){
            user.Owner_County__c = '2';
            insert user; 
        }
        System.runAs(user){
            T_COUNTY__c countyRec = TestClassUtility.createCounty('Adams','Adams',2,true);
            User user2 = TestClassUtility.createUser(userProfile.Id , 'test1','test1','test1@example.com','test1@example.com.'+string.valueof(math.random()*3),'ttes1');
            if(user!=null){
                user2.Owner_County__c = '2';
                insert user2; 
            }
            LightningServerResponse lsr = DynamicFormGenerationController.checkCountyWithOwnerCounty(countyRec.Id, user2.Id);
            System.assertEquals(true, lsr.isSuccessful, 'lsr.isSuccessful should be true');
        }
    }
    
    public static testMethod void testGetFieldDefinition(){
        List<FieldInformationWrapper.fieldDefinition> fieldWrapperList = DynamicFormGenerationController.getFieldDefinition(new List<String>{'T_SBSD_CASE__c.Name','T_SBSD_CASE__c.CDE_LANG_CORR__c'});
        System.assertEquals(false, fieldWrapperList.isEmpty(), 'fieldWrapperList should not be empty');
    }
    
    public static testMethod void testFetchUserdata(){
        LightningServerResponse lsr = DynamicFormGenerationController.fetchUserdata();
        System.assertEquals(true, lsr.isSuccessful, 'isSuccessful should be true');        
    }
    
    public static testMethod void testGetDataOnLoadInCHATS(){
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c caseRec = TestClassUtility.createCase(false, countyRec.Id);
        caseRec.CDE_LANG_CORR__c = 'ENG';
        insert caseRec;
        List<FieldInformationWrapper.fieldDefinition> fieldWrapperList = DynamicFormGenerationController.getFieldDefinition(new List<String>{'T_SBSD_CASE__c.Name','T_SBSD_CASE__c.CDE_LANG_CORR__c'});
        System.assertEquals(false, fieldWrapperList.isEmpty(), 'fieldWrapperList should not be empty');
        DynamicFormGenerationController.getDataOnLoadInCHATS(JSON.serialize(fieldWrapperList), caseRec.Id, 'T_SBSD_CASE__c');
        
    }
    
    public static testMethod void testFieldInformationWrapper(){
        FieldInformationWrapper.referenceFieldDefinition rfd = new FieldInformationWrapper.referenceFieldDefinition();
        rfd.referenecedObjectLabel = 'test';
        rfd.referenecedObjectName = 'test';
       
        FieldInformationWrapper.picklistFieldDefinition pfd = new FieldInformationWrapper.picklistFieldDefinition();
        pfd.picklistLabel = 'test';
        pfd.picklistValue = 'test';
        
        FieldInformationWrapper.fieldDefinition fd = new FieldInformationWrapper.fieldDefinition();
        fd.dataType = 'test';
        fd.fieldAPIName = 'test';
        fd.fieldLabel = 'test';
        fd.objectName = 'test';
        fd.referenecedObjectName = 'test';
        
        System.assertEquals('test', fd.dataType, 'datatype should not be test');
        
    }
    
    public static testMethod void testNewFiscalAgreement(){
        T_CHATS_PROVR_STATUS__c providerRec =TestClassUtility.createProvider(true, 'Level 1');
        Test.startTest();
        LightningServerResponse lsr = DynamicFormGenerationController.newFiscalAgreement(providerRec.Id, true);
        LightningServerResponse lsr2 = DynamicFormGenerationController.newFiscalAgreement(providerRec.Id, false);
        system.assertEquals(true, lsr.isSuccessful);
        Test.stopTest();
    }
    
    public static testMethod void testCloseFiscalAgreementUpdate(){
       T_CHATS_PROVR_STATUS__c providerRec =TestClassUtility.createProvider(true, 'Level 1');
       T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
       T_COUNTY__c countyRec2 = TestClassUtility.createCounty('Broomfield','Denver',1,true); 
       T_PROVR_FISCAL_AGREMENT__c provrFA = TestClassUtility.createFiscaAgreement(false, 'name', system.today(), countyRec.Id) ;
        T_PROVR_FISCAL_AGREMENT__c provrFA2 = TestClassUtility.createFiscaAgreement(false, 'name', system.today().addDays(-2), countyRec2.Id) ;
        provrFA.ID_SERVICE__c = TestClassUtility.createProvider(true, 'Level 1').Id;
        insert provrFA;
        Test.startTest();
        Boolean updateDone = DynamicFormGenerationController.closeFiscalAgreementUpdate(provrFA2.Id, String.valueOf(system.today().addYears(1)), 'NEW', 'CLS');
        Boolean updateDone2 = DynamicFormGenerationController.closeFiscalAgreementUpdate(provrFA.Id, String.valueOf(system.today()), 'NEW', 'CLS');
        system.assertEquals(false , updateDone);
        system.assertEquals(true , updateDone2);
        Test.stopTest();
    }
}