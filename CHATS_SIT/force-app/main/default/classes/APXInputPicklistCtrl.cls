/**
* This class is a server side controller for LIInputPicklist
* @author Nikunj Nilesh Doshi (ndoshi@deloitte.com)
*/
public class APXInputPicklistCtrl {

/**
*@description This method is responsible for returning the picklist values for the field mentioned.
* @param String which is the Object Api Name
* @param String which is the Picklist Field Api Name
* @return picklistValues
*/

    @AuraEnabled
    public static List<PicklistEntryDefinition> getPicklistValues(String obj, String fld) {
        List<PicklistEntryDefinition> picklistValues = new List<PicklistEntryDefinition>();
        //Removed unused variable on 5/13/2018 BG          
        for(Schema.PicklistEntry p : Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap().get(fld).getDescribe().getPicklistValues()) {
            //Added as part of HF_CHATS_20_09_2018
            if(obj=='T_COUNTY_RATE__c' && fld=='Rate_Type__c'){
                List<String> lstRestrictedRateTypes = Label.Inactive_Rate_Type.split(';');
                if(!lstRestrictedRateTypes.contains(p.getValue()) ){
                    picklistValues.add(new PicklistEntryDefinition(p));  
                }
            }
            else if(obj=='T_COUNTY_RATE__c' && fld=='CFS_Q1__c'){
                string label = p.getLabel();
                
                if(label == 'No'){
                   label = 'No (If this is a change from Yes to No, Counties must close the active Slot Contract Addendum records to align with effective date of this County Rate Plan. Please confirm in County Rate Plan notes.)';
                }
                picklistValues.add(new PicklistEntryDefinition(label, p.getValue(), p.isDefaultValue()));
            }
            else{
                picklistValues.add(new PicklistEntryDefinition(p));
            }
        }
        return picklistValues;
    }

    public class PicklistEntryDefinition implements Comparable {
        @AuraEnabled
        public String label {get; private set;}

        @AuraEnabled
        public String value {get; private set;}
 
        @AuraEnabled
        public Boolean isDefaultValue {get; private set;}

        public PicklistEntryDefinition(Schema.PicklistEntry p) {
            label = p.getLabel();
            value = p.getValue();
            isDefaultValue = p.isDefaultValue();
        }
        public PicklistEntryDefinition(String labelstr, String valuestr, Boolean isDefault) {
            label = labelstr;
            value = valuestr;
            isDefaultValue = isDefault;
        }

        public Integer compareTo(Object compareTo){
        /**
        *@description This method is responsible for comparing the picklist values for the field mentioned to the ones present in the system
        * @param String which is the Object Api Name
        * @return 0 if values are equal.
        */
            PicklistEntryDefinition compareToPL = (PicklistEntryDefinition)compareTo; 
            if (value == compareToPL.value){
              return 0;   
            } 
            if (value > compareToPL.value){
                return 1; 
            }
                
            return -1; 
        }
    }
}