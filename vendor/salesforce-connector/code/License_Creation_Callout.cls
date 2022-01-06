public class License_Creation_Callout {
    @future (callout=true)
    public static void licensecallout(Set<Id> VW_LicenseIds ) {
        VW_License__c[] licenses = [select Name, Channel_ID__c , App_ID__c from VW_License__c where Id = :VW_LicenseIds limit 1];
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.replicated.com/vendor/v3/customer');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('Authorization',AUTHORIZATION_TOKEN);
        // Set the body as a JSON object
        request.setBody('{"app_id":"' + licenses[0].App_ID__c + '","channel_id":"' + licenses[0].Channel_ID__c + '","name":"' + licenses[0].Name + '"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if(response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' + response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
            }
	}
}