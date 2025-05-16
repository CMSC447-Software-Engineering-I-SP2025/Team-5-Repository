import os
from dotenv import load_dotenv
from pathlib import Path

from langchain_elasticsearch import ElasticsearchStore
from langchain_ollama import OllamaEmbeddings
from langchain_ollama import ChatOllama
from langchain_core.prompts import PromptTemplate
from langchain_core.documents import Document
from langgraph.graph import START, StateGraph
from typing_extensions import List, TypedDict

# Disable LangChain tracing
#os.environ["LANGCHAIN_TRACING_V2"] = "false"

    
index_name="rag-langchain"

# Embeddings
embeddings = OllamaEmbeddings(
    model="llama3.2:3b",
)

vector_db  = ElasticsearchStore(
    es_url=os.getenv('ELASTICSEARCH_URL') ,
    embedding=embeddings,
    index_name=index_name
)

# LLM
llm = ChatOllama(model="llama3.2:3b", temperature=0.0000000001)

# Define prompt for RAG
prompt_template = PromptTemplate.from_template(
    template="Given the following context: {context}, answer to the following question: {question}."
)

# Define state for application
class State(TypedDict):
    question: str
    context: List[Document]
    answer: str

# Define application steps
def retrieve(state: State):
    retrieved_docs = vector_db.similarity_search(state["question"], k=8)
    return {"context": retrieved_docs}


def generate(state: State):
    docs_content = "\n\n".join(doc.page_content for doc in state["context"])
    prompt = prompt_template.format(question=state["question"], context=docs_content) 
    response = llm.invoke(prompt)
    return {"answer": response.content}


# Compile application and test
graph_builder = StateGraph(State).add_sequence([retrieve, generate])
graph_builder.add_edge(START, "retrieve")
graph = graph_builder.compile()

question = "Give me a list of 10 movie titles for movies most similar to Star Wars: Empire Strikes Back.  Format the list as just an array of title strings"
print(question)
response = graph.invoke({"question": question})
print(response["answer"])