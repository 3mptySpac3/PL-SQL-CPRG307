DROP TABLE mm_movie_type CASCADE CONSTRAINTS;
DROP TABLE mm_pay_type CASCADE CONSTRAINTS;
DROP TABLE mm_member CASCADE CONSTRAINTS;
DROP TABLE mm_movie CASCADE CONSTRAINTS;
DROP TABLE mm_rental CASCADE CONSTRAINTS;
DROP TABLE my_table CASCADE CONSTRAINTS;
DROP SEQUENCE mm_rental_seq;
DROP SEQUENCE seq_movie_id;
Drop view vw_movie_rental;

@"C:\Users\thefa\OneDrive\Desktop\Database Prog\Unit 1 DatabaseProgLang\Lab\Create_MM.sql"

Spool "C:\Users\thefa\OneDrive\Desktop\Database Prog\Database Spools\Lab1V1.txt"

set LINESIZE 175;
set pagesize 30;

-- Q1
desc mm_member;

-- Q2
insert into mm_member(member_id,last,first)
   values(192,'Nde','JP');


-- Q3
update mm_member
   set credit_card = '192090394523'
   where member_id = 192;

select * from mm_member;

-- Q4
delete from mm_member
   where member_id = 192;

-- Q5
COMMIT;

-- Q6
select m.movie_title, r.rental_id, mm.last
   from mm_movie m
   join mm_rental r on m.movie_id = r.movie_id
   join mm_member mm on r.member_id = mm.member_id
   order by r.rental_id;

-- Q7
select m.movie_title, r.rental_id, mm.last
   from mm_movie m, mm_rental r, mm_member mm
   where m.movie_id = r.movie_id and r.member_id = mm.member_id
   order by r.rental_id;

-- Q8
create table my_table(
   my_number number,
   my_date date,
   my_string varchar2(5)
);

-- Q9
create sequence seq_movie_id
   start with 20 
   increment by 2;

-- Q10
select sequence_name, last_number, increment_by
   from user_sequences
   where sequence_name = 'SEQ_MOVIE_ID';

-- Q11
select seq_movie_id.nextval from dual;

-- Q12
alter sequence seq_movie_id
   increment by 5;

-- Q13
insert into mm_movie ( movie_id, movie_title, movie_cat_id, movie_value, movie_qty)
   values (seq_movie_id.nextval, 'Home Alone', 5, 23.24, 1);

-- Q14
create view vw_movie_rental as
   select m.movie_title, r.rental_id, mem.last
      from mm_movie m
      join mm_rental r on m.movie_id = r.movie_id
      join mm_member mem on r.member_id = mem.member_id
      order by r.rental_id;

select * from vw_movie_rental;

-- Q15
update mm_member
   set last = 'Tangier 1'
   where member_id in (
      select member_id
         from mm_rental
         where movie_id = 2
   );

select * from vw_movie_rental;
