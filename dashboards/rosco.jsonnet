local hrm = import './http-request-metrics.jsonnet';
local jvm = import './jvm-metrics.jsonnet';
local kpm = import './kubernetes-pod-metrics.jsonnet';
local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local coveo = import './coveo.jsonnet';

grafana.dashboard.new(
  'Rosco',
  editable=true,
  time_from='now-15m',
  tags=['spinnaker'],
  uid='spinnaker-rosco',
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
      url='https://github.com/spinnaker/rosco',
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
    query='rosco',
    current='rosco',
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
      content="Rosco is Spinnaker's bakery, producing machine images with Hashicorp Packer and rendered manifests with templating engines Helm and Kustomize.",
      span=6,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Bakes (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(bakesActive{environment=~"$environment",region=~"$region",instance=~"$Instance"}) by (instance)',
        legendFormat='Active/{{instance}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Request Rate (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesRequested_total{environment=~"$environment",region=~"$region",instance=~"$Instance"}[$__interval])) by (flavor)',
        legendFormat='{{flavor}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Failure Rate (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{environment=~"$environment",region=~"$region",instance=~"$Instance",success="false"}[$__interval])) by (cause, region)',
        legendFormat='{{cause}}/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Succees Rate (rosco, $Instance)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{environment=~"$environment",region=~"$region",instance=~"$Instance",success="true"}[$__interval])) by (region)',
        legendFormat='/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Failure Duration (rosco, $Instance)',
      datasource='$datasource',
      span=3,
      format='dtdurations',
      nullPointMode='null as zero',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_sum{environment=~"$environment",region=~"$region",instance=~"$Instance",success="false"}[$__interval])) by (cause,region)\n/\nsum(rate(bakesCompleted_seconds_count{environment=~"$environment",region=~"$region",instance=~"$Instance",success="false"}[$__interval])) by (cause,region)',
        legendFormat='{{cause}}/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Success Duration (rosco, $Instance)',
      datasource='$datasource',
      span=3,
      format='dtdurations',
      nullPointMode='null as zero',
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_sum{environment=~"$environment",region=~"$region",instance=~"$Instance",success="true"}[$__interval])) by (region)\n/\nsum(rate(bakesCompleted_seconds_count{environment=~"$environment",region=~"$region",instance=~"$Instance",success="true"}[$__interval])) by (region)',
        legendFormat='{{region}}',
      )
    )
  )
)

.addRow(hrm)

.addRow(jvm)

.addRow(kpm)
