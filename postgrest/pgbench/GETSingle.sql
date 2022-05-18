\set rid random(1, 275)

BEGIN ISOLATION LEVEL READ COMMITTED READ ONLY;

select
  set_config('search_path', 'public, public', true),
  set_config('role', 'postgres', true),
  set_config('request.jwt.claims', '{"role":"postgres"}', true),
  set_config('request.method', 'GET', true),
  set_config('request.path', '/artist', true),
  set_config('request.headers', '{"user-agent":"k6/0.27.1 (https://k6.io/)","host":"postgrest"}', true),
  set_config('request.cookies', '{}', true);

WITH pgrst_source AS (
  SELECT "public"."artist".*FROM "public"."artist"
  WHERE  "public"."artist"."artist_id" = :rid)
SELECT
  null::bigint AS total_result_set,
  pg_catalog.count(_postgrest_t) AS page_total,
  array[]::text[] AS header,
  coalesce(json_agg(_postgrest_t), '[]')::character varying AS body,
  nullif(current_setting('response.headers', true), '') AS response_headers,
  nullif(current_setting('response.status', true), '') AS response_status
FROM ( SELECT * FROM pgrst_source ) _postgrest_t;

COMMIT;
