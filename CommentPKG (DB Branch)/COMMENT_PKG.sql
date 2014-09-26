create or replace package COMMENT_PKG is
-----------------------------------------------------------------------------
-- isadikov 15.08.2012: ïàêåò ñîçäàí
-- isadikov 21.08.2012: óáðàíî ëîããèðîâàíèå
-- isadikov 29.08.2012: äîáàâëåíà ïðîöåäóðà óäàëåíèÿ êîììåíòàðèÿ
-- isadikov 13.09.2012: äîáàâëåíà ôóíêöèÿ  fnc_url_decode
-- isadikov 14.09.2012: äîáàâëåíà ôóíêöèÿ fnc_url_encode
-----------------------------------------------------------------------------

  --ïðîöåäóðà çàãðóçêè êîììåíòàðèÿ
  --âõîäíûå ïàðàìåòðû: ïîëüçîâàòåëü, íàçâàíèå îò÷åòà, òåêñò êîììåíòàðèÿ, ñòðîêà ñ ïàðàìåòðàìè
  --ñòðîêà ñ ïàðàìåòðàìè èìååò âèä (ðàçäåëèòåëü ";"):
  --p1=Region;p2=Region Value;p3=City;p4=City Value;p5=Week;p6=52th Week
  procedure write_comment(
    p_username in f013_comments.f013_user%type,
    p_report_name in f013_comments.f013_report_name%type,
    p_comment in f013_comments.f013_comment%type,
    p_parameters in varchar2
  );

  --ôóíêöèÿ âîçâðàòà êîììåíòàðèÿ äëÿ èìåíè îò÷åòà è ñòðîêè ñ ïàðàìåòðàìè
  --ñòðîêà ñ ïàðàìåòðàìè èìååò âèä (ðàçäåëèòåëü ";"):
  --p1=Region;p2=Region Value;p3=City;p4=City Value;p5=Week;p6=52th Week
  --âîçâðàùàåò òàáëèöó ñ ïîëÿìè: íîìåð ñòðîêè, ïîëüçîâàòåëü, êîììåíòàðèé, äàòà ñîçäàíèÿ êîììåíòàðèÿ
  function get_comment (
    p_report_name in f013_comments.f013_report_name%type,
    p_parameters in varchar2
  )
  return comment_table_type pipelined;

  --ïðîöåäóðà óäàëåíèÿ êîììåíòàðèÿ äëÿ èìåíè ïîëüçîâàòåëÿ, íàçâàíèÿ îò÷åòà,
  --äàòû äîáàâëåíèÿ îò÷åòà è òåêñòà êîììåíòàðèÿ
  procedure delete_comment (
    p_username in f013_comments.f013_user%type,
    p_comment_id in f013_comments.comment_id%type
  );
  --ôóíêöèÿ äåêîäèðîâàíèÿ ñòðîêè èç URL type
  function fnc_url_decode (
    p_str in varchar2
  )
  return varchar2;
  
  --ôóíêöèÿ ïðåîáðàçîâàíèÿ ñòðîêè â URL type
  function fnc_url_encode(
    p_str in varchar2
  )
  return varchar2;

