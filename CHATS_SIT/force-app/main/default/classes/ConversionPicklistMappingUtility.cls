public with sharing class ConversionPicklistMappingUtility {
    public static final String EMPTY_STRING = null;
    public static Map<String,Map<String,String>> peakToCHATSMappingMap = new Map<String,Map<String,String>>();
    public static void getPicklistMappingsForPEAKRefTable(){
        Map<String,String> existingMappings = new Map<String,String>();
        for(Conversion_Picklist_Mapping__mdt mapping:[SELECT MasterLabel ,PEAK_Data__c, CHATS_Picklist_Mapping__c FROM Conversion_Picklist_Mapping__mdt limit 1000]){
            existingMappings = peakToCHATSMappingMap.containsKey(mapping.MasterLabel)?peakToCHATSMappingMap.get(mapping.MasterLabel):new Map<String,String>();
            existingMappings.put(mapping.PEAK_Data__c, mapping.CHATS_Picklist_Mapping__c);
            peakToCHATSMappingMap.put(mapping.MasterLabel,existingMappings);
        }
    }
    
    public static String translatePEAKToCHATSData(String peakRefTable,String peakData){
        Map<String,Object> methodInfo = new Map<String,Object>{'Class__c'=>'ConversionPicklistMappingUtility','Method__c'=>'translatePEAKToCHATSData'};
        try{
            //Logic to handle picklist value with leading zeroes.
            peakData = String.valueOf(Integer.valueOf(peakData));
            return peakToCHATSMappingMap.containsKey(peakRefTable)?(peakToCHATSMappingMap.get(peakRefTable).containsKey(peakData)?peakToCHATSMappingMap.get(peakRefTable).get(peakData):EMPTY_STRING):EMPTY_STRING;
        }catch(Exception ex){
            //Not capturing exception intentionally here
            return peakToCHATSMappingMap.containsKey(peakRefTable)?(peakToCHATSMappingMap.get(peakRefTable).containsKey(peakData)?peakToCHATSMappingMap.get(peakRefTable).get(peakData):EMPTY_STRING):EMPTY_STRING;
        }
    }
}