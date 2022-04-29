{
  "t3a.nano" = {
     max_connections = 40;
     shared_buffers = "128MB";
     work_mem = "655kB";
     maintenance_work_mem = "32MB";
     max_worker_processes = 2;
     max_parallel_workers_per_gather = 1;
     max_parallel_workers = 2;
     max_parallel_maintenance_workers = 1;

     effective_cache_size = "384MB";
     default_statistics_target = 100;
     effective_io_concurrency = 200;

     wal_level = "minimal";
     archive_mode = "off";
     max_wal_senders = 0;
     wal_buffers = "3932kB";
     min_wal_size = "2GB";
     max_wal_size = "8GB";
     random_page_cost = 1.1;
     checkpoint_completion_target = 0.9;
  };
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
  "t3a.xlarge" = {
    max_connections = 200;
    shared_buffers = "4GB";
    effective_cache_size = "12GB";
    maintenance_work_mem = "1GB";
    checkpoint_completion_target = 0.9;
    wal_buffers = "16MB";
    random_page_cost = 1.1;
    effective_io_concurrency = 200;
    work_mem = "10485kB";
    max_worker_processes = 4;
    max_parallel_workers_per_gather = 2;
    max_parallel_workers = 4;
    max_parallel_maintenance_workers = 2;
  };
  "t3a.2xlarge" = {
    max_connections = 200;
    shared_buffers = "8GB";
    effective_cache_size = "24GB";
    maintenance_work_mem = "2GB";
    checkpoint_completion_target = 0.9;
    wal_buffers = "16MB";
    random_page_cost = 1.1;
    effective_io_concurrency = 200;
    work_mem = "10485kB";
    max_worker_processes = 8;
    max_parallel_workers_per_gather = 4;
    max_parallel_workers = 8;
    max_parallel_maintenance_workers = 4;
  };
  "m5a.large" = {
    max_connections = 200;
    shared_buffers = "2GB";
    work_mem = "10485kB";
    maintenance_work_mem = "512MB";
    max_worker_processes = 2;
    max_parallel_maintenance_workers = 1;
    max_parallel_workers_per_gather = 1;
    max_parallel_workers = 2;

    effective_cache_size = "6GB";
    default_statistics_target = 100;
    effective_io_concurrency = 200;

    wal_level = "minimal";
    archive_mode = "off";
    max_wal_senders = 0;
    wal_compression = "on";
    wal_buffers = "16MB";
    min_wal_size = "1GB";
    max_wal_size = "4GB";
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
  "m5a.8xlarge" = {
    max_connections = 600;
    shared_buffers = "32GB";
    work_mem = "27962kB";
    maintenance_work_mem = "2GB";
    max_worker_processes = 32;
    max_parallel_maintenance_workers = 4;
    max_parallel_workers_per_gather = 4;
    max_parallel_workers = 32;

    effective_cache_size = "96GB";
    default_statistics_target = 100;
    effective_io_concurrency = 200;

    wal_level = "minimal";
    archive_mode = "off";
    max_wal_senders = 0;
    wal_compression = "on";
    wal_buffers = "16MB";
    min_wal_size = "2GB";
    max_wal_size = "8GB";
  };
  "m5a.12xlarge" = {
    max_connections = 800;
    shared_buffers = "48GB";
    work_mem = "41943kB";
    maintenance_work_mem = "2GB";
    max_worker_processes = 48;
    max_parallel_maintenance_workers = 4;
    max_parallel_workers_per_gather = 4;
    max_parallel_workers = 48;

    effective_cache_size = "144GB";
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
  "m5a.16xlarge" = {
    max_connections = 1000;
    shared_buffers = "64GB";
    work_mem = "83886kB";
    maintenance_work_mem = "2GB";
    max_worker_processes = 64;
    max_parallel_maintenance_workers = 4;
    max_parallel_workers_per_gather = 4;
    max_parallel_workers = 64;

    effective_cache_size = "192GB";
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
