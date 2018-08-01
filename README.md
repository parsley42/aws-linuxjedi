This repository forms the bulk of data files I use to manage CloudFormat assets for LinuxJedi.org. Publishing this on GitHub serves primarily as example code for use with `ruby-awstools` and `Gopherbot` - my two main free software projects. In addition to this repository, see also `parsley42/linuxjedi-amis`, `parsley42/aws-devel`, and `parsley42/deploy-gopherbot`.

TODO: Remove most of the cruft below; large chunks have been moved in to separate repositories (linuxjedi-amis and aws-devel).

What follows below is primarily my own notes on how things are done. Eventually,
all of this should be done by **Gopherbot** automated jobs / **GopherCI**.

# Managing LinuxJedi AWS Resources

## Initializing an AWS Session

NOTE: An AWS Native environment already manages the contents of .aws/credentials, so skip this section on a native environment.

The credentials in `$HOME/.aws/credentials` are only useful when combined with
a TOTP token from Authy. To use:

```bash
$ eval `aws-session 012345`
$ aws ec2 describe-instances
...
```

## Manually Building an Instance

The temporary credentials managed by Cloud9 aren't usable by `ansible_hosts.dynamic`, so source `static-hosts` to use `ansible_hosts.yaml`.

* Create the instance with `ec2` from **ruby-awstools**:
```bash
$ ec2 create parse c9-native develbastion
info: Loading configuration and variables from ../ruby-awstools/examples/ReferenceArchitecture/cloudconfig.yaml
info: Loading configuration and variables from ./cloudconfig.yaml
info: Loading api template /home/ec2-user/environment/ruby-awstools/lib/rawstools/templates/ec2/ec2.yaml
info: Loading api template ./ec2/develbastion.yaml
201807231605 Found existing volume for parse: vol-0c83a4bd3cbd18854
201807231605 Created instance parse (id: i-018cc1fcaf13fe779), waiting for it to enter state running ...
201807231605 Running
201807231605 Attaching data volume: vol-0c83a4bd3cbd18854
201807231605 Adding public DNS record parse -> 18.209.157.86
info: Loading api template /home/ec2-user/environment/ruby-awstools/lib/rawstools/templates/route53/arec.yaml
201807231605 Adding private DNS record parse -> 10.42.0.61
info: Loading api template /home/ec2-user/environment/ruby-awstools/lib/rawstools/templates/route53/arec.yaml
```

* Run the `aws_init` playbook; you may need to provide `--key-file <name>`:
```bash
$ ansible-playbook aws_init.yaml -e target=parse --key-file ~/.ssh/aws-lj.pem

PLAY [Wait for DNS and get initial SSH keys] ******************************************************************************************

TASK [Gathering Facts] ****************************************************************************************************************
ok: [parse]
...
```

* Run the `c9devel` playbook:
```bash
$ ansible-playbook aws_init.yaml -e target=parse
...
```

* Log in and run the c9 installer from https://raw.githubusercontent.com/c9/install/master/install.sh:
```bash
$ wget https://raw.githubusercontent.com/c9/install/master/install.sh
--2018-07-23 16:12:54--  https://raw.githubusercontent.com/c9/install/master/install.sh
Resolving raw.githubusercontent.com (raw.githubusercontent.com)... 151.101.32.133
Connecting to raw.githubusercontent.com (raw.githubusercontent.com)|151.101.32.133|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 12157 (12K) [text/plain]
Saving to: ‘install.sh’

100%[=============================================================================================>] 12,157      --.-K/s   in 0s

2018-07-23 16:12:54 (111 MB/s) - ‘install.sh’ saved [12157/12157]

$ chmod +x install.sh
$ ./install.sh
...
```

## Updating the Cloud9 Cloudformation Stack

```bash
[parse@parse aws-linuxjedi]$ ./scripts/cloud9sg.rb > cfn/c9ssh/main.yaml
[parse@parse aws-linuxjedi]$ cfn update c9ssh
info: Loading configuration and variables from ../ruby-awstools/examples/ReferenceArchitecture/cloudconfig.yaml
info: Loading configuration and variables from ./cloudconfig.yaml
info: Loading stack configuration from ./cfn/c9ssh/stackconfig.yaml
info: Loading CloudFormation stack template ./cfn/c9ssh/main.yaml
info: Uploading cloudformation stack template c9ssh:main.yaml to s3://org.linuxjedi.raws/C9SSHAccess/main.yaml
info: Loading api template /home/parse/ruby-awstools/lib/rawstools/templates/s3/cfnput.yaml
info: Validating c9ssh:main.yaml
info: Issued update for stack c9ssh:C9SSHAccess: arn:aws:cloudformation:us-east-1:333970265527:stack/C9SSHAccess/ce022ae0-f16c-11e7-ab5b-500c217b26c6
```

## Building the LJ Standard Image

 1. Launch the build template:
```bash
$ ec2 create imgbuild aws-lj imgbuild
info: Loading configuration and variables from ../ruby-awstools/examples/ReferenceArchitecture/cloudconfig.yaml
...
```
2. Run the aws_init playbook:
```bash
$ export ANSIBLE_HOST_KEY_CHECKING=False
$ ansible-playbook aws_init.yaml -e target=imgbuild
...
```
3. Run the ljstandard playbook:
```bash
$ ansible-playbook ljstandard.yaml -e target=imgbuild
```

## Ansible Configuration Users

Notes on who has sudo/wheel during build
* The `aws-init` playbook uses standard `ssh` to detect user centos, ec2-user, or ubuntu
* A temporary `build` user is created w/ sudo ability
* The `build` user can use the `platform-vars` playbook to later determine the native build user
* The `build` user should run any needed playbooks to build / configure the system
* The last playbook being run should remove the `build` user:
    * For building images, the image build playbook should configure the image, then use the `build_remote` native user to remove the temporary `build` user
    * For configuring a live system, the user / robot should add their own credentials, and use those to remove `build`