end COMMENT_PKG;
/
create or replace package body COMMENT_PKG is

  --isadikov: 13.09.2012
  --Ôóíêèÿ äåêîäèðîâàíèÿ ñòðîêè âèäà "%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82" â "Ïðèâåò"
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
    p_str_1 := replace(p_str, '%C2%A0', '%20'); -- íå ïîëó÷àåòñÿ îáðàáîòàòü ïðîáåëû C2A0
    --Ïðîáåãàåì ïî âõîäíîé ñòðîêå
    while l_index < length(p_str)
      loop
        l_index := l_index + 1;
        --âûáèðàåì òåêóùèé ñèìâîë
        --åñëè îí ðàâåí '%', òî ìû ïîíèìàåì, ÷òî ýòî êàêîé-òî ñèìâîë èëè êèðèëëèöà
        --Äëÿ êèðèëëèöû ñèìâîë âñåãäà ïðåäñòàâèì â âèäå "%D0%AB" èëè "D1%AB" 
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
        --ñîáèðàåì ñòðîêó ïîñèìâîëüíî
        l_string := l_string || l_symbol;
      end loop;
    return l_string;
  end fnc_url_decode;
  
  --isadikov: 14.09.2012
  --ôóíêöèÿ êîäèðîâàíèÿ â URL type
  --ñòðîêè âèäà "Ïðèâåò" â "%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82"
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
  
  --ôóíêöèÿ çàìåíû ñïåöñèìâîëîâ äëÿ ôîðìèðîâàíèÿ êîììåíòàðèåâ
  --íàäî äîïèëèòü äî íîðìàëüíîãî ñîñòîÿíèÿ
  function fnc_symb_replace (
    p_str in varchar2
  )
  return varchar2
  is
    l_str f013_comments.f013_comment%type :='';
  begin
    l_str := p_str;
    --1. Çàìåíÿåì ñèìâîëû break_line íà \u000A (èëè \n\r)
    l_str := replace(l_str, chr(10), '\u000A');
    --2. Çàìåíÿåì ñèìâîëû " íà \u0022
    l_str := replace(l_str, '"', '\u0022');
    --âîçâðàùàåì ïðåîáðàçîâàííóþ ñòðîêó
    return l_str;  
  end fnc_symb_replace;
  
  --ïðîöåäóðà çàïîëíåíèÿ òàáëèöû b009_attr_attr_group
  procedure load_b009 (
    p_attribute_id in d035_attribute.attribute_id%type,
    p_attribute_group_id in d033_attribute_group.attribute_group_id%type
  )
  is
    --ôëàã, ñèãíàëèçèðóþùèé î íàëè÷èè êîìáèíàöèè attribute_id è attribute_group_id â òàáëèöå b009
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
      --ïðè îòñóñòâèè òàêîé êîìáèíàöèè id-øíèêîâ, ïðîèñõîäèò âñòàâêà çàïèñè â òàáëèöó b009
      insert into b009_attr_attr_group values(p_attribute_id, p_attribute_group_id);
      commit;

  end load_b009;

  --ïðîöåäóðà çàïîëíåíèÿ òàáëèöû d035_attribute
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
    --ðàñïàðñèâàåì ñòðîêó ñ ïàðàìåòðàìè
    current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

    while current_element is not null
      loop
        begin
          --ôîðìèðóåì ìàñêó òèïà "p2="
          mask := 'p'|| to_char(mask_index) || '=';
          --óáèðàåì ïåðâûé ýëåìåíò ñòðîêè ñ ïàðàìåòðàìè, ñîäåðæàùèé äàííûå î êîëè÷åñòâå ïàðàìåòðîâ
          if (current_element not like 'p0=%') then
            current_element := replace(current_element, mask, '');

            --ïàðàìåòð âñåãäà èäåò ïîä íå÷åòíûì èíäåêñîì
            --çíà÷åíèå ïàðàìåòðà - ïîä ÷åòíûì
            if (mod(mask_index,2) != 0) then
              current_parameter := current_element;
            else
              current_value := current_element;

              --ïî îêîí÷àíèþ çàïèñè çíà÷åíèÿ â current_value ìîæíî çàïîëíèòü òàáëèöó d035_attribute
              --òàê êàê ïîëó÷àåì "ïàðàìåòð-çíà÷åíèå"
              select seq_dim.nextval into parameter_id from dual;
              --ìåðäæèì çàïèñè
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

              --áåðåì òåêóùèå current_parameter è current_value
              --è îïðåäåëÿåì id, ñîîòâåòñâóþùèé ýòîé ïàðå "ïàðàìåòð-çíà÷åíèå"
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

              --âûçûâàåòñÿ ïðîöåäóðà çàïîëíåíèÿ òàáëèöû b009 ñ òåêóùèìè id àòðèáóòà è ãðóïïû àòðèáóòîâ
              load_b009(current_id, p_attribute_group_id);

              end if;
            end if;
          end;
         mask_index := mask_index + 1;
         current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);
      end loop;
   end load_d035;

  --ïðîöåäóðà çàïîëíåíèÿ òàáëèöû d033_attribute_group
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
    --ðàñïàðñèâàåì ñòðîêó ñ ïàðàìåòðàìè è èõ çíà÷åíèÿìè
    current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

    while current_element is not null
      loop
        begin

          --ôîðìèðóåì ìàñêó òèïà "p2=", ÷òîáû
          --âïîñëåäñòâèè óäàëèòü åå èç òåêóùåãî ïàðàìåòðà (îñòàâëÿåì òîëüêî çíà÷åíèå)
          mask := 'p'|| to_char(mask_index) || '=';

          --óáèðàåì ïåðâûé ïàðàìåòð "p0=÷èñëî", ñîäåðæàùèé êîëè÷åñòâî ïåðåäàâàåìûõ ïàðàìåòðîâ
          if (current_element not like 'p0=%') then

            current_element := replace(current_element, mask, '');
              --è îáúåäèíÿåì îñòàëüíûå â ñòðîêó
              current_code := current_code || current_element;

            end if;

        end;
        --óâåëè÷èâàåì èíäåêñ ìàñêè
        mask_index := mask_index + 1;

        current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

      end loop;

      --ôîðìèðóåì id ãðóïïû àòðèáóòîâ èç ïîñëåäîâàòåëüíîñòè
      select seq_dim.nextval into attr_group_id from dual;

      --ìåðäæèì çàïèñè â òàáëèöå d033_attribute_group
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

      --íàõîäèì äëÿ òåêóùåãî êîììåíòàðèÿ id ãðóïïû àòðèáóòîâ â òàáëèöå d033_attribute_group
      --è ïðèñâàèâàåì ïåðåìåííîé íà âûõîäå çíà÷åíèå ýòîãî id
      select
        d033_attribute_group.attribute_group_id into p_attribute_group_id
      from
        d033_attribute_group,
        (select
          ora_hash(current_code) as code
          from dual) src_group
      where src_group.code = d033_attribute_group.d033_group_cd;

  end load_d033;

  --ïðîöåäóðà çàïîëíåíèÿ òàáëèöû f013_comments
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
    --ôîðìèðóåì id òàáëèöû f013_comments è çàíîñèì åå â ïåðåìåííóþ comments_id
    select seq_dim.nextval into comments_id from dual;

    --âûçûâàåì ïðîöåäóðó çàãðóçêè òàáëèöû d033
    --è âîçâðàùàåì id ãðóïïû àòðèáóòîâ, çàïèñûâàåì åå â ïåðåìåííóþ attr_group_id
    load_d033(p_parameters, attr_group_id);

    --âûçûâàåì ïðîöåäóðó çàïîëíåíèÿ òàáëèöû d035_attribute
    load_d035(p_parameters, attr_group_id);

    --çàïîëíÿåì òàáëèöó f013_comments
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

  --ñòàðòîâàÿ ïðîöåäóðà çàãðóçêè êîììåíòàðèåâ
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
   
    --çàïóñêàåì ïðîöåäóðó çàãðóçêè f013_comments
    l_report_name := fnc_url_decode(p_report_name);
    l_comment := fnc_url_decode(p_comment);
    l_parameters := fnc_url_decode(p_parameters);
    
    load_f013(p_username, l_report_name, l_comment,l_parameters);

  end write_comment;

  --ôóíêöèÿ âîçâðàòà íàáîðà "íîìåð ñòðîêè, ïîëüçîâàòåëü, êîììåíòàðèé, äàòà âñòàâêè êîììåíòàðèÿ"
  function get_comment (
    --èìÿ îò÷åòà
    p_report_name in f013_comments.f013_report_name%type,
    --âõîäíàÿ ñòðîêà ïàðàìåòðîâ èìååò âèä p0=2;p1=City;p2=Moscow;p3=Week;p4=53th Week
    p_parameters in varchar2
  )
  return comment_table_type pipelined
  is
    --àëèàñû äëÿ âõîäíûõ ïàðàìåòðîâ
    l_report_name f013_comments.f013_report_name%type :='';
    l_parameters f013_comments.f013_comment%type :='';
    --òåêñò çàïðîñà, âîçâðàùàþùåãî ñòðîêè èç òàáëèöû f013_comments äëÿ ñòðîêè ñ ïàðàìåòðàìè
    query varchar2(4000) :='';
    --äèíàìè÷åñêàÿ ÷àñòü çàïðîñà (äîáàâëÿåò ôèëüòðàöèþ ïî òåêóùåìó àòðèáóòó)
    query_part varchar2(1024) :='';
    --ID êîììåíòàðèÿ
    comment_id number(16);
    --èìÿ ïîëüçîâàòåëÿ
    user_name varchar2(128) := '';
    --òåêñò êîììåíòàðèÿ
    comment_text varchar2(4000) := '';
    --äàòà âñòàâêè
    insert_date date;

    /*ñëóæåáíûå ïåðåìåííûå*/
    ind number :=0;
    current_element varchar2(1024) := '';
    mask varchar2(64) :='';
    mask_index number(3) :=1;
    parameters_count number(3) :=0;
    row_number number(5) :=0;
    row_count number :=0;

    --òåêóùèå çíà÷åíèÿ ïàðû "íàçâàíèå-çíà÷åíèå" àòðèáóòà
    current_parameter varchar2(1024) := '';
    current_value varchar2(1024) := '';
  begin
    --ïðèñâàèâàåì çíà÷åíèÿ àëèàñàì
    l_report_name := fnc_url_decode(p_report_name);
    l_parameters := fnc_url_decode(p_parameters);
    
    --çàäàåì çíà÷åíèå ïåðåìåííîé òåêñòà çàïðîñà
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

    --ðàñïàðñèâàåì ñòðîêó ñ ïàðàìåòðàìè
    ind := fnc_get_next_word(l_parameters, ind + 1, ';', current_element);
    while current_element is not null
      loop
        begin
          --äëÿ êàæäîãî current_element ôîðìèðóåì ìàñêó âèäà "p[i]="
          mask := 'p' || to_char(mask_index) || '=';
          --âûáèðàåì ïåðâûé ïàðàìåòð ñòðîêè "p0=", ñîäåðæ. êîëè÷åñòâî ïåðåäàâàåìûõ ïàðàìåòðîâ
          if (current_element like 'p0=%') then
            parameters_count := to_number(replace(current_element, 'p0=', ''));
          else
            --óáèðàåì èç current_element ÷àñòü ñòðîêè ïî ìàñêå
            current_element := replace(current_element, mask, '');
            --êàæäîå íàçâàíèå àòðèáóòà èäåò ïîä íå÷åòíîé ìàñêîé (p1=)
            if (mod(mask_index, 2) != 0) then
              current_parameter := current_element;
            else
              --êàæäîå çíà÷åíèå àòðèáóòà - ïîä ÷åòíîé ìàñêîé (p2=)
              current_value := current_element;
              --åñëè çíà÷åíèå èäåò ïîä ìàñêîé "p2=" (ïåðâûé àòðèáóò), òî ìû äîáàâëÿåì â ïðåäèêàò óñëîâèÿ:
              if (mask_index = 2) then
                query_part := '
                  and d32.d035_name = ''' || current_parameter || '''
                  and d32.d035_value = ''' || current_element || '''';
              else
                --íàëè÷èå ïîñëåäóþùèõ àòðèáóòîâ äîáàâëÿåì â ïðåäèêàò "and exists()"
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

              --ôîðìèðóåì çàïðîñ, êîíêàòåíèðóÿ ñ òåêóùåé ÷àñòüþ
              query := query || query_part;

            end if;
          end if;
        end;
        mask_index := mask_index + 1;
        ind := fnc_get_next_word(l_parameters, ind + 1, ';', current_element);
      end loop;

    --çàâåðøàåì çàïðîñ îêîí÷àíèåì êîíñòðóêöèè "select * from (select smth from tables) d"
    query := query || ' ) d';

    --ïîäñ÷èòûâàåì êîëè÷åñòâî âîçâðàùàåìûõ ñòðîê
    execute immediate 'select count(*) from ('|| query || ')' into row_count;

    --äîáàâëÿåì â çàïðîñ ïðåäèêàò äëÿ âûâîäà îïðåäåëåííîé ñòðîêè âîçâðàùàåìîé òàáëèöû
    query := query || ' where d.order_num = :1';

    --âûâîäèì ñòðîêè òàáëèöû
    --(!)ïðè ýòîì ïðè âûâîäå (â pipe row) çàìåíÿì ñïåöñèìâîëû ñ ïîìîùüþ ôóíêöèè fnc_symb_replace
    if row_count is null or row_count = 0 then
      pipe row (comment_return_type(1, -1,'user', 'Êîììåíòàðèè îòñóòñòâóþò', sysdate));
    else
      for i in 1 .. row_count
        loop
          execute immediate query into row_number, comment_id, user_name, comment_text, insert_date using i;
          pipe row (comment_return_type(row_number, comment_id, user_name, fnc_symb_replace(comment_text), insert_date));
        end loop;
    end if;

    return;

  end get_comment;

  --ïðîöåäóðà óäàëåíèÿ êîììåíòàðèÿ
  --ïàðàìåòðû: ïîëüçîâàòåëü äàòà äîáàâëåíèÿ êîììåíòàðèÿ, íàçâàíèå îò÷åòà, òåêñò êîììåíòàðèÿ
  procedure delete_comment (
    p_username in f013_comments.f013_user%type,
    p_comment_id in f013_comments.comment_id%type
  )
  is
  
  begin
    --óäàëÿåì çàïèñü ñ âûáðàííûì id êîììåíòàðèÿ
    delete from f013_comments
    where
      f013_comments.comment_id = p_comment_id
      and f013_comments.f013_user = p_username;

    commit;

  end delete_comment;

end COMMENT_PKG;
/
