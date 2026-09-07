@isTest
public class corspdExceptionTest {
    static testmethod void testcorspdException(){
        corspdException exe= new corspdException();
        corspdException.corspdExp();
        system.assertEquals(true,string.valueof(exe).contains('exception'),'Should return null');
    }

}