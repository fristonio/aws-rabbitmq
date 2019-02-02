#!/bin/bash

set -euxo pipefail

setup_pkg_resources() {
	apt-key adv --keyserver "hkps.pool.sks-keyservers.net" --recv-keys "0x6B73A36E6026DFCA"
	wget -O - "https://github.com/rabbitmq/signing-keys/releases/download/2.0/rabbitmq-release-signing-key.asc" | sudo apt-key add -

	cat <<EOF > /etc/apt/sources.list.d/bintray.rabbitmq.list
deb https://dl.bintray.com/rabbitmq-erlang/debian xenial erlang
deb https://dl.bintray.com/rabbitmq/debian xenial main
EOF
}

install_rabbitmq() {
	apt-get install -y rabbitmq-server
	systemctl enable rabbitmq-server
}

# Set Erlang cookie for RabbitMQ clustering
set_erlang_cookie() {
    sh -c "echo '${erlang_cookie}' > /var/lib/rabbitmq/.erlang.cookie"
}

configure_rabbitmq() {
	cat <<EOF >> /etc/rabbitmq/rabbitmq.conf
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_aws

cluster_formation.aws.region = ap-southeast-1
cluster_formation.aws.access_key_id = ${rabbit_access_key}
cluster_formation.aws.secret_key = ${rabbit_secret_key}

cluster_formation.aws.use_autoscaling_group = true

log.file.level = debug
log.console.level = debug
EOF
	# For queue mirroring, all the queues are mirrored among all the nodes.
	rabbitmqctl set_policy ha-all ".*" '{"ha-mode":"all"}'
}

setup_rabbitmq() {
	set_erlang_cookie
	systemctl restart rabbitmq-server
	configure_rabbitmq
}

enable_plugins() {
	# Enable peer discovery plugin before node is first started.
	rabbitmq-plugins --offline enable rabbitmq_peer_discovery_aws
	rabbitmq-plugins enable rabbitmq_management
	systemctl restart rabbitmq-server
}

# This is to start the discovery service by rabbitmq aws peer discovery plugin
reset_and_start_app() {
	rabbitmqctl stop_app
	rabbitmqctl reset
	rabbitmqctl start_app
}

setup_admin_user() {
	rabbitmqctl add_user ${rabbitmq_admin_user} ${rabbitmq_admin_pass}
	rabbitmqctl set_user_tags ${rabbitmq_admin_user} administrator
	rabbitmqctl set_permissions -p / ${rabbitmq_admin_user} ".*" ".*" ".*"
	rabbitmqctl add_vhost /
	rabbitmqctl delete_user guest
}

main () {
	setup_pkg_resources
	apt-get update
	install_rabbitmq
	setup_rabbitmq
	enable_plugins

	reset_and_start_app
	setup_admin_user

	echo "[*] RabbitMQ setup done."
}

main "$@"
