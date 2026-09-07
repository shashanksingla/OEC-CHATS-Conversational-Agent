@isTest
public class IndivEmploymeentWrapperTest {
    static testMethod void returnIndivEmploymeentWrapperTest(){
        test.startTest();
        IndivEmploymeentWrapper wrapper = new IndivEmploymeentWrapper(); 
        system.assertEquals(null,wrapper.indivSfid,'Should be null');
        test.stopTest();
    }
}