data "newrelic_account" "acc" {
  account_id = "3933528"
}

// Create a policy to track
resource "newrelic_alert_policy" "my-policy" {
  name = "my_policy"
}

resource "newrelic_nrql_alert_condition" "nrql_condition" {
  account_id                     = "3933528"
  policy_id                      = newrelic_alert_policy.my-policy.id
  type                           = "static"
  name                           = "foo"
  description                    = "Alert when transactions are taking too long"
  runbook_url                    = "https://www.example.com"
  enabled                        = true
  violation_time_limit_seconds   = 3600
  fill_option                    = "static"
  fill_value                     = 1.0
  aggregation_window             = 60
  aggregation_method             = "event_flow"
  aggregation_delay              = 120
  expiration_duration            = 120
  open_violation_on_expiration   = true
  close_violations_on_expiration = true
  slide_by                       = 30

  nrql {
    query = "SELECT average(cpuPercent ) FROM ProcessSample"
  }

  critical {
    operator              = "above"
    threshold             = 0.0
    threshold_duration    = 300
    threshold_occurrences = "ALL"
  }

}


// Create a reusable notification destination
resource "newrelic_notification_destination" "destination" {
  account_id = "3933528"
  name = "email-example"
  type = "EMAIL"

  property {
    key = "email"
    value = "aman39mit@gmail.com"
  }
}

// Create a notification channel to use in the workflow
resource "newrelic_notification_channel" "notification_channel" {
  account_id = "3933528"
  name = "email-example"
  type = "EMAIL"
  destination_id = newrelic_notification_destination.destination.id
  product = "IINT"

  property {
    key = "subject"
    value = "New Subject Title"
  }

  property {
    key = "customDetailsEmail"
    value = "issue id - {{issueId}}"
  }
}

// A workflow that matches issues that include incidents triggered by the policy
resource "newrelic_workflow" "workflow-example" {
  name = "workflow-example"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  issues_filter {
    name = "Filter-name"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator = "EXACTLY_MATCHES"
      values = [ newrelic_alert_policy.my-policy.id ]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.notification_channel.id
  }
}
