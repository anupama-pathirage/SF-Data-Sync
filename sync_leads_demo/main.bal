import ballerina/log;
import ballerina/sql;
import ballerinax/postgresql;
import ballerinax/salesforce;
import ballerinax/postgresql.driver as _;

configurable string sfUsername = ?;
configurable string sfPassword = ?;

configurable string dbHost = "localhost";
configurable int dbPort = 5432;
configurable string dbUsername = ?;
configurable string dbPassword = ?;
configurable string dbName = ?;

type SfLeadPayload record {
    string Name = "";
    string Company = "";
    string IsConverted = "false";
    string CleanStatus = "";
};

type LeadRecord record {
    string name;
    string company;
    boolean isHighPriority;
};

function mapToLeadRecord(SfLeadPayload sfLead) returns LeadRecord => {
    name: sfLead.Name,
    company: sfLead.Company,
    isHighPriority: sfLead.IsConverted =="false" && sfLead.CleanStatus == "Pending"
};

final postgresql:Client dbClient = check new (
    host = dbHost,
    username = dbUsername,
    password = dbPassword,
    database = dbName,
    port = dbPort
);

function init() returns error? {
   _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS sfleads (
            Name VARCHAR(255),
            Company VARCHAR(255),
            isHighPriority BOOLEAN
        )
    `);
    log:printInfo("sfleads table ready");
}

listener salesforce:Listener sfListener = new ({
    auth: {
        username: sfUsername,
        password: sfPassword
    }
});

service salesforce:CdcService "/data/LeadChangeEvent" on sfListener {

    remote function onCreate(salesforce:EventData payload) {
        SfLeadPayload|error sfLead = payload.changedData.cloneWithType(SfLeadPayload);
        if sfLead is error {
            log:printError("Failed to parse lead payload", sfLead);
            return;
        }
        LeadRecord leadRecord = mapToLeadRecord(sfLead);
        sql:ExecutionResult|sql:Error result = dbClient->execute(`INSERT INTO sfleads (Name, Company, isHighPriority)
            VALUES (${leadRecord.name}, ${leadRecord.company}, ${leadRecord.isHighPriority})
        `);
        if result is sql:Error {
            log:printError(string `Failed to insert lead: ${leadRecord.name}`, result);
            return;
        }
        log:printInfo(string `Synced lead: ${leadRecord.name}`);
    }

    remote function onUpdate(salesforce:EventData payload) returns error? {}

    remote function onDelete(salesforce:EventData payload) returns error? {}

    remote function onRestore(salesforce:EventData payload) returns error? {}
}
