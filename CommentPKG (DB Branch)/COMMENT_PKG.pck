create or replace package COMMENT_PKG is
-----------------------------------------------------------------------------
-- isadikov 15.08.2012: ����� ������
-- isadikov 21.08.2012: ������ ������������
-- isadikov 29.08.2012: ��������� ��������� �������� �����������
-- isadikov 13.09.2012: ��������� �������  fnc_url_decode
-- isadikov 14.09.2012: ��������� ������� fnc_url_encode
-----------------------------------------------------------------------------

  --��������� �������� �����������
  --������� ���������: ������������, �������� ������, ����� �����������, ������ � �����������
  --������ � ����������� ����� ��� (����������� ";"):
  --p1=Region;p2=Region Value;p3=City;p4=City Value;p5=Week;p6=52th Week
  procedure write_comment(
    p_username in f013_comments.f013_user%type,
    p_report_name in f013_comments.f013_report_name%type,
    p_comment in f013_comments.f013_comment%type,
    p_parameters in varchar2
  );

  --������� �������� ����������� ��� ����� ������ � ������ � �����������
  --������ � ����������� ����� ��� (����������� ";"):
  --p1=Region;p2=Region Value;p3=City;p4=City Value;p5=Week;p6=52th Week
  --���������� ������� � ������: ����� ������, ������������, �����������, ���� �������� �����������
  function get_comment (
    p_report_name in f013_comments.f013_report_name%type,
    p_parameters in varchar2
  )
  return comment_table_type pipelined;

  --��������� �������� ����������� ��� ����� ������������, �������� ������,
  --���� ���������� ������ � ������ �����������
  procedure delete_comment (
    p_username in f013_comments.f013_user%type,
    p_comment_id in f013_comments.comment_id%type
  );
  --������� ������������� ������ �� URL type
  function fnc_url_decode (
    p_str in varchar2
  )
  return varchar2;
  
  --������� �������������� ������ � URL type
  function fnc_url_encode(
    p_str in varchar2
  )
  return varchar2;

