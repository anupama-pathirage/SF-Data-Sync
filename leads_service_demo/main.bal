import ballerina/http;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;

configurable string dbHost = ?;
configurable int dbPort = ?;
configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbName = ?;

type Lead record {|
    string Name;
    string Company;
    boolean isHighPriority;
|};

final postgresql:Client dbClient = check new (
    host = dbHost,
    username = dbUser,
    password = dbPassword,
    database = dbName,
    port = dbPort
);

service /sf on new http:Listener(9090) {

    resource function get leads() returns Lead[]|error {
        stream<Lead, error?> resultStream = dbClient->query(
            `SELECT Name, Company, isHighPriority FROM Leads`
        );

        Lead[] leads = [];

        check from Lead lead in resultStream
            do {
                leads.push(lead);
            };

        check resultStream.close();

        return leads;
    }

}
