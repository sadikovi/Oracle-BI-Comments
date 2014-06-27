drop table B009_ATTR_ATTR_GROUP purge;

/*==============================================================*/
/* Table: B009_ATTR_ATTR_GROUP                                  */
/*==============================================================*/
create table B009_ATTR_ATTR_GROUP 
(
   ATTRIBUTE_ID         NUMBER(16),
   ATTRIBUTE_GROUP_ID   NUMBER(16)
);

comment on table B009_ATTR_ATTR_GROUP is
'Таблица связи атрибутов с группами атрибутов';

comment on column B009_ATTR_ATTR_GROUP.ATTRIBUTE_ID is
'ID атрибута';

comment on column B009_ATTR_ATTR_GROUP.ATTRIBUTE_GROUP_ID is
'ID группы атрибутов';

alter table B009_ATTR_ATTR_GROUP
   add constraint FK_B009_D035 foreign key (ATTRIBUTE_ID)
      references D035_ATTRIBUTE (ATTRIBUTE_ID) disable;

alter table B009_ATTR_ATTR_GROUP
   add constraint FK_B009_D033 foreign key (ATTRIBUTE_GROUP_ID)
      references D033_ATTRIBUTE_GROUP (ATTRIBUTE_GROUP_ID) disable;