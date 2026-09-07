/*********************************************************************************************
*  * Version: 1.0                                                                             
*  * Date: 27-JAN-2020                                                                                                           
*  * Description: Initial version                                                 
*  * copying soundex value to TXT_SNDX__c field
*********************************************************************************************/
public with sharing class ApplicationIndividualServices {
    
    public static void fillSoundexValue(List<T_APPLN_INDIV__c> listIndivSearch, Map<Id, T_APPLN_INDIV__c> individualsOldMap){
        for(T_APPLN_INDIV__c indivSearch : listIndivSearch){
            if(String.isEmpty(indivSearch.id) || 
               (individualsOldMap.get(indivSearch.id).NAM_FIRST__c!=indivSearch.NAM_FIRST__c || 
                individualsOldMap.get(indivSearch.id).NAM_LAST__c!=indivSearch.NAM_LAST__c)){
                    String soundexValue = '';
                    
                    if((indivSearch.NAM_LAST__c!=null && indivSearch.NAM_LAST__c !='') && (indivSearch.NAM_FIRST__c != null && indivSearch.NAM_FIRST__c != '')){
                        soundexValue = (indivSearch.NAM_LAST__c !=null? SoundexUtil.toSoundex(indivSearch.NAM_LAST__c).RightPad(6,'0'):'')+SoundexUtil.toSoundex(indivSearch.NAM_FIRST__c); 
                        
                    } else if((indivSearch.NAM_LAST__c !=null && indivSearch.NAM_LAST__c != '') && (indivSearch.NAM_FIRST__c == null || indivSearch.NAM_FIRST__c == '')){
                        soundexValue =(indivSearch.NAM_LAST__c !=null? SoundexUtil.toSoundex(indivSearch.NAM_LAST__c).RightPad(6,'0'):'');
                        
                    } else if((indivSearch.NAM_LAST__c ==null || indivSearch.NAM_LAST__c == '') && (indivSearch.NAM_FIRST__c != null && indivSearch.NAM_FIRST__c != '')){
                        soundexValue =SoundexUtil.toSoundex(indivSearch.NAM_FIRST__c);
                        
                    }
                    system.debug('soundexValue---'+soundexValue);
                    if(soundexValue!=null && soundexValue!=''){
                        indivSearch.TXT_SNDX__c = soundexValue;
                    }
                }
        }
    }
}