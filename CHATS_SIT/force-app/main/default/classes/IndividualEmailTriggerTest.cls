@isTest
public class IndividualEmailTriggerTest {
     
    public static testMethod void invoke(){
        Test.startTest();
        T_COUNTY__c countyRec = TestClassUtility.createCounty('Denver','Denver',1,true);
        T_SBSD_CASE__c sbsdcase=new T_SBSD_CASE__c();
        sbsdcase.CDE_COUNTY__c=countyRec.Id;
        sbsdcase.IND_ASSIST_PROVR__c = 'N';
        sbsdcase.IND_ELG_PRE_PROVR__c  = false;
        insert sbsdcase;
        T_SBSD_CASE_INFO__c caseinforec=new T_SBSD_CASE_INFO__c ();
        caseinforec.IDN_CASE__c=sbsdcase.Id;
        caseinforec.CDE_TYPE_INFO_CASE__c='EM';
        caseinforec.TXT_VALUE_INFO_CASE__c='test@gmail.com';
        insert caseinforec;
        T_SBSD_INDIV__c sbsdIndiv = new T_SBSD_INDIV__c();
        sbsdIndiv.DTE_DOB__c=system.today().addYears(-30);
        sbsdIndiv.NAM_FIRST__c='Satty';
        sbsdIndiv.CDE_GENDER__c='2';
        sbsdIndiv.NAM_LAST__c='Nayak';
        sbsdIndiv.NBR_SSN__c='123456789';
        sbsdIndiv.CDE_SOURCE_VRFYD_IDNTY__c='MI';
        sbsdIndiv.IND_CDE_TYPE_VERIF_DOB__c='NA';
        Insert sbsdIndiv;
        T_SBSD_INDIV__c sbsdIndivone = new T_SBSD_INDIV__c();
        sbsdIndivone.DTE_DOB__c=system.today().addYears(-20);
        sbsdIndivone.NAM_FIRST__c='Matty';
        sbsdIndivone.CDE_GENDER__c='2';
        sbsdIndivone.NAM_LAST__c='Naik';
        sbsdIndivone.NBR_SSN__c='123456789';
        sbsdIndivone.CDE_SOURCE_VRFYD_IDNTY__c='MI';
        sbsdIndivone.IND_CDE_TYPE_VERIF_DOB__c='NA';
        Insert sbsdIndivone;
        T_SBSD_CASE_INDIV__c Caseindiv=TestClassUtility.createCaseIndividual(true,sbsdcase.Id,sbsdIndiv.Id,true);
        T_SBSD_CASE_INDIV__c Caseindivone=TestClassUtility.createCaseIndividual(true,sbsdcase.Id,sbsdIndiv.Id,false);
        Individual_E_mail__c indiemailrec1=new Individual_E_mail__c();
        indiemailrec1.Effective_Begin_Date__c=System.today();
        indiemailrec1.Email_Information__c='pragnayak@gmail.com';
        indiemailrec1.Individual__c=sbsdIndiv.Id;
        insert indiemailrec1;
         indiemailrec1.Email_Information__c='satarupa@gmail.com';
        update indiemailrec1;
        List<Individual_E_mail__c> IndemList = [Select Id from Individual_E_mail__c where Id =:indiemailrec1.Id];
        System.assertEquals(IndemList.size(),1);
        Test.stopTest();
        
    }    

}