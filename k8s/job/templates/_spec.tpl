{{/*
Job spec.
*/}}
{{- define "job.spec" -}}
spec:
  {{- if .Values.backoffLimit }}
  backoffLimit: {{ .Values.backoffLimit }}
  {{- end }}
  {{- if .Values.activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ .Values.activeDeadlineSeconds }}
  {{- end }}
  {{- if .Values.ttlSecondsAfterFinished }}
  ttlSecondsAfterFinished: {{ .Values.ttlSecondsAfterFinished }}
  {{- end }}
  template:
    metadata:
      {{- with .Values.podAnnotations }}
      annotations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "job.selectorLabels" . | nindent 8 }}
    spec:
      restartPolicy: {{ .Values.restartPolicy }}
      serviceAccountName: {{ include "job.serviceAccountName" . }}
      {{- if .Values.podSecurity.enabled }}
      securityContext:
        {{- toYaml .Values.podSecurity.context | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          {{- if .Values.containerSecurity.enabled }}
          securityContext: {{ toYaml .Values.containerSecurity.context | nindent 12 }}
          {{- end }}
          {{- with .Values.command }}
          command: {{ toYaml . | nindent 10 }}
          {{- end }}
          {{- with .Values.args }}
          args: {{ toYaml . | nindent 10 }}
          {{- end }}
          {{- include "library.image.tpl" . | indent 10 }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          {{- with .Values.resources }}
          resources: {{ toYaml . | nindent 12 }}
          {{- end }}
          {{- with (include "library.env.tpl" . | fromYamlArray) }}
          env: {{ toYaml . | nindent 12 }}
          {{- end }}
          {{- include "library.envFrom.tpl" . | nindent 10 }}
          {{- with .Values.extraVolumeMounts }}
          volumeMounts: {{ toYaml . | nindent 12 }}
          {{- end }}
      {{- with .Values.nodeSelector }}
      nodeSelector: {{ toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.affinity }}
      affinity: {{ toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.tolerations }}
      tolerations: {{ toYaml . | nindent 8 }}
      {{- end }}
      {{- with .Values.extraVolumes }}
      volumes: {{ toYaml . | nindent 8 }}
      {{- end }}
{{- end -}}
