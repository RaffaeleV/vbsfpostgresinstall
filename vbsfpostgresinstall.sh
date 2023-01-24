#!/bin/bash

# PostgreSQL v13.5 Installation
# =============================

# Discover OS Version
FILENAME=/etc/os-release
version=`grep -e ^VERSION_ID= ${FILENAME}`
version=${version#*\"}
version=${version%*\"}
version=${version%*\.*}


if [[ "$version" == "7" ]]
then

  # CENTOS/RHEL 7
  yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  yum -y update
  yum -y install postgresql13-13.5-1PGDG.rhel7 postgresql13-server-13.5-1PGDG.rhel7 postgresql13-contrib-13.5-1PGDG.rhel7 yum-plugin-versionlock

  # Lock package version
  yum versionlock postgresql13*

elif [[ "$version" == "8" ]]
then

  # CENTOS/RHEL 8
  dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  dnf -qy module disable postgresql
  dnf -y install postgresql13-13.5-1PGDG.rhel8 postgresql13-server-13.5-1PGDG.rhel8 postgresql13-contrib-13.5-1PGDG.rhel8 python3-dnf-plugin-versionlock

  # Lock package version
  dnf versionlock postgresql13*

fi

# Initialize database
/usr/pgsql-13/bin/postgresql-13-setup initdb


# Change "max_connections" parameter to 200 as per VBSF best practices
sed -i -e 's/max_connections = 100/max_connections = 200/g' /var/lib/pgsql/13/data/postgresql.conf

# Start PostgreSQL and enable auto-start
systemctl start postgresql-13
systemctl enable postgresql-13

# Define password for users 'postgresql' and 'vbuser'

psqlpassword='Pa$$w0rd'
vbuserpassword='Pa$$w0rd'


# Update password for postgresql user
su - postgres -c "psql -c \"alter user postgres with password '\"'${psqlpassword}'\"'\""


# Create user vbuser and set the password
su - postgres -c "psql -c \"CREATE USER vbuser WITH ENCRYPTED PASSWORD '\"'${vbuserpassword}'\"'\""
su - postgres -c "psql -c \"ALTER USER vbuser CREATEDB\""


# Enable remote connections to PostgreSQL
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/13/data/postgresql.conf
sed -i "s/127.0.0.1\/32            /0.0.0.0\/0 /g" /var/lib/pgsql/13/data/pg_hba.conf
systemctl restart postgresql-13


# Add rule to local firewall
firewall-cmd --zone=public --permanent --add-port 5432/tcp
systemctl restart firewalld.service
