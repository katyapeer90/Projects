{{- define "createDeployments" }}
{{/* Loop over each service defined in the values file. */}}
{{- range $service, $details := .Values.services }}
  {{/* Check if the service is enabled. */}}
  {{- if and (hasKey $.Values.serviceEnable $service) (default (index $.Values.serviceEnable $service) false) }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $details.name }}
  namespace: default
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  minReadySeconds: 3
  replicas: {{ if $details.spec }}{{ $details.spec.replicas }}{{ else }}{{ $.Values.global.spec.replicas }}{{ end }}
  selector:
    matchLabels:
      app: {{ $details.name }}
  template:
    metadata:
      labels:
        app: {{ $details.name }}
        aadpodidbinding: my-pod-identity
    spec:
      {{/* Loop over nodeselector. */}}
      nodeSelector:
        {{- if $details.nodeSelector }}
          {{- range $key, $value := $details.nodeSelector }}
        "{{ $key }}": {{ $value }}
          {{- end }}
        {{- else if $.Values.global.nodeSelector }}
          {{- range $key, $value := $.Values.global.nodeSelector }}
        "{{ $key }}": {{ $value }}
          {{- end }}
        {{- end }}
      containers:
      - name: {{ $details.name }}
        image: "{{ $.Values.global.acrUrl }}/{{ $details.name }}:{{ $details.imageTag }}"
        imagePullPolicy: Always
        {{- if $details.ramdisk }}
        {{- if $details.ramdisk.enabled }}
        {{- if $details.ramdisk.command }}
        command: {{ $details.ramdisk.command | toJson }}
        {{- end }}
        {{- if $details.ramdisk.args }}
        args: {{ $details.ramdisk.args | toJson }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{/* Loop over each config containerPort. */}}
        ports:
          {{- if eq $details.name "xapifunction"}}
          - containerPort: 8080
            protocol: TCP
          {{- else if $details.ports }}
          - containerPort: {{ $details.ports.containerPort }}
            protocol: TCP
          {{- else }}
          - containerPort: {{ $.Values.global.ports.containerPort }}
            protocol: TCP
          {{- end }}
        {{- if or $details.volumeCalim (and $details.ramdisk $details.ramdisk.enabled) }}
        volumeMounts:
        {{- if and $details.ramdisk $details.ramdisk.enabled }}
        - name: {{ $details.ramdisk.volumeName | default "unified-ramdisk" }}
          mountPath: {{ $details.ramdisk.mountPath | default "/app-ram" }}
        {{- else if $details.volumeCalim }}
        - name: {{ if $details.volumeMounts }}{{ $details.volumeMounts.name }}{{ end }}
          mountPath: {{ if $details.volumeMounts }}{{ $details.volumeMounts.mountPath }}{{ end }}
        {{- end }}
        {{- end }}
        # Adding resources section
        resources:
          {{- if $details.resources }}
          limits:
            memory: {{ $details.resources.limitsmemory }}
            cpu: {{ $details.resources.limitscpu }}
          requests:
            memory: {{ $details.resources.requestsmemory }}
            cpu: {{ $details.resources.requestscpu }}
          {{- else }}
          limits:
            memory: {{ $.Values.global.resources.limitsmemory }}
            cpu: {{ $.Values.global.resources.limitscpu }}
          requests:
            memory: {{ $.Values.global.resources.requestsmemory }}
            cpu: {{ $.Values.global.resources.requestscpu }}            
          {{- end }}
        env:
        {{/* Add ramdisk-specific environment variables first */}}
        {{- if $details.ramdisk }}
        {{- if $details.ramdisk.enabled }}
        {{- if $details.ramdisk.envVars }}
        {{- range $key, $value := $details.ramdisk.envVars }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{- end }}
        {{/* Loop over each environment variable directly defined in the service's envVars. */}}
        {{- if $details.envVars }}
        {{- range $key, $value := $details.envVars }}
        - name: {{ $key }}
          value: {{ $value | quote }}
        {{- end }}
        {{- end }}
        {{/* Loop over each environment variable in the global scope that is listed in the service's envVarsFromGlobal. */}}
        {{- if $details.envVarsFromGlobal }}
        {{- range $key := $details.envVarsFromGlobal }}
        - name: {{ $key }}
          value: {{ index $.Values.global $key | quote }}
        {{- end }}
        {{- end }}
      #adding liveness and readiness probes
        livenessProbe:
          {{ if $details.isTcpSocket }}
          tcpSocket:
            port: {{ $details.ports.containerPort }}
          {{- else }}
          httpGet:
            path: {{ if $details.livenessProbe }}{{ $details.livenessProbe.path | default $.Values.global.livenessProbe.path }}{{ else }}{{ $.Values.global.livenessProbe.path }}{{ end }}
            {{- if $details.ports }}
            port: {{ $details.ports.containerPort }}
            {{- else }}
            port: {{ $.Values.global.ports.containerPort }}
            {{- end }}
            scheme: HTTP
          {{- end }}
          initialDelaySeconds: {{ if $details.livenessProbe }}{{ $details.livenessProbe.initialDelaySeconds | default $.Values.global.livenessProbe.initialDelaySeconds }}{{ else }}{{ $.Values.global.livenessProbe.initialDelaySeconds }}{{ end }}
          timeoutSeconds: {{ if $details.livenessProbe }}{{ $details.livenessProbe.timeoutSeconds | default $.Values.global.livenessProbe.timeoutSeconds }}{{ else }}{{ $.Values.global.livenessProbe.timeoutSeconds }}{{ end }}
          periodSeconds: {{ if $details.livenessProbe }}{{ $details.livenessProbe.periodSeconds | default $.Values.global.livenessProbe.periodSeconds }}{{ else }}{{ $.Values.global.livenessProbe.periodSeconds }}{{ end }}
          successThreshold: {{ if $details.livenessProbe }}{{ $details.livenessProbe.successThreshold | default $.Values.global.livenessProbe.successThreshold }}{{ else }}{{ $.Values.global.livenessProbe.successThreshold }}{{ end }}
          failureThreshold: {{ if $details.livenessProbe }}{{ $details.livenessProbe.failureThreshold | default $.Values.global.livenessProbe.failureThreshold }}{{ else }}{{ $.Values.global.livenessProbe.failureThreshold }}{{ end }}
        readinessProbe:
          {{ if $details.isTcpSocket }}
          tcpSocket:
            port: {{ $details.ports.containerPort }}
          {{- else }}
          httpGet:
            path: {{ if $details.readinessProbe }}{{ $details.readinessProbe.path | default $.Values.global.readinessProbe.path }}{{ else }}{{ $.Values.global.readinessProbe.path }}{{ end }}
            {{- if $details.ports }}
            port: {{ $details.ports.containerPort }}
            {{- else }}
            port: {{ $.Values.global.ports.containerPort }}
            {{- end }}
            scheme: HTTP
          {{- end }}
          initialDelaySeconds: {{ if $details.readinessProbe }}{{ $details.readinessProbe.initialDelaySeconds | default $.Values.global.readinessProbe.initialDelaySeconds }}{{ else }}{{ $.Values.global.readinessProbe.initialDelaySeconds }}{{ end }}
          timeoutSeconds: {{ if $details.readinessProbe }}{{ $details.readinessProbe.timeoutSeconds | default $.Values.global.readinessProbe.timeoutSeconds }}{{ else }}{{ $.Values.global.readinessProbe.timeoutSeconds }}{{ end }}
          periodSeconds: {{ if $details.readinessProbe }}{{ $details.readinessProbe.periodSeconds | default $.Values.global.readinessProbe.periodSeconds }}{{ else }}{{ $.Values.global.readinessProbe.periodSeconds }}{{ end }}
          successThreshold: {{ if $details.readinessProbe }}{{ $details.readinessProbe.successThreshold | default $.Values.global.readinessProbe.successThreshold }}{{ else }}{{ $.Values.global.readinessProbe.successThreshold }}{{ end }}
          failureThreshold: {{ if $details.readinessProbe }}{{ $details.readinessProbe.failureThreshold | default $.Values.global.readinessProbe.failureThreshold }}{{ else }}{{ $.Values.global.readinessProbe.failureThreshold }}{{ end }}
      {{- if or $details.volumeCalim (and $details.ramdisk $details.ramdisk.enabled) }}
      volumes:
        {{- if and $details.ramdisk $details.ramdisk.enabled }}
        - name: {{ $details.ramdisk.volumeName | default "unified-ramdisk" }}
          emptyDir:
            medium: Memory
            sizeLimit: {{ $details.ramdisk.sizeLimit | default "1Gi" }}
        {{- else if $details.volumeCalim }}
        - name: {{ if $details.volumes }}{{ $details.volumes.name }}{{ end }}
          persistentVolumeClaim:
            claimName: {{ if $details.volumes }}{{ $details.volumes.persistentVolumeClaim }}{{ end }}
        {{- end }}
      {{- end }}      
      {{/* Loop over each host alias directly defined in the service's hostAliases. */}}
      {{- if or $details.hostAliases }}
      hostAliases:
        {{- range $value := $details.hostAliases }}
        - ip: {{ $value.ip }}
          hostnames:
          {{- range $hostname := $value.hostnames }}
            - {{ $hostname }}
          {{- end }}
        {{- end }}
      {{- end }}
{{/*}}
      restartPolicy: Always
{{*/}}
---
  {{- end }}
{{- end }}
{{- end }}

