drop table D033_ATTRIBUTE_GROUP purge;

/*==============================================================*/
/* Table: D033_ATTRIBUTE_GROUP                                  */
/*==============================================================*/
create table D033_ATTRIBUTE_GROUP 
(
   ATTRIBUTE_GROUP_ID   NUMBER(16)           not null,
   D033_GROUP_CD        VARCHAR2(36),
   INSERT_DATE          DATE,
   UPDATE_DATE          DATE,
   constraint PK_D033_ATTRIBUTE_GROUP primary key (ATTRIBUTE_GROUP_ID)
);

comment on table D033_ATTRIBUTE_GROUP is
'Справочник групп атрибутов';

comment on column D033_ATTRIBUTE_GROUP.ATTRIBUTE_GROUP_ID is
'ID группы атрибутов';

comment on column D033_ATTRIBUTE_GROUP.D033_GROUP_CD is
'Код группы';

grant select on logistics.d033_attribute_group to LOGISTICS_ACCESS;