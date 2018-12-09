#!/bin/bash -xv
exec > /tmp/userdata.log 2>&1
amazon-linux-extras install -y ansible2
cat > install-tomcat.yaml << EEE
---
- hosts: all
  become: yes
  pre_tasks:
  - name: Ensure boto and boto3 are installed
    package:
      name: "{{ item }}"
      state: present
    with_items:
    - python2-botocore
    - python2-boto3
  vars:
    javaver: 8u191
    javarpm: jdk-{{javaver}}-linux-x64.rpm
#   This only works with 'current' version; when oracle upgrades the version you need credentials and a valid cookie to download archived versions.
#   The url also changes. So this is not a long term solution. So we put the versions we want in an s3 bucket, which bypasses all the oracle credentials nonsense.
#    javaurl: http://download.oracle.com/otn-pub/java/jdk/{{javaver}}-b12/2787e4a523244c269598db4e85c51e0c/{{javarpm}}
    bucket: mybucket
    tomuser: tomcat8
    tomver: 8.0.53
    tomarc: apache-tomcat-{{tomver}}.tar.gz
    tominstdir: /usr/local
  tasks:
#   Downloading from oracle is a nightmare; welcome to corporates!
  - name: Download java jdk {{javaver}}
#    get_url:
#      url: "{{javaurl}}"
#      dest: /tmp
#      headers: 
#        Cookie: oraclelicense=accept-securebackup-cookie
    aws_s3:
      mode: get
      bucket: "{{bucket}}"
      object: /java/{{javarpm}}
      dest: /tmp/{{javarpm}}
      overwrite: different
  - name: Install jdk {{javaver}}
    yum:
      name: /tmp/{{javarpm}}
      state: present
  - name: Create {{tomuser}} group
    group:
      name: "{{tomuser}}"
      state: present
  - name: Create {{tomuser}} user
    user: 
      name: "{{tomuser}}"
      home: "{{tominstdir}}/{{tomuser}}"
      createhome: no
      group: "{{tomuser}}"
      shell: /bin/nologin
      state: present
  - name: Download and install tomcat {{tomver}}
    unarchive:                                                                                                                                        
      src: https://archive.apache.org/dist/tomcat/tomcat-8/v{{tomver}}/bin/{{tomarc}}
      dest: "{{tominstdir}}"
      remote_src: yes      
      creates: "{{tominstdir}}/{{tomuser}}"
  - name: Rename unpacked archive to {{tomuser}}
    command: creates={{tominstdir}}/{{tomuser}} mv {{tominstdir}}/apache-tomcat-{{tomver}} {{tominstdir}}/{{tomuser}}
  - name: Set unpacked archive ownership to {{tomuser}}:{{tomuser}}
    file:
      path: "{{tominstdir}}/{{tomuser}}"
      owner: "{{tomuser}}"
      group: "{{tomuser}}"
      recurse: yes
  - name: Set group recursive read on tomcat conf dir
    file:
      path: "{{tominstdir}}/{{tomuser}}/conf"
      mode: g+r
      recurse: yes
  - name: Set group execute on tomcat conf dir
    file:
      path: "{{tominstdir}}/{{tomuser}}/conf"
      mode: g+x
  - name: install {{tomuser}} systemd unit file
    template:
      src: tomcat-unit.j2
      dest: /etc/systemd/system/{{tomuser}}.service
  - name: start service {{tomuser}}
    systemd:
      state: started
      name: "{{tomuser}}"
      daemon_reload: yes
  - name: rm /tmp/{{javarpm}}
    file:
      path: /tmp/{{javarpm}}
      state: absent
EEE
cat > tomcat-unit.j2 << FFF
# Systemd unit file for tomcat
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking

# Openjdk
#Environment=JAVA_HOME=/usr/lib/jvm/jre
# Oracle jdk
Environment=JAVA_HOME=/usr/java/latest/jre
Environment=CATALINA_PID={{tominstdir}}/{{tomuser}}/temp/{{tomuser}}.pid
Environment=CATALINA_HOME={{tominstdir}}/{{tomuser}}
Environment=CATALINA_BASE={{tominstdir}}/{{tomuser}}
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Djava.net.preferIPv4Stack=true -Djava.net.preferIPv4Addresses=true'

ExecStart={{tominstdir}}/{{tomuser}}/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID

User={{tomuser}}
Group={{tomuser}}
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
FFF
ansible-playbook -i127.0.0.1, -c local -e bucket=mybucket install-tomcat.yaml
rm -f install-tomcat.yaml tomcat-unit.j2
