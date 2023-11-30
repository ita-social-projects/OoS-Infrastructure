{{/*
Environment values from config, secrets, etc.
*/}}
{{- define "library.env.tpl" -}}
{{- $envList := default list -}}
{{- $env := merge (.Values.configuration.extraEnvironment | default dict) (.Values.global.extraEnvironment | default dict) -}}
{{- range $k, $v := $env -}}
{{- $envList = append $envList (dict "name" $k "value" $v) -}}
{{- end -}}
{{- range $secret := .Values.configuration.secrets -}}
{{- if eq $secret.type "env" -}}
{{- range $key := $secret.keys -}}
{{- $envPrefix := $secret.prefix | default "" | upper -}}
{{- $envKey := (index $key "envKey") | default (index $key "key") | replace "." "_" | replace "-" "_" -}}
{{/* TODO: can't belive helm has not fixed booleans in 5 years ;) */}}
{{- $uppedKey := ternary (upper $envKey) $envKey (list nil true "true" | has (index $key "upper")) -}}
{{- $envList = append $envList (dict "name" (printf "%s%s" $envPrefix $uppedKey) "valueFrom" (dict "secretKeyRef" (dict "name" $secret.name "key" (index $key "key")))) -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toYaml $envList | indent 0 -}}
{{- end -}}

{{- define "library.envFrom.tpl" -}}
{{- if or .Values.configuration.extraEnvVarsCM .Values.configuration.extraEnvVarsSecret -}}
envFrom:
  {{- if .Values.configuration.extraEnvVarsCM }}
  - configMapRef:
      name: {{ tpl .Values.configuration.extraEnvVarsCM . | quote }}
  {{- end }}
  {{- if .Values.configuration.extraEnvVarsSecret }}
  - secretRef:
      name: {{ tpl .Values.configuration.extraEnvVarsSecret . | quote }}
  {{- end }}
{{- end }}
{{- end -}}
