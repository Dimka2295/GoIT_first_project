select *
from cohort_users_raw
limit 10;
--
select *
from cohort_events_raw
limit 10;
--
with users_date as(
	select u.user_id,
		   u.signup_datetime,
		   u.promo_signup_flag,
		   to_date((case when split_part(replace(replace(LEFT(TRIM(signup_datetime), (POSITION(' ' IN TRIM(signup_datetime))-1)),'.','-'),'/','-'),'-', 3)='2025'
		   then replace(replace(LEFT(TRIM(signup_datetime), (POSITION(' ' IN TRIM(signup_datetime))-1)),'.','-'),'/','-')
		   else
		 split_part(replace(replace(LEFT(TRIM(signup_datetime), (POSITION(' ' IN TRIM(signup_datetime))-1)),'.','-'),'/','-'),'-', 1)||'-'||
		 split_part(replace(replace(LEFT(TRIM(signup_datetime), (POSITION(' ' IN TRIM(signup_datetime))-1)),'.','-'),'/','-'),'-', 2)||'-'||
		 '2025'
		   end),'DD-MM-YYYY')
as signup_date
	from cohort_users_raw u
),
events_date as(
	select e.user_id,
		   nullif(e.event_type, '') as event_type, --додаємо, щоб відсутні значення перетворити на null
		   to_date((case when split_part(replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-'),'-', 3)='2025'
		   then replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-')
		   when split_part(replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-'),'-', 3)='2026'
		   then replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-')
		   when split_part(replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-'),'-', 3)='25'
		   or   split_part(replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-'),'-', 3)='26'
		   then 
		   --else 
		   split_part(replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-'),'-', 1)||'-'||
		   split_part(replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-'),'-', 2)||'-'||'20'||''||
		   split_part(replace(replace(LEFT(TRIM(event_datetime), (POSITION(' ' IN TRIM(event_datetime))-1)),'.','-'),'/','-'),'-', 3)
		   end),'DD-MM-YYYY')
as event_date
	from cohort_events_raw e
),
users_activity as (
	select u.user_id,
		   date_trunc('month', signup_date)::date as cohort_month,
		   u.promo_signup_flag,
		   date_trunc('month', event_date)::date as activity_month,
		   extract('month' from date_trunc('month', event_date)::date)-extract('month' from date_trunc('month', signup_date)::date) as month_offset
from users_date u
left join events_date e using (user_id)
where 
	signup_date is not null
	and event_date is not null 
	and event_type is not null 
	and event_type <> 'test_event'
)
select promo_signup_flag,
	   cohort_month,
	   month_offset,
	   count(distinct user_id) as users_total
from users_activity
where activity_month between '2025-01-01' and '2025-06-01'
group by 1,2,3
order by 1,2,3