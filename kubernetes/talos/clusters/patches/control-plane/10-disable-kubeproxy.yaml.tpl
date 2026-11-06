{{ if .Data.disableKubeProxy -}}
apiVersion: v1alpha1
kind: KubeProxyConfig
enabled: false
{{- end }}