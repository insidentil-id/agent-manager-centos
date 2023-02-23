#!/bin/bash
# Script By Cyber Threat Hunting Team
# Direktorat Operasi Keamanan Siber
# Badan Siber dan Sandi Negara
# Tahun 2022
# Special Thanks to Team: maNDayUGIikHSanNaLonAldAvIDSUBkHAnREndRAalSItAdAFi

check_root() {
	echo "---Mengecek Sistem Root---"
	if [[ $EUID -ne 0 ]]; 
    then
	   echo "[Error Step 1] Jalankan Script dengan Root (sudo su)"
	   exit 1
	else
       echo "[Step 1] Checking Root Access Complete"
    fi
	echo ""
	echo ""
}

check_os(){
    echo "---Mengecek Operating System---"
    # Installing ELK Stack
    if [ "$(grep -Ei 'centos|redhat' /etc/*release)" ]
        then
            echo " It's a RHEL based system"
            echo "[Step 2] Checking OS Complete"
            echo ""
            echo ""
    else
        echo "This script doesn't support ELK installation on this OS."
        exit 1
    fi
}

check_update() {
    echo "---Mengecek Update dan Variabel---"
	sudo yum update
    sudo yum install wget
    mkdir assets
	export $(cat .env | xargs)
    echo "[Step 3] Checking Update and Variable Complete"
    echo ""
	echo ""
}

check_java() {
    echo "---Mengecek Versi Java---"
    java -version
    if [ $? -ne 0 ]
        then
            # Installing Java 8 if it's not installed
            sudo yum install java-1.8.0-openjdk
        # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
        elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
            then
                sudo yum install java-1.8.0-openjdk
    fi
    echo "[Step 4] Checking Java Version Complete"
    echo ""
	echo ""
}

install_fw_nginx() {
    echo "---install firewall and nginx---"
    sudo yum install epel-release -y
    sudo yum install ufw -y
    sudo yum install nginx -y
    sudo ufw allow 22/tcp
    yes | sudo ufw enable
    sudo systemctl enable nginx
    sudo systemctl start nginx
    sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
    sudo yum -y install yum-utils
    sudo yum-config-manager --disable 'remi-php*'
    sudo yum-config-manager --enable remi-php81
    sudo yum install php-fpm -y
    sudo cp conf/default /etc/nginx/conf.d/default
    sudo systemctl restart nginx
    sudo ufw allow from any to any port 80
    sudo chmod -R 777 /usr/share/www/html
    sudo iptables -I INPUT -p tcp --dport 5601 -j ACCEPT
    sudo iptables -I INPUT -p tcp --dport 9200 -j ACCEPT
    echo "[Step 5] Install firewall and nginx Complete"
    echo ""
	echo ""
}

install_elasticsearch(){
    echo "---install Elasticsearch---"
    wget -O assets/elasticsearch-${ELASTICSEARCH_VERSION}-x86_64.rpm https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}-x86_64.rpm
    yes | sudo rpm --install assets/elasticsearch-${ELASTICSEARCH_VERSION}-x86_64.rpm
    sudo systemctl daemon-reload
    sudo systemctl enable elasticsearch.service
    sudo systemctl start elasticsearch.service
    sudo ufw allow from any to any port 9200
    yes | sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic | tail -1 > password-elasticsearch.txt
    sudo chmod 777 password-elasticsearch.txt
    echo ""
    echo "[Step 6] Install Elasticsearch Complete"
    echo ""
	echo ""
}

install_kibana(){
    echo "---install Kibana---"
    wget -O assets/kibana-${ELASTICSEARCH_VERSION}-x86_64.rpm https://artifacts.elastic.co/downloads/kibana/kibana-${ELASTICSEARCH_VERSION}-x86_64.rpm
    yes | sudo rpm --install assets/kibana-${ELASTICSEARCH_VERSION}-x86_64.rpm
    sudo systemctl daemon-reload
    sudo systemctl enable kibana.service
    sudo systemctl start kibana.service
    sudo cp conf/kibana.yml /etc/kibana/kibana.yml
    sudo ufw allow from any to any port 5601
    #Fleet Port
    sudo ufw allow from any to any port 8220
    echo "[Step 7] Install Kibana Complete"
    echo ""
	echo ""
}

login_kibana(){
    echo "---Login Kibana---"
    read -p "Buka halaman http://$(hostname -I):5601 (Press Anything To Continued)"
    echo "Masukkan Token Registrasi Berikut Pada Enroll Token"
    sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
    read -p "Press Anything To Continued...."
    echo "Masukkan Kode Verifikasi Berikut"
    sudo /usr/share/kibana/bin/kibana-verification-code
    read -p "Press Anything To Continued...."
    #Add Encryption Key To Kibana
    # echo "Restart Kibana (Please Wait)"
    sudo /usr/share/kibana/bin/kibana-encryption-keys generate | tail -4 >> /etc/kibana/kibana.yml
    # sudo cat conf/xpack >> /etc/kibana/kibana.yml
    sudo systemctl restart kibana.service
    read -p "Tunggu hingga bisa mengakses http://$(hostname -I):5601 (Press Anything To Continued....)"
    echo "Login dengan menggunakan username elastic dan password elastic berikut:"
    tail -3 password-elasticsearch.txt
    read -p "Press Anything To Continued...."
    echo "[Step 8] Konfigurasi Kibana and Elastic Agent Complete"
    echo ""
	echo ""
}

main(){
    check_root
    check_os
    check_update
    check_java
    install_fw_nginx
    install_elasticsearch
    install_kibana
    login_kibana
    echo ""
	echo ""
    echo "[-] Selesai Menginstall Agent-Manager dan Endpoint Security"
}

main




