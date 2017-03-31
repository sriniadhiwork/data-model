# Data Model for PULSE

This is the Data Model for PULSE.

# Installation

## Getting the code

```sh
$ git clone https://git.ainq.com/pulse/data-model.git
$ cd data-model
$ ./reset.sh
$ ./fake.sh
```

#Encrypting PHI

##Create public and private keys to use for encrypting and decrypting sensitive personal information in the database.

* Install pgp if your system does not have it already. Windows users likely have to install something and Linux users likely do not.
  * Gnupg4win (https://www.gnupg.org/download/)
```sh
$ gpg --gen-key
```

* Follow the prompts keeping in mind the notes below.
  * The preferred type of key is Option 2 (DSA and Elgamal)
  * You can set an expiration if you'd like, but it is recommended not to unless you want to create keys again.
  * DO NOT set a password. Hit enter leaving the password prompts blank and accept all related warnings.

* View the keys you created:
```sh
$ gpg --list-secret-keys
```
The one listed as "sec" is the private key and the other is the public key.

* Export the keys in a readable format.
```sh
gpg -a --export 999DEFG > public.key
gpg -a --export-secret-keys 123ABCD > private.key
```

###Add the public and private keys as data that will be returned by a database function in Postgres
* Create the below functions in both the pulse and pulse_test databases.

  * Open the public.key file and copy its contents entirely
```sql
CREATE OR REPLACE FUNCTION public_key() RETURNS varchar as $$
	BEGIN
		RETURN '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

allthestuff
inthekey
-----END PGP PUBLIC KEY BLOCK-----';
	END
$$ LANGUAGE plpgsql;
```

  * Open the private.key file and copy its contents entirely
```sql
CREATE OR REPLACE FUNCTION private_key() RETURNS varchar as $$
	BEGIN
		RETURN '-----BEGIN PGP PRIVATE KEY BLOCK-----
Version: GnuPG v2

allthestuff
inthekey
probablylonger
thanthepublickey
-----END PGP PRIVATE KEY BLOCK-----';
	END
$$ LANGUAGE plpgsql;
```

  * Test that the functions are working
```sql
select * from public_key();
select * from private_key();
```



