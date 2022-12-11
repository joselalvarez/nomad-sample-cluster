use std::{env};
use config::{Config, File, ConfigError, FileFormat, Environment};
use serde_derive::Deserialize;

pub static APP_NAME: &str = "prototype-service";

#[derive(Debug, Deserialize)]
#[allow(unused)]
pub struct App {
    pub addr: String,
    pub port: u16
}

#[derive(Debug, Deserialize)]
#[allow(unused)]
pub struct Settings {
    pub app: App
}

pub fn init() -> Result<Settings, ConfigError> {
    let app_config = env::var(format!("{}-json-config", APP_NAME)).unwrap_or_else(|_| "{}".into());
    Config::builder()
        .add_source(File::with_name("config/application.toml").required(false))
        .add_source(File::with_name("config/local.toml").required(false))
        .add_source(File::with_name(&format!("/etc/{}/application.toml", APP_NAME)).required(false))
        .add_source(File::with_name(&format!("/etc/{}/config.toml", APP_NAME)).required(false))
        .add_source(File::from_str(&app_config, FileFormat::Json).required(false))
        .add_source(Environment::with_prefix(&format!("{}-config",APP_NAME)).try_parsing(true).separator("-"))
    .build()?.try_deserialize()
}