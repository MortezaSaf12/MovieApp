#!/usr/bin/env python3
"""
rag_retrieve.py — Retrieves relevant MovieApp source code from Pinecone.

What this does (in plain terms):
1. Takes your query (e.g., "fetchRecommendations genre filtering")
2. Converts it into the same kind of embedding used during indexing
3. Asks Pinecone: "which code files have the most similar embeddings?"
4. Returns the actual source code of the top matches

Usage (standalone test):
    export PINECONE_API_KEY="your-key-here"
    python3 rag_retrieve.py --query "fetchRecommendations" --top-k 5

Also importable as a module (used by generate_tests.py in step 4):
    from rag_retrieve import retrieve_context
    context = retrieve_context("fetchRecommendations", top_k=5)
"""

import argparse
import os
import sys

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("ERROR: Install sentence-transformers: pip install sentence-transformers")
    sys.exit(1)

try:
    from pinecone import Pinecone
except ImportError:
    print("ERROR: Install pinecone: pip install pinecone")
    sys.exit(1)


INDEX_NAME = "movieapp-code"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"

# Cache the model so it's only loaded once when used as a module
_model = None


def _get_model() -> SentenceTransformer:
    global _model
    if _model is None:
        _model = SentenceTransformer(EMBEDDING_MODEL)
    return _model


def retrieve_context(query: str, top_k: int = 5, api_key: str | None = None) -> str:
    """
    Given a natural-language query, return the most relevant source code
    from the Pinecone index as a single formatted string.

    Args:
        query:   What you're looking for (e.g., "fetchRecommendations")
        top_k:   How many files to retrieve (default 5)
        api_key: Pinecone API key (falls back to PINECONE_API_KEY env var)

    Returns:
        A string containing the retrieved source files, each labeled with
        its file path and similarity score. Ready to paste into a prompt.
    """
    api_key = api_key or os.environ.get("PINECONE_API_KEY")
    if not api_key:
        raise ValueError("PINECONE_API_KEY not set.")

    # Convert query text into an embedding (same model used for indexing)
    model = _get_model()
    query_embedding = model.encode(query).tolist()

    # Ask Pinecone for the closest matches
    pc = Pinecone(api_key=api_key)
    index = pc.Index(INDEX_NAME)

    results = index.query(
        vector=query_embedding,
        top_k=top_k,
        include_metadata=True,
    )

    if not results.matches:
        return "No relevant source files found."

    # Format results into a string that Claude can use as context
    context_parts = []
    for match in results.matches:
        meta = match.metadata
        score = match.score  # Cosine similarity: 1.0 = perfect match
        filepath = meta.get("path", "unknown")
        source = meta.get("source_code", "")

        context_parts.append(
            f"// ── {filepath} (relevance: {score:.3f}) ──\n{source}"
        )

    return "\n\n".join(context_parts)


def main():
    parser = argparse.ArgumentParser(description="Retrieve relevant source code from Pinecone")
    parser.add_argument("--query", required=True, help="What feature/code to search for")
    parser.add_argument("--top-k", type=int, default=5, help="Number of files to retrieve")
    args = parser.parse_args()

    print(f"Searching for: \"{args.query}\" (top {args.top_k} results)\n")

    context = retrieve_context(args.query, args.top_k)
    print(context)


if __name__ == "__main__":
    main()
