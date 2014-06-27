--тип, определ€ющий формат возвращаемых данных дл€ функции get_comment пакета COMMENT_PKG
create or replace type comment_return_type
as object (
  row_count number(5),
  comment_id number(16),
  user_name varchar2(128),
  comment_text varchar2(4000),
  insert_date date
)
/
