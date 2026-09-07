/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           02/26/2018                                                          
*  @description    Dynamic Related list Class Test  
*  * Version: 1.0                                                                             
*  * Date:  05/14/2018                                                            
*  * Author: Diya Chaudhary                                               
*  * Description: Initial version
*  * *************************************Modification Log***************************************
*  * *********	Date	*********	Name	*********	Reason	******************************
*  * *********	8/6/18	*********	Caleb K	*********	Added test for fetchRelatedObjectdataBasedOnIndex method and fetchRelatedObjectdata method with null data
*********************************************************************************************/
@isTest
public class DynamicExternalDetailPageController_Test {
    public static testMethod void testfetchObjectdata(){

        T_COUNTY__c countyObj = TestClassUtility.createCounty('countyName', 'countyDepartmentName',10,true);
        T_CHATS_PROVR_STATUS__c providerObj = TestClassUtility.createProvider(true, 'Test');
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        T_SBSD_CASE__c sbsdcase=TestClassUtility.createCase(false,county.Id);
        upsert sbsdcase;
        List<String> pickListTypeFields = new List<String>();
        List<String> typeFields = new List<String>();
        Map<String,List<String>> mapObjToLookupFields = new Map<String,List<String>>();
        pickListTypeFields.add('cde_type_unit_care__c,CDE_RATE_TYPE__c,T_FISCAL_SCH__c');
        List<String> pickListTypeFields1 = new List<String>();
        pickListTypeFields1.add('CDE_COUNTY_TRANSFER__c,CDE_COUNTY_TRANSFER__c,T_SBSD_CASE__c');
        List<String> fieldAPINames = new List<String>();
        fieldAPINames.add('CDE_TYPE_VERIF__c');
        List<String> fieldAPINamesList = new List<String>();
        fieldAPINamesList.add('DTE_CASE_TRANSFER__c');
        String fieldString ='CDE_TYPE_VERIF__c;CDE_IMM__c;IDN_PROVR__c';
        typeFields.add('CDE_COUNTY_TRANSFER');
        typeFields.add('CDE_TYPE_VERIF__c');
        mapObjToLookupFields.put('test',typeFields);
        batchsit_t_sub_pmt_detail__x subPaymentDetails;
        T_ADJMT_DETAIL__c ajustmentDetails;
        String childName;
        String IDN_AUTH;
        Date AUTH_Effective_BGN_Date;
        String CDE_STATUS_AUTH;
        String IDN_PROVR;
        String ProviderName;
        String DTE_DOB;
        Integer AMT_COPAY_AUTH;
        String errMsg;
        String authCopayId;
        String authName;
        Test.startTest();
        DynamicExternalDetailPageController.getPickListValue('T_AUTH__c','CDE_IMM__c');
        DynamicExternalDetailPageController.fetchObjectdata(sbsdcase.Id,fieldAPINamesList,pickListTypeFields1);
        DynamicExternalDetailPageController.fetchRelatedObjectdata(sbsdcase.Id,fieldString,pickListTypeFields,'T_AUTH__c','IDN_EXTNL__c','','','');
        Boolean didThrow = false;
        try{
        	DynamicExternalDetailPageController.fetchRelatedObjectdata(null,fieldString,pickListTypeFields,'T_AUTH__c','IDN_EXTNL__c','','','');
        }catch(Exception e){
			didThrow = true;
        }
        System.assert(didThrow);
        DynamicExternalDetailPageController.getPickListRecordDef('cde_type_unit_care__c','CDE_RATE_TYPE__c','batchsit_t_auth_encmbr__x','7','T_FISCAL_SCH__c');
        DynamicExternalDetailPageController.getFieldObject('T_AUTH__c');
        DynamicExternalDetailPageController.getRelationshipFieldWithParentObject('T_AUTH__c','T_SBSD_CASE__c');
        DynamicExternalDetailPageController.getFieldDefinition('T_AUTH__c',fieldAPINames);
        DynamicExternalDetailPageController.getFieldsToBeQueried('T_AUTH__c',fieldString);
        DynamicExternalDetailPageController.getLookupNameFromId(mapObjToLookupFields);
        adjustmentWrapper wrap = new adjustmentWrapper();
        adjustmentWrapper wrap1 = new adjustmentWrapper(subPaymentDetails,ajustmentDetails,childName);
        ParentFeeAssessmentWrapper parentWrap = new ParentFeeAssessmentWrapper();
        externalObjectDefinition extDefWrap = new externalObjectDefinition();
        ParentFeeAssessmentWrapper parentWrap1 = new ParentFeeAssessmentWrapper(childName, IDN_AUTH,  AUTH_Effective_BGN_Date,  CDE_STATUS_AUTH,  IDN_PROVR,  ProviderName,  DTE_DOB,  AMT_COPAY_AUTH );        // DynamicExternalDetailPageController.getLookupNameFromId('T_AUTH__c',fieldAPINames);
        system.assertEquals(null,parentWrap1.AMT_COPAY_AUTH,'Should return null');

        /*added by Caleb K*/
        Id parentId;
        Id recordId = sbsdcase.Id;
        String childApiName = 'T_AUTH__c';
        String fieldsToBeQueried = DynamicExternalDetailPageController.getFieldsToBeQueried(childApiName, fieldString);
        T_AUTH__c auth = new T_AUTH__c(CDE_IMM__c ='test');
        List<SObject> lstRelatedRecords = new List<SObject>();
        lstRelatedRecords.add(auth);
        parentId = String.valueOf(lstRelatedRecords[0].get('IDN_EXTNL__c'));
        DynamicExternalDetailPageController.fetchRelatedObjectdataBasedOnIndex(lstRelatedRecords, 0, 0, 0, 'IDN_PROVR__c', pickListTypeFields, childApiName);
		Test.stopTest();
    }
     public static testMethod void testfetchObjectdata_Scneraio(){
      
        T_COUNTY__c county= TestClassUtility.createCounty('Test Name','Department',2,true);
        Date datetoday=System.Today();
        Date begindate = date.newInstance(datetoday.year(),datetoday.month(),1);
        begindate = begindate.addDays(25);
        //Removed unused variable on 5/13/2018 BG        
        Date enddate = begindate.addDays(20);
        T_CHATS_PROVR_STATUS__c prov = new T_CHATS_PROVR_STATUS__c(TXT_CHATS_RATING__c ='Level 1');
        insert prov;
        T_AUTH__c auth  = new T_AUTH__c(CDE_COUNTY__c =county.id,DTE_BEGIN_EFFV_AUTH__c=begindate,DTE_END_EFFV_AUTH__c=enddate,IDN_PROVR__c =prov.id);
        insert auth;
       
        List<String> pickListTypeFields = new List<String>();
        pickListTypeFields.add('CDE_IMM__c,CDE_IMM__c,T_AUTH__c');
        
        String fieldString ='CDE_IMM__c;DTE_END_EFFV_AUTH__c;DTE_BEGIN_EFFV_AUTH__c;CreatedDate';
        
        Test.startTest();
        DynamicExternalDetailPageController.fetchRelatedObjectdata(auth.Id,fieldString,pickListTypeFields,'T_AUTH__c','Id','','','');
        DynamicExternalDetailPageController.fetchRelatedObjectdata(auth.Id,fieldString,pickListTypeFields,'T_AUTH__c','Id','Name','300','ASC');
		Test.stopTest();
    }
}