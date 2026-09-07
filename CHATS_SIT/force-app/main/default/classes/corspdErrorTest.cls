@isTest
public class corspdErrorTest {
    static testmethod void testCorspdError(){
    	test.startTest();
        corspdError err = new corspdError();
        system.assertEquals(null,err.errorMsg,'Error message should be null');
        test.stopTest();
    }

}