# Labels and selectors are how Kubernetes resources discover each other.
#
# Example:
#
# Deployment
#     │
#     └── creates Pods
#             │
#             └── label:
#                 app=petclinic
#                        ▲
#                        │
#                selector:
#                app=petclinic
#                        │
#                    Service
#
# The Service does NOT know Pod names or IP addresses.
# It simply forwards traffic to every Pod matching its selector.
