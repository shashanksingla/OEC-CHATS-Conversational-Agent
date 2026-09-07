@isTest
private class IPVAllegationAPXCtrlTest {

    @isTest
    static void IPVAllegationTest(){
        T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(true, System.today().addYears(-4), 'firstName', '2', 'lastName','111222333','CWF');
        IPV_Information__c ipvinfo1 = new IPV_Information__c(Individual_Id__c = indiv.Id, Number_of_occurrences__c = '2', Disqualification_End_Date__c = System.today().addDays(7));
        insert ipvinfo1;
        IPV_Information__c ipvinfo2 = new IPV_Information__c(Individual_Id__c = indiv.Id, Number_of_occurrences__c = '3', Disqualification_End_Date__c = System.today().addDays(8), Reversal_Created__c = false);
        insert ipvinfo2;
        Investigatory_Finding__c invFinding = new Investigatory_Finding__c(IPV_Information__c = ipvInfo1.Id);
        insert invFinding;

        Test.startTest();
        IPVAllegationAPXCtrl.getDomainURL();        
        IPVAllegationAPXCtrl.getLatestIPVRecord(indiv.Id);
        IPVAllegationAPXCtrl.getDisqualificationInitData(ipvinfo1.Id);
        LightningServerResponse response = IPVAllegationAPXCtrl.getInvestigatoryFindings(ipvinfo1.Id);
        Test.stopTest();

        System.assertEquals(true, response.isSuccessful, 'Response should be successful');
    }

    @isTest
    static void getAllegationNotesTest(){
        T_SBSD_INDIV__c indiv = TestClassUtility.createIndividual(true, System.today().addYears(-4), 'firstName', '2', 'lastName','111222333','CWF');
        IPV_Information__c ipvinfo = new IPV_Information__c(Individual_Id__c = indiv.Id, Number_of_occurrences__c = '2', Disqualification_End_Date__c = System.today().addDays(7));
        insert ipvinfo;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(ipvinfo);
        PageReference pageRef = Page.AllegationNotesView;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('ipvInformationId',ipvinfo.id);        
        IPVAllegationAPXCtrl.getAllegationNotes();
        IPVAllegationAPXCtrl.getIPVInformation();
        Test.stopTest();
    }
}