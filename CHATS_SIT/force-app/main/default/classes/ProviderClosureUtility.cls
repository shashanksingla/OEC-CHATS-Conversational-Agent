public class ProviderClosureUtility {
 	public static boolean ALLOW_DELETE = false;
    
    public static void checkIfDeleteAllowed(List<T_PROVR_CLOSURE__c> provClosList){
        for(T_PROVR_CLOSURE__c provClos : provClosList) {
            if(!ALLOW_DELETE) {
                provClos.adderror('You do not have permission to delete this record.');
            }
        }
    }
}