use actix_web::{Responder, HttpResponse, web::Data, http::header};
use log::debug;
use prometheus::TextEncoder;

use crate::application::telemetry::Metrics;

pub async fn health_check() -> impl Responder {
    debug!("Health check: I'm ok");
    HttpResponse::Ok().body("Hello, I'm ok!!")
}

pub async fn metrics(metrics: Data<Metrics>) -> impl Responder {
    debug!("Metrics request");
    let encoder = TextEncoder::new();
    let response = encoder.encode_to_string(&metrics.registry.gather()).unwrap();
    HttpResponse::Ok()
        .insert_header(header::ContentType(mime::TEXT_PLAIN))
        .body(response)
}

