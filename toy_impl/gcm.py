import string
import secrets
from Crypto.Util.Padding import pad, unpad
from Crypto.Cipher import AES

import matplotlib.pyplot as plt

import numpy as np

BLOCK_SIZE = 16

# x^7 + x^2 + x + 1 = x^128 (mod P)

def xor_blocks(block1: bytes, block2: bytes):
    assert len(block1) == len(block2), f"Blocks have different length {len(block1)}, {len(block2)}"
    return bytes(a ^ b for a, b in zip(block1, block2))

def galois_mult(block1: bytes, block2: bytes):
    x = int.from_bytes(block1, "big")
    y = int.from_bytes(block2, "big")

    r = 0xe1000000000000000000000000000000 #11100001 <=> E1

    res = 0

    for i in range(128):
        if (x >> (127 - i)) & 1:
            res ^= y
        
        if y & 1 == 0:
            y >>= 1
        else:
            y >>= 1
            y ^= r
    
    return res.to_bytes(16, "big")
            

def encrypt(plaintext: bytes, key: bytes, iv: bytes, auth_data: bytes | None = None):
    assert len(iv) == 16
    assert auth_data is None,  ValueError("Unimplemented")

    aes = AES.new(key, AES.MODE_ECB)
    plaintext = pad(plaintext, BLOCK_SIZE)
    blocks = [plaintext[i:i+BLOCK_SIZE] for i in range(0, len(plaintext), BLOCK_SIZE)]

    tag1 = aes.encrypt(iv)

    ciphers = []
    ciphers.append(iv)

    H = aes.encrypt(bytes.fromhex("00")*16)

    tag = bytes.fromhex("00")*16 # or do galois_mult(auth_data, H)

    for block in blocks:
        # Increment iv
        iv_int = int.from_bytes(iv, "big")
        iv_int = (iv_int + 1) % (1 << 128)
        iv = iv_int.to_bytes(16, "big")
        k = aes.encrypt(iv)
        cipher = xor_blocks(k, block)
        ciphers.append(cipher)
        tag = xor_blocks(tag, cipher)
        tag = galois_mult(tag, H)
    
    A = (len(auth_data or []) * 8).to_bytes(8, "big")
    C = (len(plaintext) * 8).to_bytes(8, "big")
    A_C = A + C

    tag = xor_blocks(tag, A_C)
    tag = galois_mult(tag, H)
    tag = xor_blocks(tag, tag1)

    return b"".join(ciphers), tag

def decrypt(ciphertext: bytes, key: bytes, tag: bytes, auth_data: bytes | None = None):
    assert len(ciphertext) % 16 == 0, "ciphertext's length must be devisible by 16"
    blocks = [ciphertext[i:i+BLOCK_SIZE] for i in range(0, len(ciphertext), BLOCK_SIZE)]
    iv = blocks[0]
    blocks = blocks[1:]

    aes = AES.new(key, AES.MODE_ECB)

    ctag1 = aes.encrypt(iv)

    H = aes.encrypt(bytes.fromhex("00")*16)

    plaintext = []
    ctag = bytes.fromhex("00")*16

    for block in blocks:
        # Increment iv
        iv_int = int.from_bytes(iv, "big")
        iv_int = (iv_int + 1) % (1 << 128)
        iv = iv_int.to_bytes(16, "big")
        k = aes.encrypt(iv)
        plaintext_block = xor_blocks(block, k)
        plaintext.append(plaintext_block)
        ctag = xor_blocks(ctag, block)
        ctag = galois_mult(ctag, H)

    A = (len(auth_data or []) * 8).to_bytes(8, "big")
    C = (len(blocks) * BLOCK_SIZE * 8).to_bytes(8, "big")
    A_C = A + C

    ctag = xor_blocks(ctag, A_C)
    ctag = galois_mult(ctag, H)
    ctag = xor_blocks(ctag, ctag1)

    assert ctag == tag, "Tag doesn't match"

    padded_plaintext = b''.join(plaintext)

    plaintext = unpad(padded_plaintext, 16)

    return plaintext