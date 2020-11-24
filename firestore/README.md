# Supabase benchmarks

Benchmarking setup

- Install [k6](https://k6.io/docs/getting-started/installation)
- Create a [Supabase project](https://app.supabase.io/) or a Postgres Database using the migration scripts `make migrations up` 

export the following env vars from the terminal with your values plugged in:
```bash
export SUPABASE_URL=https://<>.supabase.net
export SUPABASE_KEY=<>
export BASE_FIRESTORE_URL=https://firestore.googleapis.com/v1beta1/projects/<project-id>/databases/(default)/documents
export FIRESTORE_API_KEY="<>"
export FIRESTORE_AUTH_DOMAIN="<>.firebaseapp.com"
export FIRESTORE_DATABASE_URL="https://<>.firebaseio.com"
export FIRESTORE_PROJECT_ID="<>"
export FIRESTORE_STORAGE_BUCKET="<>.appspot.com"
export FIRESTORE_MESSAGING_SENDER_ID="<>"
export FIRESTORE_APP_ID="<>"
```

Run `npm install`

Run `node read-setup.js` to populate your firestore instance with 1 million row for the read benchmarks

Run the query from `../db/migrations/20200930011957_init.sql` on your Supabase instance to install the benchmark schema if you want to store the results in supabase

Then to run all the benchmarks and upload the results to db run

> npm run benchmark
