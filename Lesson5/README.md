### Lesson 4:  EKS & NGINX Load Balancer Monitor with Prometheus, Grafana, and Alerts

In this lesson, you will learn how tosetup EKS & NGINX Load Balancer Monitor with Prometheus, Grafana, and Alerts
![MONITORING](monitoring.png)

# Before getting started:
1. Follow the instructions from the previous video to <b>create a EKS cluster with v1.30</b>

## Medium and Youtube Article Link:
- [Read the detailed guide on Medium]()


Before you begin, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html) v1.0 or later
- AWS CLI configured with appropriate credentials
- [kubectl](https://kubernetes.io/docs/tasks/tools/) for interacting with your EKS cluster

##  Kubernetes YAML configuration file for Prometheus
```
alertmanager:
  enabled: true
  alertmanagerSpec:
    retention: 24h #This setting specifies the time duration for which Alertmanager will retain alert data. 
    replicas: 1
    resources:
      limits:
        cpu: 600m
        memory: 1024Mi
      requests:
        cpu: 200m
        memory: 356Mi
  config:
    global:
      resolve_timeout: 1s # In this case, it's set to 5 minutes. If an alert is not explicitly resolved by the alert source within 5 minutes, it will be automatically marked as resolved by Alertmanager.
    route:
      group_wait: 20s
      group_interval: 1m
      repeat_interval: 30m
      receiver: "null"
      routes:
      - match:
          alertname: Watchdog
        receiver: "null"
      - match:
          severity: warning
        receiver: "slack-alerts"
        continue: true
      - match:
          severity: critical
        receiver: "slack-alerts"
        continue: true
    receivers:
      - name: "null"
      - name: "slack-alerts"
        slack_configs:
          # checkov:skip=CKV_SECRET_14 Slack Webhook URL
        - api_url: '<url>'
          channel: '#prometheus-alerts'
          send_resolved: true
          title: '[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] Production Monitoring Event Notification'
          text: >-
            {{ range .Alerts }}
              *Alert:* {{ .Annotations.summary }} - `{{ .Labels.severity }}`
              *Description:* {{ .Annotations.description }}
              *Details:*
              {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
              {{ end }}
            {{ end }}
    templates:
    - "/etc/alertmanager/config/*.tmpl"
additionalPrometheusRulesMap:
 custom-rules:
  groups:
  - name: NginxIngressController
    rules:
    - alert: NginxHighHttp4xxErrorRate
      annotations:
        summary: "High rate of HTTP 4xx errors (instance {{ $labels.ingress }})"
        description: "Too many HTTP requests with status 4xx (> 20 per second) in the last 5 minutes\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
      expr: nginx_ingress_controller_requests{status="404", ingress="photoapp"} > 5
      for: 5m
      labels:
        severity: critical      
  - name: Nodes
    rules:
    - alert: KubernetesNodeReady
      expr: sum(kube_node_status_condition{condition="Ready", status="false"}) by (node) > 0
      for: 1m
      labels:
        severity: critical
      annotations:
        summary: Kubernetes Node ready (instance {{ $labels.instance }})
        description: "Node {{ $labels.node }} has been unready for a long time\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"         
      # New alert for node deletion
    - alert: InstanceDown
      expr: up == 0
      labels:
        severity: critical
      annotations:
        summary: Kubernetes Node Deleted (instance {{ $labels.instance }})
        description: "Node {{ $labels.node }} has been unready for a long time\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"     
  - name: Pods 
    rules: 
    - alert: Container restarted 
      annotations: 
        summary: Container named {{$labels.container}} in {{$labels.pod}} in {{$labels.namespace}} was restarted 
        description: "\nCluster Name: {{$externalLabels.cluster}}\nNamespace: {{$labels.namespace}}\nPod name: {{$labels.pod}}\nContainer name: {{$labels.container}}\n" 
      expr: | 
        sum(increase(kube_pod_container_status_restarts_total{namespace!="kube-system",pod_template_hash=""}[1m])) by (pod,namespace,container) > 0 
      for: 0m 
      labels: 
        severity: critical            
prometheus:
  enabled: true
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - prometheus.codedevops.cloud
    paths:  
      - /
  prometheusSpec:
    retention: 48h
    replicas: 2
    resources:
      limits:
        cpu: 800m
        memory: 2000Mi
      requests:
        cpu: 100m
        memory: 200Mi
grafana:
  enabled: true
  adminPassword: admin@123
  replicas: 1
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - grafana.codedevops.cloud
    path: /
```
