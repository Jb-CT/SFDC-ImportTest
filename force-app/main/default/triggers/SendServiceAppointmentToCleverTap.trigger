trigger SendServiceAppointmentToCleverTap on ServiceAppointment (after insert, after update) {
    DIModule diModule = new DIModuleMain();
    IntegrationHandler handler = diModule.provideIntegrationHandler();
    handler.processServiceAppointments(Trigger.new);
}