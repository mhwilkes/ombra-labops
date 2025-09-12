# Observability Stack (Lean Phase 1)

Components targeted for initial deployment in the `observability` namespace:

* Grafana (dashboards / unified UI)
* Mimir (metrics backend via Prometheus-compatible remote write)
* Loki (logs aggregation)
* Tempo (traces storage)
* Grafana Alloy (unified agent: replaces separate OpenTelemetry Collector + partial promtail functionality)
* Promtail (as requested; can be removed later if Alloy fully adopted for logs)
* kube-state-metrics (Kubernetes object metrics)
* node-exporter (node / hardware metrics)

## Rationale

A minimal yet full-spectrum (metrics + logs + traces) stack without alerting or advanced SLO/profiling features.

## Data Flow (Initial)

Workload containers -> (stdout) -> Promtail & Alloy -> Loki  
Workload instrumentation (future OTLP) -> Alloy -> Tempo (traces)  
Node / K8s metrics -> node-exporter / kube-state-metrics -> (scraped by Alloy Prometheus receiver) -> remote write -> Mimir  
Dashboards -> Grafana querying Mimir, Loki, Tempo

## Next Steps

Add Argo CD Application manifests (`observability.yaml`) at infrastructure root referencing Helm charts with opinionated values (storage, retention, resource sizing) and optionally object storage integration later.

## Notes

Promtail and Alloy will both send logs initially (duplication). Remove Promtail after validating Alloy log pipeline if desired.

