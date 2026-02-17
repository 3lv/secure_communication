import sha
B = 64
HASH_LEN = 32

def xor_bytes(a: bytes, b: bytes):
    assert len(a) == len(b)

    return bytes([a ^ b for a, b in zip(a, b)])

def hmac(key: bytes, message: bytes):
    # sha256 (block size of 64bytes -> output 32bytes)

    if len(key) > B:
        key = sha.sha256(key)
    elif len(key) < B:
        key = key + bytes([0x00]) * (B - len(key))
    
    ipad = bytes([0x36]) * B
    opad = bytes([0x5c]) * B

    return sha.sha256(xor_bytes(key, opad) + sha.sha256(xor_bytes(key, ipad) + message))

def hkdf(shared_secret: bytes, salt: bytes, info: bytes, L: bytes):
    assert L <= 255 * HASH_LEN
    #if salt == None:
    #    salt = bytes([0x00]) * B
    
    prk = hmac(salt, shared_secret) # Pseudo random key

    N = (L + HASH_LEN - 1) // HASH_LEN

    T = ["".encode()]
    for i in range(1, N+1):
        T.append(hmac(prk, T[i-1] + info + bytes([i])))
    
    okm = b"".join(T[1:]) # Output key material
    key = okm[0:L]

    return key