local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';

grafana.dashboard.new(
  'Spinnaker Key Metrics',
  editable=true,
  refresh='1m',
  time_from='now-1h',
  tags=['spinnaker'],
  uid='spinnaker-key-metrics',
)

// Templates

.addTemplate(
  grafana.template.datasource(
    'datasource',
    'prometheus',
    '',
  )
)

.addRow(
  grafana.row.new(
    title='Monitoring Spinnaker, SLA Metrics',
  )
  .addPanel(
    grafana.text.new(
      title='Monitoring Spinnaker, SLA Metrics',
      content='\n# Monitoring Spinnaker, SLA Metrics\n\n[Medium blog by Rob Zienert](https://blog.spinnaker.io/monitoring-spinnaker-sla-metrics-a408754f6b7b)\n\n> What are the key metrics we can track that help quickly answer the question, "Is Spinnaker healthy?"',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Rate of Echo Triggers & Processed Events',
      datasource='$datasource',
      description='echo.triggers.count tracks the number of CRON-triggered pipeline executions fired. \n\nThis value should be pretty steady, so any significant deviation is an indicator of something going awry (or the addition/retirement of a customer integration).\n\n\necho.pubsub.messagesProcessed is important if you have any PubSub triggers. \n\nYour mileage may vary, but Netflix can alert if any subscriptions drop to zero for more than a few minutes.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(echo_triggers_count[$__interval])\n)',
        legendFormat='triggers/s',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(echo_events_processed_total[$__interval])\n)',
        legendFormat='events processed/s',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Igor',
      description='pollingMonitor.failed tracks the failure rate of CI/SCM monitor poll cycles. \n\nAny value above 0 is a bad place to be, but is often a result of downstream service availability issues such as Jenkins going offline for maintenance.\n\npollingMonitor.itemsOverThreshold tracks a polling monitor circuit breaker. \n\nAny value over 0 is a bad time, because it means the breaker is open for a particular monitor and it requires manual intervention.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (partition) (\n  pollingMonitor_newItems\n)',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (partition) (\n  pollingMonitor_failed_total\n)',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (partition) (\n  pollingMonitor_itemsOverThreshold\n)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocations Rate',
      description="All Spinnaker services are RPC-based, and as such, the reliability of requests inbound and outbound are supremely important: If the services can’t talk to each other reliably, someone will be having a poor experience.\n\n\nTODO: Add Recording Rules so don't melt Prometheus",
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (container, status) (\n  rate(controller_invocations_total[$__interval])\n )',
        legendFormat='{{ status }} :: {{ container }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='HTTP RPC Rate',
      datasource='$datasource',
      description='Each service emits metrics for each RPC client that is configured via okhttp.requests.\n\nHaving SLOs — and consequentially, alerts — around failure rate (determined via the succcess tag) and latency for both inbound and outbound RPC requests is, in my mind, mandatory across all Spinnaker services.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (container, requestHost, status) (\n  rate(okhttp_requests_seconds_count[$__interval])\n)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Clouddriver AWS Cache Drift',
      datasource='$datasource',
      description='cache.drift tracks cache freshness. \n\nYou should group this by agent and region to be granular on exactly what cache collection is falling behind. How much lag is acceptable for your org is up to you, but don’t make it zero.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'max by (account, agent, region) (cache_drift)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Caching Agent Failures',
      description='It’s OK that there are failures in agents: As stable as we like to think our cloud providers are, it’s still another software system and software will fail. \n\nUnless you see sustained failure, there’s not much to worry about here. \n\nThis is often an indicator of a downstream cloud provider issue.\n\nTODO: Confirm Metric Name',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Clouddriver Kubernetes / Other Provider Cache',
      description='TODO: Find metric names',
      span=3,
    )
  )
)

