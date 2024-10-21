BEGIN
   FOR rec IN (SELECT constraint_name, table_name
               FROM user_constraints
               WHERE constraint_type = 'R') 
   LOOP
      EXECUTE IMMEDIATE 'ALTER TABLE ' || rec.table_name || ' DROP CONSTRAINT ' || rec.constraint_name;
   END LOOP;
END;
/

-- 2. ¸ðµç Å×?Ìºí µå·Ó
BEGIN
   FOR rec IN (SELECT table_name FROM user_tables) 
   LOOP
      EXECUTE IMMEDIATE 'DROP TABLE ' || rec.table_name || ' CASCADE CONSTRAINTS'; 
   END LOOP;
END;
/

CREATE TABLE customer (
   customer_id   nvarchar2(50) primary key,
   customer_pw   nvarchar2(255)      NOT NULL,
   customer_phone   nvarchar2(20)      NULL,
   customer_email   nvarchar2(255)      NULL,
   customer_address   nvarchar2(255)      NULL,
   customer_birth   DATE      NULL,
   enabled integer not null 
);

CREATE TABLE authorities (
    customer_id nvarchar2(50),
    authority nvarchar2(50),
    CONSTRAINT fk_authorities_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
);
insert into authorities values('admin','ROLE_SUPERADMIN');

create table persistent_logins(
    username nvarchar2(50) not null,
    series nvarchar2(64) primary key,
    token nvarchar2(64) not null,
    last_used timestamp not null
);

CREATE TABLE musical (
   musical_id   NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
   musical_title   nvarchar2(255)      NOT NULL,
   musical_poster   nvarchar2(255)      NULL,
   musical_period_start   date      NULL,
   musical_period_end date NULL,
   musical_runningtime   number      NULL,
   musical_agelimit   number      NULL
);
CREATE SEQUENCE musical_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE venue (
   venue_id   NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
   venue_name   nvarchar2(255)      NOT NULL,
   venue_address   nvarchar2(255) null
);
CREATE SEQUENCE venue_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE hall (
   hall_id  NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
   hall_name nvarchar2(255),
   hall_total_seat number,
   venue_id number,

   CONSTRAINT fk_hall_venue
        FOREIGN KEY (venue_id)
        REFERENCES venue(venue_id)
);
CREATE SEQUENCE hall_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE musical_schedule (
   mu_sch_id    NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
   musical_id   number,
   venue_id   number,
   mu_sch_date   DATE,
   mu_sch_time   timestamp,
   hall_id number,
   seat_count nvarchar2(10) default '0',

   CONSTRAINT fk_mu_sch_musical
        FOREIGN KEY (musical_id)
        REFERENCES musical(musical_id),
   CONSTRAINT fk_mu_sch_venue
        FOREIGN KEY (venue_id)
        REFERENCES venue(venue_id),
   CONSTRAINT fk_mu_sch_hall
        FOREIGN KEY (hall_id)
        REFERENCES hall(hall_id)
);


CREATE TABLE seat (
   seat_id    NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
   hall_id number,
   mu_sch_id   number,
   musical_id   number,
   seat_grade   nvarchar2(50) NULL,
   seat_name   nvarchar2(50) NULL,
   seat_row   number NULL,
   seat_col   number NULL,
   seat_reservation   NUMBER(1) NULL,
   seat_price   number NULL,

   CONSTRAINT fk_seat_hall
        FOREIGN KEY (hall_id)
        REFERENCES hall(hall_id),
   CONSTRAINT fk_seat_mu_sch
        FOREIGN KEY (mu_sch_id)
        REFERENCES musical_schedule(mu_sch_id),
   CONSTRAINT fk_seat_musical
        FOREIGN KEY (musical_id)
        REFERENCES musical(musical_id)
);




CREATE TABLE reservation (
   reservation_id   number      primary key,
   seat_id   number      NULL,
   mu_sch_id   number      NULL,
   customer_id   nvarchar2(50)      NULL,
   total_cost number,
   reservation_cancel number default 0,
   reservation_time date default sysdate,
   payment_method VARCHAR2(20) NULL, 
   merchant_uid nvarchar2(50) NULL ,
    CONSTRAINT fk_reservation_mu_sch
        FOREIGN KEY (mu_sch_id)
        REFERENCES musical_schedule(mu_sch_id),
    CONSTRAINT fk_reservation_seat
        FOREIGN KEY (seat_id)
        REFERENCES seat(seat_id),
    CONSTRAINT fk_reservation_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE CASCADE
);

create table review(
    review_id number,
    customer_id nvarchar2(50),
    musical_id number,
    content nvarchar2(500),
    rating number,
    review_date date,
    CONSTRAINT fk_review_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_review_musical
        FOREIGN KEY (musical_id)
        REFERENCES musical(musical_id)
        ON DELETE CASCADE
);
create sequence qa_count;
drop table qa;
create table qa(
    qa_id number,
    customer_id nvarchar2(50),
    musical_id number default null,
    qa_type nvarchar2(50),
    title nvarchar2(500),
    content varchar2(4000),
    qa_date date,
    response varchar2(4000) default null,
    display NUMBER(1) default 0,
     CONSTRAINT fk_qa_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_qa_musical
        FOREIGN KEY (musical_id)
        REFERENCES musical(musical_id)
        ON DELETE CASCADE
);

