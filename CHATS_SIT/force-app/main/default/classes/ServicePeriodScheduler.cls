global with sharing class ServicePeriodScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Query the last service period's begin date and nameInt
        T_SERV_PERIOD__c lastPeriod = [
            SELECT DTE_END_EFFV__c, Name
            FROM T_SERV_PERIOD__c
            ORDER BY DTE_END_EFFV__c DESC
            LIMIT 1
        ];
        Date beginDate = lastPeriod != null ? lastPeriod.DTE_END_EFFV__c.addDays(1) : Date.newInstance(Date.today().Year(), 10, 28);
        Integer yearSeq;
        Integer nameInt = lastPeriod != null ? Integer.valueOf(lastPeriod.Name) + 1 : 796;
        Date endDate = Date.newInstance(beginDate.Year()+1, 10, 31);
        List<T_SERV_PERIOD__c> servicePeriodList = new List<T_SERV_PERIOD__c>();
        Integer Sequence = nameInt;
        List<Service_Period_Config__c> spConfig = [select id,Future_Payment__c,Service_Period_Frequency__c,Payment_Release_Day__c ,Payment_Calculation_Day__c
                                                   from Service_Period_Config__c order by createddate desc limit 1];
        if(!spConfig.isEmpty()){
            Integer frequency = Integer.valueOf(spConfig[0].Service_Period_Frequency__c);
            Integer paymentCalcDayDiff = Integer.valueOf(spConfig[0].Payment_Calculation_Day__c);
            Integer counter =1;
            Date PaymentCalcDate;
            Date batchPrcsDate;
            Date batchFileDate;
            integer weeksCounter=1;
            while (beginDate < endDate && weeksCounter<=52) {
                T_SERV_PERIOD__c serv = new T_SERV_PERIOD__c();
                serv.DTE_BEGIN_EFFV__c = beginDate;
                yearSeq = serv.DTE_BEGIN_EFFV__c.year();
                serv.DTE_END_EFFV__c = beginDate.addDays(6);
                serv.Name = String.valueOf(nameInt);
                serv.IDN_EXTNL__c = String.valueOf(nameInt);
                serv.Future_Payment__c = spConfig[0]?.Future_Payment__c;
                if(counter == 1){
                    // Calculate batch file date based on Payment_Release_Day__c in the second week
                    batchFileDate = calculateBatchFileDate(beginDate, spConfig[0]?.Payment_Release_Day__c);
                    batchPrcsDate = batchFileDate.addDays(-1);
                    PaymentCalcDate = batchPrcsDate;//batchPrcsDate.addDays(paymentCalcDayDiff*-1); changed the calculation for CCCAP-14743
                    counter++;
                }
                else if(counter>frequency){
                    counter = 2;
                    // Calculate batch file date based on Payment_Release_Day__c in the second week
                    batchFileDate = calculateBatchFileDate(beginDate, spConfig[0]?.Payment_Release_Day__c);
                    batchPrcsDate = batchFileDate.addDays(-1);
                    PaymentCalcDate = batchPrcsDate;//batchPrcsDate.addDays(paymentCalcDayDiff*-1); changed the calculation for CCCAP-14743
                    Sequence = nameInt;
                }
                else{
                    counter++;
                }
                serv.Payment_Calculations_Date__c = PaymentCalcDate;
                serv.Service_Period_Id__c = yearSeq+'_'+Sequence;
                serv.DTE_BATCH_PRCS_PMT__c = batchPrcsDate;
                serv.DTE_BATCH_FILE_PMT__c = batchFileDate;
                servicePeriodList.add(serv);
                beginDate = beginDate.addDays(7);
                nameInt = nameInt + 1;
                weeksCounter++;
            }
        }
        if (!servicePeriodList.isEmpty()) {
            try {
                GenericDmlHandler.insertRecords(servicePeriodList, new Map<String,Object>{'Method__c'=>'execute','Class__c'=>'ServicePeriodScheduler'});
            } catch (Exception ex) {
                System.debug('Error inserting service periods: ' + ex.getMessage());
                ExceptionLoggingServices.captureExceptionLog(new Exception_Log__c(Class__c = 'ServicePeriodScheduler', Method__c = 'execute', Exception_Message__c = 'Service Period Insert: '+ex.getMessage()+ ' .The Record is - '+servicePeriodList.get(0), Exception_Type__c = 'Error')); 
            }
        }
    }
    // Helper method to calculate batch file date based on Payment_Release_Day__c in the third week
    private Date calculateBatchFileDate(Date beginDate, String paymentReleaseDay) {
        if (paymentReleaseDay == null) {
            // Fallback to original logic if Payment_Release_Day__c is not set
            return beginDate.addDays(18);
        }
        
        // Find the third week from begin date
        Date thirdWeekStart = beginDate.addDays(14); // Start of third week (day 15)
        
        // Convert Payment_Release_Day__c to integer (1=Monday, 2=Tuesday, ..., 7=Sunday)
        Integer targetDayOfWeek = Integer.valueOf(paymentReleaseDay);
        
        // Get the day of week for the start of third week
        // Salesforce Date.daysBetween() with a known Monday (Jan 5, 1970 was a Monday)
        Date knownMonday = Date.newInstance(1970, 1, 5);
        Integer daysSinceMonday = knownMonday.daysBetween(thirdWeekStart);
        Integer thirdWeekStartDayOfWeek = Math.mod(daysSinceMonday, 7) + 1; // 1=Monday, 7=Sunday
        
        // Calculate days to add to reach the target day in the third week
        Integer daysToAdd = targetDayOfWeek - thirdWeekStartDayOfWeek;
        if (daysToAdd < 0) {
            daysToAdd += 7; // Move to next week if target day already passed
        }
        
        return thirdWeekStart.addDays(daysToAdd);
    }
}