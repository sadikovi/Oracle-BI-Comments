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
'Òàáëèöà ñâÿçè àòðèáóòîâ ñ ãðóïïàìè àòðèáóòîâ';

comment on column B009_ATTR_ATTR_GROUP.ATTRIBUTE_ID is
'ID àòðèáóòà';

comment on column B009_ATTR_ATTR_GROUP.ATTRIBUTE_GROUP_ID is
'ID ãðóïïû àòðèáóòîâ';

alter table B009_ATTR_ATTR_GROUP
   add constraint FK_B009_D035 foreign key (ATTRIBUTE_ID)
      references D035_ATTRIBUTE (ATTRIBUTE_ID) disable;

alter table B009_ATTR_ATTR_GROUP
   add constraint FK_B009_D033 foreign key (ATTRIBUTE_GROUP_ID)
      references D033_ATTRIBUTE_GROUP (ATTRIBUTE_GROUP_ID) disable;
