# Used for DH. Uses only the x with fast and symetric operation cuz
# This was not implemented for speed, as I wanted the formulas to be explicit


# Montgomery form curve
# By^2 = x^3 + Ax^2 + x (mod p)

A = 486662
B = 1
p = (1<<255) - 19

# The base point
u = 9

def inv(z: int, p: int):
    return pow(z % p, p - 2, p)

class Point():
    def __init__(self, x: int, z: int):
        """
        x: x of the point
        z: z from x/z representation
        Note that this doesn't uniquely define a point, we just don't care about the sign of y for the operations
        """
        self.x = x
        self.z = z
    
    def identity(): # i.e. zero
        return Point(69, 0)
    
    def get_u(self):
        return self.x * inv(self.z, p) % p

def bits_high_to_low(n: int):
    if n == 0:
        return 0
    return [(n >> i) & 1 for i in range(n.bit_length(), -1, -1)]

def add(a: Point, b: Point, d: Point):
    """
    d: difference of the two points (so that you can sum in the x/z representation)
    """
    # TODO: Maybe make a copy of the sums/diffs
    x = ((a.x - a.z) * (b.x + b.z) + (a.x + a.z) * (b.x - b.z)) ** 2 % p * d.z % p
    z = ((a.x - a.z) * (b.x + b.z) - (a.x + a.z) * (b.x - b.z)) ** 2 % p * d.x % p
    return Point(x, z)

def doubling(a: Point):
    #xz4 = ((p.x - p.y) ** 2 - (p.x - p.z) ** 2 ) % p
    xz4 = (4 * a.x * a.z) % p
    x = ((a.x + a.z) ** 2 % p) * ((a.x - a.z) ** 2 % p) % p
    z = xz4 * ((a.x - a.z) ** 2 + ((A + 2) // 4) * xz4) % p
    return Point(x, z)


def encode(u: int):
    return u.to_bytes(32, "little")

def decode(u_bytes: bytes):
    return int.from_bytes(u_bytes, "little")

def _mult(k: int, u: int):
    """
    k: Scalar to multiply the point with
    u: The point you want to multiply(the x coordinate)
    """
    r0 = Point.identity()
    r1 = Point(u, 1)
    d = Point(u, 1) # They always differ from each other by u

    for bit in bits_high_to_low(k):
        if bit == 0:
            r1 = add(r0, r1, d)
            r0 = doubling(r0)
        else:
            r0 = add(r0, r1, d)
            r1 = doubling(r1)
    
    u = r0.get_u()
    return u

def mult(k: int | bytes, u: int | bytes):
    """
    k: Scalar to multiply the point with
    u: The point you want to multiply(the x coordinate)
    """
    if isinstance(k, bytes):
        k = decode(k)

    if isinstance(u, bytes):
        u = decode(u)

    return encode(_mult(k, u))

#def public(secret: bytes):
#    return _mult(secret, u)