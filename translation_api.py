from flask import Blueprint, jsonify, request
from bson import ObjectId
from pymongo import MongoClient
from datetime import datetime
from middlewares.auth_decorator import token_required
from langdetect import detect
import requests

client = MongoClient("mongodb://localhost:27017/")
db = client["somali_translator_db"]
translations = db["translations"]
favorites = db["favorites"]
history = db["history"]

translation_routes = Blueprint("translation_routes", __name__)

def detect_language(text):
    """Detect if text is Somali using word list and langdetect"""
    try:
        # Somali word list for better detection
        somali_words = {
            'waan', 'waxaan', 'waxay', 'wuxuu', 'waxaad', 'eedda', 'nin', 'naag', 'carruur', 'qof', 'dad',
            'bulsho', 'wadan', 'dalka', 'faraxsan', 'ku', 'faraxsanahay', 'mahadsanid', 'fadlan', 'waa',
            'ma', 'miyaa', 'wax', 'qoraal', 'cod', 'hadal', 'sheeg', 'dhig', 'samee', 'ka', 'la', 'iyo',
            'ah', 'ku', 'ka', 'la', 'iyo', 'oo', 'ee', 'uu', 'ay', 'ad', 'an', 'na', 'waa', 'ma', 'miyaa'
        }
        
        # Check if text contains Somali words
        text_words = text.lower().split()
        somali_word_count = sum(1 for word in text_words if word in somali_words)
        
        # If more than 30% of words are Somali, consider it Somali
        if somali_word_count > 0 and (somali_word_count / max(1, len(text_words))) > 0.3:
            return "so"
        else:
            # Fallback to langdetect
            return detect(text)
    except Exception as e:
        print(f"Language detection error: {e}")
        return "unknown"

def translate_text(text, from_lang="so", to_lang="en"):
    """Translate text using Google Translate API"""
    try:
        url = f"https://translate.googleapis.com/translate_a/single?client=gtx&sl={from_lang}&tl={to_lang}&dt=t&q={requests.utils.quote(text)}"
        response = requests.get(url)
        
        if response.status_code == 200:
            data = response.json()
            if data and data[0]:
                return data[0][0][0] if data[0][0] else ""
        return ""
    except Exception as e:
        print(f"Translation error: {e}")
        return ""

