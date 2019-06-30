
cidr            = "192.168.0.0/16"
public_subnets  = ["192.168.0.0/18", "192.168.64.0/18"]
private_subnets = ["192.168.128.0/18", "192.168.192.0/18"]
azs             = ["eu-west-1a", "eu-west-1b"]
name            = "Blue Green"
enable_blue     = false
enable_green    = true
