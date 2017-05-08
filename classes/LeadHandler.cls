public with sharing class LeadHandler extends BaseTriggerHandler { 
    protected override void BeforeUpdate(){
    	super.BeforeUpdate();
    	CheckForUnauthorizedAccess();
	} 
	
	private void CheckForUnauthorizedAccess(){
		 for(SObject sobj : trigger.new){
			Lead tempLead = (Lead)sobj;
			Profile p = [select id from profile where name = 'Recruiter'];
			if(UserInfo.getProfileId() == p.Id){
				if(tempLead.ownerId != UserInfo.getUserId()){
					tempLead.addError(Label.Unauthorized_Permissions);
				}		
			}
		 }
	}
}