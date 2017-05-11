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

# Encrypting PHI

## Install the pgcrypto Postgres Extension

To install the extension:
```sql
CREATE EXTENSION pgcrypto;
```
To see which extensions are installed
```sql
\dx
```

## Create public and private keys to use for encrypting and decrypting sensitive personal information in the database.

Install pgp if your system does not have it already. Windows users likely have to install something and Linux users likely do not.
* Gnupg4win (https://www.gnupg.org/download/)

Create the keys:

```sh
$ gpg --gen-key
```

Follow the prompts keeping in mind the notes below.
* Type 1 (RSA) or Type 2 (DSA) should be fine.
* I chose a size of 2048.
* You can set an expiration if you'd like, but you probably shouldn't unless you really enjoy following these steps.
* **DO NOT** set a password. Hit enter to leave the password prompts blank and accept all related warnings.

View the keys you created. The one listed as "sec" is the private key and the other is the public key.

```sh
$ gpg --list-secret-keys

sec   2048R/7049EF5F 2017-03-30
uid                  pulse <pulse@ainq.com>
ssb   2048R/F68178C3 2017-03-30
```

Export the keys in a readable format.

```sh
gpg -a --export F68178C3 > public.key
gpg -a --export-secret-keys 7049EF5F > private.key
```

## Add the public and private keys as data that will be returned by a database function in Postgres

Add the functions below to a file named `keys.sql` in the root directory of the project. That file will be executed during the reset process to add the functions to both the pulse and pulse_test databases, but not stored in git

Open the public.key file and copy its contents into a function like the one below.

```sql
CREATE OR REPLACE FUNCTION pulse.public_key() RETURNS text as $$
	BEGIN
		RETURN '-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2

allthestuff
inthekey
-----END PGP PUBLIC KEY BLOCK-----';
	END
$$ LANGUAGE plpgsql;
```

Open the private.key file and copy its contents into a function like the one below.

```sql
CREATE OR REPLACE FUNCTION pulse.private_key() RETURNS text as $$
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

Reset the database with `reset.sh` and verify the functions work correctly by running `psql` and executing the below SQL commands

```sql
select * from public_key();
select * from private_key();
```
