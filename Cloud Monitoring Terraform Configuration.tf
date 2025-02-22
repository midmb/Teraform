//https://developer.hashicorp.com/terraform/tutorials

This Terraform configuration sets up a basic cloud monitoring infrastructure with:
Alert Policies:
CPU utilization (alerts at 80%)
Memory utilization (alerts at 80%)
Error rate (alerts if more than 10 errors in 5 minutes)

Uptime Monitoring:
Regular HTTP checks
SSL validation
5-minute check intervals


Dashboard:
CPU usage graph
Memory usage graph
Error count graph


Notification Channel:
Email notifications for alerts



# Configure the required providers
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

# Variables
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "app_name" {
  description = "Name of the application to monitor"
  type        = string
}

# Monitoring notification channel (email)
resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification Channel"
  type         = "email"
  labels = {
    email_address = "your-email@domain.com"
  }
}

# CPU utilization alert policy
resource "google_monitoring_alert_policy" "cpu_usage" {
  display_name = "High CPU Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "CPU utilization"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
      duration        = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = 0.8  # 80% CPU utilization
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Memory usage alert policy
resource "google_monitoring_alert_policy" "memory_usage" {
  display_name = "High Memory Usage Alert"
  combiner     = "OR"
  conditions {
    display_name = "Memory utilization"
    condition_threshold {
      filter          = "metric.type=\"compute.googleapis.com/instance/memory/utilization\" AND resource.type=\"gce_instance\""
      duration        = "300s"
      comparison     = "COMPARISON_GT"
      threshold_value = 0.8  # 80% memory utilization
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Error rate alert policy
resource "google_monitoring_alert_policy" "error_rate" {
  display_name = "High Error Rate Alert"
  combiner     = "OR"
  conditions {
    display_name = "Error rate"
    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/log_entry_count\" AND resource.type=\"gce_instance\" AND severity=\"ERROR\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 10  # More than 10 errors in 5 minutes
      trigger {
        count = 1
      }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# Uptime check
resource "google_monitoring_uptime_check_config" "app_uptime" {
  display_name = "${var.app_name} Uptime Check"
  timeout      = "10s"
  period      = "300s"  # Check every 5 minutes

  http_check {
    path         = "/"
    port         = "443"
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = "your-app-url.com"
    }
  }
}

# Dashboard
resource "google_monitoring_dashboard" "app_dashboard" {
  dashboard_json = jsonencode({
    displayName = "${var.app_name} Dashboard"
    gridLayout = {
      widgets = [
        {
          title = "CPU Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/cpu/utilization\" AND resource.type=\"gce_instance\""
                }
              }
            }]
          }
        },
        {
          title = "Memory Usage"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"compute.googleapis.com/instance/memory/utilization\" AND resource.type=\"gce_instance\""
                }
              }
            }]
          }
        },
        {
          title = "Error Count"
          xyChart = {
            dataSets = [{
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"logging.googleapis.com/log_entry_count\" AND resource.type=\"gce_instance\" AND severity=\"ERROR\""
                }
              }
            }]
          }
        }
      ]
    }
  })
}

# Outputs
output "dashboard_url" {
  description = "URL of the monitoring dashboard"
  value       = "https://console.cloud.google.com/monitoring/dashboards/custom/${google_monitoring_dashboard.app_dashboard.id}"
}
