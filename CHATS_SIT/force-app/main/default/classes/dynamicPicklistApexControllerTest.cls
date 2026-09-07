@isTest
public class dynamicPicklistApexControllerTest {
    static testmethod void dynamicPicklistTest(){
        String picklistType1 = 'GlobalPicklist';
        String picklistType2 = 'TableFetchPicklist';
        Map<string,string> map1 = new Map<string,string>();
        Map<string,string> map2 = new Map<string,string>();
        Map<string,string> map3 = new Map<string,string>();
        Map<string,string> map4 = new Map<string,string>();
        Map<string,string> map5 = new Map<string,string>();
        map1.put('objectName', 'T_DOC_RQ__c');
        map1.put('fieldName', 'CDE_CORSPD_STATUS__c');
        map2.put('method', 'getManualCorrespondences');
        map3.put('method', 'getSystemCorrespondences');
        map4.put('keyColName', 'NME_CORSPD__c');
        map4.put('valueColName', 'NME_CORSPD__c');
        map4.put('method', 'getAllCorrespondences');
        map5.put('method', 'getCountyCode');
        
        test.startTest();
        dynamicPicklistApexController.getPicklistValues(picklistType2, map2);
        dynamicPicklistApexController.getPicklistValues(picklistType2, map3);
        dynamicPicklistApexController.getPicklistValues(picklistType2, map4);
        dynamicPicklistApexController.getPicklistValues(picklistType2, map5);
        system.assert(string.valueOf(dynamicPicklistApexController.getPicklistValues(picklistType1, map1)).contains('isDefaultValue=false'),'isDefaultValue should be false');
        
        dynamicPicklistApexController.getGlobalPicklist(picklistType1, map1);
        dynamicPicklistApexController.getManualCorrespondences(picklistType2, map2);
        dynamicPicklistApexController.getSystemCorrespondences(picklistType2, map3);
        dynamicPicklistApexController.getAllCorrespondences(picklistType2, map4);
        dynamicPicklistApexController.getCountyCode();

        test.stopTest();
        
    }
    

}