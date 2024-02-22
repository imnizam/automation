aws autoscaling put-lifecycle-hook \
--lifecycle-hook-name proxysql-reserved-cluster-lc-hook \
--auto-scaling-group-name proxysql-reserved-cluster \
--lifecycle-transition autoscaling:EC2_INSTANCE_TERMINATING \
--role-arn arn:aws:iam::12345:role/ecs-cluster-spot-asg-ASGlifecycleHookRole-12456 \
--notification-target-arn arn:aws:sns:us-west-2:123456:phantom_ecs_asg_lifecycle_target \
--heartbeat-timeout 600 \
--default-result CONTINUE

