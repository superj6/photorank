#!/usr/bin/env python3
"""Print ANON_KEY and SERVICE_ROLE_KEY for a self-hosted Supabase JWT_SECRET.

    tool/selfhost_keys.py "$JWT_SECRET"
"""
import base64, hashlib, hmac, json, sys, time

def b64(b: bytes) -> str:
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def jwt(secret: str, role: str) -> str:
    now = int(time.time())
    header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    payload = b64(json.dumps({"role": role, "iss": "supabase", "iat": now, "exp": now + 10 * 365 * 86400}, separators=(",", ":")).encode())
    sig = b64(hmac.new(secret.encode(), f"{header}.{payload}".encode(), hashlib.sha256).digest())
    return f"{header}.{payload}.{sig}"

if len(sys.argv) != 2 or len(sys.argv[1]) < 32:
    sys.exit(__doc__ + "\nJWT_SECRET must be at least 32 characters.")
print("ANON_KEY=" + jwt(sys.argv[1], "anon"))
print("SERVICE_ROLE_KEY=" + jwt(sys.argv[1], "service_role"))
