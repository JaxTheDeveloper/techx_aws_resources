# MH5 - GROUP 1:

## Serverless Scaling Pattern — Handle Load Correctly


### FIRST OF ALL

Why choose Async Invocation + Dead Letter Queue?
- Lambda runs on a schedule and scans for price anomalies. If it crashes mid-run -> we don't want to lose the data we've already processed. With async invocation and dead letter queue, we can ensure that our data is not lost even if the function crashes. Lambda will automatically retry the failed invocations and send the failed events to the dead letter queue so that we can investigate and fix the issue. This is better than synchronous invocation because it allows the function to continue processing other events while waiting for the failed ones to be retried.


---

## Evidence

### 1. Lambda Configuration — Async Invocation + DLQ

`AnomalyLoggingService` is configured with **Retry attempts: 2** and **Dead-letter queue: AnomalyLoggingService_DLQ**. This means on failure, Lambda retries 2 more times (3 total) before sending the event to SQS.

![Lambda async invocation config](~/Pictures/Screenshots/Screenshot%20from%202026-05-15%2011-49-42.png)

---

### 2. Failed Invocation Result (Test tab)

A manual test invocation from the Lambda console shows **"Executing function: failed"** with `OperationalError: unable to open database file`. This is the intentional failure used to demonstrate the retry + DLQ pattern.

![Failed invocation detail](~/Pictures/Screenshots/Screenshot%20from%202026-05-15%2011-44-39.png)

---

### 3. CloudWatch Logs — 3 Retry Attempts

CloudWatch shows **3 separate START/END/REPORT entries** for the same `RequestId: a0dad215-dc0c-4917-a341-c3ff9af16da7`, each with `Status: error`. This confirms Lambda attempted the invocation 3 times (original + 2 retries) before giving up.

![CloudWatch 3 retry attempts - overview](~/Pictures/Screenshots/Screenshot%20from%202026-05-15%2011-41-21.png)

![CloudWatch 3 retry attempts - detail](~/Pictures/Screenshots/Screenshot%20from%202026-05-15%2011-42-52.png)

---

### 4. Failed Event in DLQ

After all 3 attempts failed, the original event was automatically sent to `AnomalyLoggingService_DLQ`. The message body contains the original EventBridge scheduled event payload, confirming nothing was silently lost.

![DLQ message list](~/Pictures/Screenshots/Screenshot%20from%202026-05-15%2011-44-14.png)

![DLQ message body](~/Pictures/Screenshots/Screenshot%20from%202026-05-15%2011-48-10.png)
