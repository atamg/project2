# Monitoring Stack Documentation

## Overview
The monitoring stack consists of Prometheus, Grafana, and Loki, providing comprehensive monitoring and logging capabilities.

## Components

### Prometheus
- Metrics collection and storage
- High availability setup with 2 replicas
- 15-day retention period
- Automated service discovery
- Custom alerting rules

### Grafana
- Visualization platform
- Pre-configured dashboards
- High availability setup
- Persistent storage
- SSO integration with Keycloak

### Loki
- Log aggregation
- 30-day retention
- S3 storage backend
- Automated log parsing
- Integration with Grafana

## Alert Configuration

### Severity Levels
1. Critical - Immediate action required
2. Warning - Investigation needed
3. Info - For awareness

### Notification Channels
- Slack: General alerts
- PagerDuty: Critical alerts
- Email: Daily summaries

## Dashboard Overview

### Kubernetes Cluster Dashboard
- Node status
- Pod metrics
- Resource utilization
- Network statistics

### Application Dashboards
- MongoDB metrics
- Kafka performance
- Application-specific metrics 