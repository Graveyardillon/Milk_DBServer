#!/bin/bash
gcloud alpha monitoring policies update projects/e-players6814/alertPolicies/1210267003267830423 --no-enabled
gcloud app deploy app-production.yaml
gcloud alpha monitoring policies update projects/e-players6814/alertPolicies/1210267003267830423 --enabled