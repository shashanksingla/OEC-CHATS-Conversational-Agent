trigger IdeasVoteTrigger on Ideas_Vote__c (before insert, after insert) {
	if(Trigger.isBefore){
        IdeasVoteServices.avoidMultipleVotesByUserPerIdea(Trigger.New);
    }
    if(Trigger.isAfter){
        IdeasVoteServices.updateUserSfid(Trigger.New);
    }
}