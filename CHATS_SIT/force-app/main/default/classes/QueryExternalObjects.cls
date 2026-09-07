/**************************************************************************************************************************
Class Name      - QueryExternalObjects
Test Class      - caseReviewApexController_Test
Description     - Generic class to query External object records. 
                  External object records can be mocked via this class, mock can be used in Test classes. 
Author          - Rishav Maji
Code Sample     - Main Class: caseReviewApexController.getParentFeeSubsidyAmount()
                  Test Class: caseReviewApexController_Test.caseReviewApexController_Test4()
***************************************************************************************************************************/
public virtual inherited sharing class QueryExternalObjects {
    
    static QueryExternalObjects instance = new QueryExternalObjects();
    
    public static List<SObject> query(List<SObject> records) {
        return instance.passThrough(records);
    }
    
    protected virtual List<SObject> passThrough(List<SObject> records) {
        return records;
    }
    
    @TestVisible 
    static void setMock(QueryExternalObjects mock) { 
        instance = mock; 
    }
}