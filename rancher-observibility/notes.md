
Request

- POST: https://rancher/v3/clusters/c-fz5rn?action=enableMonitoring
- POST: https://rancher/v3/clusters/c-zv6zm/namespace
- POST: https://rancher/v3/projects/c-zv6zm:p-hqr7d/app

note that istio has a seperate call to create the namespace in the system project, this may be why its not supported at cluster creation..
 
