/**
* This class is a server side controller for LIDependentPicklist
* @see APXPicklistEntryWrapper
* @see APXBitSet
* @author Nikunj Nilesh Doshi (ndoshi@deloitte.com)
*/

public class InputDependentPicklistApxCtrl {
 /**
*@description This method is responsible for handling dependent picklist
* @param String which is the Object Api Name
* @param String which is the Controlling Picklist Field Api Name
* @param String which is the Dependent Picklist Field Api Name
* @return Map<String,List<String>>
*/
    
    @AuraEnabled  
    public static Map<String,List<String>> getDependentOptionsImpl(string objApiName , string contrfieldApiName , string depfieldApiName){
        system.debug(objApiName + '##' + contrfieldApiName + '###' + depfieldApiName);
        
        String objectName = objApiName.toLowerCase();
        String controllingField = contrfieldApiName.toLowerCase();
        String dependentField = depfieldApiName.toLowerCase();
        
        Map<String,List<String>> objResults = new Map<String,List<String>>();
        // This list will hold the children during the build, and will be copied to the final map at the end
        List<List<String>> workingList = new List<List<String>>();
        
        
        //get the string to sobject global map
        Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
        
        if (!Schema.getGlobalDescribe().containsKey(objectName)){
            System.debug('OBJNAME NOT FOUND --.> ' + objectName);
            return null;
        }
        
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
        if (objType==null){
            return objResults;
        }
        APXBitset bitSetObj = new APXBitset();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        //Check if picklist values exist
        if (!objFieldMap.containsKey(controllingField) || !objFieldMap.containsKey(dependentField)){
            System.debug('FIELD NOT FOUND --.> ' + controllingField + ' OR ' + dependentField);
            return objResults;     
        }
        
        List<Schema.PicklistEntry> contrEntries = objFieldMap.get(controllingField).getDescribe().getPicklistValues();
        List<Schema.PicklistEntry> depEntries = objFieldMap.get(dependentField).getDescribe().getPicklistValues();
        objFieldMap = null;
        List<Integer> controllingIndexes = new List<Integer>();
        for(Integer contrIndex=0; contrIndex<contrEntries.size(); contrIndex++){            
            Schema.PicklistEntry ctrlentry = contrEntries[contrIndex];
            String label = ctrlentry.getLabel();
            objResults.put(label,new List<String>());
            controllingIndexes.add(contrIndex);
            workingList.add(new List<String>());
        }
        List<Schema.PicklistEntry> objEntries = new List<Schema.PicklistEntry>();
        List<APXPicklistEntryWrapper> objJsonEntries = new List<APXPicklistEntryWrapper>();
        for(Integer dependentIndex=0; dependentIndex<depEntries.size(); dependentIndex++){            
            Schema.PicklistEntry depentry = depEntries[dependentIndex];
            //objEntries.add(depentry);
            String pEntryStructure = JSON.serialize(depentry);
      APXPicklistEntryWrapper objDepPLE = (APXPicklistEntryWrapper)JSON.deserialize(pEntryStructure, APXPicklistEntryWrapper.class);
            //if valid for is empty, skip
            if (objDepPLE.validFor==null || objDepPLE.validFor==''){
                continue;
            }
            
            List<Integer> valids = bitSetObj.validFor(objDepPLE.validFor);
            for(Integer v : valids) {
                // As a safety valve, make sure we didn’t get an index out of range
                if (v < workingList.size()) {
                    workingList[v].add(objDepPLE.label);
                }
            }
        } 
           for(Integer pControllingIndex = 0; pControllingIndex < contrEntries.size(); pControllingIndex++) {
                String pControllingLabel = contrEntries[pControllingIndex].getLabel();
                objResults.put(pControllingLabel, workingList[pControllingIndex]);
            }


        system.debug('objEntries ' + JSON.serialize(objEntries));
        system.debug('objResults--->' + objResults);
        return objResults;
    }
}