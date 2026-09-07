/*********************************************************************************************
*  @author         Deloitte Consulting LLP.                                            
*  @date           1/04/2018                                                          
*  @description    This class implements Comparable Interface which is invoked by AdjustmentPaymentServices class                            
*  Modification Log:                                                                             
*                                                                                      
*  * Version: 1.0                                                                             
*  * Date: 4-Jan-2018                                                             
*  * Author: Bharadwaj Gaddam                                                      
*  * Description: Initial version                   
*********************************************************************************************/
public class CompareAdjustments implements Comparable {
    
    public Datetime recCreatedDate;
    public sObject record;
    public Integer rectype; 
    public string compareField;
    
    // Constructor
    public CompareAdjustments(sObject obj,Datetime dt,string compField) {
        record = obj;
        recCreatedDate = dt;
        compareField = compField;
    }
    
    public CompareAdjustments(sObject obj,Integer num,string compField) {
        record = obj;
        rectype = num;
        compareField = compField;  
    }
    
    // Implement the compareTo() method
    public Integer compareTo(Object compareTo) {
        CompareAdjustments compareToObj = (CompareAdjustments)compareTo;
        if(compareToObj.compareField=='Createddate') {
            if(recCreatedDate == (Datetime)compareToObj.record.get('Createddate')) {
                return 0;
            }
            if(recCreatedDate > (Datetime)compareToObj.record.get('Createddate')) {
                return 1;
            }
            return -1;
        } else if(compareToObj.compareField=='Type') {
            if(rectype == integer.valueof(compareToObj.record.get('CDE_TYPE_CLSFN__c'))) {
                return 0;
            }
            if(rectype > integer.valueof(compareToObj.record.get('CDE_TYPE_CLSFN__c'))) {
                return 1;
            }
            return -1;
        }
        return -1;
    }
}