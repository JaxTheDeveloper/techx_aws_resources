"""EventBridge-triggered Lambda — fires Bedrock KB sync on S3 upload.

Trigger: S3 Event Notification → EventBridge (detail-type: Object Created)
Skips .metadata.json sidecar files to avoid double-syncs.
"""
import os

import boto3

KB_ID = os.environ["KB_ID"]
DATA_SOURCE_ID = os.environ["DATA_SOURCE_ID"]


def lambda_handler(event, context):
    obj_key = (
        event.get("detail", {})
        .get("object", {})
        .get("key", "")
    )
    if obj_key.endswith(".metadata.json"):
        return

    boto3.client("bedrock-agent").start_ingestion_job(
        knowledgeBaseId=KB_ID,
        dataSourceId=DATA_SOURCE_ID,
    )
