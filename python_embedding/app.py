from flask import Flask, request, jsonify
import numpy as np
from transformers import GPT2TokenizerFast
import torch
import os
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Global variables for model and tokenizer
tokenizer = None
dimension = 1536  # text-embedding-ada-002 dimension size

# Initialize tokenizer
def load_tokenizer():
    global tokenizer
    logger.info("Loading tokenizer...")
    try:
        tokenizer = GPT2TokenizerFast.from_pretrained('Xenova/text-embedding-ada-002')
        logger.info("Tokenizer loaded successfully")
    except Exception as e:
        logger.error(f"Error loading tokenizer: {e}")
        raise

# Generate a simple embedding using token IDs as features
def generate_embedding(text):
    if not text:
        return np.zeros(dimension, dtype=np.float32)
    
    # Tokenize the text
    token_ids = tokenizer.encode(text, truncation=True, max_length=8191)
    
    # Generate simple embedding by normalizing token IDs
    # Note: In a production environment, you would use a real embedding model
    # This is a simplistic approach that maps token IDs to a feature space
    feat_vec = np.zeros(dimension, dtype=np.float32)
    
    # Map tokens to the embedding space
    for i, token_id in enumerate(token_ids):
        # Distribute token information across the vector
        # Using modulo to wrap around the dimension
        pos = i % dimension
        feat_vec[pos] += np.float32(token_id) / 50000.0  # Normalize by vocab size
    
    # L2 normalize the vector
    norm = np.linalg.norm(feat_vec)
    if norm > 0:
        feat_vec = feat_vec / norm
    
    return feat_vec

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

# Load tokenizer on startup
load_tokenizer()

# If running directly, not through gunicorn
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 6000))
    app.run(host='0.0.0.0', port=port, debug=False) 