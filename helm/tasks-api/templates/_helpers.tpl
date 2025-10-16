{{/*
Expand the name of the chart.
*/}}
{{- define "tasks-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tasks-api.fullname" -}}
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
{{- define "tasks-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tasks-api.labels" -}}
helm.sh/chart: {{ include "tasks-api.chart" . }}
{{ include "tasks-api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tasks-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tasks-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tasks-api.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tasks-api.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name for the ConfigMap storing non-sensitive env variables.
*/}}
{{- define "tasks-api.configMapName" -}}
{{- printf "%s-config" (include "tasks-api.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name for the Secret storing sensitive env variables.
*/}}
{{- define "tasks-api.secretName" -}}
{{- if .Values.secret.nameOverride }}
{{- .Values.secret.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else if .Values.secret.create }}
{{- printf "%s-secret" (include "tasks-api.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- required "secret.nameOverride must be set when secret.create is false" .Values.secret.nameOverride }}
{{- end }}
{{- end }}
