--creating the tables and importing the data 

select * from dim_dates;
select * from dim_districts;
select * from fact_stamps;
select * from fact_transport;
select * from fact_ts_ipass;


--top 5 document reg revenue districts are rangareddy, medchal_malkajgiri, hyderabad, sangareddy, hanumakonda

select sum(fs.documents_registered_rev) doc_rev,dd.district_name
from fact_stamps fs
left join dim_districts dd on fs.dist_code=dd.district_code
group by 2
order by 1 desc
limit 5;

--top5 estamp reg revenue districts in the year 2022: "Rangareddy","Medchal_Malkajgiri", "Hyderabad",
--"Sangareddy", "Hanumakonda"
select sum(fs.estamps_challans_rev) estamp_rev,dd.district_name,dds.financial_year
from fact_stamps fs
left join dim_districts dd on fs.dist_code=dd.district_code
join dim_dates dds on dds.date=fs.date
where dds.financial_year=2022
group by 2,3
order by 1 desc
limit 5;

--total revenue generated from estamps <  document registration
with t1 as
	(select sum(fs.estamps_challans_rev) total_estamp_rev,sum(fs.documents_registered_rev) total_doc_rev,
	dds.financial_year,dd.district_name
	from fact_stamps fs 
	join dim_dates dds on dds.date=fs.date
	join dim_districts dd on dd.district_code=fs.dist_code
	group by 3,4
	order by 1,2)


--top 5 districts revenue where estamp is greater than doc rev in FY2022
--"Rangareddy"
--"Hyderabad"
--"Hanumakonda"
--"Yadadri Bhuvanagiri"
--"Khammam"
select sum(t1.total_estamp_rev),t1.financial_year,t1.district_name from t1
where t1.total_estamp_rev >  t1.total_doc_rev
and t1.financial_year=2022
group by 2,3
order by sum(t1.total_estamp_rev) desc
limit 5; 


--gettintg the data on sum of estamp rev of different districts in different quarters
select dd.quarter,dd.financial_year as year,sum(fs.estamps_challans_rev) as estamp_rev,dds.district_name
from dim_dates dd
left join fact_stamps fs on fs.date=dd.date
left join dim_districts dds on dds.district_code=fs.dist_code
where dd.financial_year between 2021 and 2022
group by 1,2,4
order by 2,4;

--checking which city has max no. of sales on the basis of fuel type
with cte as
	(select dds.district_name,sum(ft.fuel_type_petrol) petrol,sum(ft.fuel_type_diesel) diesel,
	sum(ft.fuel_type_electric) electric, sum(ft.fuel_type_others) others 
	from fact_transport ft 
	join dim_districts dds on dds.district_code=ft.district_code
	group by 1
	order by 1)

select district_name,max(petrol) petrol_car_sales from cte group by 1 order by 2 desc limit 5;
--hyd has max pertrol_car_sales 
select district_name,max(diesel) diesel_car_sales from cte group by 1 order by 2 desc limit 5;
--medchal_malkajgiri has max_diesel_car sales
select district_name,max(electric) electric_car_sales from cte group by 1 order by 2 desc limit 5;
--hyd also has max electric_car_sales


--to find the vehicle sales in the year 2022
--hyderabad has the highest sales of vehicles
with cte1 as (
    select dds.district_name,
    sum(ft.vehicleclass_auto) as auto,
    sum(ft.vehicleclass_agriculture) as agriculture,
    sum(ft.vehicleclass_car) as car,
    sum(ft.vehicleclass_bike) as bike
    from fact_transport ft
    left join dim_districts dds on dds.district_code = ft.district_code
    inner join dim_dates dd on ft.date = dd.date
    where dd.financial_year = 2022
    group by dds.district_name),

cte2 as 
	(select district_name,
	sum(auto + agriculture + car + bike) as total_vehicle_sales,
	dense_rank() over (order by sum(auto + agriculture + car + bike) desc)  rnk
	from cte1

	group by district_name
	order by total_vehicle_sales desc)

select * from cte2 
where cte2.rnk<=5;


--Top 5 sectors with more investment in FY2022
--"Plastic and Rubber"
--"Pharmaceuticals and Chemicals"
--"Real Estate,Industrial Parks and IT Buildings"
--"Solar and Other Renewable Energy"
--"Engineering"
select sector,sum(investment_in_cr),financial_year
from fact_ts_ipass ip
left join dim_dates dd on dd.date=ip.date
where dd.financial_year=2022
group by 1,3
order by 2 desc
limit 5;


--From FY 2019 to 2022, 
--"Rangareddy"  -"Real Estate,Industrial Parks and IT Buildings",
--"Peddapalli"  -"Fertlizers Organic and Inorganic,Pesticides,Insecticides, and Other Related",
--"Rangareddy"  -"Plastic and Rubber"
--has the highest sector investment
select dds.district_name,ip.sector,sum(ip.investment_in_cr), dd.financial_year
from fact_ts_ipass ip
left join dim_districts dds on dds.district_code=ip.district_code
inner join dim_dates dd on dd.date=ip.date

group by 1,2,4
order by 3 desc
limit 3;


--investment,vehicle sales,stamps
select
dds.district_name,
sum(ip.investment_in_cr) as investment_in_cr,
sum(fs.estamps_challans_rev)/10000000 as estamp_rev_cr,
sum(fs.documents_registered_rev)/10000000 as document_revenue_cr,
SUM(ft.vehicleclass_bike::bigint + ft.vehicleclass_car::bigint + ft.vehicleclass_auto::bigint) as total_sum


from fact_stamps fs
inner join fact_transport ft on fs.dist_code = ft.district_code
inner join fact_ts_ipass ip on fs.dist_code = ip.district_code
inner join dim_districts dds on fs.dist_code = dds.district_code
group by dds.district_name
order by investment_in_cr desc;


--Top 3 sector investments
--"Real Estate,Industrial Parks and IT Buildings"
--"Pharmaceuticals and Chemicals"
--"Plastic and Rubber"
select sector, count(sector),sum(investment_in_cr) 
from fact_ts_ipass ip
inner join dim_districts dds on dds.district_code=ip.district_code
group by 1
order by 3 desc;


