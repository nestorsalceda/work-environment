resource "aws_key_pair" "k8s" {
  key_name   = "kubernetes-heptio-aws"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
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
