import sha

def hash_fn(data: bytes):
    return sha.sha512(data)

#-x^2 + y^2 = 1 + d*x^2*y^2 (mod p)

p = (1 << 255) - 19
l = (1 << 252) + 27742317777372353535851937790883648493 # Group order
a = -1

def inv(val, p):
    return pow(val % p, p-2, p) # p prime

d = -121665 * inv(121666, p)

class Point():
    def __init__(self, x: int, y: int):
        self.x = x
        self.y = y

    def identity():
        return Point(0, 1)
    
    def __eq__(self, other):
        if not isinstance(other, Point):
            return NotImplemented
        return self.x == other.x and self.y == other.y

    
    def _is_on_curve(self):
        return (-pow(self.x, 2, p) + pow(self.y, 2, p)) % p == 1 + d * pow(self.x, 2, p) * pow(self.y, 2, p) % p

# TODO: Choose a B point
B = Point(
    15112221349535400772501151409588531511454012693041857206046113283949847762202,
    46316835694926478169428394003475163141307993866256225615783033603165251855960
) # Hardcoded point with order l

# Twisted Edwards Addition
# Or use extended edwards coordinates (X, Y, Z, T):
# x = X/Z
# y = Y/Z
# T = XY/Z
# This way you don't have to compute the inverse at every step
# Etc

def add(a: Point, b: Point):
    t = d * a.x * a.y * b.x * b.y % p
    assert t != 1 and t != -1, "Division by zero"

    cx = ((a.x * b.y + a.y * b.x) % p) * inv(1 + t, p) % p
    cy = ((a.y * b.y + a.x * b.x) % p) * inv(1 - t, p) % p

    return Point(cx, cy)
    #if a != b:
    #    m = (b.y - a.y) * inv(b.x - a.x, p)

def mult(k: int, p: Point):
    r = Point.identity()
    while k:
        if k & 1:
            r = add(r, p)
        k >>= 1
        p = add(p, p)
    return r
    
def encode_point(p: Point):
    y = p.y.to_bytes(32, "little")
    #x = p.x.to_bytes(32, "little")
    last = y[-1]
    new_last = last & (0xff - (1<<7)) # Clear top bit
    #new_last = new_last | (x[-1] & (1<<7)) # Use x top bit sign
    new_last = new_last | ((p.x & 1) << 7) # Use x LSB as sign bit
    return y[:-1] + bytes([new_last])

def mod_sqrt(a: int, p: int):
    """
    Solve x^2 ≡ a (mod p) for an odd prime p.
    Returns a tuple x one of the two roots (the other one being p-x), or None if no root exists.
    """
    if p <= 2:
        raise ValueError("p must be an odd prime > 2")
    a %= p
    if a == 0:
        return (0, 0)

    # Legendre symbol: a^((p-1)/2) mod p is 1 if residue, p-1 if non-residue
    ls = pow(a, (p - 1) // 2, p)
    if ls != 1:
        return None  # no solution

    # Fast path: p ≡ 3 (mod 4)
    if p % 4 == 3:
        r = pow(a, (p + 1) // 4, p)
        return r

    # Tonelli–Shanks
    # Factor p-1 = q * 2^s with q odd
    q = p - 1
    s = 0
    while q % 2 == 0:
        s += 1
        q //= 2

    # Find a quadratic non-residue z
    z = 2
    while pow(z, (p - 1) // 2, p) != p - 1:
        z += 1

    m = s
    c = pow(z, q, p)
    t = pow(a, q, p)
    r = pow(a, (q + 1) // 2, p)

    while t != 1:
        # Find the least i (0 < i < m) such that t^(2^i) == 1
        i = 1
        t2i = (t * t) % p
        while i < m and t2i != 1:
            t2i = (t2i * t2i) % p
            i += 1

        # b = c^(2^(m-i-1))
        b = c
        for _ in range(m - i - 1):
            b = (b * b) % p

        r = (r * b) % p
        bb = (b * b) % p
        t = (t * bb) % p
        c = bb
        m = i

    return r


def decode_point(p_bytes: bytes):
    b = (p_bytes[-1] >> 7) & 1 # Extract x sign
    y_bytes = p_bytes[:-1] + bytes([p_bytes[-1] & (0xff - (1<<7))]) # Remove x sign
    y = int.from_bytes(y_bytes, "little")
    # x^2 = (y^2 - 1) * (d*y^2 + 1)^-1
    x_squared = (pow(y, 2, p) - 1) * inv(d * pow(y, 2, p) + 1, p)

    x = mod_sqrt(x_squared, p)
    if x == None:
        raise ValueError("x_squared doesn't have a root")
    # TODO: Handle x = None
    
    if x & 1 != b: # If the x is negative, get the other root
        x = p - x

    return Point(x, y)

def key_gen(seed_k: bytes):
    h = hash_fn(seed_k)
    assert len(h) == 64
    h_L = bytearray(h[:32])
    h_R = h[32:]

    # Clamp h_L
    h_L[0] &= (0xff ^ (0b111)) # Clear low 3 bits
    h_L[31] &= (0xff ^ (1<<7)) # Clear top bit
    h_L[31] |= (1<<6) # Set second top bit

    return bytes(h_L), h_R

def pk(seed_k: bytes):
    h_L, _ = key_gen(seed_k)
    a = int.from_bytes(h_L, "little")
    A = mult(a, B)
    return encode_point(A)

#    a = int.from_bytes(h_L, "little")
#    A = mult(a, B)
#    return A, h_R

def sign(seed_k: bytes, M: bytes):
    """
    seed_k: The secret seed(key) which is expanded
    M: Message to sign
    """
    h_L, h_R = key_gen(seed_k)
    a = int.from_bytes(h_L, "little")
    A = mult(a, B)
    A_enc = encode_point(A)

    r = int.from_bytes(hash_fn(h_R + M), "little") % l
    R = mult(r, B)
    R_enc = encode_point(R)

    c = int.from_bytes(hash_fn(R_enc + A_enc + M), "little") % l

    s = (r + c * a) % l
    s_enc = s.to_bytes(32, "little")

    sig = R_enc + s_enc
    return sig

def verify(pk: bytes, M: bytes, sig: bytes):
    """
    pk: Encoded A point
    M: Message to verify
    sig: Signiture to verify
    """
    assert len(sig) == 64
    A_enc = pk

    A = decode_point(A_enc)
    R_enc, s_enc = sig[:32], sig[32:]
    # TODO: Try catch:
    R = decode_point(R_enc)
    s = int.from_bytes(s_enc, "little")
    if s >= l:
        #raise ValueError("s >= l")
        return False
    
    c = int.from_bytes(hash_fn(R_enc + A_enc + M), "little") % l

    if mult(s, B) != add(R, mult(c, A)):
        return False
    
    return True
