You are an expert in DevOps and observability stacks. Generate a complete, plug-and-play setup using Docker Compose that provides a modular observability stack with Prometheus, Loki, Promtail, and Grafana. The setup should be designed so that developers can drop it into any project and immediately have log aggregation and monitoring without writing any LogQL queries.

Requirements:

Directory structure – Show a clear folder layout for the stack.

podman Compose file – Include all services (Prometheus, Loki, Promtail, Grafana) with proper volume mounts for configuration and logs.

Configuration files – Provide the content for:

prometheus.yml

loki-config.yml

promtail-config.yml – Highlight that this is the only file developers need to modify, and include clear comments indicating which lines to change for a new service (service name and log path). Show how to add multiple services by repeating the labels block.

grafana-datasources.yml – Auto-provision Loki and Prometheus as datasources in Grafana.

Grafana dashboard setup – Explain how to create a “zero-query” dashboard:

Create a variable named service using Loki as the data source and the query label_values(service).

Add a Logs panel with the query {service="$service"}.

Optionally provide a JSON export of this dashboard so it can be auto-provisioned.

Instructions – Briefly explain how to start the stack (docker-compose up -d), how to access Grafana, and how to use the dashboard.

Tone and format – Write in a clear, instructional style. Use code blocks for all file contents. Keep it practical and focused on reusability.

Make sure the output is self-contained and can be copied directly by a user to create the stack.