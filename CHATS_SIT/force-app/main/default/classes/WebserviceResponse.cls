public class WebserviceResponse {
    public boolean isSuccess;
    public Integer statusCode;
    public String message;
    public HttpRequest req;
    public HttpResponse resp;
    public List<String> lstInsertedExtIds;
    public List<sObject> lstSObject;
    public map<Date, String> mapCareDateToExtId;
}