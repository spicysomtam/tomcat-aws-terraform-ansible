#!/bin/bash

ud=userdata.sh

echo "#!/bin/bash -xv" > $ud
echo "exec > /tmp/userdata.log 2>&1" >> $ud
echo "amazon-linux-extras install -y ansible2" >> $ud
echo "cat > install-tomcat.yaml << EEE" >> $ud

cat install-tomcat.yaml >> $ud
echo "EEE" >> $ud

echo "cat > tomcat-unit.j2 << FFF" >> $ud
cat tomcat-unit.j2 >> $ud
echo "FFF" >> $ud
echo "ansible-playbook -i127.0.0.1, -c local -e bucket=mybucket install-tomcat.yaml" >> $ud
echo "rm -f install-tomcat.yaml tomcat-unit.j2" >> $ud
