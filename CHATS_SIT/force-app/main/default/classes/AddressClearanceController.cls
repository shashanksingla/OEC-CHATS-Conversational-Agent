/**
* @Component Name   : AddressClearanceController
* @Developed By     : Deloitte LLC
* @Created Date     : July 19, 2018
* @Description      : Webservice call for Address verification
* @Test Class		: AddressClearanceControllerTest
* ***************************************************************************************************
*										Modification Log
* ***************************************************************************************************
* 	Name				|	Version		|		Date		|					Discription
* ***************************************************************************************************
*		Shubham K		|		1		|		(5/12)		|
*		Caleb			|		2		|		(8/18)		|	Changed the exception with insert flag 
*						|				|					|	so that it can be by-passed
*/
public with sharing class AddressClearanceController {
    public static LightningServerResponse responseToUIComponent;
    public static String ADDRESS_VALIDATION = 'Address_Validation';
	/**
	* @function     :   getMatchingAddress
	* @description  :   Call address verification for Case address
	* @parm         :   {String} street, {String} street2, {String} city, {String} state, {String} zipcode
	* @return       :    LightningServerResponse
	*/
    @auraEnabled
    public Static LightningServerResponse getMatchingAddress(String street , String street2 , String city, String state, String zipcode) {
        Exception_Log__c xLog;
        List<AddressWrapper> respAddrlst = new List<AddressWrapper>();
        try {
            List<WebServiceConfiguration__mdt> serviceMetaData = new List<WebServiceConfiguration__mdt>();
            serviceMetaData = [SELECT id, AuthId__c, AuthToken__c, EndPoint__c, isActive__c, ServiceType__c, MasterLabel, DeveloperName FROM WebServiceConfiguration__mdt WHERE isActive__c = true AND DeveloperName = :ADDRESS_VALIDATION LIMIT 1];
            if (!serviceMetaData.isEmpty() && serviceMetaData[0].AuthId__c <> null && serviceMetaData[0].AuthToken__c <> null && serviceMetaData[0].EndPoint__c <> null) {
                Httprequest request = new Httprequest();
                Http http = new Http();
                request.setMethod('GET');
                request.setHeader('Content-Type', 'Application/json');
                request.setHeader('client_id', CryptoClass.decrypt(serviceMetaData[0].AuthId__c));
                request.setHeader('client_secret', CryptoClass.decrypt(serviceMetaData[0].AuthToken__c));
                String adrParams = '';
                if (String.isNotBlank(street)) {
                    adrParams += '&street=' + EncodingUtil.urlEncode(street, 'UTF-8');
                    if (String.isNotBlank(street2))
                        adrParams += EncodingUtil.urlEncode(' '+street2, 'UTF-8');
                }
                if (String.isNotBlank(city))
                    adrParams += '&city=' + EncodingUtil.urlEncode(city, 'UTF-8');
                if (String.isNotBlank(state))
                    adrParams += '&state=' + EncodingUtil.urlEncode(state, 'UTF-8');
                if (String.isNotBlank(zipcode))
                    adrParams += '&zipCode=' + EncodingUtil.urlEncode(zipcode, 'UTF-8');
                request.setEndpoint((serviceMetaData[0].EndPoint__c + adrParams));
                HttpResponse response = http.send(request);
                if (response <> null && response.getStatusCode() == 200) {
                    String responseJSON = response.getBody();
                    List<Object> responseList = (List<Object>) JSON.deserializeUntyped(responseJSON);
                    if (!responseList.isEmpty()) {
                        for (integer i = 0; responseList.size() > i; i++) {
                            Map<String, Object> responseMap = (Map<String, Object>) responseList[i];
                            Map<String, Object> componentsMap = (Map<String, Object>) responseMap.get('components');
                            AddressWrapper responseAddress = new AddressWrapper();
                            responseAddress.ADR_CITY = (String) componentsMap.get('city_name');
                            responseAddress.ADR_LINE_1 = (String) responseMap.get('delivery_line_1');
                            responseAddress.ADR_LINE_2 = (String) responseMap.get('delivery_line_2');
                            responseAddress.ADR_STATE = (String) componentsMap.get('state_abbreviation');
                            responseAddress.ADR_ZIP_MAIN = (String) componentsMap.get('zipcode');
                            responseAddress.ADR_ZIP_EXTN = (String) componentsMap.get('plus4_code');
                            respAddrlst.add(responseAddress);
                        }
                    }
                } else {
                    xLog = new Exception_Log__c();
                    xLog.Class__c = 'AddressClearanceController';
                    xLog.Method__c = 'getMatchingAddress';
                    if (response != null) {
                        xLog.Exception_Message__c = 'Status is :' + response.getStatus() + ',Status Code is :' + String.valueOf(response.getStatusCode());
                        if (response.getStatusCode() != null) {
                            xLog.Exception_Type__c = 'Web Service';
                        }
                        xLog.Response__c = response.getBody();
                    }
                    if (response != null) {
                        xLog.Request__c = 'End point:' + request.getEndpoint() + ':' + response.getBody();
                    }
                    ExceptionLoggingServices.captureExceptionLog(xLog); 
                }
            } else
                    throw new customException('Metadata configuration error. \n Please configure the metadata for this web-service first.');
            responseToUIComponent = responseToComponent(null, 'getMatchingAddress', new Map<String, Object>{
                    'addressList' => respAddrlst, 'xLog' => xLog
            }, true);
        } catch (Exception e) {
            responseToUIComponent = responseToComponent(e, 'getMatchingAddress', new Map<String, Object>{
                    'xLog' => xLog
            }, false);
        }
        return responseToUIComponent;
    }
    @auraEnabled
    public static LightningServerResponse updateAddress(String addressWrapperStr, String recordId) {
        try{
            AddressWrapper addressRecord = (AddressWrapper)JSON.deserialize(addressWrapperStr, AddressWrapper.class);
            T_SBSD_CASE_ADR__c caseAddress = new T_SBSD_CASE_ADR__c();
            caseAddress.ADR_LINE_1__c = addressRecord.ADR_LINE_1;
            caseAddress.ADR_LINE_2__c = addressRecord.ADR_LINE_2;
            caseAddress.ADR_CITY__c = addressRecord.ADR_CITY;
            caseAddress.ADR_STATE__c = addressRecord.ADR_STATE;
            caseAddress.ADR_ZIP_MAIN__c = addressRecord.ADR_ZIP_MAIN;
            caseAddress.ADR_ZIP_EXTN__c = addressRecord.ADR_ZIP_EXTN;
            caseAddress.Id = recordId;
            Database.update(caseAddress);
            responseToUIComponent = responseToComponent(null, 'updateAddress', null, true);
        }catch(DMLException e){
            responseToUIComponent = responseToComponent(e, 'updateAddress', null, true);
        }
        return responseToUIComponent;
    }
    @auraEnabled
    public static LightningServerResponse getCaseAddressIdList(String caseId) {
        list<Id> caseAddressIdList = new list<Id>();
        try{
            for( T_SBSD_CASE_ADR__c caseAddress : [select id, ADR_LINE_1__c, ADR_LINE_2__c, CDE_TYPE_ADR__c, ADR_CITY__c from T_SBSD_CASE_ADR__c where IDN_CASE__c =:caseId and CDE_TYPE_ADR__c in ('MAL','HOM')]){
                caseAddressIdList.add(caseAddress.Id);
            }
            responseToUIComponent = responseToComponent(null, 'getMatchingAddress', new Map<String, Object>{'caseAddressIdList'=>caseAddressIdList}, true);
        }
        catch(Exception ex){
            responseToUIComponent = responseToComponent(ex, 'getCaseAddressIdList', null, true);
        }
        return responseToUIComponent;
    }
    /**
    * @function     :   responseToComponent
    * @description  :   Create response for lightning component
    * @parm         :   {Exception} e, {String} methodName, {Map<String,Object>} ojectMap, {Boolean} isInsert
    * @return       :    LightningServerResponse
    */
    private static LightningServerResponse responseToComponent(Exception e, String methodName, Map<String, Object> ojectMap, Boolean isInsert){
        Boolean finalResult = true;
        String status = 'Success';
        Map<String,Object> methodInfo = new Map<String,Object>();
        methodInfo.put('Class__c','AddressClearanceController');
        methodInfo.put('Method__c',methodName);
        if(e <> null) {
            if(isInsert)
            	ExceptionLoggingServices.captureExceptionLog(e, methodInfo);
            finalResult = false;
            status = e.getMessage();
        }
        return new LightningServerResponse(finalResult, status, ojectMap);
    }
    public class customException extends Exception {}
}