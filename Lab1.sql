DESC MM_MEMBER;


INSERT INTO MM_MEMBER (member_id, last, first) VALUES (15, 'Chat', 'GPT');


UPDATE MM_MEMBER SET credit_card = '987654321012' WHERE member_id = 15;


COMMIT;


SELECT MM_MOVIE.movie_title, MM_RENTAL.rental_id, MM_MEMBER.last 
FROM MM_MOVIE
JOIN MM_RENTAL ON MM_MOVIE.movie_id = MM_RENTAL.movie_id
JOIN MM_MEMBER ON MM_RENTAL.member_id = MM_MEMBER.member_id
ORDER BY MM_RENTAL.rental_id;


SELECT MM_MOVIE.movie_title, MM_RENTAL.rental_id, MM_MEMBER.last 
FROM MM_MOVIE, MM_RENTAL, MM_MEMBER
WHERE MM_MOVIE.movie_id = MM_RENTAL.movie_id AND MM_RENTAL.member_id = MM_MEMBER.member_id
ORDER BY MM_RENTAL.rental_id;


CREATE TABLE MY_TABLE (
    MY_NUMBER NUMBER,
    MY_DATE DATE,
    MY_STRING VARCHAR2(5)
);



CREATE SEQUENCE seq_movie_id START WITH 20 INCREMENT BY 2;



SELECT sequence_name, last_number, increment_by 
FROM user_sequences 
WHERE sequence_name = 'SEQ_MOVIE_ID';



SELECT seq_movie_id.NEXTVAL FROM DUAL;



ALTER SEQUENCE seq_movie_id INCREMENT BY 5;



INSERT INTO MM_MOVIE (movie_id, movie_title, movie_cat_id, movie_value, movie_qty)
VALUES (seq_movie_id.NEXTVAL, 'Your Favorite Movie', 1, 20.00, 5);



CREATE VIEW VW_MOVIE_RENTAL AS
SELECT MM_MOVIE.movie_title, MM_RENTAL.rental_id, MM_MEMBER.last 
FROM MM_MOVIE
JOIN MM_RENTAL ON MM_MOVIE.movie_id = MM_RENTAL.movie_id
JOIN MM_MEMBER ON MM_RENTAL.member_id = MM_MEMBER.member_id
ORDER BY MM_RENTAL.rental_id;


SELECT * FROM VW_MOVIE_RENTAL;


UPDATE MM_MEMBER
SET last = 'Tangier 1'
WHERE member_id IN (
    SELECT member_id FROM VW_MOVIE_RENTAL WHERE rental_id = 2
);
