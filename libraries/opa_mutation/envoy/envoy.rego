package libraries.opa_mutation.envoy

import data.libraries.opa_mutation.util.injectable_object
import data.libraries.opa_mutation.util.opa_patch
import data.libraries.opa_mutation.util.opa_volume
import data.libraries.opa_mutation.util.root_path
import data.libraries.opa_mutation.util.existing_volumes

# Envoy doesn't tag a "lastest" version, either way this should be 
# matched with the configuration of DAS
default envoy_image := "envoyproxy/envoy:v1.21-latest" 

envoy_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.rapid_channel_envoy_image {
  data.library.parameters.channel == "Rapid"
}
envoy_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.regular_channel_envoy_image {
  data.library.parameters.channel == "Regular"
}
envoy_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.stable_channel_envoy_image {
  data.library.parameters.channel == "Stable"
}

default init_image := "openpolicyagent/proxy_init:latest" 

init_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.rapid_channel_init_image {
  data.library.parameters.channel == "Rapid"
}

init_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.regular_channel_init_image {
  data.library.parameters.channel == "Regular"
}

init_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.stable_channel_init_image {
  data.library.parameters.channel == "Stable"
}

#############################################################################
# METADATA: library-snippet/kubernetes
# version: v1
# title: "Inject opa & envoy sidecars into pod"
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
#     default: opa-envoy-config
#   - name: "config-envoy"
#     label: "ConfigMap for Envoy"
#     type: string
#     default: envoy-config
#   - name: "label"
#     label: "Label to check"
#     type: string
#     default: inject-opa
#   - name: "use-socket"
#     label: "Use Socket"
#     type: string
#     items: ["Yes", "No"]
#     default: "Yes"
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
#       value: "\"Adding OPA and Envoy sidecars & volumes\""
#     - type: rego
#       key: allowed
#       value: "true"
# policy:
#   rule:
#     type: rego
#     value: "{{this}}[patch]"
envoy_and_opa_patches[patch] {
  injectable_object
  patch := array.concat([
    init_patch,
    envoy_patch,
    opa_patch,
  ], opa_and_envoy_volume_patch)
}

init_patch = patch {
  init_containers
  patch := {
        "op": "add",
        "path": sprintf("%v/spec/initContainers/-",[root_path]),
        "value": init_container_patch} 
}

init_patch = patch {
  not init_containers
  patch = {
        "op": "add",
        "path": sprintf("%v/spec/initContainers",[root_path]),
        "value": [init_container_patch]
     }
}

init_container_patch := {
          "image": init_image,
          "name": "proxy-init",
          "args": [
            "-p",
            "8000",
            "-o",
            "8001",
            "-u",
            "1111",
            "-w",
            "8282"
          ],
          "securityContext": {
            "capabilities": {
              "add": [
                "NET_ADMIN"
              ]
            },
            "runAsNonRoot": false,
            "runAsUser": 0
          }
        }
     
init_containers {
  input.request.object.spec.template.spec.initContainers
}
init_containers {
  input.request.object.spec.initContainers
}

envoy_patch := {
        "op": "add",
        "path": sprintf("%v/spec/containers/-",[root_path]),
        "value": {
      "name": "envoy",
      "image": envoy_image,
      "volumeMounts": [
        {
          "readOnly": true,
          "mountPath": "/config",
          "name": "envoy-config-vol"
        },
        {
          "readOnly": false,
          "mountPath": "/run/opa/sockets",
          "name": "opa-socket"
        }
      ],
      "args": [
        "envoy",
        "--config-path",
        "/config/envoy.yaml"
      ],
      "env": [
        {
          "name": "ENVOY_UID",
          "value": "1111"
        }
      ]
    }
  }


opa_and_envoy_volume_patch = patch {
  existing_volumes
  patch := [
      {
        "op": "add",
        "path": sprintf("%v/spec/volumes/-", [root_path]),
        "value": opa_volume
      },
      {
        "op": "add",
        "path": sprintf("%v/spec/volumes/-", [root_path]),
        "value": envoy_volume
      },
      {
        "op": "add",
        "path": sprintf("%v/spec/volumes/-", [root_path]),
        "value": socket_volume
      },
      ]
}
opa_and_envoy_volume_patch := patch {
  not existing_volumes
  patch := [{
        "op": "add",
        "path": sprintf("%v/spec/volumes", [root_path]),
        "value": [opa_volume, envoy_volume, socket_volume]
      }]
}
envoy_volume := {
      "name": "envoy-config-vol",
      "configMap": {
        "name": data.library.parameters["config-envoy"]
      }
    }
socket_volume := {
      "name": "opa-socket",
      "emptyDir": {
      }
    }

