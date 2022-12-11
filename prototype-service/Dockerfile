FROM rust:1.65.0 AS builder
COPY . .
RUN cargo build --release

FROM debian:buster-slim
COPY --from=builder ./config ./etc/prototype-service
COPY --from=builder ./target/release/prototype-service ./opt/prototype-service/app
CMD ["/opt/prototype-service/app"]