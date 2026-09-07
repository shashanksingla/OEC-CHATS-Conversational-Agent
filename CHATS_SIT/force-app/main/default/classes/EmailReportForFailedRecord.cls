public without sharing class EmailReportForFailedRecord {
    
    public transient List<Messaging.SingleEmailMessage> messages { get; private set; }
    public EmailReportForFailedRecord(){
        messages = new List<Messaging.SingleEmailMessage>
        {
            new Messaging.SingleEmailMessage()
        };
    }
    
    public  void sendEmail(List<String> deleteResults,String batchName){
        System.debug(':Started method sendEmail in EmailReportForFailedRecord');
        System.debug(':Started method sendEmail in EmailReportForFailedRecord;size'+deleteResults.size());
        Id owEmailAddressId = EmailUtility.getOrgWideEmailIdByLabel(System.Label.CHATS_Notifications_OW_Email);
        String emailBody='<html><body> Hi,  </br></br> This is an Automated Report for failed records by '+batchName+'</br></br>';
        emailBody+='<table style="width:100%; border: 1px solid black"> <tr> <th style="text-align: left;border: 1px solid black;  border-collapse: collapse">Record Id</th> <th style="text-align: left;border: 1px solid black;  border-collapse: collapse">Status</th> <th style="text-align: left;border: 1px solid black;  border-collapse: collapse">Failure Reason</th> </tr>';
        for(String dr: deleteResults){
            
              emailBody+='<tr>';
              emailBody+='<td style="border: 1px solid black;  border-collapse: collapse">'+dr.split(';;')[0]+'</td>'; 
              emailBody+='<td style="border: 1px solid black;  border-collapse: collapse">'+dr.split(';;')[1]+'</td>';
             
              emailBody+='<td style="border: 1px solid black;  border-collapse: collapse">'+dr.split(';;')[2]+'</td>';
              emailBody+='</tr>';
            
            
            



        }
        emailBody+='</table></br></br>***End Of Mail***</br>';
        emailBody+='</body></html>';
        List<String> emails =  new List<String>();
            if(null!=deleteResults&&deleteResults.size()>0){
            emails.addAll(system.label.junk_deletion_batch_report_email.split(';'));
            messages.get(0).setToAddresses(emails);
            messages.get(0).setSubject('Junk Record Deletion Batch Report');
            messages.get(0).setHTMLbody(emailBody);
            System.debug('Email Body:'+emailBody);
            if(owEmailAddressId != null) {
                messages.get(0).setOrgWideEmailAddressId(owEmailAddressId);
            }           
            Messaging.sendEmail(messages); 
            }
        
    }   
}