"""Application-level CloudWatch metrics for DocHub."""
from __future__ import annotations

import logging
import os
import time
from typing import Callable, TypeVar

import boto3


logger = logging.getLogger(__name__)

T = TypeVar("T")
NAMESPACE = "W7/DocHub"


def timed_call(fn: Callable[[], T]) -> tuple[T, float]:
    started = time.perf_counter()
    result = fn()
    elapsed_ms = (time.perf_counter() - started) * 1000
    return result, elapsed_ms


def _cloudwatch_client():
    region = os.getenv("AWS_REGION") or os.getenv("AWS_DEFAULT_REGION") or "us-west-2"
    return boto3.client("cloudwatch", region_name=region)


def publish_document_upload_metrics(s3_upload_latency_ms: float) -> None:
    """Publish DocHub upload metrics without breaking the upload request."""
    try:
        _cloudwatch_client().put_metric_data(
            Namespace=NAMESPACE,
            MetricData=[
                {
                    "MetricName": "DocumentsUploaded",
                    "Value": 1,
                    "Unit": "Count",
                    "Dimensions": [
                        {"Name": "App", "Value": "DocHub"},
                        {"Name": "Team", "Value": "G1"},
                        {"Name": "Environment", "Value": "hackathon"},
                        {"Name": "Source", "Value": "Lambda"},
                    ],
                },
                {
                    "MetricName": "DocumentUploadToS3LatencyMs",
                    "Value": s3_upload_latency_ms,
                    "Unit": "Milliseconds",
                    "Dimensions": [
                        {"Name": "App", "Value": "DocHub"},
                        {"Name": "Operation", "Value": "UploadDocument"},
                        {"Name": "Storage", "Value": "S3"},
                        {"Name": "Team", "Value": "G1"},
                        {"Name": "Environment", "Value": "hackathon"},
                        {"Name": "Source", "Value": "Lambda"},
                    ],
                },
            ],
        )
    except Exception:
        logger.exception("Failed to publish DocHub custom metrics")
