local hrm = import './http-request-metrics.jsonnet';
local jvm = import './jvm-metrics.jsonnet';
local kpm = import './kubernetes-pod-metrics.jsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local coveo = import './coveo.jsonnet';

grafana.dashboard.new(
  'Front50',
  editable=true,
  time_from='now-15m',
  tags=['spinnaker'],
  uid='spinnaker-front50',
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
      url='https://github.com/spinnaker/front50',
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
    query='front50',
    current='front50',
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
      content='Front50 is the system of record for all Spinnaker metadata, including: application, pipeline and service account configurations.\n\nAll metadata is durably stored and served out of an in-memory cache.',
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
      title='Resilience4J Open (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{job=~"$job", state=~".*open", environment=~"$environment",region=~"$region",instance=~"$Instance"}) by (name)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Failure Rate (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(resilience4j_circuitbreaker_failure_rate{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (name)',
        legendFormat='{{ name }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Half-Open (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{job=~"$job", state="half_open", environment=~"$environment",region=~"$region",instance=~"$Instance"}) by (name)',
        legendFormat='{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Cache Refreshes / Minute  (negative are scheduled) (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(storageServiceSupport_autoRefreshTime_seconds_sum{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='force/{{objectType}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        '-1 * (sum(rate(storageServiceSupport_scheduledRefreshTime_seconds_sum{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (objectType))',
        legendFormat='{{objectType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Size (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(storageServiceSupport_cacheSize{environment=~"$environment",region=~"$region",instance=~"$Instance"}) by (objectType)',
        legendFormat='{{objectType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Adds (+) and Removes (-) (front50, $Instance)',
      aliasColors={
        'del APPLICATION': '#7EB26D',
        'del APPLICATION_PERMISSION': '#EAB839',
        'del NOTIFICATION': '#6ED0E0',
        'del PIPELINE': '#EF843C',
        'del PROJECT': '#E24D42',
        'del SERVICE_ACCOUNT': '#1F78C1',
        'del SNAPSHOT': '#BA43A9',
        'del STRATEGY': '#705DA0',
      },
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(storageServiceSupport_numAdded_total{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='add {{objectType}}',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        '-1 * sum(rate(storageServiceSupport_numRemoved_total{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='del {{objectType}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Service Invocations (front50, $Instance)',
      description='TODO: Swap for relevant SQL metrics?',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__count_total{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (method)',
        legendFormat='{{method}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Updates (front50, $Instance)',
      description='TODO: Swap for relevant SQL metrics?',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(storageServiceSupport_numUpdated_total{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (objectType)',
        legendFormat='{{objectType}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Google Storage Service Invocation Latency (front50, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(front50:google:storage:invocation__totalTime_total{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (method) / sum(rate(front50:google:storage:invocation__count_total{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (method)',
        legendFormat='{{method}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Item Cache Age (front50, $Instance)',
      datasource='$datasource',
      span=3,
      format='dtdurationms',
    )
    .addTarget(
      grafana.prometheus.target(
        'avg by (objectType) (storageServiceSupport_cacheAge{environment=~"$environment",region=~"$region",instance=~"$Instance"})',
        legendFormat='{{objectType}}',
      )
    )
  )
)

.addRow(hrm)

.addRow(jvm)

.addRow(kpm)