{{- define "createServices" }}
  {{/* Loop over each service defined in the values file. */}}
  {{- range $service, $details := .Values.services }}
    {{/* Check if the service is enabled. */}}
    {{- if and (hasKey $.Values.serviceEnable $service) (default (index $.Values.serviceEnable $service) false) }}
apiVersion: v1
kind: Service
metadata:
  name: {{ $details.name }}-service
  {{/* Loop over each config service healthcheck annotations. */}}
  annotations:
  {{- if or $details.annotations }}
    {{- range $key, $value := $details.annotations }}
    {{ $key }}: {{ quote $value }}
    {{- end }}
  {{- else if $.Values.global.annotations }}
    {{- range $key, $value := $.Values.global.annotations }}
    {{ $key }}: {{ quote $value }}
    {{- end }}
  {{- end }}
  namespace: default
  labels:
    app: {{ $details.name }}
spec:
  {{/* Loop over each config service ports. */}}
  ports:
  - name: http
  {{- if eq $details.name "xapifunction"}}
    port: 80
    Protocol: TCP
    targetPort: 8080
  {{- else if $details.ports }}
    port: {{ $details.ports.containerPort }}
    protocol: TCP
    targetPort: {{ $details.ports.containerPort }}
  {{- else }}
    port: {{ $.Values.global.ports.containerPort }}
    protocol: TCP
    targetPort: {{ $.Values.global.ports.containerPort }}
  {{- end }}
  selector:
    app: {{ $details.name }}
  type: LoadBalancer
