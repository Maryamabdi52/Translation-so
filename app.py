# import os
# from flask import Flask, request, jsonify
# from flask_cors import CORS
# from transformers import MarianTokenizer, TFMarianMTModel
# from pymongo import MongoClient
# from datetime import datetime
# from dotenv import load_dotenv
# from datetime import datetime
# import pytz
# from flask_bcrypt import Bcrypt
# import jwt
# from routes.auth_routes import auth_routes 
# from routes.user_routes import user_routes
# from routes.favorites_routes import favorites_routes
# from routes.history_routes import history_routes
# from routes.voice_routes import voice_routes
# from routes.language_routes import language_routes
# from routes.admin_routes import admin_routes


# load_dotenv()

# app = Flask(__name__, static_folder='static')
# CORS(app)
# bcrypt = Bcrypt(app)


# app.register_blueprint(auth_routes)
# app.register_blueprint(user_routes)
# app.register_blueprint(favorites_routes)
# app.register_blueprint(history_routes)
# app.register_blueprint(voice_routes)
# app.register_blueprint(language_routes)
# app.register_blueprint(admin_routes)
# #MongoDB setup
# mongo_uri = "mongodb://localhost:27017/"
# client = MongoClient(mongo_uri)
# db = client["somali_translator_db"]
# translations = db["translations"]
# users = db["users"] 

# #Load translation model
# model_dir = "./amiin_model"
# tokenizer = MarianTokenizer.from_pretrained(model_dir, local_files_only=True)
# model = TFMarianMTModel.from_pretrained(model_dir, local_files_only=True)

# @app.route("/")
# def home():
#     return "Somali Translator API waa socda oo MongoDB waa ku xiran!"

# @app.route("/voice-demo")
# def voice_demo():
#     return app.send_static_file('voice-recorder-demo.html')

# @app.route("/language-demo")
# def language_demo():
#     return app.send_static_file('language-detection-demo.html')

# @app.route("/translate", methods=["POST"])
# def translate():
#     data = request.get_json()
#     input_text = data.get("text", "")

#     if not input_text.strip():
#         return jsonify({"translation": "No input text provided."})

#     # Check if user is authenticated
#     user_id = None
#     auth_header = request.headers.get('Authorization')
#     if auth_header and auth_header.startswith('Bearer '):
#         try:
#             token = auth_header.split(' ')[1]
#             from middlewares.auth_decorator import decode_token
#             claims = decode_token(token)
#             user_id = claims.get("user_id")
#         except:
#             pass  # Continue without user_id if token is invalid

#     try:
#         # Detect language of input text (for information only, no validation)
#         from routes.language_detection import somali_detector
#         language_detection = somali_detector.detect_text_language(input_text)
#         detected_language = language_detection['language']
#         language_confidence = language_detection['confidence']
#         detection_method = language_detection['method']

#         # Remove Somali language validation - allow any text to be translated
#         # The language detection is now only for informational purposes

#         inputs = tokenizer(input_text, return_tensors="tf", padding=True, truncation=True)
#         outputs = model.generate(**inputs)
#         translated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)

#         # Define Somalia timezone
#         somalia_tz = pytz.timezone('Africa/Mogadishu')

#         # Save to MongoDB
#         new_entry = {
#             "original_text": input_text,
#             "translated_text": translated_text,
#             "timestamp": datetime.now(somalia_tz).isoformat(),
#             "is_favorite": False,
#             "detected_language": detected_language,
#             "language_confidence": language_confidence,
#             "detection_method": detection_method
#         }
        
#         # Add user_id if authenticated
#         if user_id:
#             from bson import ObjectId
#             new_entry["user_id"] = ObjectId(user_id)
            
#         result = translations.insert_one(new_entry)
#         new_entry["_id"] = str(result.inserted_id)

#         return jsonify({
#             "translated_text": translated_text,
#             "id": str(result.inserted_id),  # Return MongoDB document ID
#             "language_detection": {
#                 "detected_language": detected_language,
#                 "language_confidence": language_confidence,
#                 "detection_method": detection_method,
#                 "is_somali": detected_language == 'so'
#             }
#         })

#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# # Legacy endpoints for backward compatibility (public access)
# @app.route("/history", methods=["GET"])
# def get_history():
#     docs = list(translations.find().sort("timestamp", -1))
#     for doc in docs:
#         doc["_id"] = str(doc["_id"])
#         doc["timestamp"] = str(doc["timestamp"])  # no isoformat needed
#     return jsonify(docs)

# @app.route("/favorites", methods=["GET"])
# def get_favorites():
#     docs = list(translations.find({"is_favorite": True}).sort("timestamp", -1))
#     for doc in docs:
#         doc["_id"] = str(doc["_id"])
#         doc["timestamp"] = doc["timestamp"]
#     return jsonify(docs)




# if __name__ == "__main__":
#     app.run(host="0.0.0.0", port=5000, debug=True)
