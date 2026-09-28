import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';

if (!process.env.DATABASE_URL) throw new Error('DATABASE_URL is required for migration');
const schemaPath = path.join(path.dirname(fileURLToPath(import.meta.url)), 'schema.sql');
const sql = await readFile(schemaPath, 'utf8');
const client = new pg.Client({ connectionString: process.env.DATABASE_URL, connectionTimeoutMillis: 5000 });
try {
  await client.connect();
  await client.query(sql);
  process.stdout.write('Momosup content-block schema is ready.\n');
} finally {
  await client.end();
}