end COMMENT_PKG;
/
create or replace package body COMMENT_PKG is

  --isadikov: 13.09.2012
  --������ ������������� ������ ���� "%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82" � "������"
  function fnc_url_decode (
    p_str in varchar2
  )
  return varchar2
  is
    p_str_1 f013_comments.f013_comment%type :='';
    l_string f013_comments.f013_comment%type :='';
    l_index number(3) := 0;
    l_symbol varchar2(128) :='';
    current_element varchar2(255) :='';
  begin
    p_str_1 := replace(p_str, '%C2%A0', '%20'); -- �� ���������� ���������� ������� C2A0
    --��������� �� ������� ������
    while l_index < length(p_str)
      loop
        l_index := l_index + 1;
        --�������� ������� ������
        --���� �� ����� '%', �� �� ��������, ��� ��� �����-�� ������ ��� ���������
        --��� ��������� ������ ������ ���������� � ���� "%D0%AB" ��� "D1%AB" 
        l_symbol := substr(p_str_1, l_index, 1);
        if l_symbol = '%' then
          if substr(p_str_1, l_index +1, 2) = 'D0' or substr(p_str_1, l_index +1, 2) = 'D1' then
            current_element := substr(p_str_1, l_index, 6);
            l_symbol := utl_raw.cast_to_varchar2(replace(current_element, '%', ''));
            l_index := l_index + 5;
          else
            current_element := substr(p_str_1, l_index, 3);
            l_symbol := utl_raw.cast_to_varchar2(replace(current_element, '%', ''));
            l_index := l_index + 2;
          end if;       
        end if;
        --�������� ������ �����������
        l_string := l_string || l_symbol;
      end loop;
    return l_string;
  end fnc_url_decode;
  
  --isadikov: 14.09.2012
  --������� ����������� � URL type
  --������ ���� "������" � "%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82"
  function fnc_url_encode(
    p_str in varchar2
  )
  return varchar2
  is
    l_string varchar2(1024) :='';
    l_index number(3) := 0;
    l_inner_index number(3) := 0;
    l_ascii binary_integer;
    l_symbol varchar2(128) := '';
    in_element varchar2(128) :='';
    out_element varchar2(128) :='';
  begin
    while l_index < length(p_str)
      loop
        l_index := l_index + 1;
        l_symbol := substr(p_str, l_index, 1);
        l_ascii := ascii(substr(p_str, l_index, 1));
        if l_ascii > (127 + 53264) and l_ascii < (500 + 53264) then
          in_element := rawtohex(utl_raw.cast_to_raw(l_symbol));
          out_element := '';
          l_inner_index := 0;
          while l_inner_index < length(in_element)
            loop
              l_inner_index := l_inner_index + 1;
              if l_inner_index = 1 then
                out_element := out_element || '%' || substr(in_element,l_inner_index,1);
              elsif l_inner_index = 3 then
                out_element := out_element || '%' || substr(in_element,l_inner_index,1);
              else 
                out_element := out_element || substr(in_element,l_inner_index,1);
              end if;
            end loop;
            l_symbol := out_element;
         elsif regexp_like(chr(l_ascii), '[ !"#%&''*,:;<=>?^`{|}]') then
          l_symbol := '%' || rawtohex(utl_raw.cast_to_raw(l_symbol));
         end if;
        l_string := l_string || l_symbol;
      end loop;
    return l_string;
  end fnc_url_encode;
  
  --������� ������ ������������ ��� ������������ ������������
  --���� �������� �� ����������� ���������
  function fnc_symb_replace (
    p_str in varchar2
  )
  return varchar2
  is
    l_str f013_comments.f013_comment%type :='';
  begin
    l_str := p_str;
    --1. �������� ������� break_line �� \u000A (��� \n\r)
    l_str := replace(l_str, chr(10), '\u000A');
    --2. �������� ������� " �� \u0022
    l_str := replace(l_str, '"', '\u0022');
    --���������� ��������������� ������
    return l_str;  
  end fnc_symb_replace;
  
  --��������� ���������� ������� b009_attr_attr_group
  procedure load_b009 (
    p_attribute_id in d035_attribute.attribute_id%type,
    p_attribute_group_id in d033_attribute_group.attribute_group_id%type
  )
  is
    --����, ��������������� � ������� ���������� attribute_id � attribute_group_id � ������� b009
    flg number(1) :=0;
  begin
    select
      1 into flg
    from dual
      where exists (
        select *
        from
          b009_attr_attr_group
        where
          b009_attr_attr_group.attribute_id = p_attribute_id
          and b009_attr_attr_group.attribute_group_id = p_attribute_group_id
       );

  exception
    when others then
      --��� ��������� ����� ���������� id-������, ���������� ������� ������ � ������� b009
      insert into b009_attr_attr_group values(p_attribute_id, p_attribute_group_id);
      commit;

  end load_b009;

  --��������� ���������� ������� d035_attribute
  procedure load_d035 (
    p_parameters in varchar2,
    p_attribute_group_id in d033_attribute_group.attribute_group_id%type
  )
  is
    current_index number(3) :=0;
    mask varchar(36) :='';
    mask_index number :=1;
    parameter_id d035_attribute.attribute_id%type;
    current_element varchar2(4000) :='';
    current_id d035_attribute.attribute_id%type;
    current_parameter varchar2(255) :='';
    current_value varchar2(4000) :='';
  begin
    --������������ ������ � �����������
    current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

    while current_element is not null
      loop
        begin
          --��������� ����� ���� "p2="
          mask := 'p'|| to_char(mask_index) || '=';
          --������� ������ ������� ������ � �����������, ���������� ������ � ���������� ����������
          if (current_element not like 'p0=%') then
            current_element := replace(current_element, mask, '');

            --�������� ������ ���� ��� �������� ��������
            --�������� ��������� - ��� ������
            if (mod(mask_index,2) != 0) then
              current_parameter := current_element;
            else
              current_value := current_element;

              --�� ��������� ������ �������� � current_value ����� ��������� ������� d035_attribute
              --��� ��� �������� "��������-��������"
              select seq_dim.nextval into parameter_id from dual;
              --������� ������
              merge into d035_attribute using
              (select
                  parameter_id as id,
                  current_parameter as parameter,
                  current_value as value
               from dual) src_attr
              on (src_attr.parameter = d035_attribute.d035_name
                  and src_attr.value = d035_attribute.d035_value)

              when matched then
                update set
                  d035_attribute.update_date = sysdate

              when not matched then
                insert (
                  d035_attribute.attribute_id,
                  d035_attribute.d035_name,
                  d035_attribute.d035_value,
                  insert_date
                )
                values (
                  src_attr.id,
                  src_attr.parameter,
                  src_attr.value,
                  sysdate
                );

              commit;

              --����� ������� current_parameter � current_value
              --� ���������� id, �������������� ���� ���� "��������-��������"
              select
                  d035_attribute.attribute_id
                  into current_id
              from
                d035_attribute,
                (select
                  current_parameter as parameter,
                  current_value as value
                  from dual) src_attr
              where
                d035_attribute.d035_name = src_attr.parameter 
                and d035_attribute.d035_value = src_attr.value;

              --���������� ��������� ���������� ������� b009 � �������� id �������� � ������ ���������
              load_b009(current_id, p_attribute_group_id);

              end if;
            end if;
          end;
         mask_index := mask_index + 1;
         current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);
      end loop;
   end load_d035;

  --��������� ���������� ������� d033_attribute_group
  procedure load_d033 (
      p_parameters in varchar2,
      p_attribute_group_id out d033_attribute_group.attribute_group_id%type
    )
  is
    current_index number(3) :=0;
    mask varchar(36) :='';
    mask_index number :=1;
    attr_group_id  d033_attribute_group.attribute_group_id%type;
    current_element varchar2(4000) :='';
    current_code varchar2(1024) :='';
  begin
    --������������ ������ � ����������� � �� ����������
    current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

    while current_element is not null
      loop
        begin

          --��������� ����� ���� "p2=", �����
          --������������ ������� �� �� �������� ��������� (��������� ������ ��������)
          mask := 'p'|| to_char(mask_index) || '=';

          --������� ������ �������� "p0=�����", ���������� ���������� ������������ ����������
          if (current_element not like 'p0=%') then

            current_element := replace(current_element, mask, '');
              --� ���������� ��������� � ������
              current_code := current_code || current_element;

            end if;

        end;
        --����������� ������ �����
        mask_index := mask_index + 1;

        current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

      end loop;

      --��������� id ������ ��������� �� ������������������
      select seq_dim.nextval into attr_group_id from dual;

      --������� ������ � ������� d033_attribute_group
      merge into d033_attribute_group using
          (select
              attr_group_id as id,
              ora_hash(current_code) as code
           from dual) src_group

          on (src_group.code = d033_attribute_group.d033_group_cd)

          when matched then
            update set
              d033_attribute_group.update_date = sysdate

          when not matched then
            insert (
              d033_attribute_group.attribute_group_id,
              d033_attribute_group.d033_group_cd,
              insert_date
            )
            values (
              src_group.id,
              src_group.code,
              sysdate
            );

            commit;

      --������� ��� �������� ����������� id ������ ��������� � ������� d033_attribute_group
      --� ����������� ���������� �� ������ �������� ����� id
      select
        d033_attribute_group.attribute_group_id into p_attribute_group_id
      from
        d033_attribute_group,
        (select
          ora_hash(current_code) as code
          from dual) src_group
      where src_group.code = d033_attribute_group.d033_group_cd;

  end load_d033;

  --��������� ���������� ������� f013_comments
  procedure load_f013 (
    p_username in varchar2,
    p_report_name in varchar2,
    p_comment in varchar2,
    p_parameters in varchar2
  )
  is
    comments_id  f013_comments.comment_id%type;
    attr_group_id d033_attribute_group.attribute_group_id%type;
  begin
    --��������� id ������� f013_comments � ������� �� � ���������� comments_id
    select seq_dim.nextval into comments_id from dual;

    --�������� ��������� �������� ������� d033
    --� ���������� id ������ ���������, ���������� �� � ���������� attr_group_id
    load_d033(p_parameters, attr_group_id);

    --�������� ��������� ���������� ������� d035_attribute
    load_d035(p_parameters, attr_group_id);

    --��������� ������� f013_comments
    insert into f013_comments (
      comment_id,
      attribute_group_id,
      f013_report_name,
      f013_user,
      f013_comment,
      f013_insert_date
    )
    values(
      comments_id,
      attr_group_id,
      p_report_name,
      p_username,
      p_comment,
      sysdate
    );

    commit;
  end load_f013;

  --��������� ��������� �������� ������������
  procedure write_comment(
    p_username in f013_comments.f013_user%type,
    p_report_name in f013_comments.f013_report_name%type,
    p_comment in f013_comments.f013_comment%type,
    p_parameters in varchar2
  )
  is
    opid number;
    l_report_name f013_comments.f013_report_name%type := '';
    l_comment f013_comments.f013_comment%type := '';
    l_parameters f013_comments.f013_comment%type :='';
  begin
    select seq_operation_log.nextval into opid from dual;
   
    --��������� ��������� �������� f013_comments
    l_report_name := fnc_url_decode(p_report_name);
    l_comment := fnc_url_decode(p_comment);
    l_parameters := fnc_url_decode(p_parameters);
    
    load_f013(p_username, l_report_name, l_comment,l_parameters);

  end write_comment;

  --������� �������� ������ "����� ������, ������������, �����������, ���� ������� �����������"
  function get_comment (
    --��� ������
    p_report_name in f013_comments.f013_report_name%type,
    --������� ������ ���������� ����� ��� p0=2;p1=City;p2=Moscow;p3=Week;p4=53th Week
    p_parameters in varchar2
  )
  return comment_table_type pipelined
  is
    --������ ��� ������� ����������
    l_report_name f013_comments.f013_report_name%type :='';
    l_parameters f013_comments.f013_comment%type :='';
    --����� �������, ������������� ������ �� ������� f013_comments ��� ������ � �����������
    query varchar2(4000) :='';
    --������������ ����� ������� (��������� ���������� �� �������� ��������)
    query_part varchar2(1024) :='';
    --ID �����������
    comment_id number(16);
    --��� ������������
    user_name varchar2(128) := '';
    --����� �����������
    comment_text varchar2(4000) := '';
    --���� �������
    insert_date date;

    /*��������� ����������*/
    ind number :=0;
    current_element varchar2(1024) := '';
    mask varchar2(64) :='';
    mask_index number(3) :=1;
    parameters_count number(3) :=0;
    row_number number(5) :=0;
    row_count number :=0;

    --������� �������� ���� "��������-��������" ��������
    current_parameter varchar2(1024) := '';
    current_value varchar2(1024) := '';
  begin
    --����������� �������� �������
    l_report_name := fnc_url_decode(p_report_name);
    l_parameters := fnc_url_decode(p_parameters);
    
    --������ �������� ���������� ������ �������
    query := 'select *
              from
              (select
                rownum as order_num,
                f13.comment_id as f13_id,
                f13.f013_user as f13_user,
                f13.f013_comment as f13_comment,
                f13.f013_insert_date as f13_insert_date
              from
                (select *
                  from f013_comments
                  order by f013_comments.f013_insert_date desc) f13,
                d035_attribute d32,
                d033_attribute_group d33,
                b009_attr_attr_group b09
              where
                f13.f013_report_name = ''' || l_report_name || '''
                and f13.attribute_group_id = d33.attribute_group_id
                and d33.attribute_group_id = b09.attribute_group_id
                and b09.attribute_id = d32.attribute_id';

    --������������ ������ � �����������
    ind := fnc_get_next_word(l_parameters, ind + 1, ';', current_element);
    while current_element is not null
      loop
        begin
          --��� ������� current_element ��������� ����� ���� "p[i]="
          mask := 'p' || to_char(mask_index) || '=';
          --�������� ������ �������� ������ "p0=", ������. ���������� ������������ ����������
          if (current_element like 'p0=%') then
            parameters_count := to_number(replace(current_element, 'p0=', ''));
          else
            --������� �� current_element ����� ������ �� �����
            current_element := replace(current_element, mask, '');
            --������ �������� �������� ���� ��� �������� ������ (p1=)
            if (mod(mask_index, 2) != 0) then
              current_parameter := current_element;
            else
              --������ �������� �������� - ��� ������ ������ (p2=)
              current_value := current_element;
              --���� �������� ���� ��� ������ "p2=" (������ �������), �� �� ��������� � �������� �������:
              if (mask_index = 2) then
                query_part := '
                  and d32.d035_name = ''' || current_parameter || '''
                  and d32.d035_value = ''' || current_element || '''';
              else
                --������� ����������� ��������� ��������� � �������� "and exists()"
                query_part :=' and exists (
                    select 1
                    from
                      d035_attribute attr_1,
                      b009_attr_attr_group at_at_group_1
                    where
                      d33.attribute_group_id = at_at_group_1.attribute_group_id
                      and at_at_group_1.attribute_id = attr_1.attribute_id
                      and attr_1.d035_name = ''' || current_parameter || '''
                      and attr_1.d035_value = ''' || current_element || ''')';
               end if;

              --��������� ������, ������������ � ������� ������
              query := query || query_part;

            end if;
          end if;
        end;
        mask_index := mask_index + 1;
        ind := fnc_get_next_word(l_parameters, ind + 1, ';', current_element);
      end loop;

    --��������� ������ ���������� ����������� "select * from (select smth from tables) d"
    query := query || ' ) d';

    --������������ ���������� ������������ �����
    execute immediate 'select count(*) from ('|| query || ')' into row_count;

    --��������� � ������ �������� ��� ������ ������������ ������ ������������ �������
    query := query || ' where d.order_num = :1';

    --������� ������ �������
    --(!)��� ���� ��� ������ (� pipe row) ������� ����������� � ������� ������� fnc_symb_replace
    if row_count is null or row_count = 0 then
      pipe row (comment_return_type(1, -1,'user', '����������� �����������', sysdate));
    else
      for i in 1 .. row_count
        loop
          execute immediate query into row_number, comment_id, user_name, comment_text, insert_date using i;
          pipe row (comment_return_type(row_number, comment_id, user_name, fnc_symb_replace(comment_text), insert_date));
        end loop;
    end if;

    return;

  end get_comment;

  --��������� �������� �����������
  --���������: ������������ ���� ���������� �����������, �������� ������, ����� �����������
  procedure delete_comment (
    p_username in f013_comments.f013_user%type,
    p_comment_id in f013_comments.comment_id%type
  )
  is
  
  begin
    --������� ������ � ��������� id �����������
    delete from f013_comments
    where
      f013_comments.comment_id = p_comment_id
      and f013_comments.f013_user = p_username;

    commit;

  end delete_comment;

end COMMENT_PKG;
/
