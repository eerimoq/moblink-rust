mod protocol;
mod relay;

use clap::Parser;
use env_logger;
use log::info;
use std::env;
use std::sync::Arc;
use tokio::sync::Mutex;

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
struct Args {
    /// Relay ID
    #[arg(short = 'i', long)]
    relay_id: String,

    /// Streamer URL (websocket)
    #[arg(short = 'u', long)]
    streamer_url: String,

    /// Password
    #[arg(short, long)]
    password: String,

    /// Name to identify the relay
    #[arg(short, long, default_value = "Relay")]
    name: String,
}

#[tokio::main]
async fn main() {
    env::set_var("RUST_LOG", "debug"); // Set log level to info, you might want "debug" for development
    env_logger::init();

    let args = Args::parse();

    // Wrap the Relay instance in Arc<Mutex>
    let relay = Arc::new(Mutex::new(relay::Relay::new()));

    // Call setup on the wrapped Relay
    {
        let mut relay_lock = relay.lock().await;
        relay_lock
            .setup(
                args.relay_id,
                args.streamer_url,
                args.password,
                args.name,
                move |status| {
                    info!("Status updated: {}", status);
                },
                move |callback| {
                    // Simulate getting the battery percentage
                    let battery_percentage = 75; // Replace with actual battery percentage retrieval
                    callback(battery_percentage);
                },
            )
            .await;
    }

    // Start the relay
    relay::Relay::start(relay.clone()).await;

    // Keep the main thread alive
    loop {
        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
    }
}
