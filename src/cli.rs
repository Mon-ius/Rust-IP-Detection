use clap::Parser;

#[cfg(all(target_env = "musl", target_pointer_width = "64", not(any(target_arch = "powerpc64", target_arch = "powerpc"))))]
use jemallocator::Jemalloc;

#[cfg(any(not(all(target_env = "musl")), any(target_arch = "powerpc64", target_arch = "powerpc")))]
use mimalloc::MiMalloc;

#[cfg(all(target_env = "musl", target_pointer_width = "64", not(any(target_arch = "powerpc64", target_arch = "powerpc"))))]
#[global_allocator]
static GLOBAL: Jemalloc = Jemalloc;

#[cfg(any(not(all(target_env = "musl")), any(target_arch = "powerpc64", target_arch = "powerpc")))]
#[global_allocator]
static GLOBAL: MiMalloc = MiMalloc;

#[derive(Parser)]
#[command(about = "The Rust-IP-Detection Project service cli")]
struct Cli {
    #[arg(short = 'p', long, name = "PORT", help = "Listen port")]
    port: Option<u16>,
    #[arg(short = 'c', long = "cloudflare", name = "CLOUDFLARE",help = "The CloudFlare Secret Key")]
    cloudflare: Option<String>,
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let start_time = std::time::Instant::now();

    {
        let cli = Cli::parse();
        let _ = ld_::interface(
            cli.port,
            cli.cloudflare
        );
    }

    println!("Processing time: {:?}", start_time.elapsed());
    Ok(())
}