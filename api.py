# api.py
# Save this file in the root of the cloned 'pyky' repository.

from flask import Flask, jsonify, request
import base64
from Crypto.Random import get_random_bytes

# import encrypt, decrypt and constants from local modules
from cpake import encrypt, decrypt
from params import KYBER_SYM_BYTES

# This assumes the script is placed in the root of the cloned pyky repository.
# The main key generation function is kem_keygen512 from ccakem.py.
try:
    from ccakem import kem_keygen512
except ImportError as e:
    # Provide a helpful error message if the module isn't found.
    print(f"A critical import failed: {e}")
    raise ImportError("Could not import kem_keygen512 from ccakem.py. Make sure this script is running from the root of the 'pyky' repository and all dependencies are installed.")

# Initialize the Flask application
app = Flask(__name__)

@app.route('/generate_keys', methods=['GET'])
def generate_keys():
    """
    API endpoint to generate Kyber512 public and secret keys.
    When a request is received, it generates a new key pair and returns it
    as a JSON object.
    """
    try:
        # 1. Generate the key pair by calling the KEM key generation function.
        # The function returns (secret_key, public_key) as lists of integers.
        sk, pk = kem_keygen512()

        # 2. Encode the keys into Base64 strings to safely transport them via JSON.
        # The lists can contain numbers outside the 0-255 range for a byte.
        # We use the modulo operator (%) to wrap each number into the valid range.
        public_key_bytes = bytearray([x % 256 for x in pk])
        secret_key_bytes = bytearray([x % 256 for x in sk])
        
        public_key_b64 = base64.b64encode(public_key_bytes).decode('utf-8')
        secret_key_b64 = base64.b64encode(secret_key_bytes).decode('utf-8')

        # 3. Prepare the JSON response
        response_data = {
            'status': 'success',
            'public_key': public_key_b64,
            'secret_key': secret_key_b64
        }
        return jsonify(response_data), 200

    except Exception as e:
        # Basic error handling for any unexpected issues during key generation.
        error_response = {
            'status': 'error',
            'message': str(e)
        }
        return jsonify(error_response), 500


@app.route('/encapsulate', methods=['POST'])
def encapsulate():
    """
    Accepts JSON with:
      - 'aes_key': base64-encoded AES session key (expected length = KYBER_SYM_BYTES)
      - 'recipient_pk': base64-encoded Kyber public key bytes
      - optional 'kyber_mode': one of 512, 768, 1024 (default 512)

    Returns JSON with base64-encoded Kyber ciphertext under 'ciphertext'.
    """
    try:
        data = request.get_json(force=True)
        if data is None:
            return jsonify({'status': 'error', 'message': 'Missing JSON payload'}), 400

        aes_b64 = data.get('aes_key') or data.get('aesKey')
        pk_b64 = data.get('recipient_pk') or data.get('recipientPk') or data.get('public_key')
        mode = int(data.get('kyber_mode', 512))

        if not aes_b64 or not pk_b64:
            return jsonify({'status': 'error', 'message': 'Both aes_key and recipient_pk are required'}), 400

        try:
            aes_key = base64.b64decode(aes_b64)
            recipient_pk = base64.b64decode(pk_b64)
        except Exception:
            return jsonify({'status': 'error', 'message': 'Invalid base64 encoding'}), 400

        # Enforce AES key size to match Kyber symmetric size (common case: AES-256 -> 32 bytes)
        if len(aes_key) != KYBER_SYM_BYTES:
            return jsonify({'status': 'error', 'message': f'Invalid aes_key length; expected {KYBER_SYM_BYTES} bytes'}), 400

        # map mode to params_k used by cpake.encrypt
        if mode == 512:
            params_k = 2
        elif mode == 768:
            params_k = 3
        elif mode == 1024:
            params_k = 4
        else:
            return jsonify({'status': 'error', 'message': 'Unsupported kyber_mode; choose 512, 768, or 1024'}), 400

        # coins/randomness used by Kyber
        coins = get_random_bytes(KYBER_SYM_BYTES)

        # cpake.encrypt expects message (m) as a bytes/bytearray and pubkey as bytes
        ciphertext = encrypt(list(aes_key), list(recipient_pk), list(coins), params_k)

        # encrypt returns a byte array (list of ints) per cpake implementation; encode to base64
        ciphertext_bytes = bytearray([x & 0xFF for x in ciphertext])
        ciphertext_b64 = base64.b64encode(ciphertext_bytes).decode('utf-8')

        return jsonify({'status': 'success', 'ciphertext': ciphertext_b64}), 200

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/decapsulate', methods=['POST'])
def decapsulate():
    """
    Accepts JSON with:
      - 'ciphertext': base64-encoded Kyber ciphertext
      - 'private_key': base64-encoded Kyber private key bytes
      - optional 'kyber_mode': one of 512, 768, 1024 (default 512)

    Returns JSON with base64-encoded decapsulated AES session key under 'aes_key'.
    """
    try:
        data = request.get_json(force=True)
        if data is None:
            return jsonify({'status': 'error', 'message': 'Missing JSON payload'}), 400

        ciphertext_b64 = data.get('ciphertext')
        sk_b64 = data.get('private_key')
        mode = int(data.get('kyber_mode', 512))

        if not ciphertext_b64 or not sk_b64:
            return jsonify({'status': 'error', 'message': 'Both ciphertext and private_key are required'}), 400

        try:
            ciphertext = base64.b64decode(ciphertext_b64)
            private_key = base64.b64decode(sk_b64)
        except Exception:
            return jsonify({'status': 'error', 'message': 'Invalid base64 encoding'}), 400

        # map mode to params_k used by cpake.decrypt
        if mode == 512:
            params_k = 2
        elif mode == 768:
            params_k = 3
        elif mode == 1024:
            params_k = 4
        else:
            return jsonify({'status': 'error', 'message': 'Unsupported kyber_mode; choose 512, 768, or 1024'}), 400

        # decrypt returns a byte array (list of ints); convert to bytes and encode as base64
        decrypted_key = decrypt(list(ciphertext), list(private_key), params_k)
        decrypted_bytes = bytearray([x & 0xFF for x in decrypted_key])
        aes_key_b64 = base64.b64encode(decrypted_bytes).decode('utf-8')

        return jsonify({'status': 'success', 'aes_key': aes_key_b64}), 200

    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    # Run the app.
    # host='0.0.0.0' makes the server accessible from your local network,
    # which is necessary for the Flutter app running on an emulator or physical device.
    # debug=True provides helpful error messages in the browser if something goes wrong.
    app.run(host='0.0.0.0', port=5000, debug=True)
