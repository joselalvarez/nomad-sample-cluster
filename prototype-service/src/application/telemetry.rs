use prometheus::{Registry, Opts, Counter, core::{GenericCounter, AtomicF64}, Histogram, HistogramOpts};

pub static METRICS_NAMESPACE: &str = "prototype_service";

pub struct Metrics {
    pub registry : Registry,
    pub echo_counter : GenericCounter<AtomicF64>,
    pub echo_traffic : Histogram
}



pub fn init() -> Metrics {
    
    let registry = Registry::new();

    let echo_counter_opts = Opts::new(format!("{}_echo_request_count", METRICS_NAMESPACE), "echo request count");
    let echo_counter = Counter::with_opts(echo_counter_opts).unwrap();
    registry.register(Box::new(echo_counter.clone())).unwrap();

    let echo_traffic_opts = HistogramOpts::new(format!("{}_echo_traffic_size", METRICS_NAMESPACE), "echo traffic size");
    let echo_traffic = Histogram::with_opts(echo_traffic_opts).unwrap();
    registry.register(Box::new(echo_traffic.clone())).unwrap();

    Metrics {
        registry,
        echo_counter,
        echo_traffic
    }
}

