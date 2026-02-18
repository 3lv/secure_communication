# Secure Communication

gmail (insecure) + bash (insecure) = secure communication

## Usage
### Initialization
```bash
# Initialize once
./src/api/init "<gmail_address>"
# Add your first person in contacts
./src/api/add_contact "<contact_name>" "<contact_gmail>"
## Meet face to face and input his `ed25519_public.pem`
```

## Directory layout: `contacts/`

The `contacts/` directory stores all contacts.

- Each subfolder represents one person (folder name = identifier/handle).
- The special folder `__me__` is **your identity**, `ed25519_private.pem` must remain private

```text
contacts/
├── __me__/
│   ├── ed25519_private.pem
│   ├── ed25519_public.pem
│   └── email_address.txt
├── jendrik/
│   ├── dh_my_points/
│   ├── dh_received_points/
│   ├── ed25519_public.pem
│   └── email_address.txt
├── teo/
│   ├── dh_my_points/
│   ├── dh_received_points/
│   ├── ed25519_public.pem
│   └── email_address.txt
└── ...
```


## The actual communication

### Sending message
```bash
./src/api/send "<recipient_name>" "<message>"
```

### Reciving message
```bash
./src/api/rec "<sender_name>"
```
> This receives the last sent message


## Security Model

Used crypto algorithms from openssl:
ed25519 signatures + x25519 static-static Diffe-Hellman + HKDF + AES-GCM(128)

> Not having the $decrypted_message stored anywhere as well as having the eph_x25519_private.pem removed from both sides, make the message unrecoverable

Dependencies: `openssl` `base64` `gmi` `notmuch`

# TODO: Complete Security Model