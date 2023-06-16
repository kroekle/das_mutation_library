package libraries.opa_mutation.istio

import data.libraries.opa_mutation.util.injectable_object
import data.libraries.opa_mutation.util.opa_patch
import data.libraries.opa_mutation.util.opa_volume_patch

#############################################################################
# METADATA: library-snippet/kubernetes
# version: v1
# title: "Inject opa sidecar to istio pod"
# description: >-
#  Injects an OPA sidecar to a Pod/Deployment template for objects labeled
#  with the specified label/value.  Will default to using the 
#  "opa:latest-envoy-rootless" image unless channel overrides are included in 
#  the mutation policy file.
# filePath:
# - .*/policy/com.styra.kubernetes.mutating/rules/.*
#
# schema:
#   parameters:
#   - name: "channel"
#     label: "Channel"
#     type: string
#     items: ["Rapid", "Regular", "Stable"]
#     default: "Regular"
#   - name: "config"
#     label: "ConfigMap for OPA"
#     type: string
#     default: opa-istio-config
#   - name: "label"
#     label: "Label to check"
#     type: string
#     default: istio-injection
#   - name: "label-value"
#     label: "Label value to check for"
#     type: string
#     default: enabled
#   decision:
#     - type: rego
#       key: patch
#       value: "patch"
#     - type: rego
#       key: message
#       value: "\"Adding OPA sidecar & volume\""
#     - type: rego
#       key: allowed
#       value: "true"
# policy:
#   rule:
#     type: rego
#     value: "{{this}}[patch]"
istio_opa_patches[patch] {
  injectable_object
  patch := [
    opa_patch,
    opa_volume_patch
  ]
}
