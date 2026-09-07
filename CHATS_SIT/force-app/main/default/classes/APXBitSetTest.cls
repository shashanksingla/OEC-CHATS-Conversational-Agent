/********************************************************************************************
* NAME         : APXBitSetTest
* DESCRIPTION  : THIS TEST CLASS IS USED TO TEST THE FUNCTIONALITY IMPLEMENTED IN THE APXBitSet APEX CLASS
* MODIFICATION LOG:
* DEVELOPER                         DATE                               DESCRIPTION
* ----------------------------------------------------------------------------                 
SHUBHAM JAIN                        06/22/2017                         - Removed existing "unitTestConstructor" method 
																	   - Added new "testValidFor" &  "testBits" methods to 
																		 clearly demonstrate the funtionality of APXBitSet class.
********************************************************************************************/
@isTest
public class APXBitSetTest 
{
    /********************************************************
METHOD NAME  : testValidFor
DESCRIPTION    : This method tests "ValidFor" of APXBitSet class.
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/
    public static testMethod void testValidFor(){
        //[Shubham Jain 6/22/2017 : Feching picklist values for CDE_VALUE_INFO_INDIV__c from the metadata] 
        List<Schema.PicklistEntry> ple = T_SBSD_INDIV_INFO__c.CDE_VALUE_INFO_INDIV__c.getDescribe().getPicklistValues();
        APXPicklistEntryWrapper objDepPLE = new APXPicklistEntryWrapper();
        APXBitSet bitsetObj = new APXBitSet();
        for( Schema.PicklistEntry picklistEntry : ple)
        {
            String pEntryStructure = JSON.serialize(picklistEntry);
            //[Shubham Jain 6/22/2017 : Fetching "validFor" attribute for each PicklistEntry by deserializing
            //							"PicklistEntry"	into APXPicklistEntryWrapper object] 
            objDepPLE = (APXPicklistEntryWrapper)JSON.deserialize(pEntryStructure, APXPicklistEntryWrapper.class);
            //[Shubham Jain 6/22/2017 : Passing "validFor" attribute to "validFor" method to get the indices of controlling field]
            List<Integer> valids = bitsetObj.validFor(objDepPLE.validFor);
            if(objDepPLE.validFor=='' || objDepPLE.validFor==null){
                //[Shubham Jain 6/22/2017 : Asserting that returned list of controlling indices should be empty
                //							as "validFor" attribute is blank.]
                System.assertEquals(true, valids.size()==0,'List of controlling indices(valids) should be empty.');
            }else{
                //[Shubham Jain 6/22/2017 : Asserting that returned list of controlling indices should not be empty
                //							as "validFor" attribute contains some value.]
                System.assertEquals(true, valids.size()>0,'List of controlling indices(valids) should not be empty.');
            }
        }   
    }
    
    /********************************************************
METHOD NAME  : testBits
DESCRIPTION    : This method tests "testBits" of APXBitSet class.
RETURN TYPE    : VOID
PARAMETER      : 
**********************************************************/
    public static testMethod void testBits(){
        //[Shubham Jain 6/22/2017 : Feching picklist values for CDE_TYPE_INFO_INDIV__c from the metadata] 
        List<Schema.PicklistEntry> contrEntries = T_SBSD_INDIV_INFO__c.CDE_TYPE_INFO_INDIV__c.getDescribe().getPicklistValues();
        //[Shubham Jain 6/22/2017 : Creating a list of integer. Each item represents an index of controlling picklist value.] 
        List<Integer> controllingIndexes = new List<Integer>();
        for(Integer contrIndex=0; contrIndex<contrEntries.size(); contrIndex++){            
            controllingIndexes.add(contrIndex);
        }
        
        //[Shubham Jain 6/22/2017 : Feching picklist values for CDE_VALUE_INFO_INDIV__c from the metadata] 
        Schema.DescribeFieldResult fieldResult = T_SBSD_INDIV_INFO__c.CDE_VALUE_INFO_INDIV__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        APXPicklistEntryWrapper objDepPLE = new APXPicklistEntryWrapper();
        APXBitSet bitsetObj = new APXBitSet();
        for( Schema.PicklistEntry picklistEntry : ple)
        {
            //[Shubham Jain 6/22/2017 : Fetching "validFor" attribute for each PicklistEntry by deserializing
            //							"PicklistEntry"	into APXPicklistEntryWrapper object] 
            String pEntryStructure = JSON.serialize(picklistEntry);
            objDepPLE = (APXPicklistEntryWrapper)JSON.deserialize(pEntryStructure, APXPicklistEntryWrapper.class);
            List<Integer> valids = bitsetObj.testBits(objDepPLE.validFor,controllingIndexes);
            if(objDepPLE.validFor=='' || objDepPLE.validFor==null){
                //[Shubham Jain 6/22/2017 : Asserting that returned list of controlling indices should be empty
                //							as "validFor" attribute is blank.]
                System.assertEquals(true, valids.size()==0,'List of controlling indices(valids) should be blank.');
            }else{
                //[Shubham Jain 6/22/2017 : Asserting that returned list of controlling indices should not be empty
                //							as "validFor" attribute contains some value.]
                System.assertEquals(true, valids.size()>0,'List of controlling indices(valids) should not be blank.');
            }
        }   
    }
    
}