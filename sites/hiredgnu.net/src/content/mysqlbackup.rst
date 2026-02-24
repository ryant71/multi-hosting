MySQL Backup Script
===================

:date: 2013-08-23 09:51
:tags: mysql, bash
:category: tech
:author: Ryan Tracey
:slug: mysql-backup-script


.. code-block:: bash

    #!/bin/bash
    
    user='root'
    pass='r00t'
    date=$(date +%Y.%m.%d)
    backuproot='/var/backups/mysql'
    
    # echo and exit
    function die {
        echo "$1"
        exit 1
    }
    
    # dump per database
    function per_db {
        for db in $(mysql -u ${user} -p${pass} -Bse "show databases"); do
            [ ${db} = "information_schema" ] && continue
            [ ${db} = "performance_schema" ] && continue
            echo ${db}
            mysqldump -u ${user} -p${pass} --master-data=2 --hex-blob ${db} | gzip > ${backuproot}/${db}-${date}.sql.gz
        done
    }
    
    # dump per table per database
    function per_db_table {
        for db in $(mysql -u ${user} -p${pass} -Bse "show databases"); do
            [ ${db} = "information_schema" ] && continue
            [ ${db} = "performance_schema" ] && continue
            echo ${db}
            for table in $(mysql -u ${user} -p${pass} -Bse "show tables" ${db}); do
                echo "  ${table}"
                mkdir -p ${backuproot}/${db}
                mysqldump -u ${user} -p${pass} --master-data=2 --hex-blob ${db} ${table} | gzip > ${backuproot}/${db}/${db}-${table}-${date}.sql.gz
            done
        done
    }
    
    # mkdirs, etc
    function prep {
        mkdir -p ${backuproot} 2>/dev/null || die "cannot mkdir ${backuproot}"
        touch ${backuproot}/.foo 2>/dev/null || die "${backuproot} not writeable" && rm -v ${backuproot}/.foo
        find ${backuproot}/* -maxdepth 0 -exec rm -rv {} \; 2>/dev/null
    }
    
    # run the appropriate functions
    [ "$1" = "--per_db" ]       && prep && per_db          && exit 0
    [ "$1" = "--per_db_table" ] && prep && per_db_table    && exit 0
    
    # if you reach here...
    echo "Usage: $(basename $0) --per_db | --per_db_table" && exit 0


