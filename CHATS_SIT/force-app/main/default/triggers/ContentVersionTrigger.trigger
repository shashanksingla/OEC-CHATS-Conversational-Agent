trigger ContentVersionTrigger on ContentVersion (after insert) {
    
    //User u = [SELECT Profile.Name FROM User WHERE Id = :Userinfo.getUserId() limit 1]; Using Custom permission CCCAP-14993
    
    String keyPrefix = T_CHATS_PROVR_STATUS__c.SObjectType.getDescribe().getKeyPrefix();
    
    Set<Id> contentDocumentIdSet = new Set<Id>();
    for(ContentVersion cv : trigger.new){
        if(cv.ContentDocumentId != null){
            contentDocumentIdSet.add(cv.ContentDocumentId);
        }
        String errorMessage = 'This file type is not supported. Please upload an accepted file type.';
        Set<String> allowedFileTypes = new Set<String>{'CSV','WORD','WORDT','WORD_X','PDF','POWER_POINT','POWER_POINTT','POWER_POINT_X','PPS','EXCEL','EXCELT','EXCEL_X','PNG','JPG','JPEG','BMP','GIF','TIFF','TIF'};
            if( cv.FileType != null && 
               !allowedFileTypes.contains(cv.FileType) && !test.isrunningTest()) {
                   cv.addError(errorMessage);
               }
    }
    
    if(!contentDocumentIdSet.isEmpty()){
        String entityId;
        Map<Id, Id> cdlMap = new Map<Id, Id>();
        for(ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN:contentDocumentIdSet]){
            cdlMap.put(cdl.ContentDocumentId, cdl.LinkedEntityId);
        }
        
        List<ContentVersion> cvsToUpdate = new List<ContentVersion>();
        for(ContentVersion cv : trigger.new){
            if(cv.ContentDocumentId != null){
                entityId = cdlMap.get(cv.ContentDocumentId);
                if(entityId.startsWith(keyPrefix)){
                    //Replaced with custom permission CCCAP-14993
                    if(!FeatureManagement.checkPermission('System_Administrator') && !FeatureManagement.checkPermission('CCCAP_Program_Internal_Team')){
                        cv.addError('You do not have permission to upload files here.');
                    } else {
                        cvsToUpdate.add(new ContentVersion(Id = cv.Id, SharingOption = 'R'));
                    }
                }
            }
        }
        if(!cvsToUpdate.isEmpty()){
            update cvsToUpdate;
        }
    }
}