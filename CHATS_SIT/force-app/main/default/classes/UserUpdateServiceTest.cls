@isTest
public class UserUpdateServiceTest {
    
    public static testMethod void testvalidateUserBeforeUpdate(){
    	test.startTest();
        User user1;
        User user2;
        Profile userProfile=[Select id from Profile where Name ='System Administrator'];
        user1 = TestClassUtility.createUserWithPS(userProfile.Id ,'System_Administrator_PS', 'test','test','test@example.com','test@example.com.'+string.valueof(math.random()*3),'ttes');
        
        Profile userProfile2=[Select id from Profile where Name ='Provider Worker'];
        user2 = TestClassUtility.createUserWithPS(userProfile2.Id, 'Provider_Worker_PS', 'test2','test2','test2@example.com','test2@example.com.'+string.valueof(math.random()*3),'ttes2');
        
        System.runAs(user1){
            
            user1.FirstName = 'test 2';
            update user1;
            String userName = [Select FirstName from User where id =: user1.id].FirstName;
            System.assertEquals('test 2',userName,'User First Name should match');
        }
        
        System.runAs(user2){
            
            user2.FirstName = 'test 2';
            try{
            update user2;
            }catch(DMLException exp){
            
            String userName = [Select FirstName from User where id =: user2.id].FirstName;
            System.assertNotEquals('test 2',userName,'User First Name should match');
            }
            
        }
        test.stopTest();
    }
    
}