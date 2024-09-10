packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# GitHub Runnerのバージョン指定 2024/09/03現在最新バージョンは2.319.1
variable "runner_version" {
  description = "The version (no v prefix) of the runner software to install https://github.com/actions/runner/releases. The latest release will be fetched from GitHub if not provided."
  default     = "2.319.1"
}

# リージョン指定
variable "region" {
  description = "The region to build the image in"
  type        = string
  default     = "ap-northeast-1"
}

# セキュリティグループIDの指定
variable "security_group_id" {
  description = "The ID of the security group Packer will associate with the builder to enable access"
  type        = string
  default     = "sg-01d1bca78c54a279e" # allow-ssh
}

# サブネットIDの指定
variable "subnet_id" {
  description = "If using VPC, the ID of the subnet, such as subnet-12345def, where Packer will launch the EC2 instance. This field is required if you are using an non-default VPC"
  type        = string
  default     = "subnet-00432bd9dc1262304" # packer用のパブリックサブネット
}

# パブリックIPアドレスの関連付け
variable "associate_public_ip_address" {
  description = "If using a non-default VPC, there is no public IP address assigned to the EC2 instance. If you specified a public subnet, you probably want to set this to true. Otherwise the EC2 instance won't have access to the internet"
  type        = string
  default     = null
}

# インスタンスタイプの指定
variable "instance_type" {
  description = "The instance type Packer will use for the builder"
  type        = string
  default     = "t3.large"
}

# ルートボリュームサイズの指定
variable "root_volume_size_gb" {
  type    = number
  default = 8
}

# インスタンス終了時にEBSボリュームを削除するかどうかの指定
variable "ebs_delete_on_termination" {
  description = "Indicates whether the EBS volume is deleted on instance termination."
  type        = bool
  default     = true
}

# グローバルタグの指定
variable "global_tags" {
  description = "Tags to apply to everything"
  type        = map(string)
  default     = {}
}

# AMIタグの指定
variable "ami_tags" {
  description = "Tags to apply to the AMI"
  type        = map(string)
  default     = {}
}

# スナップショットタグの指定
variable "snapshot_tags" {
  description = "Tags to apply to the snapshot"
  type        = map(string)
  default     = {}
}

# カスタムシェルコマンドの指定
variable "custom_shell_commands" {
  description = "Additional commands to run on the EC2 instance, to customize the instance, like installing packages"
  type        = list(string)
  default     = []
}

# 一時セキュリティグループのソースとしてパブリックIPを使用するかどうかの指定
variable "temporary_security_group_source_public_ip" {
  description = "When enabled, use public IP of the host (obtained from https://checkip.amazonaws.com) as CIDR block to be authorized access to the instance, when packer is creating a temporary security group. Note: If you specify `security_group_id` then this input is ignored."
  type        = bool
  default     = false
}

# github runnnerのダウンロード
data "http" github_runner_release_json {
  url = "https://api.github.com/repos/actions/runner/releases/latest"
  request_headers = {
    Accept = "application/vnd.github+json"
    X-GitHub-Api-Version : "2022-11-28"
  }
}

# ローカル変数の指定
locals {
  runner_version = coalesce(var.runner_version, trimprefix(jsondecode(data.http.github_runner_release_json.body).tag_name, "v"))
}

