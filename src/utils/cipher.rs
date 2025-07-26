use base64::{engine::general_purpose::STANDARD as BASE64, Engine as _};
use x25519_dalek::{PublicKey, StaticSecret};

pub fn x25519_keypair() -> Result<(String, String), String> {
    let private = StaticSecret::random();
    let public = PublicKey::from(&private);
    
    let private_bytes = private.to_bytes();
    let public_bytes = public.to_bytes();

    let private_key = BASE64.encode(private_bytes);
    let public_key = BASE64.encode(public_bytes);

    Ok((private_key, public_key))
}