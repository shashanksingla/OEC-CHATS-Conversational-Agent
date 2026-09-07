public class FailLogEmailHelper {
	List<SObject> batchLogRecords;
    String batchType; 
    
    public FailLogEmailHelper(List<SObject> recs, String failedBatchType){
     	this.batchLogRecords = recs;
        this.batchType = failedBatchType;
    }
    
    public Messaging.SingleEmailMessage createEmails(String toAddressee){
        List<FailBatchLogPOCO> pocoList = new List<FailBatchLogPOCO>();
        Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email); 
        for(sObject extObj : this.batchLogRecords){
                FailBatchLogPOCO singleObj = new FailBatchLogPOCO();
                singleObj.IDN_EXTNL = (extObj.get('idn_batch_log__c') == null ? '' : String.ValueOf((Decimal)extObj.get('idn_batch_log__c')) );
                singleObj.Batch_Name = (String)extObj.get('batch_name__c');
                singleObj.Status = (String)extObj.get('status__c');
            	if((Decimal)extObj.get('records_processed__c') != null && (Decimal)extObj.get('records_processed__c') != 0){
                    singleObj.Records_Processed = String.valueOf((Decimal)extObj.get('records_processed__c')).split('\\.')[0];
                    //system.debug(String.valueOf((Decimal)sobj.get('records_processed__c')).split('\\.')[0]);
                }
                else {
                    singleObj.Records_Processed = '0';
                    system.debug('0');
                }
                //singleObj.Records_Processed = String.ValueOf((Decimal)extObj.get('records_processed__c'));
                if((Decimal)extObj.get('records_failed__c') != null && (Decimal)extObj.get('records_failed__c') != 0){
                    singleObj.Records_Failed = String.valueOf((Decimal)extObj.get('records_failed__c')).split('\\.')[0];
                    //system.debug(String.valueOf((Decimal)sobj.get('records_processed__c')).split('\\.')[0]);
                }
                else {
                    singleObj.Records_Failed = '0';
                    system.debug('0');
                }
                //singleObj.Records_Failed = String.ValueOf((Decimal)extObj.get('records_failed__c'));
                singleObj.Error_Message = (extObj.get('error_message__c')==null? '' : (String)extObj.get('error_message__c'));
                Datetime batchRunDatetime = (Datetime)extObj.get('batch_run_date__c');
                singleObj.RunDate = String.ValueOf(Date.newinstance(batchRunDatetime.year(), batchRunDatetime.month(), batchRunDatetime.day()));
                singleObj.start_time = String.ValueOf((DateTime)extObj.get('start_time__c'));
                singleObj.end_time = String.ValueOf((DateTime)extObj.get('end_time__c'));
                pocoList.add(singleObj);
                
            }
        String toEmail = toAddressee;
        List<String> addressList = toEmail.split(';');
        //String ccEmail = 'bensprague@deloitte.com';
        String msg1 = '<p>Hello,</p>';
        msg1 += '<p>The following items require your attention.</p>';
        msg1 += '<p>&nbsp;</p>';
        msg1 += '<table border="1">';
        msg1 += '<tbody>';
        msg1 += '<tr>';
        msg1 += '<th>IDN Batch Log</th>';
        msg1 += '<th>Batch Name</th>';
        msg1 += '<th>Status</th>';
        msg1 += '<th>Records Processed</th>';
        msg1 += '<th>Records Failed</th>';
        msg1 += '<th>Error Message</th>';
        msg1 += '<th>Date Run</th>';
        msg1 += '<th>Start Time</th>';
        msg1 += '<th>End Time</th>';
        msg1 += '</tr>';
        // msg1 += '<td>1231231</td>';
        // msg1 += '<td>Sample</td>';
        // msg1 += '<td>TEST</td>';
        // msg1 += '<td>11</td>';
        // msg1 += '<td>1</td>';
        // msg1 += '<td>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua</td>';
        // msg1 += '<td>01/10/2020</td>';
        // msg1 += '<td>01/10/2020</td>';
        // msg1 += '<td>01/10/2020</td>';
        // msg1 += '</tr>';
        if(pocoList.size()>0){
            for(FailBatchLogPOCO failObj : pocoList){
                msg1 += '<tr>';
                msg1 += '<td>' + failObj.IDN_EXTNL + '</td>';
                msg1 += '<td>' + failObj.Batch_Name+ '</td>';
                msg1 += '<td>' + failObj.Status+ '</td>';
                msg1 += '<td>' + failObj.Records_Processed+ '</td>';
                msg1 += '<td>' + failObj.Records_Failed+ '</td>';
                msg1 += '<td>' + failObj.Error_Message+ '</td>';
                msg1 += '<td>' + failObj.RunDate+ '</td>';
                msg1 += '<td>' + failObj.start_time+ '</td>';
                msg1 += '<td>' + failObj.end_time+ '</td>';
                msg1 += '</tr>';
            }
        }
        
        msg1 += '</tbody>';
        msg1 += '</table>';
        msg1 += '<p><br />&nbsp;Thank you&nbsp;</p>';
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(addressList);
        //email.setCcAddresses(new List<String> {ccEmail});
        email.setbccAddresses(new List<String> {});
        //SET SUBJECT
        
        String evaluatedSubject = determineSubject(this.batchType);
        email.setSubject(evaluatedSubject);
        email.setHtmlBody(msg1);    
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        if(owEmailAddressId != null){
            email.setOrgWideEmailAddressId(owEmailAddressId);
        }
        
        return email;
    }

    private String determineSubject(String batchNameType){
        Datetime dt = System.now();
        String currentDayOfWeek = dt.format('E');
        String ticketType = '';
        if(batchNameType == 'ATS SUMMARY' ){
            ticketType = 'P2 Ticket';
        }
        else if(batchNameType=='CFMS SEND' || batchNameType == 'CFMS005' || batchNameType == 'CFMS006' || batchNameType == 'CFMS007' || batchNameType == 'CHATSB' || batchNameType == 'CHATSR' ){
            if(currentDayOfWeek == 'Thu'){
                ticketType = 'P2 Ticket';
            }
            else{
                ticketType = 'P3 Ticket';
            }
        }
        else{
            ticketType='P3 Ticket'; 
        }
        return 'CHATS Batch Failed - '+ batchNameType + ' - ' + dt.month() + '/' + dt.day()+ '/' + dt.year() + ' - ' + ticketType;
    } 

}