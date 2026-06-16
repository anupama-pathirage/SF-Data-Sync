import ballerina/log;
import ballerina/sql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerinax/salesforce;

configurable string sfUsername = ?;
configurable string sfPassword = ?;
configurable string dbHost = ?;
configurable int dbPort = ?;
configurable string dbUsername = ?;
configurable string dbPassword = ?;
configurable string dbName = ?;

type LeadRecord record {|
    string name;
    string company;
    boolean isHighPriority;
|};

final postgresql:Client dbClient = check new (
    host = dbHost,
    username = dbUsername,
    password = dbPassword,
    database = dbName,
    port = dbPort
);

listener salesforce:Listener sfListener = new (listenerConfig = {
    auth: {
        username: sfUsername,
        password: sfPassword
    }
});

function mapToLeadRecord(string name, string company, boolean isConverted, string cleanStatus) returns LeadRecord => {
    name: name,
    company: company,
    isHighPriority: !isConverted && cleanStatus == "Pending"
};

service "/data/LeadChangeEvent" on sfListener {

    remote function onCreate(salesforce:EventData payload) returns error? {
        map<json> changedData = payload.changedData;

        string name = (changedData["Name"] ?: "").toString();
        string company = (changedData["Company"] ?: "").toString();
        json isConvertedRaw = changedData["IsConverted"] ?: false;
        boolean isConverted = isConvertedRaw is boolean ? isConvertedRaw : false;
        string cleanStatus = (changedData["CleanStatus"] ?: "").toString();

        LeadRecord leadRecord = mapToLeadRecord(
            name = name,
            company = company,
            isConverted = isConverted,
            cleanStatus = cleanStatus
        );

        sql:ExecutionResult _ = check dbClient->execute(`
            INSERT INTO Leads (Name, Company, isHighPriority)
            VALUES (${leadRecord.name}, ${leadRecord.company}, ${leadRecord.isHighPriority})
        `);

        log:printInfo("Lead synced to database",
            name = leadRecord.name,
            company = leadRecord.company,
            isHighPriority = leadRecord.isHighPriority
        );
    }

    remote function onUpdate(salesforce:EventData payload) returns error? {}

    remote function onDelete(salesforce:EventData payload) returns error? {}

    remote function onRestore(salesforce:EventData payload) returns error? {}
}
