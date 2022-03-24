{
  "t3a.micro" = {
    max_connections = 60;
    shared_buffers = "256MB";
    work_mem = "3500kB";
    maintenance_work_mem = "64MB";
    max_worker_processes = 2;
    max_parallel_maintenance_workers = 1;
    max_parallel_workers_per_gather = 1;
    max_parallel_workers = 2;

    effective_cache_size = "768MB";
    default_statistics_target = 100;
    effective_io_concurrency = 200;

    wal_level = "minimal";
    archive_mode = "off";
    max_wal_senders = 0;
    wal_compression = "on";
    wal_buffers = "7864kB";
    max_wal_size = "4GB";
    min_wal_size = "1GB";
  };
  "t3a.medium" = {
    max_connections = 120;
    shared_buffers = "1GB";
    work_mem = "7MB";
    maintenance_work_mem = "256MB";
    max_worker_processes = 2;
    max_parallel_maintenance_workers = 1;
    max_parallel_workers_per_gather = 1;
    max_parallel_workers = 2;

    effective_cache_size = "3GB";
    default_statistics_target = 100;
    effective_io_concurrency = 200;

    wal_level = "minimal";
    archive_mode = "off";
    max_wal_senders = 0;
    wal_compression = "on";
    wal_buffers = "16MB";
    max_wal_size = "4GB";
    min_wal_size = "1GB";
  };
  "m5a.xlarge" = {
    max_connections = 240;
    shared_buffers = "4GB";
    work_mem = "16MB";
    maintenance_work_mem = "1GB";
    max_worker_processes = 4;
    max_parallel_maintenance_workers = 2;
    max_parallel_workers_per_gather = 2;
    max_parallel_workers = 4;

    effective_cache_size = "12GB";
    default_statistics_target = 100;
    effective_io_concurrency = 200;

    wal_level = "minimal";
    archive_mode = "off";
    max_wal_senders = 0;
    wal_compression = "on";
    wal_buffers = "16MB";
    max_wal_size = "4GB";
    min_wal_size = "2GB";
  };
  "m5a.2xlarge" = {
    max_connections = 380;
    shared_buffers = "8GB";
    work_mem = "20MB";
    maintenance_work_mem = "2GB";
    max_worker_processes = 8;
    max_parallel_maintenance_workers = 4;
    max_parallel_workers_per_gather = 4;
    max_parallel_workers = 8;

    effective_cache_size = "24GB";
    default_statistics_target = 100;
    effective_io_concurrency = 200;

    wal_level = "minimal";
    archive_mode = "off";
    max_wal_senders = 0;
    wal_compression = "on";
    wal_buffers = "16MB";
    max_wal_size = "4GB";
    min_wal_size = "2GB";
  };
  "m5a.4xlarge" = {
    max_connections = 480;
    shared_buffers = "16GB";
    work_mem = "32MB";
    maintenance_work_mem = "2GB";
    max_worker_processes = 16;
    max_parallel_maintenance_workers = 8;
    max_parallel_workers_per_gather = 8;
    max_parallel_workers = 16;

    effective_cache_size = "48GB";
    default_statistics_target = 100;
    effective_io_concurrency = 200;

    wal_level = "minimal";
    archive_mode = "off";
    max_wal_senders = 0;
    wal_compression = "on";
    wal_buffers = "16MB";
    max_wal_size = "4GB";
    min_wal_size = "2GB";
  };
}
