use actix_web::{web::Data, Responder, HttpResponse};
use log::info;

use crate::application::telemetry::Metrics;


pub async fn call(body: String, metrics: Data<Metrics>) -> impl Responder {
    info!("echo request: {}", body);
    metrics.echo_counter.inc();
    metrics.echo_traffic.observe(body.len() as f64);
    HttpResponse::Ok().body(body)
}