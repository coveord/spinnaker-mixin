local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.row.new(
  title='HTTP Metrics',
)
.addPanel(
  grafana.graphPanel.new(
    title='Inbound Request Rate by Method',
    description='Inbound HTTP requests. \n\n`controller_invocations_total` is an enhanced version of Spring `http_server_requests_seconds_count` with additional labels.',
    datasource='$datasource',
    span=4,
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (controller, method) (rate(controller_invocations_total{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))',
      legendFormat='{{controller}}/{{method}}',
    )
  )
)

.addPanel(
  grafana.graphPanel.new(
    title='Inbound Request Latency by Method',
    description='Inbound HTTP request latencies. \n\n`controller_invocations_total` is an enhanced version of Spring `http_server_requests_seconds_count` with additional labels.',
    datasource='$datasource',
    span=4,
    format='dtdurations',
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (controller, method) (rate(controller_invocations_seconds_sum{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))\n / \n sum by (controller, method) (rate(controller_invocations_total{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))',
      legendFormat='{{controller}}/{{method}}',
    )
  )
)

.addPanel(
  grafana.graphPanel.new(
    title='Inbound Request Errors by Method',
    description='Inbound HTTP request errors. \n\n`controller_invocations_total` is an enhanced version of Spring `http_server_requests_seconds_count` with additional labels.',
    datasource='$datasource',
    span=4,
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (statusCode, cause, controller, method) (rate(controller_invocations_total{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance", status="5xx"}[$__interval]))',
      legendFormat='{{statusCode}}/{{cause}}/{{controller}}/{{method}}',
    )
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (statusCode, cause, controller, method) (rate(controller_invocations_total{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance", statusCode="429"}[$__interval]))',
      legendFormat='{{statusCode}}/{{cause}}/{{controller}}/{{method}}',
    )
  )
)

.addPanel(
  grafana.graphPanel.new(
    title='Outbound Request Rate',
    description='Rate of outbound http requests to other Spinnaker services.',
    datasource='$datasource',
    span=4,
    fill=0,
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (requestHost) (rate(okhttp_requests_seconds_count{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))',
      legendFormat='{{requestHost}}',
      interval='1m',
    )
  )
)
.addPanel(
  grafana.graphPanel.new(
    title='Outbound Request Latency',
    description='Latency of outbound http requests to other Spinnaker services.',
    datasource='$datasource',
    span=4,
    fill=0,
    format='dtdurations',
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (requestHost) (rate(okhttp_requests_seconds_sum{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))\n / \n sum by (requestHost) (rate(okhttp_requests_seconds_count{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))',
      legendFormat='{{requestHost}}',
      interval='1m',
    )
  )
)
.addPanel(
  grafana.graphPanel.new(
    title='Outbound Request Error Rate',
    description='Rate of outbound http request errors when calling other Spinnaker services. \n\nCheck the logs looking for `retrofit error` or `<--- 500`',
    datasource='$datasource',
    span=4,
    fill=0,
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (requestHost, statusCode) (rate(okhttp_requests_seconds_count{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance", status=~"(5xx|Unknown)"}[$__interval]))',
      legendFormat='{{statusCode}}/{{status}}/{{requestHost}}',
      interval='1m',
    )
  )
  .addTarget(
    grafana.prometheus.target(
      'sum by (requestHost, statusCode) (rate(okhttp_requests_seconds_count{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance", statusCode="429"}[$__interval]))',
      legendFormat='{{statusCode}}/{{requestHost}}',
      interval='1m',
    )
  )
)
