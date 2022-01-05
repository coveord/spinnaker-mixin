local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local coveo = import './coveo.jsonnet';

grafana.dashboard.new(
  'Spinnaker Application Details',
  editable=true,
  refresh='15m',
  time_from='now-15m',
  tags=['spinnaker'],
  uid='spinnaker-application-details',
  timepicker=coveo.timepicker
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
  grafana.template.new(
    name='Application',
    datasource='$datasource',
    query='label_values(stage_invocations_total{spinSvc=".*orca.*"}, application)',
    allValues='.*',
    current='All',
    refresh=2,
    includeAll=true,
    multi=true,
    sort=1,
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

.addRow(
  grafana.row.new()
  .addPanel(
    grafana.graphPanel.new(
      title='Active Stages by Application (orca, $Application)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(stage_invocations_total{spinSvc=~".*orca.*", application=~"$Application"}[$__interval])) by (application, type)',
        legendFormat='{{application}}/{{type}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='$Application Pipelines Triggered (echo, $Application)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(pipelines_triggered_total{spinSvc=~".*echo.*", application=~"$Application", environment=~"$environment",region=~"$region"}[$__interval])) by (application)',
        legendFormat='{{application}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Bakes Active and Requested (rosco)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(bakesActive{spinSvc=~".*rosco.*", environment=~"$environment",region=~"$region"})',
        legendFormat='Active',
      )
    )

    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesRequested_total{spinSvc=~".*rosco.*", environment=~"$environment",region=~"$region"}[$__interval])) by (flavor)',
        legendFormat='Request({{flavor}})',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Bake Failure Rate (rosco)',
      datasource='$datasource',
      span=3,
      min=0,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{spinSvc=~".*rosco.*",success="false", environment=~"$environment",region=~"$region"}[$__interval])) by (cause, region)',
        legendFormat='{{cause}}/{{region}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Bake Succees Rate (rosco)',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(rate(bakesCompleted_seconds_count{spinSvc=~".*rosco.*",success="true", environment=~"$environment",region=~"$region"}[$__interval])) by (region)',
        legendFormat='{{region}}',
      )
    )
  )

  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Open',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{state=~".*open", environment=~"$environment",region=~"$region"}) by (name, spinSvc)',
        legendFormat='{{spinSvc}}-{{name}}',
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
        'sum(rate(resilience4j_circuitbreaker_failure_rate{environment=~"$environment",region=~"$region"}[$__interval])) by (name, spinSvc)',
        legendFormat='{{spinSvc}}-{{name}}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Resilience4J Half-Open',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(resilience4j_circuitbreaker_state{state="half_open", environment=~"$environment",region=~"$region"}) by (name, spinSvc)',
        legendFormat='{{spinSvc}}-{{name}}',
      )
    )
  )
)
