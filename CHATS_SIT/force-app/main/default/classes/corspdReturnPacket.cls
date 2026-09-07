public class corspdReturnPacket {
    @auraEnabled
    public string returnStatus;
    @auraEnabled
    public list<corspdError> errorMessage;
	@auraEnabled
    public object payload;
    @auraEnabled
    public String targetUrl;
    @auraEnabled
    public String corspdPathInAws;
    @auraEnabled
    public String manualLetter1;
    @auraEnabled
    public String manualLetter2;
    @auraEnabled
    public integer corspdSearchListCount;
    @auraEnabled
    public integer CountOfGeneratedRecordsInDelete;
    @auraEnabled
    public integer CountOfRequestedRecordsInPrint;
    @auraEnabled
    public boolean CorrespondenceAlreadyGenerated;
    @auraEnabled
    public string CorrespondenceFileName;
    @auraEnabled
    public string assembledDocumentId;
    @auraEnabled
    public String dateRequested;
    @auraEnabled
    public string isPrinted;
    public corspdReturnPacket(){
        
    }
}