import hashlib

def sha512(data: bytes):
    return hashlib.sha512(data).digest()

def sha256(data: bytes):
    return hashlib.sha256(data).digest()