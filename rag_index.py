#!/usr/bin/env python3
"""
rag_index.py — Embeds MovieApp Swift source files into Pinecone.

What this does (in plain terms):
1. Finds all .swift source files in your project (skips test files and build artifacts)
2. Reads each file's content
3. Converts the text into a list of numbers (an "embedding") that captures
   the meaning of the code — similar code gets similar numbers
4. Uploads those embeddings to Pinecone so we can search them later

Usage:
    export PINECONE_API_KEY="your-key-here"
    python3 rag_index.py --project-dir "."

Run this once to set up the index, and again whenever your source code changes.
"""

import argparse
import os
import sys
from pathlib import Path

try:
    from sentence_transformers import SentenceTransformer
except ImportError:
    print("ERROR: Install sentence-transformers: pip install sentence-transformers")
    sys.exit(1)

try:
    from pinecone import Pinecone, ServerlessSpec
except ImportError:
    print("ERROR: Install pinecone: pip install pinecone")
    sys.exit(1)


# ──────────────────────────────────────────────
# Configuration
# ──────────────────────────────────────────────
INDEX_NAME = "movieapp-code"
EMBEDDING_MODEL = "all-MiniLM-L6-v2"  # 384 dimensions, runs locally, free
EMBEDDING_DIMENSION = 384

# Directories and files to skip when scanning for source code
SKIP_DIRS = {
    ".build", "build", "DerivedData", ".git", "Pods",
    "Movie Recommendation AppTests",
    "Movie Recommendation AppUITests",
    ".github", "hitl_logs", "__pycache__", "venv",
}
SKIP_FILES = {"Package.resolved", ".DS_Store"}


def find_swift_files(project_dir: str) -> list[Path]:
    """
    Walk the project directory and collect all .swift source files.
    Skips test files, build artifacts, and hidden directories.
    """
    swift_files = []
    root = Path(project_dir)

    for path in sorted(root.rglob("*.swift")):
        if any(skip in path.parts for skip in SKIP_DIRS):
            continue
        if path.name in SKIP_FILES:
            continue
        swift_files.append(path)

    return swift_files


def create_chunks(swift_files: list[Path], project_dir: str) -> list[dict]:
    """
    Each Swift file becomes one chunk. A chunk has:
    - an ID (the file path, sanitized)
    - the file content (what gets converted to an embedding)
    - metadata (file name, path, size — stored alongside the embedding)
    """
    chunks = []
    root = Path(project_dir)

    for filepath in swift_files:
        content = filepath.read_text(errors="replace")
        relative_path = str(filepath.relative_to(root))

        chunks.append({
            "id": relative_path.replace("/", "_").replace(" ", "-"),
            "content": content,
            "metadata": {
                "filename": filepath.name,
                "path": relative_path,
                "lines": content.count("\n") + 1,
                "chars": len(content),
            },
        })

    return chunks


def setup_pinecone_index(api_key: str):
    """
    Connect to Pinecone and create the index if it doesn't exist.
    An index is like a database table — it holds all your embeddings.
    """
    pc = Pinecone(api_key=api_key)

    existing_indexes = [idx.name for idx in pc.list_indexes()]

    if INDEX_NAME not in existing_indexes:
        print(f"Creating Pinecone index '{INDEX_NAME}'...")
        pc.create_index(
            name=INDEX_NAME,
            dimension=EMBEDDING_DIMENSION,
            metric="cosine",
            spec=ServerlessSpec(cloud="aws", region="us-east-1"),
        )
        print("Index created.")
    else:
        print(f"Index '{INDEX_NAME}' already exists.")

    return pc.Index(INDEX_NAME)


def main():
    parser = argparse.ArgumentParser(description="Index MovieApp source code into Pinecone")
    parser.add_argument(
        "--project-dir",
        default=".",
        help="Path to the MovieApp project root (default: current directory)",
    )
    args = parser.parse_args()

    pinecone_key = os.environ.get("PINECONE_API_KEY")
    if not pinecone_key:
        print("ERROR: Set PINECONE_API_KEY environment variable.")
        sys.exit(1)

    # Step 1: Find Swift source files
    print(f"\nScanning for Swift files in: {args.project_dir}")
    swift_files = find_swift_files(args.project_dir)
    if not swift_files:
        print("ERROR: No Swift files found. Check --project-dir path.")
        sys.exit(1)

    print(f"Found {len(swift_files)} Swift files:")
    for f in swift_files:
        print(f"  {f}")

    # Step 2: Create chunks (one per file)
    chunks = create_chunks(swift_files, args.project_dir)
    print(f"\nCreated {len(chunks)} chunks.")

    # Step 3: Generate embeddings locally
    # Downloads the model (~80MB) on first run, then caches it
    print(f"\nLoading embedding model '{EMBEDDING_MODEL}'...")
    model = SentenceTransformer(EMBEDDING_MODEL)

    print("Generating embeddings...")
    texts = [chunk["content"] for chunk in chunks]
    embeddings = model.encode(texts, show_progress_bar=True)
    print(f"Generated {len(embeddings)} embeddings (dimension={embeddings[0].shape[0]}).")

    # Step 4: Upload to Pinecone
    print(f"\nConnecting to Pinecone...")
    index = setup_pinecone_index(pinecone_key)

    vectors = []
    for chunk, embedding in zip(chunks, embeddings):
        metadata = chunk["metadata"].copy()
        # Store actual source code in metadata so retrieval returns it directly.
        # Pinecone metadata limit is 40KB per vector — fine for individual files.
        metadata["source_code"] = chunk["content"][:39000]

        vectors.append({
            "id": chunk["id"],
            "values": embedding.tolist(),
            "metadata": metadata,
        })

    index.upsert(vectors=vectors)
    print(f"Uploaded {len(vectors)} vectors to Pinecone index '{INDEX_NAME}'.")

    print("\n── Done ──")
    print(f"Index:     {INDEX_NAME}")
    print(f"Vectors:   {len(vectors)}")
    print(f"Dimension: {EMBEDDING_DIMENSION}")


if __name__ == "__main__":
    main()