source "amazon-ebs" "githubrunner" {
  ami_name                                  = "ubuntu-custom-java-node-php-${formatdate("YYYYMMDDhhmm", timestamp())}"
  instance_type                             = var.instance_type
  region                                    = var.region
  security_group_id                         = var.security_group_id
  subnet_id                                 = var.subnet_id
  associate_public_ip_address               = var.associate_public_ip_address
  temporary_security_group_source_public_ip = var.temporary_security_group_source_public_ip

  source_ami_filter {
    filters = {
      name                = "*ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
  tags = merge(
    var.global_tags,
    var.ami_tags,
    {
      OS_Version    = "ubuntu-jammy"
      Release       = "Latest"
      Base_AMI_Name = "{{ .SourceAMIName }}"
  })
  snapshot_tags = merge(
    var.global_tags,
    var.snapshot_tags,
  )

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = "${var.root_volume_size_gb}"
    volume_type           = "gp3"
    delete_on_termination = "${var.ebs_delete_on_termination}"
  }
}

build {
  name = "githubactions-runner"
  sources = [
    "source.amazon-ebs.githubrunner"
  ]
  provisioner "shell" {
  environment_vars = [
    "DEBIAN_FRONTEND=noninteractive"
  ]
  inline = concat([
    "sudo cloud-init status --wait",
    "sudo DEBIAN_FRONTEND=noninteractive apt-get -y update",
    "sudo apt-get -y install ca-certificates curl gnupg lsb-release",
    "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
    "echo deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
    "sudo apt-get -y update",
    "sudo apt-get -y install docker-ce docker-ce-cli containerd.io jq git unzip",
    "sudo systemctl enable containerd.service",
    "sudo service docker start",
    "sudo usermod -a -G docker ubuntu",
    "sudo curl -f https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o amazon-cloudwatch-agent.deb",
    "sudo dpkg -i amazon-cloudwatch-agent.deb",
    "sudo systemctl restart amazon-cloudwatch-agent",
    "sudo curl -f https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip",
    "unzip awscliv2.zip",
    "sudo ./aws/install",
    # Node.js関連
    "curl -sLS https://deb.nodesource.com/setup_22.x | sudo bash -",
    "sudo apt-get install -y nodejs",
    # PHP関連
    "sudo add-apt-repository ppa:ondrej/php -y",
    "sudo apt-get update",
    "sudo apt-get install -y libzip-dev",
    "sudo apt-get install -y php8.3 php8.3-cli php8.3-intl php8.3-common php8.3-dev php8.3-fpm php8.3-gd php8.3-mbstring php8.3-pdo php8.3-xml php8.3-pgsql php8.3-bcmath php8.3-zip php8.3-curl php-pear",
    "sudo apt-get install -y libmagickwand-dev",
    "sudo apt-get install -y imagemagick gcc",
    "sleep 5",
    # imagickのインストール(apt-getでインストールできないため)
    "wget https://pecl.php.net/get/imagick-3.7.0.tgz",
    "tar -xvzf imagick-3.7.0.tgz",
    "cd imagick-3.7.0",
    "phpize",
    "./configure",
    "make",
    "sudo make install",
    "sudo echo \"extension=imagick.so\" | sudo tee -a /etc/php/8.3/cli/php.ini",
    # Composerのインストール    
    "curl -sS https://getcomposer.org/installer | php",
    "sudo mv composer.phar /usr/local/bin/composer",
    "sudo composer self-update",
    # Java 17のインストール
    "sudo apt-get update && sudo apt-get install -y wget dpkg",
    "sudo wget https://download.java.net/openjdk/jdk17/ri/openjdk-17+35_linux-x64_bin.tar.gz",
    "sudo tar zxvf openjdk-17+35_linux-x64_bin.tar.gz",
    "sudo mv jdk-17 /usr/local/",
    "sudo update-alternatives --install /usr/bin/java java /usr/local/jdk-17/bin/java 1",
    "sudo update-alternatives --install /usr/bin/javac javac /usr/local/jdk-17/bin/javac 1",
    # # PostgreSQLのインストールと設定
    "sudo apt-get install -y postgresql postgresql-contrib",
    "sudo systemctl enable postgresql",
    "sudo systemctl start postgresql",
    "sudo -u postgres psql -c \"CREATE USER laravel WITH PASSWORD 'laravel';\"",
    "sudo -u postgres psql -c \"CREATE DATABASE test OWNER laravel;\"",
    "sudo -u postgres psql -c \"CREATE DATABASE laravel OWNER laravel;\""
  ], var.custom_shell_commands)
}

  provisioner "file" {
    content = templatefile("../install-runner.sh", {
      install_runner = templatefile("../../modules/runners/templates/install-runner.sh", {
        ARM_PATCH                       = ""
        S3_LOCATION_RUNNER_DISTRIBUTION = ""
        RUNNER_ARCHITECTURE             = "x64"
      })
    })
    destination = "/tmp/install-runner.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "RUNNER_TARBALL_URL=https://github.com/actions/runner/releases/download/v${local.runner_version}/actions-runner-linux-x64-${local.runner_version}.tar.gz"
    ]
    inline = [
      "sudo chmod +x /tmp/install-runner.sh",
      "echo ubuntu | tee -a /tmp/install-user.txt",
      "sudo RUNNER_ARCHITECTURE=x64 RUNNER_TARBALL_URL=$RUNNER_TARBALL_URL /tmp/install-runner.sh",
      "echo ImageOS=ubuntu22 | tee -a /opt/actions-runner/.env"
    ]
  }

  provisioner "file" {
    content = templatefile("../start-runner.sh", {
      start_runner = templatefile("../../modules/runners/templates/start-runner.sh", { metadata_tags = "enabled" })
    })
    destination = "/tmp/start-runner.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo mv /tmp/start-runner.sh /var/lib/cloud/scripts/per-boot/start-runner.sh",
      "sudo chmod +x /var/lib/cloud/scripts/per-boot/start-runner.sh",
    ]
  }
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
