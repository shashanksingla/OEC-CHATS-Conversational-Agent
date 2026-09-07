public with sharing class IdeasVoteServices {
    
    public static void avoidMultipleVotesByUserPerIdea(List<Ideas_Vote__c> newIdeasVoteList){
        set<String> userVotedSFIDList = new set<String>();
        map<string, Ideas_Vote__c> userVotedMap = new map<string, Ideas_Vote__c>();
        for(Ideas_Vote__c eachnewIdeasVote : newIdeasVoteList){
            userVotedSFIDList.add(eachnewIdeasVote.Voter_SFID__c);
            userVotedMap.put(userinfo.getuserid(), eachnewIdeasVote);
        }
        if (!userVotedSFIDList.isEmpty()){
            for(Ideas_Vote__c eachVote: [select id, createdById, NBR_IDEA__c, Voter_SFID__c from Ideas_Vote__c where Voter_SFID__c =: userinfo.getuserid() and Id != null]){
                if(eachVote.NBR_IDEA__c == userVotedMap.get(eachVote.Voter_SFID__c).NBR_IDEA__c){
                    Ideas_Vote__c ideasVoteRcrd = userVotedMap.get(eachVote.Voter_SFID__c);
                    ideasVoteRcrd.adderror('Maximum of one vote is allowed per User for an Idea.');
                }
            }
        }
    }

    public static void updateUserSfid(List<Ideas_Vote__c> newIdeasVoteList){
        Ideas_Vote__c eachVoterRecord = new Ideas_Vote__c();
        List<Ideas_Vote__c> ideasVoteList = new List<Ideas_Vote__c>();
        system.debug('the userId-->' +userinfo.getuserid());
        system.debug('the user-->' +userinfo.getFirstName());
        for(Ideas_Vote__c eachVoter : newIdeasVoteList){
            eachVoterRecord.Id = eachVoter.Id;
            eachVoterRecord.Voter_SFID__c = userinfo.getuserid();
            eachVoterRecord.Voted_User__c = userinfo.getFirstName() +' ' + userinfo.getLastName();
            ideasVoteList.add(eachVoterRecord);
        }
        if(!ideasVoteList.isEmpty()){
            GenericDMLHandler.updateRecords(ideasVoteList,null);
        }  
    }

}