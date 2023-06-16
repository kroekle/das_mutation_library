# OPA sidecars library for Styra DAS Kubernetes Mutations

This library has mutation rules structured for use with the Styra DAS Kubernetes [system type](https://docs.styra.com/das/systems/kubernetes/).  This library is not provided or officially supported by Styra.

## Concepts
These rules will look for a label on any one of nameapace, deployment, or pod level and will inject the appropriate sidecars/volumes to the pod or deployment object.  The label that is searched for is configurable and the images injected can be overridden.  The intent is to match up well with how the Istio/Envoy systems are installed from Styra DAS, so minimal changes should be necessary to make work.

Each rule has a configuration for a "channel".  Each channel can be configured to use a different image.  This should allow for rolling out different images to different services to support internal deployment processes.  By default all images (except Envoy which doesn't have a latest image) will use the latest image tag in the public repos, but can be overridden to whatever image/tag works for your needs.

## Installing Library
This library is intended to be directly imported into a Styra DAS tenant using the "LIBRARIES" feature.  To add it, click the "+" next to "LIBRARIES" in DAS, give it whatever name you want (description is optional) and click "Add library".  Then in Settings>Git Repository add your credentials (currently a DAS requirement even for public repos) and this repo URL.  Do not add anything for path.  Currently I have everything in main, but if I start having breaking changes, I may add tags in the future for versions.

## Using rules
After the library is added in DAS (previous section), the rules should show up in any Kubernetes system in the tenant in the Mutating policy file.  If you don't see them, try refreshing your browser.  They will be found when clicking the "Add rule" button in the policy.  All rules will support the filters that DAS K8S rules support by default.

### Envoy Rule
Before using the rule make sure to have run the install instructions (or equivalent) for the Envoy system.

The "Inject opa & envoy sidecars into pod" rule is intended to be used with the Envoy system type and has been tested with the SLP install.  The default options should all match up with what was installed with the default Envoy SLP install instructions.  You will need to included the "inject-opa" (or whatever label you configure) to one of namespace/deployment/pod.  Make sure to have the rule in "Enforce" mode and publish the rule.

The rule will inject both OPA and Envoy (unless they already exist) and volumes for the configMaps for each.  It will also add a socket volume for communication between them.

### Istio Rule
Before using the rule make sure to have run the install instructions (or equivalent) for the Istio system.

The "Inject opa sidecar to istio pod" rule is intended to be used with the Istio system type and has been tested with the SLP install.  (this system should work well with other mesh systems, with just the name of the configMap needing to be updated)  The default options should all match up with what was installed with the default Istio SLP install instructions.  It will by default use the "istio-injection" label that can also be used for injecting the Istio proxy.  Make sure to have the rule in "Enforce" mode and publish the rule.

The rule will inject the OPA sidecar and the configMap volume.

## Overriding Images
Each of the rules will let you override the OPA image that is being used and the Envoy system will also let you override the init & Envoy images.  You can add the following lines in the mutation rule to override.

Note: The versions listed in the channels below should not be suggestions, they are just examples.  You should set versions according to your internal testing.

### OPA (Envoy & Istio)
Will be "openpolicyagent/opa:latest-envoy-rootless" by default
```
rapid_channel_opa_image := "openpolicyagent/opa:0.53.1-envoy-rootless"
regular_channel_opa_image := "openpolicyagent/opa:0.52.0-envoy-rootless"
stable_channel_opa_image := "openpolicyagent/opa:0.49.2-envoy-rootless"
```
### Envoy (Envoy only)
Will be "envoyproxy/envoy:v1.21-latest" by default (Envoy doesn't support a latest)
```
rapid_channel_envoy_image := "envoyproxy/envoy:v1.23-latest"
regular_channel_envoy_image := "envoyproxy/envoy:v1.21=2-latest"
stable_channel_envoy_image := "envoyproxy/envoy:v1.21-latest"
```

### Init (Envoy only)
Init is used to ensure all ingress & egress traffic is routed through the Envoy proxy

Will be "openpolicyagent/proxy_init:latest" by default
```
rapid_channel_init_image := "openpolicyagent/proxy_init:v8"
regular_channel_init_image := "openpolicyagent/proxy_init:v7"
stable_channel_init_image := "openpolicyagent/proxy_init:v6"
```

## Changes
If you find a bug or see some changes that you would like to have, feel free to file an issue or contact me directly.
