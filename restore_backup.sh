#!/bin/bash

SITE_DB_NAME='is_sdusa_django'
ODK_DB_NAME='odk_db'
SQL_USER="root"
SQL_PASS="343^kjfllgtTTorr"
TRAC_DIR=/home/sitemaster/trac-data
PROJECT_DIR=/home/django-demo/is-sdusa-src
ODK_DISTRO=/home/sitemaster/distro/ODKAggregate
BACKUP_DIR=`pwd`

echo "Restoring django..." 
	sudo -u django-demo rsync -r ./is-sdusa-src/ ${PROJECT_DIR}
	set +e
	mysql -u${SQL_USER} -p${SQL_PASS} -e "create database `is_sdusa_db` character set utf8 collate utf8_general_ci; create user 'django-demo'@'localhost' identified by 'E#J(_eught9'; grant all on `is_sdusa_db`.* to 'django-demo'@'localhost' identified by 'E#J(_eught9'; flush privileges;"
	set -e
	cd ${PROJECT_DIR}
	sudo -u django-demo ./install_demo.sh
	cd ${BACKUP_DIR}
	gunzip < ./is-sdusa-src/db.gz | mysql -u${SQL_USER} -p${SQL_PASS} ${SITE_DB_NAME}
echo "Done."

echo "Restoring odk..."
	set +e
	mysql -u${SQL_USER} -p${SQL_PASS} < ./ODKAggregate/create_db_and_user.sql
	set -e
	sudo cp ./ODKAggregate/ODKAggregate.war /var/lib/tomcat6/webapps	
echo "Done."

echo "Restoring trac..."
	rsync -r ./trac-data/ ${TRAC_DIR}
	ln -s ${TRAC_DIR}/common/git_hooks/post-receive ${TRAC_DIR}/projects/is-sdusa/repo.git/hooks/ 
	ln -s ${TRAC_DIR}/common/git_hooks/post-receive ${TRAC_DIR}/projects/is-sdusa/django.git/hooks/
	cd ${TRAC_DIR}
	./create_venv.sh
	cd ${BACKUP_DIR}
echo "Done."

echo "Restoring configs..."
	sudo mv ./configs/nginx/is-sdusa-* /etc/nginx/sites-available/
	sudo ln -s /etc/nginx/sites-available/is-sdusa-django /etc/nginx/sites-enabled
	sudo ln -s /etc/nginx/sites-available/is-sdusa-odk /etc/nginx/sites-enabled
	sudo ln -s /etc/nginx/sites-available/is-sdusa-trac /etc/nginx/sites-enabled
	sudo mv ./configs/uwsgi/*.ini /etc/uwsgi/apps-available/
	sudo ln -s /etc/uwsgi/apps-available/is-sdusa-django.ini /etc/uwsgi/apps-enabled
	sudo ln -s /etc/uwsgi/apps-available/is-sdusa.ini /etc/uwsgi/apps-enabled
	sudo mv ./configs/tomcat/tomcat6 /etc/init.d/
	sudo mv ./configs/tomcat/mysql-connector-java-5.1.34-bin.jar /usr/share/tomcat6/lib/
	sudo mv ./configs/mysql/my.cnf /etc/mysql/
	sudo echo "0 3 * * * sitemaster bash /home/sitemaster/backups/create_backup.sh" >> /etc/crontab
echo "Done."

echo "Restoring backups creation..."
	cd /home/sitemaster
	if [ ! -d "backups" ]; then
	    mkdir backups
	fi
	cp /home/django-demo/is-sdusa-src/create_backup.sh ./backups
	cp /home/django-demo/is-sdusa-src/restore_backup.sh ./backups
echo "Done."

echo "Restarting servers..."
	sudo service tomcat6 restart
	sudo service uwsgi restart
	sudo service nginx restart
echo "Done."
