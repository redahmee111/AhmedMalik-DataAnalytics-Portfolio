-- SQL Portfolio Project
-- Name: Ahmed Malik
-- Class: DA 6 Black
-- Email: ahmed89.mu111@gmail.com

create schema virginia_patients_appointments;
use virginia_patients_appointments;

create table appointments(
PatientId int,
AppointmentID varchar(50),
Gender varchar(10),
ScheduledDay varchar(20),
AppointmentDay varchar(20),
Age int,
Neighbourhood varchar(50),
Scholarship int,
Hypertension int,
Diabetes int,
Alcoholism int,
Handcap int,
SMS_received int,
Date_diff int,
Showed_up varchar(10)
);

-- Basic SQL & Data Retrieval 
-- Answer Q1 (In order to retrieve table, I used the SELECT query)
select * from appointments;

-- Answer Q2 ( By using WHERE clause, I narrowed down the list of patients over the age of 60 and used LIMIT function to extract first 10 rows) 
select * from appointments
where age>60
limit 10;

-- Answer Q3 (By using DISTINCT function, I was able to extract unique neighbourhoods)
select distinct Neighbourhood
 from appointments;

-- Answer Q4 (In order to find total number of female patients who received sms, I used COUNT function)
select count(*) as total_sms_female
from appointments
where Gender = 'female'
and SMS_received = 1 
;
-- Total count of female patients who received sms message = 3465

-- Data Modification & Filtering
-- Answer Q5 ( In order to convert the date, I used the str to date function but added a tweek of using c and e in date format to eliminate leading zero errors I was getting before)
set sql_safe_updates = 0;
update appointments
set
ScheduledDay = str_to_date(ScheduledDay, '%c/%e/%Y'),
AppointmentDay = str_to_date(AppointmentDay, '%c/%e/%Y')
where AppointmentID is not null
;

-- Answer Q6 (Once I cleaned the data, I used the modify column function to change the column type to 'Date')
alter table appointments
modify column ScheduledDay date,
modify column AppointmentDay date;

-- Answer Q7 (In order to handle missing values, I used WHERE and OR clause)
update appointments
set Showed_up = 'yes'
where Showed_up is null
or Showed_up = ' '
;

-- Answer Q8 ( I created a new column and then used CASE function to show which patients showed up and which didnt)
alter table appointments
add column AppointmentStatus varchar(20);
select * from appointments;
update appointments
set AppointmentStatus = case
when Showed_up = 'No' 
then 'no show'
else 'attended'
end;
select * from appointments;

-- Answer Q9 ( I used WHERE and AND clauses to extract patients having both diseases)
select * from appointments
where Diabetes = 1
and 
Hypertension = 1;

-- Answer Q10 (By using ORDER BY and LIMIT clauses, I was able to find top 5 oldest patients)
select * from appointments
order by Age desc
limit 5;

-- Answer Q11 (In order to find first 5 appointments under the age of 18, I used WHERE and LIMIT clauses)
select * from appointments
where age < 18
limit 5;

-- Answer Q12 (In order to find appointments scheduled, I used WHERE and AND clauses)
select * from appointments
where 
ScheduledDay >= '2023-05-01'
and
ScheduledDay < '2023-06-01'
;

-- Aggregation and CASE
-- Answer Q13 (I used GROUP BY to separate data based on gender, then calculated the average age for each gender using AVG())
select gender,
avg(Age) as avg_age_per_gender
from appointments 
group by gender;

-- Answer Q14 (I applied a WHERE clause to filter only the rows where SMS_received = 1, and then grouped them by Showed_up status to count how many showed up and how many didn’t.)
select Showed_up,
count(*) as SMS_reminders
from appointments
where SMS_received = 1
group by Showed_up
;

-- Answer Q15 (I used a WHERE clause to find patients who didn’t show up (Showed_up = 'No'), then grouped them by neighbourhood to count how many no-shows occurred in each area.)
select Neighbourhood,
count(*) as no_show_appointments
from appointments
where Showed_up = 'No'
group by Neighbourhood
;

-- Answer Q16 (I grouped the data by neighbourhood and used COUNT(*) to calculate total appointments, then added a HAVING clause to only include neighbourhoods with more than 100 appointments.)
select Neighbourhood,
count(*) as patient_appointments
from appointments
group by Neighbourhood
having count(*) > 100
;

-- Answer Q17 (I used CASE statements inside SUM() to split patients into three age groups — children, adults, and seniors — based on their age ranges.)
select sum(
case
when Age < 12 
then 1
else 0
end)
as Children
from appointments
;

