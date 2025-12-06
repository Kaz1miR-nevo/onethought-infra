{{/*
=============================================================================
OneThought Helm Chart - Template Helpers
=============================================================================
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "onethought.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "onethought.fullname" -}}
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
{{- define "onethought.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "onethought.labels" -}}
helm.sh/chart: {{ include "onethought.chart" . }}
{{ include "onethought.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
environment: {{ .Values.global.environment }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "onethought.selectorLabels" -}}
app.kubernetes.io/name: {{ include "onethought.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "onethought.frontend.labels" -}}
{{ include "onethought.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "onethought.frontend.selectorLabels" -}}
{{ include "onethought.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend labels
*/}}
{{- define "onethought.backend.labels" -}}
{{ include "onethought.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "onethought.backend.selectorLabels" -}}
{{ include "onethought.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Create the name of the frontend service account to use
*/}}
{{- define "onethought.frontend.serviceAccountName" -}}
{{- if .Values.frontend.serviceAccount.create }}
{{- default (printf "%s-frontend" (include "onethought.fullname" .)) .Values.frontend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.frontend.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the backend service account to use
*/}}
{{- define "onethought.backend.serviceAccountName" -}}
{{- if .Values.backend.serviceAccount.create }}
{{- default (printf "%s-backend" (include "onethought.fullname" .)) .Values.backend.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.backend.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create image pull secrets
*/}}
{{- define "onethought.imagePullSecrets" -}}
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

