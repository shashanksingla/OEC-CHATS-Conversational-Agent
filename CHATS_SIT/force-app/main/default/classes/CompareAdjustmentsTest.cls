@isTest
public class CompareAdjustmentsTest {
    static testmethod void testCompareTo() {
    List<CompareAdjustments> compAdjustCreatedList= new List<CompareAdjustments>();
        List<T_ADJMT__c> adjustList= new List<T_ADJMT__c>();
        adjustList.add(new T_ADJMT__c(CDE_TYPE_CLSFN__c='3'));
        adjustList.add(new T_ADJMT__c(CDE_TYPE_CLSFN__c='2'));
        adjustList.add(new T_ADJMT__c(CDE_TYPE_CLSFN__c='2'));
        adjustList.add(new T_ADJMT__c(CDE_TYPE_CLSFN__c='1'));
               
        for(T_ADJMT__c adjmt:adjustList) {       
           compAdjustCreatedList.add( new CompareAdjustments(adjmt,Integer.valueOf(adjmt.CDE_TYPE_CLSFN__c),'Type'));
        }
        
        compAdjustCreatedList.sort(); 
        
        compAdjustCreatedList.add( new CompareAdjustments(new T_ADJMT__c(),2,'test'));
         
        compAdjustCreatedList.sort();        
        
        
        system.assert(string.valueOf(compAdjustCreatedList[0]).contains('CDE_TYPE_CLSFN__c=1'),'Sorted list');
        system.assert(string.valueOf(compAdjustCreatedList[1]).contains('CDE_TYPE_CLSFN__c=2'),'Sorted list');
        system.assert(string.valueOf(compAdjustCreatedList[2]).contains('CDE_TYPE_CLSFN__c=2'),'Sorted list');
        system.assert(string.valueOf(compAdjustCreatedList[3]).contains('CDE_TYPE_CLSFN__c=3'),'Sorted list');
        
        
       
    }

}