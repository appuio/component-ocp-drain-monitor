// main template for openshift4-slos
local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';

local slo = import 'slos.libsonnet';

local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.ocp_drain_monitor;

local upstreamNamespace = 'ocp-drain-monitor-system';

local removeUpstreamNamespace = {
  patch: std.manifestJsonMinified({
    '$patch': 'delete',
    apiVersion: 'v1',
    kind: 'Namespace',
    metadata: {
      name: upstreamNamespace,
    },
  }),
};

com.Kustomization(
  'https://github.com/appuio/ocp-drain-monitor//config/default',
  params.manifests_version,
  {
    'ghcr.io/appuio/ocp-drain-monitor': {
      local image = params.images.ocp_drain_monitor_controller,
      newTag: image.tag,
      newName: '%(registry)s/%(image)s' % image,
    },
    'gcr.io/kubebuilder/kube-rbac-proxy': {
      local image = params.images.kube_rbac_proxy,
      newTag: image.tag,
      newName: '%(registry)s/%(image)s' % image,
    },
  },
  params.kustomize_input {
    patches+: [
      removeUpstreamNamespace,
    ],
    patchesStrategicMerge+: [
    ],
  },
)
