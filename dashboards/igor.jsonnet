local hrm = import './http-request-metrics.jsonnet';
local jvm = import './jvm-metrics.jsonnet';
local kpm = import './kubernetes-pod-metrics.jsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local coveo = import './coveo.jsonnet';

grafana.dashboard.new(
  'Igor',
  editable=true,
  refresh='15m',
  time_from='now-15m',
  tags=['spinnaker'],
  uid='spinnaker-igor',
  timepicker=coveo.timepicker
)

// Links

.addLinks(
  [
    grafana.link.dashboards(
      icon='info',
      tags=[],
      title='GitHub',
      type='link',
      url='https://github.com/spinnaker/igor',
    ),
  ]
)

// Templates

.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  )
)
.addTemplate(
  grafana.template.custom(
    name='spinSvc',
    query='igor',
    current='igor',
    hide=2,
  )
)
.addTemplate(
  grafana.template.new(
    name='job',
    datasource='$datasource',
    query='label_values(up{job=~".*$spinSvc.*"}, job)',
    current='All',
    refresh=1,
    includeAll=true,
  )
)
.addTemplate(
  grafana.template.new(
    name='environment',
    label='Environment',
    datasource='$datasource',
    query='label_values(container_cpu_usage_seconds_total, environment)',
    allValues='.*',
    current='All',
    refresh=1,
    includeAll=true,
    sort=1,
  )
)
.addTemplate(
  grafana.template.new(
    name='region',
    label='Region',
    datasource='$datasource',
    query='label_values(container_cpu_usage_seconds_total{environment=~"$environment"}, region)',
    allValues='.*',
    current='All',
    refresh=1,
    includeAll=true,
    sort=1,
  )
)
.addTemplate(
  grafana.template.new(
    name='Instance',
    datasource='$datasource',
    query='label_values(up{job=~"$job",environment=~"$environment",region=~"$region"}, instance)',
    allValues='.*',
    current='All',
    refresh=1,
    includeAll=true,
    multi=true,
    sort=1,
  )
)

.addRow(
  grafana.row.new(
    title='Key Metrics',
  )
  .addPanel(
    grafana.text.new(
      title='Service Description',
      content='Igor is a service that provides a single point of integration with Continuous Integration (CI) and Source Control Management (SCM) services for Spinnaker.',
      span=3,
    )
  )
)

.addRow(
  grafana.row.new(
    title='Additional Metrics',
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Open',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (name) (\n  max_over_time(resilience4j_circuitbreaker_state{job=~"$job", state=~".*open", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Failure Rate',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (name) (\n  rate(resilience4j_circuitbreaker_failure_rate{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Half-Open',
      description='The requests/s for Poll Monitor invocations.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (name) (\n  max_over_time(resilience4j_circuitbreaker_state{job="$job", state="half_open", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Poll Monitor req/s',
      description='The requests/s for Poll Monitor invocations.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor) (\n  rate(pollingMonitor_pollTiming_seconds_count{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{monitor}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Poll Monitor Latency',
      description='Failed Poll requests per sec by monitor and partition.',
      datasource='$datasource',
      span=3,
      format='dtdurations',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor) (rate(pollingMonitor_pollTiming_seconds_sum{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))\n/\nsum by (monitor) (rate(pollingMonitor_pollTiming_seconds_count{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval]))',
        legendFormat='{{monitor}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Failed Polls',
      description='The requests/s to retrieve docker images by account. This triggers the pipelines.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor, partition) (\n  rate(pollingMonitor_failed_total{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{monitor}} / {{partition}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Docker Images Retrieved',
      description="This gauge tracks the circuit breaker (threshold) for new items (docker, etc).\n\nGenerally the value should always be null or 0.\n\nA positive value indicates the threshold has been exceeded and the circuit breaker tripped. This means Igor will no longer notify Echo of new items and pipelines won't be triggered.\n\nThe circuit breaker can be reset by performing a 'fast-forward' or adjusting the the threshold item limit value and redeploying Igor.\n\nThe threshold can be exceeded due to loss of cache (abnormal) or large influx of new items.",
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (account) (\n  rate(pollingMonitor_docker_retrieveImagesByAccount_seconds_count{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{account}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Items over Threshold',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (monitor, partition) (\n  max_over_time(pollingMonitor_itemsOverThreshold{job="$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])\n)',
        legendFormat='{{ monitor }} / {{ partition }}',
      )
    )
  )
)

.addRow(hrm)

.addRow(jvm)

.addRow(kpm)
