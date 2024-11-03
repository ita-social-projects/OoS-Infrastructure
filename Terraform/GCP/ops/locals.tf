locals {
  uptime = {
    Elasticsearch = {
      host    = "elastic.oos.dmytrominochkin.cloud"
      period  = "60s"
      regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA", "USA_IOWA"]
      path    = "/_cluster/health"
    }
    Kibana = {
      host    = "kibana.oos.dmytrominochkin.cloud"
      period  = "60s"
      regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA", "USA_IOWA"]
      path    = "/api/task_manager/_health"
    }
  }

  notification = {
    display_name = "Discord"
    type         = "pubsub"
    labels = {
      topic : "${module.pubsub.id}"
      #fallback_channel : true # The id of this channel will be included in the "fallback_channels_ids" output.type = "pubsub" }
    }
  }
  topic_name = "uptime-notification"
  file_name  = "uptime-notification.zip"

  topic_kibana     = "kibana-notification"
  kibana_file_name = "kibana-notification.zip"
}
