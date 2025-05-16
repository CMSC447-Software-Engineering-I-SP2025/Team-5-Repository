#!/usr/bin/env python3
from datetime import datetime
from elasticsearch import Elasticsearch, helpers
import json
import logging
import sys
import zipfile
import glob, os
from dotenv import load_dotenv
from pathlib import Path
from langchain_community.document_loaders import JSONLoader
from langchain_elasticsearch import ElasticsearchStore
from langchain_ollama import OllamaEmbeddings
from langchain_core.documents import Document
import tempfile
# ──────────────────────────────────────────────────────────────────────────────
# CONFIGURATION
# ──────────────────────────────────────────────────────────────────────────────

ES_HOST = os.getenv('ELASTICSEARCH_URL') #"http://localhost:9200"     # your Elasticsearch endpoint
ES_INDEX = "movies-index"                 # target index name
BULK_CHUNK_SIZE = 500                 # number of docs per bulk request

# ──────────────────────────────────────────────────────────────────────────────
# LOGGER SETUP
# ──────────────────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("bulk-indexer")

# ──────────────────────────────────────────────────────────────────────────────
# BULK INDEXING FUNCTION
# ──────────────────────────────────────────────────────────────────────────────

def bulk_index(docs, es: Elasticsearch, index: str, chunk_size: int = BULK_CHUNK_SIZE):
    """
    Indexes a list of Python dicts `docs` into Elasticsearch `index` using bulk API.
    Each doc must have an 'id' field if you want deterministic IDs, otherwise ES will auto-generate.
    """
    actions = []
    for doc in docs:
        # Prepare the action for each document
        action = {
            "_index": index,
            # Optional: specify your own document _id
            # "_id": doc.get("id", None),
            "_source": doc
        }
        actions.append(action)

    # helpers.bulk will chunk the actions automatically
    success, failures = helpers.bulk(es, actions, chunk_size=chunk_size, stats_only=False)
    logger.info(f"Bulk insert completed: {success} success, {len(failures)} failures")
    if failures:
        logger.error(f"Failures: {failures}")


def loadsearch():
    # 1) Connect to Elasticsearch
    es = Elasticsearch([ES_HOST],verify_certs=False)
    if not es.ping():
        logger.error(f"Cannot connect to Elasticsearch at {ES_HOST}")
        sys.exit(1)
    logger.info(f"Connected to Elasticsearch at {ES_HOST}")

    # 2) Prepare your list of docs
    #    In real use, replace this with loading from a file, database, etc.
    # load zipfile
    archive = zipfile.ZipFile('movie_dump.zip','r')
    # pull db dump from zip
    dump = archive.open('movie_dump.json')
    # parse json
    parsed_data = json.load(dump)
    docs = [parsed_data[x] for x in parsed_data]

    # 3) Ensure the index exists (optional; ES can auto-create on first insert)
    if not es.indices.exists(index=ES_INDEX):
        es.indices.create(index=ES_INDEX)
        logger.info(f"Created index '{ES_INDEX}'")

    # 4) Perform the bulk index
    bulk_index(docs, es, ES_INDEX)
    loadrag(parsed_data)

def loadrag(parsed_data):
    index_name="rag-langchain"
    documents = []
    for doc_id, doc_content in parsed_data.items():
        text = doc_content.get("title","") + " " + doc_content.get("overview","") + " " + doc_content.get("tagline","")
        metadata = doc_content
        documents.append(Document(page_content=text, metadata=doc_content))
    

        #ollama_url = "http://localhost:11434"
    # Embeddings
    embeddings = OllamaEmbeddings(
        model="llama3.2:3b",
#        ollama_api_url=os.getenv('OLLAMA_API_URL')
    )
    logger.info(f"Loading {len(documents)} into vector db...")
    for i in range(0, len(documents), 100): 
        logger.info(f"Loading {i}:{i+100}")
        vector_db  = ElasticsearchStore.from_documents(
            documents[i:i+100],
            embedding=embeddings,
            es_url=ES_HOST,
            index_name=index_name
        )
#    # Check if the index already exists
#    res = vector_db.client.indices.exists(index=index_name)
#    if res.body:
#        print(f"The index {index_name} already exists in Elasticseach")
#        exit(1)
#
#    vector_db.from_documents(
#        documents=load_dicts_to_jsonloader(docs),
#        embedding=embeddings,
#        es_connection=vector_db.client,
#        index_name=index_name
#    )
    
if __name__ == "__main__":
    loadsearch()