---
    {{- end }}
  {{- end }}
{{- end }}

{{- define "createAPIServices" }}
{{/* Create APIService for servicebusmetrics if enabled */}}
{{- if and (hasKey $.Values.serviceEnable "servicebusmetrics") (default (index $.Values.serviceEnable "servicebusmetrics") false) }}
apiVersion: apiregistration.k8s.io/v1
kind: APIService
metadata:
  name: v1beta1.external.metrics.k8s.io
spec:
  service:
    name: servicebusmetrics-service
    namespace: default
    port: 443
  group: external.metrics.k8s.io
  version: v1beta1
  insecureSkipTLSVerify: true
  groupPriorityMinimum: 100
  versionPriority: 100
---
{{- end }}
{{- end }}


{{- define "createHPA" }}
  {{- range $service, $details := .Values.services }}
    {{- if and (hasKey $.Values.serviceEnable $service) (default (index $.Values.serviceEnable $service) false) }}
      {{- $autoscaling := $details.autoscaling | default $.Values.global.autoscaling }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ $details.name }}-autoscale
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ $details.name }}
  minReplicas: {{ $autoscaling.minReplicas }}
  maxReplicas: {{ $autoscaling.maxReplicas }}
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ $autoscaling.metrics.cpuaverageUtilization }}
  - type: Resource
    resource:
      name: memory
      target:
        type: AverageValue
        averageValue: {{ $autoscaling.metrics.memoryaverageValue }}
  {{- if $details.includeExternalMetric }}
  - type: External
    external:
      metric:
        name: activemessagecount
      target:
        type: AverageValue
        averageValue: '25'
  {{- else }}
  {{- end }}
---
    {{- end }}
  {{- end }}
{{- end }}
