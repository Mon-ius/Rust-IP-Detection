use clap::Parser;

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