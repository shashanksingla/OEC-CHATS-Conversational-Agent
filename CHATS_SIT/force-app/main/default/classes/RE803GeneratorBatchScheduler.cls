// CCCAP-1548
global without sharing class RE803GeneratorBatchScheduler implements schedulable{
	
    global void execute(SchedulableContext sc){
    	
    	String batchName = 'Report803GeneratorBatch';
    	String reportName = 'RE803 - Attendance Report';
    	String status = 'INI';
    	
      	Boolean isBtchInQueue = false;
      	List<AsyncApexJob> asyncJobList = [SELECT ApexClass.Name,JobType,Status,CreatedById from AsyncApexJob where ApexClassId IN (SELECT Id FROM ApexClass WHERE Name =:batchName) and Status IN ('Holding', 'Queued', 'Preparing', 'Processing')];
      	System.debug('***********asyncJobList***********:'+asyncJobList);
      	if(asyncJobList != null && asyncJobList.size() >= 1){
      		isBtchInQueue = true;
      	}
      	
      	// Invoke only if the RE803 batch is not in queue
      	if(!isBtchInQueue) {
      		
			String query = 'SELECT Id, Name, createddate FROM Canned_Report_Request__c WHERE Report_Name__c =:reportName AND Status__c =:status';
			List<Canned_Report_Request__c> canRptReqs = Database.query(query);
		
			if(!canRptReqs.isEmpty()) {
				database.executebatch(new Report803GeneratorBatch(), 1);
	    	}
		}
    }

}