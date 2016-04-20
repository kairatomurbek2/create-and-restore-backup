#!/bin/bash
set -e

BASE_DIR=/home/sitemaster/backups
SITE_DB_NAME='is_sdusa_django'
ODK_DB_NAME='odk_db'
SQL_USER="root"
SQL_PASS="343^kjfllgtTTorr"
CURRENTDATE=`date +%Y-%m-%d-%s`
TRAC_DIR=/home/sitemaster/trac-data
PROJECT_DIR=/home/django-demo/is-sdusa-src
ODK_DISTRO=/home/sitemaster/distro/ODKAggregate

cd ${BASE_DIR}
mkdir backup-${CURRENTDATE}
BACKUP_DIR=${BASE_DIR}/backup-${CURRENTDATE}

echo "Making backup of django site..."
	cd ${BACKUP_DIR}
	# rsync копирует файлы сайта за исключением виртуаленва, гита и статиков.
	rsync -r --exclude=venv --exclude=.git --exclude=is_sdusa/static ${PROJECT_DIR} .
	# mysqldump делает полный бэкап базы сайта
	mysqldump -u${SQL_USER} -p${SQL_PASS} ${SITE_DB_NAME} | gzip -c > ./is-sdusa-src/db.gz
echo "Done."

# то же самое, но для одк
echo "Making backup of odk..."
	cd ${BACKUP_DIR}
	mkdir odk
	cp -r ${ODK_DISTRO} ./
	mysqldump -u${SQL_USER} -p${SQL_PASS} ${ODK_DB_NAME} | gzip -c > ./odk/db.gz
echo "Done."

# бэкап файлов трака, включая репозитории
echo "Making backup of trac..."
	cd ${BACKUP_DIR}
	rsync -r --exclude=trac-venv ${TRAC_DIR} .
echo "Done."

# бэкап конфигов от всех серверов, используемых в проекте
echo "Making config backup..."
	cd ${BACKUP_DIR}
	mkdir configs
	cd configs
	mkdir nginx
	cp /etc/nginx/sites-available/is-sdusa-* nginx/
	mkdir uwsgi
	cp /etc/uwsgi/apps-available/*.ini uwsgi/
	mkdir tomcat
	cp /etc/init.d/tomcat6 tomcat/
	cp /usr/share/tomcat6/lib/mysql-connector-java-5.1.34-bin.jar tomcat/
	mkdir mysql
	cp /etc/mysql/my.cnf mysql/
echo "Done."


# запаковка бэкапов отдельных компонентов в один архив
echo "Packing backup into archive..."
	cd ${BASE_DIR}
	cp restore_backup.sh backup-${CURRENTDATE}
	tar -zcf backup-${CURRENTDATE}.tar.gz ./backup-${CURRENTDATE}
	rm -rf ${BACKUP_DIR}
echo "Done."

# удаление старых бэкапов, пока их не останется 10 штук
# ls -1 - выводит список файлов
# grep tar.gz - выбирает из этих файлов только архивы
# wc -l - считает количество строк
# ls -t - выводит список файлов от новых к старым
# tail -n1 - выбирает последнюю строчку, т.е. самый старый из бэкапов
echo "Removing older backups..."
	while [ `ls -1 | grep tar.gz | wc -l` -gt 10 ]
	do
		REMOVED=`ls -t | grep tar.gz | tail -n1`
		rm -rf ./${REMOVED}
		echo "Removed "${REMOVED}
	done
echo "Done."

