trigger LeadTrigger on Lead (before update) {
    (new LeadHandler()).Handle();
}