{{ if .Data.disableFlannelCNI -}}
apiVersion: v1alpha1
kind: KubeFlannelCNIConfig
$patch: delete
{{- end }}