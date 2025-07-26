mod utils;

use actix_web::{web, App, HttpRequest, HttpServer, Responder};
use serde::Serialize;

#[derive(Clone, Serialize)]
struct AppConfig {
    port: u16,
    cloudflare: String,
}

#[derive(Serialize)]
struct IpInfo {
    cf_conn_ip: Option<String>, 
    conn_real_ip: Option<String>,
    forwarded_for: Vec<String>,
    x_real_ip: Option<String>,
    remote_addr: Option<String>,
    peer_addr: Option<String>,
}

fn get_all_ips(req: &HttpRequest, _config: &AppConfig) -> IpInfo {
    let cf_conn_ip = req
        .headers()
        .get("CF-Connecting-IP")
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string());

    let conn_real_ip = req
        .connection_info()
        .realip_remote_addr()
        .map(|addr| addr.to_string());

    let forwarded_for = req
        .headers()
        .get("X-Forwarded-For")
        .and_then(|h| h.to_str().ok())
        .map(|s| {
            s.split(',')
                .map(|ip| ip.trim().to_string())
                .collect::<Vec<String>>()
        })
        .unwrap_or_default();

    let x_real_ip = req
        .headers()
        .get("X-Real-IP")
        .and_then(|h| h.to_str().ok())
        .map(|s| s.to_string());

    let remote_addr = req
        .peer_addr()
        .map(|addr| addr.to_string());

    let peer_addr = req
        .peer_addr()
        .map(|addr| addr.ip().to_string());

    println!("{:#?}", req.headers());

    IpInfo {
        cf_conn_ip,
        conn_real_ip,
        forwarded_for,
        x_real_ip,
        remote_addr,
        peer_addr,
    }
}

async fn get_ips(req: HttpRequest, config: web::Data<AppConfig>) -> impl Responder {
    let ip_info = get_all_ips(&req, &config);
    web::Json(ip_info)
}

async fn get_ed25519_pub() -> Result<impl Responder, actix_web::Error> {
    let (_private_key, public_key) = utils::x25519_keypair()
        .map_err(|_| actix_web::error::ErrorBadRequest("Failed to generate keypair"))?;

    let response = serde_json::json!({
        "key": public_key
    });

    Ok(web::Json(response))
}


async fn actix(
    port: u16,
    cloudflare: String,
) -> Result<(), Box<dyn std::error::Error>> {
    let app_config = web::Data::new(AppConfig {
        port,
        cloudflare
    });

    HttpServer::new(move || {
        App::new()
            .app_data(app_config.clone())
            .route("/", web::get().to(get_ips))
            .route("/v1/ed25519.pub", web::get().to(get_ed25519_pub)
        )
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await?;

    Ok(())
}

pub fn interface(
    _port: Option<u16>,
    _cloudflare: Option<String>
) -> Result<(), Box<dyn std::error::Error>> {
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()?;

    let port = _port.unwrap_or(8080);
    let cloudflare = _cloudflare.unwrap_or_else(|| "ZXhhbXBsZV9jbG91ZGZsYXJlX2FjY291bnRfdG9rZW4=".to_string());

    println!("* [Debug] {}", port);
    println!("* [Debug] {}", cloudflare);

    let _ = rt.block_on(actix(port, cloudflare));
    Ok(())
}