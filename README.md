# Secure Communication

gmail (insecure) + bash (insecure) = secure communication

## Usage
```bash
cd
git clone https://github.com/3lv/secure_communication
cd secure_communication
```
### Initialization
```bash
# Initialize once
./src/api/init "<gmail_address>"
# Add your first person in contacts
./src/api/add_contact "<contact_name>" "<contact_gmail>"
## Meet face to face and input his `ed25519_public.pem`
# Enable clearing expired points using systemd timer
sudo cp systemd/clear_expired_points@.{service,timer} /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now "clear_expired_points@$USER.timer"
```

## Directory layout: `contacts/`

The `~/contacts/` directory stores all contacts.

- Each subfolder represents one person (folder name = identifier/handle).
- The special folder `__me__` is **your identity**, `ed25519_private.pem` must remain private

```text
contacts/
├── __me__/
│   ├── ed25519_private.pem
│   ├── ed25519_public.pem
│   └── email_address.txt
├── jendrik/
│   ├── .state/
│   ├── ed25519_public.pem
│   └── email_address.txt
├── teo/
│   ├── .state/
│   ├── ed25519_public.pem
│   └── email_address.txt
└── ...
```

```text
.state/
└── dh_points
    ├── my
    │   ├── 1771505332
    │   │   ├── eph_x25519_private.pem
    │   │   ├── eph_x25519_public.pem
    │   │   └── eph_x25519_public.sig
    │   ├── 1771505569
    │   │   ├── eph_x25519_private.pem
    │   │   ├── eph_x25519_public.pem
    │   │   └── eph_x25519_public.sig
    │   └── ...
    └── received
        ├── 1771505402
        │   ├── eph_x25519_public.pem
        │   └── eph_x25519_public.sig
        ├── 1771505600
        │   ├── eph_x25519_public.pem
        │   └── eph_x25519_public.sig
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

Not having the $decrypted_message stored anywhere as well as having the eph_x25519_private.pem removed from both sides, make the message unrecoverable.
Because it's a known fact that the other party can "maliciously" keep the old points by modifing the client, /src/api/MALICIOUS_clear_points is provided

Used crypto algorithms from openssl:
ed25519 signatures + x25519 static-static Diffe-Hellman + HKDF + AES-GCM(128)


Dependencies: `openssl` `base64` `gmi` `notmuch`

# TODO: Complete Security Model