## Injecting Failures with Chaosd

**Chaosd** is a lightweight chaos engineering tool for virtual machines and non-Kubernetes environments unlike Chaos Mesh which requires Kubernetes. It allows you to inject faults into distributed systems to test their resilience and recovery mechanisms.
To evaluate the resilience of my system, I used Chaosd to simulate various failure scenarios in the distributed environment, including:  
- **Disk saturation** to test storage limits.  
- **Container crashes** to simulate service failures.  
- **Volume deletion** to test data loss handling.  
- **Cassandra node failures** to evaluate replication and restoration mechanisms.  

These experiments help ensure that the CI/CD pipeline and the distributed Cassandra-based architecture can recover gracefully under different stress conditions.  


