local hrm = import './http-request-metrics.jsonnet';
local jvm = import './jvm-metrics.jsonnet';
local kpm = import './kubernetes-pod-metrics.jsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local coveo = import './coveo.jsonnet';

grafana.dashboard.new(
  'Echo',
  editable=true,
  time_from='now-15m',
  tags=['spinnaker'],
  uid='spinnaker-echo',
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
      url='https://github.com/spinnaker/echo',
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
    query='echo',
    current='echo',
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
      content='Echo serves as two purposes within Spinnaker:\n\n1. a router for events\n   - incoming events, for example a new build is detected by Igor which should trigger a pipeline.\n   - outgoing events such as notifications via email, Slack, etc\n2. a scheduler for CRON triggered pipelines.',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Pipelines Triggered (echo, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(pipelines_triggered_total{job=~"$job", environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (application)',
        legendFormat='{{application}}',
      )
    )
  )
)

.addRow(hrm)

.addRow(jvm)

.addRow(kpm)
