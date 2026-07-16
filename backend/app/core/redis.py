import redis
import json
from app.core.config import settings

class RedisSessionManager:
    def __init__(self):
        try:
            self.client = redis.Redis(
                host=settings.REDIS_HOST,
                port=settings.REDIS_PORT,
                decode_responses=True,
                socket_timeout=2.0
            )
            # Test connection
            self.client.ping()
            self.use_fallback = False
            print("Connected to Redis successfully.")
        except Exception as e:
            print(f"Warning: Could not connect to Redis: {e}. Falling back to in-memory session storage.")
            self.use_fallback = True
            self._fallback_db = {}

    def create_session(self, session_id: str, user_data: dict, expire_seconds: int = 60 * 60 * 24 * 7) -> bool:
        if self.use_fallback:
            self._fallback_db[session_id] = user_data
            return True
        try:
            self.client.set(
                f"session:{session_id}",
                json.dumps(user_data),
                ex=expire_seconds
            )
            return True
        except Exception as e:
            print(f"Error writing to Redis, writing to fallback: {e}")
            self._fallback_db[session_id] = user_data
            return True

    def get_session(self, session_id: str) -> dict | None:
        if self.use_fallback:
            return self._fallback_db.get(session_id)
        try:
            data = self.client.get(f"session:{session_id}")
            if data:
                return json.loads(data)
        except Exception as e:
            print(f"Error reading from Redis, reading from fallback: {e}")
            return self._fallback_db.get(session_id)
        return None

    def delete_session(self, session_id: str) -> bool:
        if self.use_fallback:
            self._fallback_db.pop(session_id, None)
            return True
        try:
            self.client.delete(f"session:{session_id}")
            return True
        except Exception as e:
            print(f"Error deleting from Redis, deleting from fallback: {e}")
            self._fallback_db.pop(session_id, None)
            return True

redis_session = RedisSessionManager()
