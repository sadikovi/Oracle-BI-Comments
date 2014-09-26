drop table D035_ATTRIBUTE purge;

/*==============================================================*/
/* Table: D035_ATTRIBUTE                                        */
/*==============================================================*/
create table D035_ATTRIBUTE 
(
   ATTRIBUTE_ID         NUMBER(16)           not null,
   D035_NAME            VARCHAR2(255),
   D035_VALUE           VARCHAR2(4000),
   INSERT_DATE          DATE,
   UPDATE_DATE          DATE,
   constraint PK_D035_ATTRIBUTE primary key (ATTRIBUTE_ID)
);

create unique index UI_D035_ATTRIBURE_NAME_VALUE on d035_attribute(d035_name, d035_value) 
	tablespace LOGISTICS_TBS;

comment on table D035_ATTRIBUTE is
'Ñïðàâî÷íèê àòðèáóòîâ';

comment on column D035_ATTRIBUTE.ATTRIBUTE_ID is
'ID àòðèáóòà';

comment on column D035_ATTRIBUTE.D035_NAME is
'Íàçâàíèå àòðèáóòà';

comment on column D035_ATTRIBUTE.D035_VALUE is
'Çíà÷åíèå àòðèáóòà';
