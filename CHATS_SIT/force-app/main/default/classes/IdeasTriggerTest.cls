@isTest
public class IdeasTriggerTest {
    public static testmethod void testIdeasVote(){
        Ideas__c newIdea = new Ideas__c (	Summary__c = 'IdeaTest',
                                   		Description__c = 'testing the Idea',
                                        Category__c = 'Authorization',
                                        value__c = 'Idea Test');
    	insert newIdea;
    
		Ideas_Vote__c newIdeaVote = new Ideas_Vote__c(	NBR_IDEA__c = newIdea.Id);
    	insert newIdeaVote;
    }
}