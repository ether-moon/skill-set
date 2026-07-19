# Cache proposal notes

The API's measured p95 latency is 420 ms in the July 18 staging benchmark. The proposal adds Redis as a dependency to cache catalog reads. Cached catalog entries must expire after 30 days. The team has not estimated the infrastructure cost. Redis reduces repeated database reads but adds another service to operate.
