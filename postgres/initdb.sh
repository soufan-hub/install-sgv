#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	GRANT ALL on DATABASE alop_sgv TO alo;	
EOSQL

echo "host all  all    0.0.0.0/0  trust" >> $PGDATA/pg_hba.conf
echo "local all all trust" >> $PGDATA/pg_hba.conf
echo "listen_addresses='*'" >> $PGDATA/postgresql.conf
echo "max_connections = 500" >> $PGDATA/postgresql.conf
echo "shared_buffers = 1GB" >> $PGDATA/postgresql.conf
echo "effective_cache_size = 3GB" >> $PGDATA/postgresql.conf
echo "maintenance_work_mem = 256MB" >> $PGDATA/postgresql.conf
echo "min_wal_size = 1GB" >> $PGDATA/postgresql.conf
echo "max_wal_size = 2GB" >> $PGDATA/postgresql.conf
echo "checkpoint_completion_target = 0.7" >> $PGDATA/postgresql.conf
echo "wal_buffers = 16MB" >> $PGDATA/postgresql.conf
echo "default_statistics_target = 100" >> $PGDATA/postgresql.conf
echo "random_page_cost = 4" >> $PGDATA/postgresql.conf
echo "effective_io_concurrency = 2" >> $PGDATA/postgresql.conf
echo "max_worker_processes = 2" >> $PGDATA/postgresql.conf
echo "max_parallel_workers_per_gather = 1" >> $PGDATA/postgresql.conf
echo "work_mem = 2097kB" >> $PGDATA/postgresql.conf

pg_restore -w -F c -v --role alo -U $POSTGRES_USER -d alop_sgv /tmp/alo.dump