.addRow(
  grafana.row.new(
    title='Monitoring Spinnaker Part 1',
  )
  .addPanel(
    grafana.text.new(
      title='Monitoring Spinnaker Part 1',
      content='\n# Monitoring Spinnaker, Part 1\n\n[Medium blog by Rob Zienert](https://blog.spinnaker.io/monitoring-spinnaker-part-1-4847f42a3abd)\n',
      span=3,
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Active Executions',
      description='The primary domain model is an Execution, of which there are two types: PIPELINE and ORCHESTRATION. \n\nThe PIPELINE type is, you guessed it, for pipelines while ORCHESTRATION is what you see in the “Tasks” tab for an application. \n\nThis is really just good insight for answering the question of workload distribution. \n\nSince adding this metric, we’ve never seen it crater, but if that were to happen it’d be bad. \n\nFor Netflix, most ORCHESTRATION executions are API clients. \n\nDisregarding what the execution is doing, there’s no baseline cost difference between a running orchestration and a pipeline.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (executionType) (\n  executions_active{container="orca"}\n)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Controller Invocation Time',
      description='If you’ve got a lot of 500’s, check your logs. \n\nWhen we see a spike in either invocation times or 5xx errors, it’s usually one of two things: \n\n1) Clouddriver is having a bad day, \n\n2) Orca doesn’t have enough capacity in some respect to service people polling for pipeline status updates. \n\nYou’ll need to dig elsewhere to find the cause.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (controller, status) (\n  rate(controller_invocations_seconds_sum{container="orca"}[$__interval])\n) \n/\nsum by (controller, status) (\n  rate(controller_invocations_seconds_count{container="orca"}[$__interval])\n)\n',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Rate of Task Invocations',
      description='This will look similar to the first metric we looked at, but this is directly looking at our queue: \n\nThis is the number of Execution-related Messages that we’re invoking every second.\n\nIf this drops, it’s a sign that your QueueProcessor may be starting to freeze up.\n\nAt that point, check that the thread pool it’s on isn’t starved for threads.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (executionType) (\n  rate(task_invocations_duration_seconds_count{container="orca"}[$__interval])\n)',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Task Invocations by Application',
      description='This is handy to see who your biggest customers are, from a pure orchestration volume perspective. \n\nOften times, if we start to experience pain and see a large uptick in queue usage, it’ll be due to a large submission from one or two customers. \n\nIf we were having pain, we could bump our capacity, or look to adjust some rate limits.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum by (application, executionType) (\n  rate(\n    task_invocations_duration_seconds_count{container="orca", status="RUNNING"}[$__interval])\n) ',
        legendFormat='{{ application }} - {{ executionType }}',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Message Handler Executor Usage',
      datasource='$datasource',
      description='This is our thread pool for the Message Handlers.\n\n\nSpare capacity is good.\n\nActive is actual active usage.\n\nBlocking is when a thread is blocked. \n\nBlockingQueueSize is bad, especially "pollSkippedNoCapacity" should always block blockingQueueSize being changed from 0.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  threadpool_activeCount{container="orca"}\n)',
        legendFormat='Active',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  threadpool_blockingQueueSize{container="orca"}\n)',
        legendFormat='Blocking',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  threadpool_poolSize{container="orca"}\n)',
        legendFormat='Size',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Rate of Queue Messages Pushed / Acked (s)',
      description='If messages pushed is out pacing acked, you’re presently having a bad time. \n\nMost messages will complete in a blink of an eye, only RunTask will really take much time. \n\nIf you see an uptick in messages pushed, but not a correlating ack’d, it’s a good indicator you’ve got a downstream service issue that’s preventing message handlers completing: \n\nTake a look at Clouddriver, it probably wants your love and attention.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(queue_pushed_messages_total{container="orca"}[$__interval])\n)',
        legendFormat='Pushed',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(queue_acknowledged_messages_total{container="orca"}[$__interval])\n)',
        legendFormat="Ack'd",
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Queue Depth',
      description='Keiko supports setting a delivery time for messages, so you’ll always see queued messages outpacing in-process messages if your Spinnaker install is active.\n\nThings like wait tasks, execution windows, retries, and so-on all schedule message delivery in the future, and in-process messages are usually in-process for a handful of milliseconds.\n\nOperating Orca, one of your life mission is to keep ready messages at 0. \n\nA ready message is a message that has a delivery time of now or in the past, but it hasn’t been picked up and transitioned into processing yet: \n\nThis is a key contributor to a complaint of, “Spinnaker is slow.” \n\nAs I’ve mentioned before, Orca is horizontally scalable. \n\nGive Orca an adrenaline shot of instances if you see ready messages over 0 for more than two intervals so you can clear the queue out.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_depth{container="orca"}\n)',
        legendFormat='queued',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_ready_depth{container="orca"}\n)',
        legendFormat='ready',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\nqueue_unacked_depth{container="orca"}\n)',
        legendFormat='unacked',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Queue Errors',
      datasource='$datasource',
      description='Retried is a normal error condition by itself. \n\nDead-lettered occurs when a message has been retried a bunch of times and has never been successfully delivered.\n\nOrphaned messages are bad. \n\nThey’re messages whose message contents are in the queue, but do not have a pointer in either the queue set or unacked set. \n\nThis is a sign of an internal error, likely a troubling issue with Redis. \n\nIt “should never happen” if your system is healthy, and likewise “should never happen” even if your system is really, really overloaded. It’s worth a bug report.',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_retried_messages_total{container="orca"}\n)',
        legendFormat='retried',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  rate(queue_orphaned_messages{container="orca"}[$__interval])\n)',
        legendFormat='orphaned',
      )
    )
  )
  .addPanel(
    grafana.graphPanel.new(
      title='Message Lag',
      description='This is a measurement of a message’s desired delivery time and the actual delivery time: Smaller and tighter is better. This is a timer measurement of every message’s (usually very short) life in a ready state. When your queue gets backed up, this number will grow. \n\nWe consider this one of Orca’s key performance indicators.\n\nA mean message lag of anything under a few hundred milliseconds is fine. \n\nDon’t panic until you’re getting around a second. \n\nScale up, everything should be fine.',
      datasource='$datasource',
      span=3,
    )
    .addTarget(
      grafana.prometheus.target(
        'sum(\n  queue_message_lag_seconds_sum\n)\n/\nsum(\n  queue_message_lag_seconds_count\n)',
        legendFormat='mean',
      )
    )
    .addTarget(
      grafana.prometheus.target(
        'max(queue_message_lag_seconds_max)',
        legendFormat='max',
      )
    )
  )
)
