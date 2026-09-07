@isTest
public class corspdReturnPacketTest {
    static testmethod void returnPacketTest(){
    	test.startTest();
       corspdReturnPacket rtn = new corspdReturnPacket(); 
       system.assertEquals(null,rtn.corspdSearchListCount,'Should be null');
       test.stopTest();
    }

}