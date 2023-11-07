-- Вывести к каждому самолету класс обслуживания и количество мест этого класса
select s.aircraft_code, s.fare_conditions, count(s.fare_conditions) from bookings.aircrafts_data a
join bookings.seats s on s.aircraft_code=a.aircraft_code
group by s.fare_conditions, s.aircraft_code

-- Найти 3 самых вместительных самолета (модель + кол-во мест)

with t as (select s.aircraft_code, count(s.fare_conditions) seats from bookings.aircrafts_data a
join bookings.seats s on s.aircraft_code=a.aircraft_code
group by s.aircraft_code)
select ad.model, seats from t
join bookings.aircrafts_data ad on ad.aircraft_code=t.aircraft_code
order by seats desc
limit 3

-- Вывести код, модель самолета и места не эконом класса для самолета 'Аэробус A321-200' с сортировкой по местам

select s.aircraft_code, ad.model, s.seat_no from bookings.aircrafts_data ad
join bookings.seats s on s.aircraft_code=ad.aircraft_code
where ad.model->>'ru' like '%Аэробус A321-200%'  and s.fare_conditions != 'Economy'
order by s.seat_no

-- Вывести города в которых больше 1 аэропорта ( код аэропорта, аэропорт, город)

select ar.city, count(ar.city) amount_airpots from bookings.airports ar
group by ar.city
having count(ar.city) > 1

-- Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация

select f.flight_id, f.flight_no, ad.city, aa.city, f.status from bookings.flights f
join bookings.airports_data ad on ad.airport_code = f.departure_airport
join bookings.airports_data aa on aa.airport_code = f.arrival_airport
where ad.city->>'ru' like 'Екатеринбург' and
aa.city->>'ru' like 'Москва' and (status = 'On Time' or status = 'Delayed')

-- Вывести самый дешевый и дорогой билет и стоимость ( в одном результирующем ответе)

(select * from bookings.ticket_flights tf
where tf.amount = (select max(amount) from bookings.ticket_flights)
limit 1)
union all
(select * from bookings.ticket_flights tf
where tf.amount = (select min(amount) from bookings.ticket_flights)
limit 1)

-- Вывести информацию о вылете с наибольшей суммарной стоимостью билетов

select f.flight_no, f.status, f.aircraft_code, am.max_amount from bookings.flights f
join (
select tf.flight_id as f_id, sum(tf.amount) as max_amount from bookings.ticket_flights tf
group by tf.flight_id
order by max_amount desc
limit 1
) am on am.f_id = f.flight_id


-- Найти модель самолета, принесшую наибольшую прибыль (наибольшая суммарная стоимость билетов). Вывести код модели, информацию о модели и общую стоимость

select cr.aircraft_code, cr.model, am.max_amount from bookings.flights f
join (
select tf.flight_id as f_id, sum(tf.amount) as max_amount from bookings.ticket_flights tf
group by tf.flight_id
order by max_amount desc
limit 1
) am on am.f_id = f.flight_id
join bookings.aircrafts_data cr on cr.aircraft_code = f.aircraft_code

-- Найти самый частый аэропорт назначения для каждой модели самолета. Вывести количество вылетов, информацию о модели самолета, аэропорт назначения, город

with tempo as (select f.aircraft_code, f.arrival_airport, count(*) count_ports from bookings.flights f
group by f.arrival_airport, f.aircraft_code
order by count_ports desc)
select tm.max_port from 
(select tempo.aircraft_code, max(tempo.count_ports) max_port from tempo
group by tempo.aircraft_code) tm
join tempo on tempo.aircraft_code = tm.aircraft_code and tempo.count_ports = tm.max_port
join bookings.aircrafts_data cr on cr.aircraft_code = tempo.aircraft_code
join bookings.airports_data ad on ad.airport_code = tempo.arrival_airport