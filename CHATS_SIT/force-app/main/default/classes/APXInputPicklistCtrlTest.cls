/********************************************************************************************
* NAME         : APXInputPicklistCtrlTest
* DESCRIPTION  : THIS TEST CLASS IS USED TO TEST THE FUNCTIONALITY IMPLEMENTED IN THE APXInputPicklistCtrl APEX CLASS
********************************************************************************************/
@isTest
private class APXInputPicklistCtrlTest {
    /********************************************************
METHOD NAME    : testValidFor
DESCRIPTION    : Test method for APXInputPicklistCtrl.getPicklistValues()
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/
    @isTest 
    static void getPicklistValues() {
        // Use picklist value from Contact --> Salutation field as Test Data
        List<APXInputPicklistCtrl.PicklistEntryDefinition> picklistValuesTest = new List<APXInputPicklistCtrl.PicklistEntryDefinition>();
        
        for(Schema.PicklistEntry p : Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().get('Salutation').getDescribe().getPicklistValues()) {
            picklistValuesTest.add(new APXInputPicklistCtrl.PicklistEntryDefinition(p));
        }
        
        // Retrieve data from server, then TEST
        List<APXInputPicklistCtrl.PicklistEntryDefinition> picklistValuesFromServer = APXInputPicklistCtrl.getPicklistValues('Contact', 'Salutation'); 
        
        picklistValuesTest.sort(); 
        picklistValuesFromServer.sort(); 
        Integer plValueCnt = picklistValuesTest.size();
        System.assertEquals(true, plValueCnt>0, 'plValueCnt should be greater than 0');
        for (Integer i = 0; i < plValueCnt; i++){
            System.assertNotEquals(null, picklistValuesFromServer[i]); 
            
            System.assertEquals(picklistValuesTest[i].label, picklistValuesFromServer[i].label); 
            System.assertEquals(picklistValuesTest[i].value, picklistValuesFromServer[i].value); 
            System.assertEquals(picklistValuesTest[i].isDefaultValue, picklistValuesFromServer[i].isDefaultValue); 
        }
    }
}