import boto3
from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth

region = 'us-west-2'
service = 'aoss'

credentials = boto3.Session().get_credentials()
auth = AWSV4SignerAuth(credentials, region, service)

host = '0zdunobonc6vwtyzfbpj.us-west-2.aoss.amazonaws.com'

client = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=auth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection,
)

index_name = "dochub-vectors"

index_body = {
    "settings": {"index.knn": True},
    "mappings": {
        "properties": {
            "embedding": {
                "type": "knn_vector",
                "dimension": 1024,
                "method": {
                    "name": "hnsw",
                    "engine": "faiss",
                    "space_type": "l2"
                }
            },
            "text": {"type": "text"},
            "metadata": {"type": "text", "index": False}
        }
    }
}

response = client.indices.create(index=index_name, body=index_body)
print(response)
