# Application Manifests for Snapshot Feature

# Example how-to
1. Create a new KOTS application
2. Copy "kubernetes.yaml" from /kubernetes-installer to the "Kubernetes Installers" in Vendor and promote to channels. (Or simply add `velero: version: latest` to your default YAML)
3. Create a new release with default manifests. 
4. Drag and drop contents from this /manifests folder. 
5. Promote your release. Admin Console setup may need to happen separately (e.g., customer using GCP to backup)
