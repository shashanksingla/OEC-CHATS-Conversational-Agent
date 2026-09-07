@isTest(seeAllData=false)
public class AttendanceSearchAPXCtrl_Test {
    public static testMethod void testAttendanceFetch(){
        LightningServerResponse lsr=AttendanceSearchAPXCtrl.getAttendanceResults('23156', '451112893', 'O942500', '2017-10-01', '2017-10-31');
        system.assertEquals(false,lsr.isSuccessful,'testing');
        LightningServerResponse lsr2=AttendanceSearchAPXCtrl.getAttendanceResults('23156', '451112893', 'O942500', '2017-10-01', null);
        system.assertEquals(false,lsr2.isSuccessful,'testing');
        LightningServerResponse lsr3=AttendanceSearchAPXCtrl.getAttendanceResults('23156', '451112893', 'O942500', '2017-10-01-', null);
        system.assertEquals(false,lsr3.isSuccessful,'testing');
        Map<String, Object> testMap1 = AttendanceSearchAPXCtrl.getAttendanceResultsFor803Report('23156', '451112893', 'O942500', '2017-10-01', '2017-10-31', 'true');
        system.assert(testMap1 == null, 'testing');
    }
}