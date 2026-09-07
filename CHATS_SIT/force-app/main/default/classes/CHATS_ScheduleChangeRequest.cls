/****
* Objective: CHATS-side REST webservice that receives the CCCAP Schedule Change
*            Request payload and creates a Task record representing the change
*            request for downstream processing.
* */
@RestResource(urlMapping='/CCCAP/ScheduleChangeRequest/*')
global with sharing class CHATS_ScheduleChangeRequest {
    
    @HttpPost
    global static CHATS_ScheduleChangeRequestHandler.ApiResponseWrapper createScheduleChangeTask() {
        String body = RestContext.request != null && RestContext.request.requestBody != null
            ? RestContext.request.requestBody.toString() : '';
        return CHATS_ScheduleChangeRequestHandler.handleCreate(body);
    }
}