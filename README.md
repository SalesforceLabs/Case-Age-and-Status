# Case-Age-and-Status

Many a times, organizations need to know exactly where cases sit in different statuses and after accounting for business hours. There is no out-of-the-box way of doing that today. This does that very elegantly. It calculates in business hours how long your case has spent in each status. This allows you to generate reports and dashboards and identify areas of concern.

The package essentially consists of the following three elements:

1. “Case Status Change” custom object (and associated fields) to record all the changes to all cases. Essentially a record is written here every time a case changes status.

2.“CaseStatusChangeTrigger” and associated Apex classes – This trigger fires every time a case changes status and inserts the record in the “Case Status Change” custom object. 3.“Case Age in Business Hours” Dashboard (with the underlying reports (starting with CABH). This gives some interesting insights on your cases, status’ and agents. Drill and change the dashboard and the underlying reports to suit your needs.

This app is part of the Force™ Collection.
You can see it here: https://sforce.co/33fkLT7

You can install the published version of this package via the AppExchange listing: https://appexchange.salesforce.com/listingDetail?listingId=a0N3A00000E1hf7&tab=d

