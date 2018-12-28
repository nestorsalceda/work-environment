resource "aws_key_pair" "k8s" {
  key_name   = "kubernetes-heptio-aws"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA0Xdx1tnCMf7CwLS2rOrcUakmQfSrO5ITpIdz925HeQpSsybY6swDHOy9fjpuPLiHkKBSOjSPAYlvS61nllhFyPdzeFGctgcCQ0wxWaTpbdtt1iguT+5lx6pxA+M1q9Tx8uLlSyETVcywh2k/iRjq9hlXusapl4SfgfRXB4srNLKfkps7H3BHV0wqZLr1gDTmgxkp0uJ0QmfjlA6Bvo0JqV8zq640mofzQ8xTWQUw4wlWH+FuknWPFYfoKxPTdFc6grqyIEDkEHPy6hwFYeHCNgEA7c0qC7Ghw400ER5sHVcW8dakRS3cAGjrbSoqRtQIci7vjHxVxT4eBe3qtDJ5UQ== nestor@point"
}

resource "aws_cloudformation_stack" "k8s" {
  name = "kubernetes-heptio-aws"

  parameters {
    AvailabilityZone = "eu-west-1a"
    AdminIngressLocation = "0.0.0.0/0"
    KeyName = "${aws_key_pair.k8s.key_name}"
    VPCCIDR = "10.0.0.0/16"
    PrivateSubnetCIDR = "10.0.0.0/19"
    PublicSubnetCIDR = "10.0.128.0/20"
    ClusterDNSProvider = "CoreDNS"
    NetworkingProvider = "calico"
    K8sNodeCapacity = 3
    InstanceType = "m4.large"
    DiskSizeGb = "40"
    BastionInstanceType = "t2.micro"
    QSS3BucketName = "aws-quickstart"
    QSS3KeyPrefix = "quickstart-heptio/"
  }

  template_url = "https://aws-quickstart.s3.amazonaws.com/quickstart-heptio/templates/kubernetes-cluster-with-new-vpc.template"

  capabilities = ["CAPABILITY_IAM"]
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = "scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ProxyCommand=\"ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@${aws_cloudformation_stack.k8s.outputs.BastionHostPublicIp} nc %h %p\" ubuntu@${aws_cloudformation_stack.k8s.outputs.MasterPrivateIp}:~/kubeconfig kubeconfig"
  }
}
