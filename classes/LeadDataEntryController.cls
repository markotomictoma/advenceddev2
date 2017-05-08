public with sharing class LeadDataEntryController {
    //Paging properties, nothing interesting here
	private final Integer pageSize = 5;
	public final Lead recLead {public get; private set;}
	public Integer currentPage {
		public get{
			return setCon.getPageNumber();
		}
		private set;
	}
	public Integer totalPages{
		public get{
			if(setCon.getResultSize() == 0){
				return 0;
			}else{
				if(math.mod(setCon.getResultSize(), setCon.getPageSize()) != 0){//calculates number of pages based on the MOD of total records number and specified page size. 
					return setCon.getResultSize()/setCon.getPageSize() + 1;
				}
			}
			return setCon.getResultSize()/setCon.getPageSize();
		}
	}
	public Boolean firstRendered{
		get{
			return currentPage == 1;
		}
	}
	public Boolean lastRendered{
		get{
			return currentPage == totalPages;
		}
	}
	public String selectedCategory{get; set;}//gets value from the category picklist change
	public String selectedPositionStatus {get; set;}//gets value from the position status picklist change
	public Map<Id, Boolean> positionId2Selected {//map that maintains selected positions. On Page Load is map initialized and preselected if there are saved applications. Binded to pageblocktable
		get{
			if(positionId2Selected == null){
				positionId2Selected = new Map<Id, Boolean>();
			}
			return positionId2Selected;
		} 
		private set;
	}
	public Boolean isAtLeastOnePositionSelected{
		get{
			for(Boolean positionSelected : positionId2Selected.values()){
				if(positionSelected){
					return true;
				}
			}
			return false;
		}
	}

	public LeadDataEntryController(ApexPages.StandardController ctrl){		
		this.recLead = (Lead)ctrl.getRecord();						
		if(!GetUserHasPermissions()){
			ApexPages.addMessage(new APexPages.Message(ApexPages.Severity.Error, Label.Unauthorized_Permissions));		
		}
		InitApplicationsData(); 
	}

	public ApexPages.StandardSetController setCon {//standard Salesforce Set controller. Here is the logic what should be selected in case of no selected categories and positions and in case of new/edit
        get {
            if(setCon == null) {            					
				Set<Id> relatedPositionIds = new Set<Id>();
				if(recLead.Id != null){
					for(Application__c app : [select Position__c from Application__c where Lead__c =: recLead.Id]){
						relatedPositionIds.add(app.Position__c);
					}
				}
				//on new record page load or when user selects "any type". No filters
				if((selectedCategory == null || selectedCategory == '-1') && (selectedPositionStatus == null || selectedPositionStatus == '-1')){					
					if(recLead.Id != null){
						List<Position__c> positions = GetAllPositionsUnfiltered();
                        List<Position__c> tmpPositions = RemoveNotOpenNotPartOfApplication(positions);
                        positions = tmpPositions;
                        setCon = new ApexPages.StandardSetController(positions);
					}else{
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c FROM Position__c where position_status__c = 'Open' order by number_of_applications__c asc, base_salary__c desc]));
					}
				}//category selected, position status not
				else if(selectedCategory != null && selectedCategory != '-1' && (selectedPositionStatus == null || selectedPositionStatus == '-1')){										
					if(recLead.Id != null){//edit record mode
						List<Position__c> positions = [SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c, (select application_status__c from applications__r where lead__c =: recLead.Id) FROM Position__c where category__c =: selectedCategory order by number_of_applications__c asc, base_salary__c desc  ];
						setCon = new ApexPages.StandardSetController(positions);
					}else{//new record mode
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c FROM Position__c where category__c =: selectedCategory and position_status__c = 'Open' order by number_of_applications__c asc, base_salary__c desc]));
						system.debug(setCon.getRecords());
					}
				}//position status selected, category not				
				else if(selectedPositionStatus != null && selectedPositionStatus != '-1' && (selectedCategory == null || selectedCategory == '-1')){					
					if(recLead.Id != null){//edit record mode
						List<Position__c> positions = [SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c, (select application_status__c from applications__r where lead__c =: recLead.Id) FROM Position__c where position_status__c =: selectedPositionStatus order by number_of_applications__c asc, base_salary__c desc  ];
						setCon = new ApexPages.StandardSetController(positions);
					}else{//new record mode
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c FROM Position__c where position_status__c = 'Open' order by number_of_applications__c asc, base_salary__c desc]));
						system.debug(setCon.getRecords());
					}
				}else{				
					if(recLead.Id != null){
						List<Position__c> positions = [SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c, (select application_status__c from applications__r where lead__c =: recLead.Id) FROM Position__c where category__c =: selectedCategory and position_status__c =: selectedPositionStatus order by number_of_applications__c asc, base_salary__c desc  ];
						setCon = new ApexPages.StandardSetController(positions);
					}else{
						setCon = new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c FROM Position__c where category__c =: selectedCategory and position_status__c = 'Open' order by number_of_applications__c asc, base_salary__c desc]));
						system.debug(setCon.getRecords());
					}
				}
            }
            return setCon;
        }
        set;
    }
    
    private List<Position__c> RemoveNotOpenNotPartOfApplication(List<Position__c> positions){
    	List<Position__c> tmpPositions = new List<Position__c>();//removing the positions that are not part of the application and are not Open
        for(Position__c p : positions){                        	
        	if(p.applications__r.size() > 0){
        		tmpPositions.add(p);
        	}else if(p.position_status__c == 'Open'){
        		tmpPositions.add(p);
        	}
        }
        return tmpPositions;
    }
    
    private List<Position__c> GetAllPositionsUnfiltered(){//selects all positions with applications as child object for the context lead
    	return [SELECT Name, Category__c, number_of_applications__c, base_salary__c, position_status__c, (select application_status__c from applications__r where lead__c =: recLead.Id) FROM Position__c order by number_of_applications__c asc, base_salary__c desc ];
    }
 
    public List<Position__c> GetPositions() {//takes the records from set controller, sets the page size and initializes the map of selected positions
		setCon.setPageSize(pageSize);
		List<Position__c> results = (List<Position__c>) setCon.getRecords();
		for(Position__c pos : results){			
			if(!positionId2Selected.containsKey(pos.Id)){
				positionId2Selected.put(pos.Id, false);
			}
		}
        return results;
    }

	//Paging methods. They do nothing, just calls the build in standard set controller's methods
	public PageReference ShowNext(){
		system.debug(positionId2Selected);
		setCon.Next();
		return null;
	}

	public PageReference ShowPrevious(){
		setCon.Previous();
		return null;
	}

	public PageReference ShowFirst(){
		setCon.First();
		return null;
	}

	public PageReference ShowLast(){
		setCon.Last();
		return null;
	}

	public List<SelectOption> GetCategories()//retrieves all picklist values from Category field
	{
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('-1', '--Any Type--'));
        
	    Schema.DescribeFieldResult fieldResult = Position__c.Category__c.getDescribe();
	    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
	    for( Schema.PicklistEntry f : ple)
	    {
		    options.add(new SelectOption(f.getValue(), f.getLabel()));
	    }       
	    return options;
	}
	
	public List<SelectOption> GetPositionStatuses()//retrieves all picklist values from Position Status field
	{
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('-1', '--Any Type--'));
        
	    Schema.DescribeFieldResult fieldResult = Position__c.Position_status__c.getDescribe();
	    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
	    for( Schema.PicklistEntry f : ple)
	    {
		    options.add(new SelectOption(f.getValue(), f.getLabel()));
	    }       
	    return options;
	}

	public PageReference FilterPositions(){//called upon category or position status picklist change. Resets the standard set controller and creates new for new selected category/position status. 
		system.debug(positionId2Selected);
		setCon = null;
		GetPositions();
		return null;
	}

	public List<CategoryWedgeData> getBarData() {//For selected positions creates List of DTOs. Used as a bind variable for Chart component
		Set<Id> selectedPositionIds = new Set<Id>();
		for(Id positionId : positionId2Selected.keySet()){
			if(positionId2Selected.get(positionId)){
				selectedPositionIds.add(positionId);
			}
		}
        List<CategoryWedgeData> data = new List<CategoryWedgeData>();
		if(selectedPositionIds.size() > 0){//selects number of appereances for every category for selected position
			for(AggregateResult agg : [select count(id) cnt, Category__c from Position__c where id in: selectedPositionIds  group by Category__c]){
				data.add(new CategoryWedgeData((String)agg.get('Category__c'), Integer.valueOf(agg.get('cnt'))));
			}
		}
        return data;
    }
    
    public List<CategoryWedgeData> GetCountOfOpenPositionsPerCategory(){//used for display in the summary section as a table
    	Map<String, Integer> category2Cnt = new Map<String, Integer>();    	
        
	    Schema.DescribeFieldResult fieldResult = Position__c.Category__c.getDescribe();
	    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	        
	    for( Schema.PicklistEntry f : ple){
	       category2Cnt.put(f.getLabel(), 0);
	    }       

    	for(Position__c p : [select Category__c from Position__c where position_status__c = 'open']){
    		category2Cnt.put(p.category__c, category2Cnt.get(p.category__c) + 1);    		
    	}    	
    	List<CategoryWedgeData> dtos = new List<CategoryWedgeData>();
    	for(String catName : category2Cnt.keySet()){
    		dtos.add(new CategoryWedgeData(catName, category2Cnt.get(catName)));
    	}
    	return dtos;
    }	

	private void InitApplicationsData(){//in edit mode initializes map of selected positions. Used in pageblocktable checkbox column
		if(recLead.Id != null){
			for(Application__c app : [select Position__c from Application__c where Lead__c =: recLead.Id]){
				positionId2Selected.put(app.Position__c, true);
			}
		}
	}
    
	public PageReference Save(){// saves lead then deletes existing applications that are not selected and then creates new ones for every selected
		system.debug(positionId2Selected);
		Savepoint sp = Database.setSavepoint();
		try{
			upsert recLead;
			List<Application__c> apps4Delete = new List<Application__c>();
			List<Application__c> apps4Insert = new List<Application__c>();	
			List<Position__c> positions = GetAllPositionsUnfiltered();
            List<Position__c> tmpPositions = RemoveNotOpenNotPartOfApplication(positions);
            positions = tmpPositions;		
			for(Position__c p :  positions){
				system.debug(p.applications__r.size());	
				system.debug(p.id);
				system.debug(p);			
				if(p.applications__r.size() == 0 && positionId2Selected.containsKey(p.Id) && positionId2Selected.get(p.Id)){					
					apps4Insert.add(new Application__c(lead__c = recLead.Id, position__c = p.Id, application_status__c = 'Submitted'));					
				}				
				if(p.applications__r.size() > 0 && !positionId2Selected.get(p.Id)){
					apps4Delete.add(p.applications__r[0]);					
				}
			}
			delete apps4Delete;
			insert apps4Insert;
			
			return new PageReference('/' + recLead.Id);
		}catch(Exception e){
			Database.rollback(sp);
			system.debug(e.GetMessage());
			system.debug(e.GetStackTraceString());
			ApexPages.addMessage(new APexPages.Message(ApexPages.Severity.Error, Label.Unexpected_error));
		}
		return null;
	}
	
	public Boolean GetUserHasPermissions(){//only Recruiter who owns the record can edit it!
		if(this.recLead.Id == null){//if new then has 
			return true;
		}
		//check if current user is of profile Recruiter
		Profile p = [select id from profile where name = 'Recruiter'];
		if(UserInfo.getProfileId() == p.Id){						
			//check if the owner of the lead is same as current user
			if(UserInfo.getUserId() == recLead.ownerId){
				return true;
			}else{
				return false;
			}			
		}
		return true;
	}

    public class CategoryWedgeData {//DTO Class used as data source for Chart
        public String category { get; set; }
        public Integer cnt { get; set; }
        public CategoryWedgeData(String category, Integer cnt) {
            this.category = category;
            this.cnt = cnt;
        }
    }
}