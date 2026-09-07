/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           11/30/2017                                                          
*  @description    Handler class for Custody Trigger                             
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 30-Nov-2017                                                             
*  * Author: Azharuddin Mohammad                                                      
*  * Description: Initial version                                                 
*  *CHAT-1175: When Save is clicked, show a warning message (""This record may not be appropriate for this individual
*  *		   based on their age and/or relationship to the primary caretaker of this case"") 
*  *		   on the screen only for individuals who:
*  *           -are 19 and older (Validation Rule )
*  *           -are younger than 19 but have a relationship of mother, father, spouse, common law husband, 
*  *            common law wife, husband, wife, live-in companion
*  *		   -are the primary caretaker
*********************************************************************************************/
public class custodyServices {
    /*
    public static void primaryCareTaker(List<T_INDIV_CUST__c> newCustodyList){
        Map<Id,T_INDIV_CUST__c> custody_caseIndiv_Map = new Map<Id,T_INDIV_CUST__c>();
        List<string> relationship = new List<string>();
        relationship.add('M');
        relationship.add('F');
        relationship.add('CLH');
        relationship.add('CLW');
        relationship.add('H');
        relationship.add('W');
        relationship.add('LIC');
        
        for(T_INDIV_CUST__c eachCustody : newCustodyList){
            if(eachCustody.IDN_CLIENT__c != NULL){
                custody_caseIndiv_Map.put(eachCustody.IDN_CLIENT__c, eachCustody);
            }
        }
        if(custody_caseIndiv_Map != NULL){
            for(T_SBSD_CASE_INDIV__c caseIndiv : [select Id, IDN_CLIENT__c, IND_CRTKR__c FROM T_SBSD_CASE_INDIV__c WHERE IDN_CLIENT__c IN:custody_caseIndiv_Map.keySet() AND IND_CRTKR__c = TRUE] ){
                T_INDIV_CUST__c custodyRec = custody_caseIndiv_Map.get(caseIndiv.IDN_CLIENT__c);
                custodyRec.addError('This record may not be appropriate because individual is the primary caretaker');
            }
            for(T_INDIV_REL__c caseRelationship : [select Id, IDN_CLIENT_RELTD__c, IDN_CLIENT__c, CDE_TYPE_REL_INDIV__c FROM T_INDIV_REL__c WHERE IDN_CLIENT_RELTD__c IN:custody_caseIndiv_Map.keySet() AND IDN_CLIENT__c != NULL AND CDE_TYPE_REL_INDIV__c IN:relationship]){
                T_INDIV_CUST__c custodyRec1 = custody_caseIndiv_Map.get(caseRelationship.IDN_CLIENT_RELTD__c);
                custodyRec1.addError('This record may not be appropriate for this individual based on their age and/or relationship to the primary caretaker of this case');
            }
        }
    }*/
}