-- -- Total number of children = 1074

select sum(
case
when Age between 12 and 60 
then 1
else 0
end)
as Adults
from appointments
;

-- Total number of Adults = 4910

select sum(
case 
when Age > 60
then 1
else 0
end)
as Seniors
from appointments
;

-- Total number of Seniors = 3932

-- Answer Q18 (I used DAYNAME() to get the weekday name from AppointmentDay, then counted how many appointments happened on each day. I also calculated how many patients showed up and how many didn’t,
-- and added percentages for show and no-show rates. Finally, I sorted the results by no-show percentage to highlight the worst-performing days.)
select dayname(AppointmentDay)
as Day_of_the_week,
count(*) as Total_Appointments,
sum(case when Showed_up = 'Yes'
then 1
else 0
end)
as Showed,
sum(case when Showed_up = 'No'
then 1
else 0
end)
as No_Show,
round(count(case when Showed_up = 'Yes'
then 1 
end) * 100.0/count(*),2) as Showed_Percentage,
round(count(case when Showed_up = 'No'
then 1
end) * 100.0/count(*),2) as No_Show_Percentage
from appointments
group by dayname(AppointmentDay)
order by No_Show_Percentage desc
;

-- Window Functions
-- Answer Q19 (I used GROUP BY to get total appointments per day for each neighbourhood. Then I used SUM(COUNT(*)) OVER() as a window function to calculate a running total, ordered by appointment day within each neighbourhood.)
select AppointmentDay,
Neighbourhood,
count(*) as Daily_Appointments,
sum(count(*)) 
over(partition by Neighbourhood
order by AppointmentDay) 
as Running_Total
from appointments
group by Neighbourhood, AppointmentDay
;

-- Answer Q20 (I selected PatientId, Gender, and Age, then used DENSE_RANK() to assign age ranks from highest to lowest within each gender group.)
select PatientId,
Gender,
Age,
dense_rank() 
over(partition by Gender
order by Age desc)
as Age_Rank
from appointments
;

-- Answer Q21 (I used LAG() with PARTITION BY Neighbourhood and ORDER BY AppointmentDay to get each patient’s previous appointment day. 
-- Then I applied DATEDIFF() to calculate how many days passed since their last visit in the same neighbourhood.)
select PatientId,
AppointmentDay,
Neighbourhood,
datediff(AppointmentDay,
lag(AppointmentDay) 
over(partition by Neighbourhood
 order by AppointmentDay))
 as days_since_last_appointment
 from appointments
 ;
 
 -- Answer Q22 ( I built a CTE named NoShows that counts how many patients didn’t show up in each neighbourhood. Then I ranked neighbourhoods using DENSE_RANK() based on their no-show counts.)
 with No_Shows as(
 select 
 Neighbourhood,
 count(*) as No_Show_Total
 from appointments
 where Showed_up = 'No'
 group by Neighbourhood)
 select 
 Neighbourhood,
 No_Show_Total,
 dense_rank()
 over(order by No_Show_Total desc)
 as No_Show_Rank
 from No_Shows
 ;
 
 -- Subqueries and CTEs
 -- Answer Q23 (I created a CTE called Ranked to count no-shows by neighbourhood and rank them using DENSE_RANK(). Then I filtered the final result to only include ranks 2 and 3.)
 with No_Show_ranking as (
 select Neighbourhood,
 count(*) as No_Show_Count,
 dense_rank()
 over(order by count(*) desc)
 as No_Show_Rank
 from appointments
 where Showed_up = 'No'
 group by Neighbourhood)
 select * from No_Show_Ranking
 where No_Show_Rank in (2, 3)
 ;
 
 -- Answer Q24 (I used a subquery to calculate the average age of female patients, then filtered the main query to only include female patients older than that average.)
 select * from appointments
 where Gender = 'Female'
 and Age > (
 select avg(Age)
 from appointments
 where Gender = 'Female')
 ;
 
 -- Answer Q25 (I created a CTE called Latest_Appointments to find the most recent appointment day for each neighbourhood using MAX(). 
 -- Then I joined this with the original table to get full details of those latest appointments.)
 with Latest_Appointments as (
 select Neighbourhood,
 max(AppointmentDay) as
 Latest_Day
 from appointments
 group by Neighbourhood)
 select a.*
 from appointments a
 join Latest_Appointments l
 on a.Neighbourhood = l.Neighbourhood
 and a.AppointmentDay = l.Latest_Day
 ;
 
 -- END--
 
 
 
 
 
 
 



