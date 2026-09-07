@RestResource(urlMapping='/Provider/Claims/*')
global class CHATS_ProviderClaims {
    @HttpPost
    global static CHATS_claimResponseWrapper upsertManualClaims() {
        String Body = RestContext.request.requestBody.toString();
        system.debug('Body'+body);
        CHATS_claimResponseWrapper resp = new CHATS_claimResponseWrapper();
        resp  = CHATS_ProviderClaimRequestHandler.handleSaveOperation(Body); // will run when any updates happen on any claim record or file upload/change to fetch latest information.
        return resp;
    }
}