{{/*
Expand the name of the chart.
*/}}
{{- define "infra.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "infra.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "infra.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "infra.labels" -}}
helm.sh/chart: {{ include "infra.chart" . }}
{{ include "infra.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "infra.selectorLabels" -}}
app.kubernetes.io/name: {{ include "infra.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "infra.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "infra.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the infra gateway
*/}}
{{- define "infra.gatewayName" -}}
{{- include "infra.fullname" . }}-gateway
{{- end }}

{{/*
Name of the cluster issuer
*/}}
{{- define "infra.clusterIssuerName" -}}
{{- include "infra.fullname" . }}-cluster-issuer
{{- end }}

{{/*
Name of the solver http listener 
*/}}
{{- define "infra.solverHttpListener" -}}
{{- include "infra.fullname" .}}-acme-solver-http
{{- end }}

{{/*
Name of the https listener
*/}}
{{- define "infra.httpsListener" -}}
{{ . | replace "." "-" }}-https
{{- end }}
