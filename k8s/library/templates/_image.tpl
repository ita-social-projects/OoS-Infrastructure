{{/*
Image configuration
*/}}
{{- define "library.image.tpl" -}}
{{- if .Values.image.fullTagOverride }}
image: "{{ .Values.image.fullTagOverride }}"
{{- else }}
image: "{{ .Values.image.registry }}/{{ .Values.image.repository }}/{{ .Values.image.name }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
{{- end }}
{{- end -}}
