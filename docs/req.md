# SyncLeadsDemo — Project Description

## Overview
A **Ballerina** integration named `sync_leads` that listens for new Lead creation events in **Salesforce** and automatically syncs the lead data into a PostgreSQL DB.

## What the Integration Does
1. When a new Lead is **created** in Salesforce the Salesforce listener will be triggered. Use `ballerinax/salesforce` listner.
2. The integration extracts the relevant fields from the event payload (`Name`, `Company`, `IsConverted`, `CleanStatus`).
3. Add the `Name`, `Company`, `isHighPriority` fields to the Database table named `sfleads` as a new Row. Add a mapping function to generate the output data leaving the room for future expansion in fields.
- A lead is marked **high priority** (`true`) when **both** conditions hold:
 - `IsConverted` equals `"false"` — the lead has **not** yet been converted to an opportunity/contact
 - `CleanStatus` equals `"Pending"` — the lead data has not been cleaned/verified yet
 - Otherwise, `isHighPriority` is `false`.
- DB Fields are Name VARCHAR(255),Company VARCHAR(255), isHighPriority BOOLEAN. Create the DB table `sfleads` if not exists and then generate insert query accordingly and generate data.



