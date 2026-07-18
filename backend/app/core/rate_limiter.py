import time
from fastapi import Request, HTTPException, status
from app.core.redis import redis_session

class RateLimiter:
    def __init__(self, requests_limit: int, window_seconds: int = 60):
        self.requests_limit = requests_limit
        self.window_seconds = window_seconds

    async def __call__(self, request: Request):
        # Identify the client by their IP address (or proxy header if behind a proxy)
        ip = "unknown"
        if request.client:
            ip = request.client.host
        
        # Check X-Forwarded-For header in case of reverse proxy setups
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            ip = forwarded_for.split(",")[0].strip()

        path = request.url.path
        key = f"rate_limit:{ip}:{path}"

        # Fallback to in-memory rate limiting if Redis is unavailable
        if redis_session.use_fallback:
            now = time.time()
            if not hasattr(redis_session, "_rate_limits"):
                redis_session._rate_limits = {}
            
            history = redis_session._rate_limits.get(key, [])
            # Filter history to keep only requests within the active time window
            history = [t for t in history if now - t < self.window_seconds]
            
            if len(history) >= self.requests_limit:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many requests. Please try again later."
                )
            
            history.append(now)
            redis_session._rate_limits[key] = history
            return

        # Standard Redis token/request counter using pipelines for transaction safety
        try:
            pipe = redis_session.client.pipeline()
            pipe.incr(key)
            pipe.expire(key, self.window_seconds, nx=True)  # nx=True sets TTL only if it is not already set
            current_requests, _ = pipe.execute()
            
            if current_requests > self.requests_limit:
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Too many requests. Please try again later."
                )
        except HTTPException:
            raise
        except Exception as e:
            # Fail open: if Redis has connection problems, log it but don't block the request
            print(f"Rate limiter connection error: {e}. Request allowed (fail-open).")
            pass

# Initialize ready-to-use rate limiters for different scenarios
global_rate_limiter = RateLimiter(requests_limit=100, window_seconds=60)      # 100 req/min globally
auth_rate_limiter = RateLimiter(requests_limit=15, window_seconds=60)        # 15 req/min for authentication
solver_rate_limiter = RateLimiter(requests_limit=5, window_seconds=60)        # 5 req/min for solving schedules
