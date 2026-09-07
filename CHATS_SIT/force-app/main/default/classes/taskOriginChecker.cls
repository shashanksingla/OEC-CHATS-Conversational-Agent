public class taskOriginChecker {
    @InvocableMethod(label='Check Task Origin Bulkified' description='Stable approach using core system state flags.')
    public static List<Boolean> checkIfUI(List<Task> tasks) {
        Boolean isUI = true;

        if (System.isBatch() || System.isQueueable() || System.isFuture() || System.isScheduled()) {
            isUI = false;
        }
        if (tasks != null && tasks.size() > 1) {
            isUI = false;
        }
        List<Boolean> results = new List<Boolean>();
        for (Integer i = 0; i < tasks.size(); i++) {
            results.add(isUI);
        }
        
        return results;
    }
}