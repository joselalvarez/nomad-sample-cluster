
use actix_web::{self, HttpServer, App, web::{self, Data}/* , middleware::Logger*/};

mod application;
mod api;

#[actix_web::main]
async fn main() -> std::io::Result<()> {

    application::logger::init();

    let settings = application::config::init().unwrap();
    
    let addr = String::from(&settings.app.addr);
    let port = settings.app.port;

    let settings_data = Data::new(settings);
    let metrics_data = Data::new(application::telemetry::init());

    HttpServer::new(move || {
        App::new()
           // .wrap(Logger::default())
            .route("/health", web::get().to(api::telemetry::health_check))
            .route("/metrics", web::get().to(api::telemetry::metrics))
            .route("/echo", web::post().to(api::echo::call))
            .app_data(web::Data::clone(&settings_data))
            .app_data(web::Data::clone(&metrics_data))
    })
    .bind((addr, port))?
    .run()
    .await
}