@translation_routes.route("/translate", methods=["POST"])
def translate():
    """Translate text from Somali to English or vice versa"""
    try:
        data = request.get_json() or {}
        text = data.get("text", "").strip()
        from_lang = data.get("from_lang", "so")
        to_lang = data.get("to_lang", "en")
        
        if not text:
            return jsonify({"error": "Text is required"}), 400
        
        # Auto-detect language if not specified
        if from_lang == "auto":
            detected_lang = detect_language(text)
            if detected_lang == "so":
                from_lang = "so"
                to_lang = "en"
            elif detected_lang == "en":
                from_lang = "en"
                to_lang = "so"
            else:
                # Default to Somali if detection fails
                from_lang = "so"
                to_lang = "en"
        
        # Validate Somali input if translating from Somali
        if from_lang == "so":
            detected = detect_language(text)
            if detected != "so":
                return jsonify({"error": "Fadlan ku hadal Somali"}), 400
        
        # Perform translation
        translated_text = translate_text(text, from_lang, to_lang)
        
        if not translated_text:
            return jsonify({"error": "Translation failed"}), 500
        
        # Create translation record
        translation_doc = {
            "original_text": text,
            "translated_text": translated_text,
            "from_lang": from_lang,
            "to_lang": to_lang,
            "timestamp": datetime.utcnow(),
            "is_favorite": False
        }
        
        # Save to database if user is authenticated
        user_id = None
        if hasattr(request, "user") and request.user:
            user_id = request.user.get("user_id")
            if user_id:
                translation_doc["user_id"] = ObjectId(user_id)
                result = translations.insert_one(translation_doc)
                translation_doc["_id"] = str(result.inserted_id)
        
        return jsonify({
            "translated_text": translated_text,
            "original_text": text,
            "from_lang": from_lang,
            "to_lang": to_lang,
            "id": translation_doc.get("_id", ""),
            "timestamp": translation_doc["timestamp"].isoformat()
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/history", methods=["GET"])
@token_required
def get_history():
    """Get translation history for authenticated user"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        # Get translations from both collections
        translations_list = list(translations.find({"user_id": ObjectId(user_id)}).sort("timestamp", -1))
        history_list = list(history.find({"user_id": ObjectId(user_id)}).sort("timestamp", -1))
        
        # Combine and format results
        all_translations = []
        
        for item in translations_list:
            item["_id"] = str(item["_id"])
            item["user_id"] = str(item["user_id"])
            if hasattr(item.get("timestamp"), "isoformat"):
                item["timestamp"] = item["timestamp"].isoformat()
            all_translations.append(item)
        
        for item in history_list:
            item["_id"] = str(item["_id"])
            item["user_id"] = str(item["user_id"])
            if hasattr(item.get("timestamp"), "isoformat"):
                item["timestamp"] = item["timestamp"].isoformat()
            all_translations.append(item)
        
        # Sort by timestamp (newest first)
        all_translations.sort(key=lambda x: x["timestamp"], reverse=True)
        
        return jsonify({"translations": all_translations}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/history", methods=["POST"])
@token_required
def save_to_history():
    """Save translation to history"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        data = request.get_json() or {}
        original_text = data.get("original_text", "").strip()
        translated_text = data.get("translated_text", "").strip()
        from_lang = data.get("from_lang", "so")
        to_lang = data.get("to_lang", "en")
        
        if not original_text or not translated_text:
            return jsonify({"error": "Original and translated text are required"}), 400
        
        doc = {
            "user_id": ObjectId(user_id),
            "original_text": original_text,
            "translated_text": translated_text,
            "from_lang": from_lang,
            "to_lang": to_lang,
            "timestamp": datetime.utcnow(),
            "is_favorite": False
        }
        
        result = history.insert_one(doc)
        
        return jsonify({
            "message": "Translation saved to history",
            "id": str(result.inserted_id)
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/history/<translation_id>", methods=["DELETE"])
@token_required
def delete_history_item(translation_id):
    """Delete a specific translation from history"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        # Try to delete from both collections
        result1 = history.delete_one({
            "_id": ObjectId(translation_id),
            "user_id": ObjectId(user_id)
        })
        
        result2 = translations.delete_one({
            "_id": ObjectId(translation_id),
            "user_id": ObjectId(user_id)
        })
        
        if result1.deleted_count == 0 and result2.deleted_count == 0:
            return jsonify({"error": "Translation not found"}), 404
        
        return jsonify({"message": "Translation deleted successfully"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/history", methods=["DELETE"])
@token_required
def clear_history():
    """Clear all translation history for user"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        # Clear both collections
        result1 = history.delete_many({"user_id": ObjectId(user_id)})
        result2 = translations.delete_many({"user_id": ObjectId(user_id)})
        
        total_deleted = result1.deleted_count + result2.deleted_count
        
        return jsonify({
            "message": f"Cleared {total_deleted} translations from history"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/favorite", methods=["POST"])
@token_required
def add_to_favorites():
    """Add translation to favorites"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        data = request.get_json() or {}
        translation_id = data.get("id")
        original_text = data.get("original_text", "").strip()
        translated_text = data.get("translated_text", "").strip()
        from_lang = data.get("from_lang", "so")
        to_lang = data.get("to_lang", "en")
        
        if not original_text or not translated_text:
            return jsonify({"error": "Original and translated text are required"}), 400
        
        # Check if already in favorites
        existing = favorites.find_one({
            "user_id": ObjectId(user_id),
            "original_text": original_text,
            "translated_text": translated_text
        })
        
        if existing:
            return jsonify({"error": "Translation already in favorites"}), 400
        
        doc = {
            "user_id": ObjectId(user_id),
            "original_text": original_text,
            "translated_text": translated_text,
            "from_lang": from_lang,
            "to_lang": to_lang,
            "timestamp": datetime.utcnow(),
            "translation_id": translation_id
        }
        
        result = favorites.insert_one(doc)
        
        return jsonify({
            "message": "Added to favorites",
            "id": str(result.inserted_id)
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/favorites", methods=["GET"])
@token_required
def get_favorites():
    """Get all favorites for authenticated user"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        favorites_list = list(favorites.find({"user_id": ObjectId(user_id)}).sort("timestamp", -1))
        
        # Format results
        for item in favorites_list:
            item["_id"] = str(item["_id"])
            item["user_id"] = str(item["user_id"])
            if hasattr(item.get("timestamp"), "isoformat"):
                item["timestamp"] = item["timestamp"].isoformat()
        
        return jsonify(favorites_list), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/favorites/<favorite_id>", methods=["DELETE"])
@token_required
def remove_from_favorites(favorite_id):
    """Remove translation from favorites"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        result = favorites.delete_one({
            "_id": ObjectId(favorite_id),
            "user_id": ObjectId(user_id)
        })
        
        if result.deleted_count == 0:
            return jsonify({"error": "Favorite not found"}), 404
        
        return jsonify({"message": "Removed from favorites"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/favorites", methods=["DELETE"])
@token_required
def clear_favorites():
    """Clear all favorites for user"""
    try:
        claims = getattr(request, "user", {}) or {}
        user_id = claims.get("user_id")
        if not user_id:
            return jsonify({"error": "Invalid token payload"}), 403
        
        result = favorites.delete_many({"user_id": ObjectId(user_id)})
        
        return jsonify({
            "message": f"Cleared {result.deleted_count} favorites"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@translation_routes.route("/languages", methods=["GET"])
def get_supported_languages():
    """Get list of supported languages"""
    languages = [
        {"code": "so", "name": "Somali", "native_name": "Soomaali"},
        {"code": "en", "name": "English", "native_name": "English"},
        {"code": "ar", "name": "Arabic", "native_name": "العربية"},
        {"code": "fr", "name": "French", "native_name": "Français"},
        {"code": "es", "name": "Spanish", "native_name": "Español"}
    ]
    
    return jsonify({"languages": languages}), 200

