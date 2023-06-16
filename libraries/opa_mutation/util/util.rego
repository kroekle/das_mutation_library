package libraries.opa_mutation.util

import future.keywords.in

default opa_image := "openpolicyagent/opa:latest-envoy-rootless" 

opa_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.rapid_channel_opa_image {
  data.library.parameters.channel == "Rapid"
}

opa_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.regular_channel_opa_image {
  data.library.parameters.channel == "Regular"
}

opa_image := data.policy["com.styra.kubernetes.mutating"].rules.rules.stable_channel_opa_image {
  data.library.parameters.channel == "Stable"
}

injectable_pod {
  input.request.kind.kind == "Pod"
  not input.request.object.metadata.labels.app == "slp"
  inject_label
  input.request.operation in ["CREATE", "UPDATE"]
  not opa_container_exists
}

injectable_deployment {
  input.request.kind.kind == "Deployment"
  inject_label
  input.request.operation in ["CREATE", "UPDATE"]
  not opa_container_exists
}

inject_label {
  data.kubernetes.resources.namespaces[input.request.namespace].metadata.labels[data.library.parameters.label] == data.library.parameters["label-value"]
}

inject_label {
  input.request.object.metadata.labels[data.library.parameters.label] == data.library.parameters["label-value"]
}

inject_label {
  input.request.object.spec.template.metadata.labels[data.library.parameters.label] == data.library.parameters["label-value"]
}

opa_container_exists {
  input.request.object.spec.containers[_].name == "opa"
}

opa_container_exists {
  input.request.object.spec.template.spec.containers[_].name == "opa"
}

injectable_object {
  injectable_pod
}

injectable_object {
  injectable_deployment
}

root_path := "" {
  injectable_pod
}

root_path := "/spec/template" {
  injectable_deployment
}

opa_config_mount := {
              "readOnly": true,
              "mountPath": "/config",
              "name": "opa-config-vol"
            }
            
opa_socket_mount := {
      "readOnly": false,
      "mountPath": "/run/opa/sockets",
      "name": "opa-socket"
    } 
    
opa_volume_mounts := [opa_config_mount] {
  not data.library.parameters["use-socket"] == "Yes"
}
opa_volume_mounts := [opa_config_mount, opa_socket_mount] {
  data.library.parameters["use-socket"] == "Yes"
}

opa_patch := {
        "op": "add",
        "path": sprintf("%v/spec/containers/-",[root_path]),
        "value": {
          "name": "opa",
          "image": opa_image,
          "securityContext": {
            "runAsUser": 1111
          },
          "volumeMounts": opa_volume_mounts,
          "env": [
            {
              "name": "OPA_LOG_TIMESTAMP_FORMAT",
              "value": "2006-01-02T15:04:05.999999999Z07:00"
            }
          ],
          "args": [
            "run",
            "--server",
            "--config-file=/config/conf.yaml",
            "--addr=http://127.0.0.1:8181",
            "--diagnostic-addr=0.0.0.0:8282",
            "--authorization=basic"
          ],
          "readinessProbe": {
            "initialDelaySeconds": 20,
            "httpGet": {
              "path": "/health?plugins",
              "scheme": "HTTP",
              "port": 8282
            }
          },
          "resources": {
            "requests": null,
            "limits": null
          }
        }
    }

existing_volumes {
  input.request.object.spec.template.spec.volumes
}
existing_volumes {
  input.request.object.spec.volumes
}

opa_volume_patch := patch {
  existing_volumes
  patch := {
        "op": "add",
        "path": sprintf("%v/spec/volumes/-", [root_path]),
        "value": opa_volume
      }
}
opa_volume_patch := patch {
  not existing_volumes
  patch := {
        "op": "add",
        "path": sprintf("%v/spec/volumes", [root_path]),
        "value": [opa_volume]
      }
}

opa_volume := {
          "name": "opa-config-vol",
          "configMap": {
            "name": data.library.parameters.config
          }
        }