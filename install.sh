# This is a personal exploration of the kubemci zone printer tutorial
# Original tutorial here: https://github.com/GoogleCloudPlatform/k8s-multicluster-ingress/tree/master/examples/zone-printer

# Install kubemci
go get -u github.com/GoogleCloudPlatform/k8s-multicluster-ingress/cmd/kubemci

# Configure environmental variables
PROJECT=my-gcp-project-id

# Create Google Kubernetes Engine clusters around the world in Iowa, Belgium and Taiwan
KUBECONFIG=clusters.yaml gcloud container clusters create --cluster-version=1.10.9 --zone=us-central1-a cluster-americas
KUBECONFIG=clusters.yaml gcloud container clusters create --cluster-version=1.10.9 --zone=europe-west1-b cluster-europe
KUBECONFIG=clusters.yaml gcloud container clusters create --cluster-version=1.10.9 --zone=asia-east1-a cluster-asiapacific

# Deploy the zone printer application
for ctx in $(kubectl config get-contexts -o=name --kubeconfig clusters.yaml); do
  kubectl --kubeconfig clusters.yaml --context="${ctx}" create -f manifests/
done

# Reserve a static IP address
ZP_KUBEMCI_IP="zp-kubemci-ip"
gcloud compute addresses create --global "${ZP_KUBEMCI_IP}"

# Modify the ingress with your static IP address
sed -i -e "s/\$ZP_KUBEMCI_IP/${ZP_KUBEMCI_IP}/" ingress/ingress.yaml

# Deploy the multi-cluster ingress using kubemci
kubemci create zone-printer --ingress=ingress/ingress.yaml --gcp-project=$PROJECT --kubeconfig=clusters.yaml

# Check the status of the multi-cluster ingress
kubemci get-status zone-printer --gcp-project=$PROJECT

# Visit the site, using a VPN to modify your internet location and see that your traffic gets routed to the nearest GKE cluster
