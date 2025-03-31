from flask import Flask, request, jsonify
import numpy as np
from transformers import GPT2TokenizerFast
import torch
import os
import logging
from sentence_transformers import SentenceTransformer

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global variables for model and tokenizer
model = None
dimension = 1536  # text-embedding-ada-002 dimension size

# Initialize model
def load_model():
    global model
    logger.info("Loading sentence transformer model...")
    try:
        model = SentenceTransformer('all-MiniLM-L6-v2')
        logger.info("Model loaded successfully")
    except Exception as e:
        logger.error(f"Error loading model: {e}")
        raise

# Generate embedding using sentence transformer
def generate_embedding(text):
    if not text:
        return np.zeros(dimension, dtype=np.float32)
    
    # Generate embedding using the model
    embedding = model.encode(text, convert_to_numpy=True)
    
    # Ensure the embedding is the correct dimension
    if embedding.shape[0] != dimension:
        logger.warning(f"Embedding dimension mismatch. Expected {dimension}, got {embedding.shape[0]}")
        # Pad or truncate if necessary
        if embedding.shape[0] < dimension:
            embedding = np.pad(embedding, (0, dimension - embedding.shape[0]))
        else:
            embedding = embedding[:dimension]
    
    return embedding.astype(np.float32)

@app.route('/embed', methods=['POST'])
def embed():
    try:
        data = request.json
        if not data or 'text' not in data:
            return jsonify({'error': 'No text provided'}), 400
        
        text = data['text']
        logger.info(f"Generating embedding for text of length: {len(text)}")
        
        # Generate embedding
        embedding = generate_embedding(text)
        
        # Convert to list for JSON serialization
        embedding_list = embedding.tolist()
        
        return jsonify({'embedding': embedding_list})
    
    except Exception as e:
        logger.error(f"Error in embed endpoint: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

# Load model on startup
load_model()

# If running directly, not through gunicorn
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 6000))
    app.run(host='0.0.0.0', port=port, debug=False) 