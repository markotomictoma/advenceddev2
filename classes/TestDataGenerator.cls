public with sharing class TestDataGenerator { 	
	public static Position__c CreatePosition(String fName, String category, Decimal baseSalary, String positionStatus){
		return new Position__c(name = fName, category__c = category, base_salary__c = baseSalary, position_status__c = positionStatus);
	}

	public static List<Lead> CreateLeads(integer numOfLeads){
		List<Lead> leads = new List<Lead>();
		for(integer i = 1; i <= numOfLeads; i++){
			leads.add(new Lead(firstName = 'test', lastname = String.valueOf(i), company = 'test company'));
		}
		return leads;
	}

	public static Application__c CreateApplication(ID positionId, ID leadId, String status){
		return new Application__c(Position__c = positionId, Lead__c = leadId, application_status__c = status);
	}
}