-- ============================================================
--  ONE-TIME FIX — undo the bad penalty state caused by the
--  off-by-one miss-detection bug (fixed in app v1.0.0).
--
--  Run this in: Supabase Dashboard → SQL Editor → New query.
--  Replace the email below with the address you log in with.
-- ============================================================

-- 1) Clear the wrongful pending penalty + restore the grace.
update public.profiles p
set pending_penalty = false,
    missed_days     = 0,
    grace_used      = false
where p.id in (
  select id from auth.users where email = 'YOUR_LOGIN_EMAIL@example.com'
);

-- 2) Remove any penalty rows wrongly recorded in the last 14 days.
delete from public.penalties pen
where pen.user_id in (
  select id from auth.users where email = 'YOUR_LOGIN_EMAIL@example.com'
)
and pen.day >= current_date - 14;

-- 3) OPTIONAL — if you had already tapped "ACCEPT PENALTY" and lost days,
--    add them back. Change 5 to however many days were deducted.
-- update public.profiles p
-- set total_days = total_days + 5
-- where p.id in (
--   select id from auth.users where email = 'YOUR_LOGIN_EMAIL@example.com'
-- );
