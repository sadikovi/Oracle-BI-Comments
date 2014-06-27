drop table F013_COMMENTS purge;

/*==============================================================*/
/* Table: F013_COMMENTS                                         */
/*==============================================================*/
create table F013_COMMENTS 
(
   COMMENT_ID           NUMBER(16),
   ATTRIBUTE_GROUP_ID   NUMBER(16),
   F013_REPORT_NAME     VARCHAR2(1024),
   F013_USER            VARCHAR2(128),
   F013_COMMENT         VARCHAR2(4000),
   F013_INSERT_DATE     DATE
);

comment on table F013_COMMENTS is
'������� ������������';

comment on column F013_COMMENTS.COMMENT_ID is
'ID �����������';

comment on column F013_COMMENTS.ATTRIBUTE_GROUP_ID is
'ID ������ ���������';

comment on column F013_COMMENTS.F013_REPORT_NAME is
'�������� �������';

comment on column F013_COMMENTS.F013_USER is
'������������, ���������� �����������';

comment on column F013_COMMENTS.F013_COMMENT is
'����������� ������������';

comment on column F013_COMMENTS.F013_INSERT_DATE is
'���� ������� �����������';

alter table F013_COMMENTS
   add constraint FK_F013_D033 foreign key (ATTRIBUTE_GROUP_ID)
      references D033_ATTRIBUTE_GROUP (ATTRIBUTE_GROUP_ID) disable;

grant select on logistics.f013_comments to LOGISTICS_ACCESS;