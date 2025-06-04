trigger SendLeadToCleverTap on Lead (after insert, after update) {
    if (TestUtils.bypassTriggers) {
        return;
    }

    if (System.isBatch() || System.isFuture() || System.isQueueable()) {
        return;
    }

    List<Lead> leadsToProcess = new List<Lead>();

    if (Trigger.isInsert) {
        leadsToProcess = Trigger.new;
    } else if (Trigger.isUpdate) {
        for (Lead lead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(lead.Id);

            if (
                lead.FirstName != oldLead.FirstName ||
                lead.LastName != oldLead.LastName ||
                lead.Salutation != oldLead.Salutation ||
                lead.Name != oldLead.Name ||
                lead.Phone != oldLead.Phone ||
                lead.MobilePhone != oldLead.MobilePhone ||
                lead.Fax != oldLead.Fax ||
                lead.Title != oldLead.Title ||
                lead.Email != oldLead.Email ||
                lead.Company != oldLead.Company ||
                lead.Website != oldLead.Website ||
                lead.Industry != oldLead.Industry ||
                lead.Status != oldLead.Status ||
                lead.AnnualRevenue != oldLead.AnnualRevenue ||
                lead.Rating != oldLead.Rating ||
                lead.NumberOfEmployees != oldLead.NumberOfEmployees ||
                lead.OwnerId != oldLead.OwnerId ||
                lead.LeadSource != oldLead.LeadSource ||
                lead.Street != oldLead.Street ||
                lead.City != oldLead.City ||
                lead.PostalCode != oldLead.PostalCode ||
                lead.State != oldLead.State ||
                lead.Country != oldLead.Country ||
                lead.Description != oldLead.Description
            ) {
                leadsToProcess.add(lead);
            }
        }
    }

    if (!leadsToProcess.isEmpty()) {
        DIModule diModule = new DIModuleMain();
        IntegrationHandler handler = diModule.provideIntegrationHandler();
        handler.processLeads(Trigger.new);
    }
}