create table actor(
actor_id number primary key,
actor_name varchar(50),
birthday date,
height number,
weight number,
actor_img nvarchar2(100)
);
CREATE SEQUENCE actor_seq START WITH 1 INCREMENT BY 1;

create table character(
character_id number primary key,
musical_id number,
character_name varchar2(50),

CONSTRAINT fk_musical
    FOREIGN KEY (musical_id)
    REFERENCES musical(musical_id)

);
CREATE SEQUENCE character_seq START WITH 1 INCREMENT BY 1;

create table actor_character(
character_id number,
actor_id number,
CONSTRAINT fk_actor
    FOREIGN KEY (actor_id)
    REFERENCES actor(actor_id)
    ON DELETE CASCADE,
CONSTRAINT fk_character
    FOREIGN KEY (character_id)
    REFERENCES character(character_id)
    ON DELETE CASCADE
);

create table musical_like(
    musical_id number,
    customer_id nvarchar2(50),
    CONSTRAINT fk_musical_like
        FOREIGN KEY (musical_id)
        REFERENCES musical(musical_id),
    CONSTRAINT fk_customer_like
        FOREIGN KEY (customer_id)
        REFERENCES customer(customer_id)
        ON DELETE CASCADE
);

create sequence reservation_seq
start with 1000
increment by 1
nocache
nocycle;

create sequence seat_create_seq
start with 1000
increment by 1
nocache
nocycle;

create or replace procedure manage_seats(
    p_hall_id in number,
    p_mu_sch_id in number,
    p_musical_id in number,
    p_seat_price in number
) as
begin
    for row_num in 1..6 loop
        for col_num in 1..8 loop
            insert into seat(hall_id, mu_sch_id, musical_id, seat_grade, seat_name, seat_row, seat_col, seat_reservation, seat_price)
            values(p_hall_id, p_mu_sch_id, p_musical_id, '?Ï¹Ý¼®', chr(64 + row_num) || '-' || col_num, row_num, col_num, 0, p_seat_price);
        end loop;
    end loop;
end;


  



CREATE TABLE venue_api (
    x NUMBER,
    y NUMBER,
    venue_id NUMBER,
    geometry SDO_GEOMETRY,
    CONSTRAINT pk_venue_api PRIMARY KEY (x, y),
    CONSTRAINT fk_venue_api_venue FOREIGN KEY (venue_id) REFERENCES venue(venue_id)
);

CREATE TABLE notice_board (
nGroupKind VARCHAR2(255),
nId NUMBER PRIMARY KEY,
nTitle VARCHAR2(255) NOT NULL,
nContent CLOB NOT NULL,
nEtc VARCHAR2(4000) NULL,
nOpenTime DATE DEFAULT null,
nWriteTime DATE DEFAULT sysdate,
nUpdateTime DATE DEFAULT null,
nHit NUMBER DEFAULT 0,
nDelete VARCHAR2(1) DEFAULT 'Y'
);
CREATE SEQUENCE notice_board_seq START WITH 1 INCREMENT BY 1;

CREATE TABLE faq_board (
fGroupKind VARCHAR2(255),
fId NUMBER PRIMARY KEY,
fTitle VARCHAR2(255) NOT NULL,
fContent CLOB NOT NULL,
fEtc VARCHAR2(4000) NULL,
fWriteTime DATE DEFAULT sysdate,
fUpdateTime DATE DEFAULT null,
fDelete VARCHAR2(1) DEFAULT 'Y'
);
CREATE SEQUENCE faq_board_seq START WITH 1 INCREMENT BY 1;

create table admin(
manage_id number primary key,
table_name varchar2(50),
table_id number,
table_content varchar2(400) null,
table_crud varchar2(50),
crud_reason varchar2(4000) DEFAULT null,
fileName varchar2(200) DEFAULT null,
crud_date date DEFAULT sysdate
);
CREATE SEQUENCE admin_seq START WITH 1 INCREMENT BY 1;



CREATE SEQUENCE review_seq
  START WITH 1
  INCREMENT BY 1
  MINVALUE 1;



CREATE TABLE main_img (
    img_id    NUMBER GENERATED BY DEFAULT ON NULL AS IDENTITY PRIMARY KEY,
    musical_id NUMBER,
    img_name NVARCHAR2(50),
    img_num  NUMBER,

    CONSTRAINT fk_main_img_musical
        FOREIGN KEY (musical_id)
        REFERENCES musical(musical_id)
);










--ALTER TABLE character DROP CONSTRAINT fk_actor;