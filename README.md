TuxTech infrastructure automations with Ansible
===
A scalable automated provisioning platform for CentOS 7, 8, 8Stream, RHEL7, RHEL8 using free and opensource tools:
* [VMware ESXi](https://www.vmware.com/ca/products/esxi-and-esx.html)
* [The Foreman](https://theforeman.org)
* [CentOS](https://www.centos.org) / [RHEL](https://www.redhat.com/en/technologies/linux-platforms/enterprise-linux)
* [FreeIPA](https://www.freeipa.org/) ([IDM](https://access.redhat.com/products/identity-management))
* [Apache HTTPd](https://httpd.apache.org)

purpose of this is to...  
Scripts for automating virtual infrastructure in the [Tuxtech.com](https://www.tuxtech.com) lab.
* ESXi Configuration
* Foreman/Satellite installation and configuration
* CentOS7/8Stream provisioning and configuration
* FreeIPA/IDM installation and configuration
* Apache web server installation, configuration, SSL-enablement and content 

see: *tuxtech-main.yml* for gist.

preamble:
linked stuff
might not work for any one else but..

Application Roles combine an operating system, version and purpose.
Using the dynamic provisioning capabilities of Foreman, any number of combinations and scale are possible without a pre-built VMware virtual template.  
Application Role customizations are provided by matching a Foreman hostgroup and an ansible script in the _tuxtech.os.10_provision_os_ collection.

Application Roles available:

| Role | OS | Version | Description |
| ---- | ---- | --- | --- |
| CentOS_7_GP | CentOS | 7 | General Purpose
| CentOSStream_8_GP  | CentOSStream | 8 | General Purpose
| CentOSStream_8_FMN | CentOSStream | 8 | Foreman
| CentOSStream_8_IDM | CentOSStream | 8 | FreeIPA/IDM
| CentOSStream_8_WEB | CentOSStream | 8 | Apache HTTPd

Requirements
===

Tested With:
| <!-- --> | <!-- --> |
|---|---|
|python             | 3.9.6  |
|ansible            | 4.4.0  |
|ansible-core       | 2.11.3 |
|ansible-lint       | 5.1.2  |
|pyvmomi            | 7.0.2  |
|community.vmware   | 1.12.0 | 
|theforeman.foreman | 2.1.2  |

Configuration
===
Inventory
---
DNS must already exist  
Define ansible/infrastructure groups  
Define hostname, IP address and application role/hostgroup

VM defaults will applied from _tuxtech.vmware.20_create_vmclients_ unless specified:  
| key | value |
| ------- | ------- |
| num_cpus | 2 |
| memory_mb | 2560 |
| sda_gb | 1 |
| sdb_gb | 20 |

TuxTech.com lab _inventory_:
```
[esxi]
esxi.tuxtech.com        ipaddr=192.168.1.4
mondain.tuxtech.com     ipaddr=192.168.1.11

[foreman]
foreman1.tuxtech.com    ipaddr=192.168.1.203    hostgroup='CentOSStream_8_FMN'
foreman2.tuxtech.com    ipaddr=192.168.1.204    hostgroup='CentOSStream_8_FMN'

[foreman:vars]
memory_mb=8192
sdb_gb=80

[idm]
idm1.tuxtech.com        ipaddr=192.168.1.201    hostgroup='CentOSStream_8_IDM'
idm2.tuxtech.com        ipaddr=192.168.1.202    hostgroup='CentOSStream_8_IDM'

[web]
web1.tuxtech.com        ipaddr=192.168.1.219    hostgroup='CentOSStream_8_WEB'
web2.tuxtech.com        ipaddr=192.168.1.220    hostgroup='CentOSStream_8_WEB'

[clients]
centos7-1.tuxtech.com   ipaddr='192.168.1.217'  hostgroup='CentOS_7_GP'
centos7-2.tuxtech.com   ipaddr='192.168.1.218'  hostgroup='CentOS_7_GP'
rhel7-1.tuxtech.com     ipaddr='192.168.1.211'  hostgroup='CentOS_7_GP'
rhel7-2.tuxtech.com     ipaddr='192.168.1.212'  hostgroup='CentOS_7_GP'
rhel8-1.tuxtech.com     ipaddr='192.168.1.213'  hostgroup='CentOSStream_8_GP'
rhel8-2.tuxtech.com     ipaddr='192.168.1.214'  hostgroup='CentOSStream_8_GP'
centstr8-1.tuxtech.com  ipaddr='192.168.1.215'  hostgroup='CentOSStream_8_GP'
centstr8-2.tuxtech.com  ipaddr='192.168.1.216'  hostgroup='CentOSStream_8_GP'

```

Global configuration
---
For clarity and scalability, we put infrastructure configuration in a global dictionary. 
These hostnames and credentials represent endpoints ansible will target for API commands. 
Encrypting sensitive credentials with inline ansible vault is strongly recommended.

TuxTech.com lab _tuxtech-configuration.yml_:

```
---
# Main configuration for TuxTech infrastructure
tuxtech:
  vmware:
    hostname: 'esxi.tuxtech.com'
    username: 'root'
    password: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      EXAMPLE
  foreman:
    hostname: 'foreman1.tuxtech.com'
    username: 'admin'
    password: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      EXAMPLE
  idm:
    hostname: 'idm1.tuxtech.com'
    username: 'admin'
    password: !vault |
      EXAMPLE
```
Usage
===


VMware ESXi
-----------
Configure common settings for an ESXi host
- ESXi host must have an IP address, basic network settings and dns entry.
- ESXi host must have root password set and matched in _tuxtech-configuration.yml_

`ansible-playbook tuxtech-main.yml --tags vmware_10 --limit esxi
`

Create VMware virtual machine guest clients   
 - ESXi host must be either in evaluation mode or licensed for vSphere APIs

`ansible-playbook tuxtech-main.yml --tags vmware_20 --limit idm,clients
`


Delete VMware virtual guest clients
- ESXi host must be either in evaluation mode or licensed for vSphere APIs

`ansible-playbook tuxtech-main.yml --tags vmware_99 --limit clients
`

Foreman
-------
Configure common settings for a Foreman/Satellite server
- Foreman host must have admin password set and matched in _tuxtech-configuration.yml_

`ansible-playbook tuxtech-main.yml --tags foreman_10 --limit foreman1.tuxtech.com
`

Create Foreman host client definitions with MAC address from ESXi
- virtual machine must exist in VMware

`ansible-playbook tuxtech-main.yml --tags foreman_20 --limit idm,clients
`

Delete Foreman host clients

`ansible-playbook tuxtech-main.yml --tags foreman_99 --limit clients
`

FreeIPA/IDM
-----------
Provision and configure the operating system
- inventory host must have matching Foreman/Satellite hostgroup defined

`ansible-playbook tuxtech-main.yml --tags os_10 --limit idm1.tuxtech.com
`

Decommision operating system
- inventory host must have matching Foreman/Satellite hostgroup defined

`ansible-playbook tuxtech-main.yml --tags os_99 --limit idm1.tuxtech.com
`


Streamlined usage
====
provision: vmware_20, foreman_20, os_10  
delete: vmware_99, foreman_99, os_99

Three-step provision process:

Step | Ansible Tag |
-----|----------|
 Provision Operation System  | os_provision |
 Configure Operation System | os_config |
 Configure Application Role | role_config |

Provision  
`ansible-playbook tuxtech-main.yml --tags provision --limit foreman1.tuxtech.com
`

`ansible-playbook tuxtech-main.yml --tags provision --limit idm2.tuxtech.com,web
`

`ansible-playbook tuxtech-main.yml --tags delete --limit web2.tuxtech.com
`

Use _--skip-tags_ to run only certain pieces of provisioning.  For example, to update web configuration/content across the fleet, skip initial provisioning and OS configuration, only running the application role:  
`ansible-playbook tuxtech-main.yml --tags os_10 --limit web2.tuxtech.com --skip-tags os_provision,os_config
`
