@isTest
public class GenericDMLHandlerTest {
public static testMethod void testinsertRecords(){
    User user;
    Profile userProfile=[Select id from Profile where Name ='Read Only User'];
    user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
    System.runAs(user){
        try {
        GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ TestClassUtility.createCounty('Denver','Denver',1,false)},null);
        } catch(Exception ex) {
           System.assertEquals(false, ex.getMessage().contains('exception'));
           
        }
        
        try {
             GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ TestClassUtility.createCounty('Denver','Denver',1,false)},new Map<String,Object>{'byPassObjects'=> new set<string>{'T_SBSD_CASE__c'}});
        }
        catch(Exception ex) {
             System.assertEquals(false, ex.getMessage().contains('exception'));
        }
        
        try {
            GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ TestClassUtility.createCounty('Denver','Denver',1,false)},new Map<String,Object>{'Method__c'=>'TestMetod','Class__c'=>'TestClass'});
        
        }
         catch(Exception ex) {
             System.assertEquals(false, ex.getMessage().contains('exception'));
        }
        
    }
    
    
    }
    
public static testMethod void testupdateRecords(){
    User user;
    Profile userProfile=[Select id from Profile where Name ='Read Only User'];
    user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
    T_COUNTY__c county= TestClassUtility.createCounty('Denver','Denver',1,true);
    System.runAs(user){
        try {
        GenericDMLHandler.updateRecords(new List<T_COUNTY__c>{county },null);
        } catch(Exception ex) {
            System.assertEquals(false, ex.getMessage().contains('exception'));
           
        }
        
        try {
             GenericDMLHandler.updateRecords(new List<T_COUNTY__c>{ county},new Map<String,Object>{'byPassObjects'=> new set<string>{'T_SBSD_CASE__c'}});
        }
        catch(Exception ex) {
             System.assertEquals(false, ex.getMessage().contains('exception'));
        }
        
        try {
            GenericDMLHandler.updateRecords(new List<T_COUNTY__c>{ county},new Map<String,Object>{'Method__c'=>'TestMetod','Class__c'=>'TestClass'});
        
        }
         catch(Exception ex) {
             System.assertEquals(false, ex.getMessage().contains('exception'));
        }
        
    }
    
    
    }     
    
    public static testMethod void testdeleteRecords(){
    User user;
    Profile userProfile=[Select id from Profile where Name ='Read Only User'];
    user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
    T_COUNTY__c county= TestClassUtility.createCounty('Denver','Denver',1,true);
    System.runAs(user){
        try {
        GenericDMLHandler.deleteRecords(new List<T_COUNTY__c>{ county},null);
        } catch(Exception ex) {
            System.assertEquals(false, ex.getMessage().contains('exception'));
           
        }
        
        try {
             GenericDMLHandler.deleteRecords(new List<T_COUNTY__c>{ county},new Map<String,Object>{'byPassObjects'=> new set<string>{'T_SBSD_CASE__c'}});
        }
        catch(Exception ex) {
             System.assertEquals(false, ex.getMessage().contains('exception'));
        }
        
        try {
            GenericDMLHandler.deleteRecords(new List<T_COUNTY__c>{ county},new Map<String,Object>{'Method__c'=>'TestMetod','Class__c'=>'TestClass'});
        
        }
         catch(Exception ex) {
             System.assertEquals(false, ex.getMessage().contains('exception'));
        }
        
    }
    
    
    }  
    
    public static testMethod void testinsertRecords2(){
    User user;
    Profile userProfile=[Select id from Profile where Name ='Read Only User'];
    user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
    System.runAs(user){
        try {
        GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ TestClassUtility.createCounty('Denver','Denver',1,false)},false,null);
        } catch(Exception ex) {
            System.assertEquals(true, ex.getMessage().contains('exception'));
           
        }
        
        try {
             GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ TestClassUtility.createCounty('Denver','Denver',1,false)},false,new Map<String,Object>{'byPassObjects'=> new set<string>{'T_SBSD_CASE__c'}});
        }
        catch(Exception ex) {
             System.assertEquals(true, ex.getMessage().contains('exception'));
        }
        try {
             GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ TestClassUtility.createCounty('Denver','Denver',1,false)},false,new Map<String,Object>{'byPassObjects'=> new set<string>{'T_COUNTY__c'}});
        }
        catch(Exception ex) {
             System.assertEquals(true, ex.getMessage().contains('exception'));
        }
        
        try {
            GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ TestClassUtility.createCounty('Denver','Denver',1,false)},false,new Map<String,Object>{'Method__c'=>'TestMetod','Class__c'=>'TestClass'});
        
        }
         catch(Exception ex) {
             System.assertEquals(true, ex.getMessage().contains('exception'));
        }
        
    }
    
    
    }      
     
    public static testMethod void testupdateRecords2(){
    User user;
    Profile userProfile=[Select id from Profile where Name ='Read Only User'];
    user = TestClassUtility.createUser(userProfile.Id , 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
    T_COUNTY__c county= TestClassUtility.createCounty('Denver','Denver',1,true);
    System.runAs(user){
        try {
        GenericDMLHandler.updateRecords(new List<T_COUNTY__c>{ county},false,null);
        } catch(Exception ex) {
            System.assertEquals(true, ex.getMessage().contains('exception'));
           
        }
        
        try {
             GenericDMLHandler.updateRecords(new List<T_COUNTY__c>{ county},false,new Map<String,Object>{'byPassObjects'=> new set<string>{'T_SBSD_CASE__c'}});
        }
        catch(Exception ex) {
             System.assertEquals(true, ex.getMessage().contains('exception'));
        }
        try {
             GenericDMLHandler.insertRecords(new List<T_COUNTY__c>{ county},false,new Map<String,Object>{'byPassObjects'=> new set<string>{'T_COUNTY__c'}});
        }
        catch(Exception ex) {
             System.assertEquals(true, ex.getMessage().contains('exception'));
        }
        
        try {
            GenericDMLHandler.updateRecords(new List<T_COUNTY__c>{ county},false,new Map<String,Object>{'Method__c'=>'TestMetod','Class__c'=>'TestClass'});
        
        }
         catch(Exception ex) {
             System.assertEquals(true, ex.getMessage().contains('exception'));
        }
        
    }
    
    
    }     
    
  
    
}