SELECT 'CREATE DATABASE mypet_auth'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_auth'
)\gexec

SELECT 'CREATE DATABASE mypet_users'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_users'
)\gexec

SELECT 'CREATE DATABASE mypet_estab'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_estab'
)\gexec

SELECT 'CREATE DATABASE mypet_market'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_market'
)\gexec

SELECT 'CREATE DATABASE mypet_booking'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_booking'
)\gexec

SELECT 'CREATE DATABASE mypet_notif'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_notif'
)\gexec

SELECT 'CREATE DATABASE mypet_review'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_review'
)\gexec

SELECT 'CREATE DATABASE mypet_faq'
WHERE NOT EXISTS (
  SELECT FROM pg_database WHERE datname = 'mypet_faq'
)\gexec
