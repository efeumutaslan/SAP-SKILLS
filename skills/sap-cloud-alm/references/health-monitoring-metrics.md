# SAP Cloud ALM — Health Monitoring Metrics Reference

## BTP Application Metrics

| Metric | Description | Warning | Critical |
|--------|-------------|---------|----------|
| `app.cpu.usage` | CPU utilization % | >70% | >90% |
| `app.memory.usage` | Memory utilization % | >75% | >90% |
| `app.disk.usage` | Disk utilization % | >80% | >95% |
| `app.requests.count` | Request count/min | Context-based | Context-based |
| `app.requests.error_rate` | Error rate % | >5% | >15% |
| `app.requests.avg_time` | Avg response time ms | >2000 | >5000 |
| `app.instances.running` | Running instances | <desired | 0 |

## HANA Cloud Metrics

| Metric | Description | Warning | Critical |
|--------|-------------|---------|----------|
| `hana.memory.used_pct` | Memory usage % | >80% | >90% |
| `hana.cpu.usage` | CPU utilization % | >70% | >85% |
| `hana.disk.used_pct` | Disk usage % | >75% | >90% |
| `hana.connections.active` | Active connections | >80% of max | >95% of max |
| `hana.alerts.current` | Open alerts count | >0 | >5 |
| `hana.backup.age_hours` | Hours since last backup | >25 | >49 |
| `hana.replication.delay` | Replication delay sec | >60 | >300 |

## S/4HANA (Managed Gateway) Metrics

| Metric | Description | Warning | Critical |
|--------|-------------|---------|----------|
| `s4.work_processes.dialog_free` | Free dialog WPs | <30% | <10% |
| `s4.work_processes.update_free` | Free update WPs | <30% | <10% |
| `s4.spool.requests` | Pending spool requests | >1000 | >5000 |
| `s4.dumps.count` | Short dumps/hour | >10 | >50 |
| `s4.batch_jobs.failed` | Failed batch jobs | >5 | >20 |
| `s4.locks.entries` | Enqueue lock entries | >70% of table | >90% |
| `s4.idoc.errors` | IDoc errors | >10 | >100 |
| `s4.transport.stuck` | Stuck transports | >0 | >5 |

## Integration Suite Metrics

| Metric | Description | Warning | Critical |
|--------|-------------|---------|----------|
| `cpi.messages.failed` | Failed messages/hour | >10 | >50 |
| `cpi.messages.retry` | Messages in retry | >20 | >100 |
| `cpi.certificate.expiry_days` | Days to cert expiry | <30 | <7 |
| `cpi.runtime.memory` | JVM memory usage % | >75% | >90% |

## Real User Monitoring (RUM) Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| `rum.page_load.avg` | Avg page load time | <3s |
| `rum.first_paint` | First contentful paint | <1.5s |
| `rum.dom_interactive` | DOM interactive time | <2s |
| `rum.js_errors.rate` | JS errors per session | <0.5% |
| `rum.ajax.avg_time` | Avg AJAX response time | <1s |
| `rum.bounce_rate` | Single-page sessions | <40% |

## Alert Configuration (JSON)

```json
{
  "alertRule": {
    "name": "High Memory Usage",
    "metric": "app.memory.usage",
    "condition": {
      "operator": "GREATER_THAN",
      "threshold": 85,
      "duration": "5m"
    },
    "severity": "WARNING",
    "notifications": [
      { "type": "EMAIL", "recipients": ["ops-team@company.com"] },
      { "type": "WEBHOOK", "url": "https://hooks.slack.com/services/xxx" }
    ]
  }
}
```

## Business Process Monitoring

| Check Type | Example | Frequency |
|-----------|---------|-----------|
| Data consistency | Order count matches between systems | Hourly |
| Process completion | All invoices posted by EOD | Daily |
| SLA compliance | PO approval within 2 business days | Real-time |
| Interface status | All IDocs processed successfully | Every 15 min |
| Batch job completion | MRP run finished before cutoff | Daily |
