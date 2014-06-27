create or replace package COMMENT_PKG is
-----------------------------------------------------------------------------
-- isadikov 15.08.2012: пакет создан
-- isadikov 21.08.2012: убрано логгирование
-- isadikov 29.08.2012: добавлена процедура удаления комментария
-- isadikov 13.09.2012: добавлена функция  fnc_url_decode
-- isadikov 14.09.2012: добавлена функция fnc_url_encode
-----------------------------------------------------------------------------

  --процедура загрузки комментария
  --входные параметры: пользователь, название отчета, текст комментария, строка с параметрами
  --строка с параметрами имеет вид (разделитель ";"):
  --p1=Region;p2=Region Value;p3=City;p4=City Value;p5=Week;p6=52th Week
  procedure write_comment(
    p_username in f013_comments.f013_user%type,
    p_report_name in f013_comments.f013_report_name%type,
    p_comment in f013_comments.f013_comment%type,
    p_parameters in varchar2
  );

  --функция возврата комментария для имени отчета и строки с параметрами
  --строка с параметрами имеет вид (разделитель ";"):
  --p1=Region;p2=Region Value;p3=City;p4=City Value;p5=Week;p6=52th Week
  --возвращает таблицу с полями: номер строки, пользователь, комментарий, дата создания комментария
  function get_comment (
    p_report_name in f013_comments.f013_report_name%type,
    p_parameters in varchar2
  )
  return comment_table_type pipelined;

  --процедура удаления комментария для имени пользователя, названия отчета,
  --даты добавления отчета и текста комментария
  procedure delete_comment (
    p_username in f013_comments.f013_user%type,
    p_comment_id in f013_comments.comment_id%type
  );
  --функция декодирования строки из URL type
  function fnc_url_decode (
    p_str in varchar2
  )
  return varchar2;
  
  --функция преобразования строки в URL type
  function fnc_url_encode(
    p_str in varchar2
  )
  return varchar2;

end COMMENT_PKG;
/
create or replace package body COMMENT_PKG is

  --isadikov: 13.09.2012
  --Функия декодирования строки вида "%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82" в "Привет"
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
    p_str_1 := replace(p_str, '%C2%A0', '%20'); -- не получается обработать пробелы C2A0
    --Пробегаем по входной строке
    while l_index < length(p_str)
      loop
        l_index := l_index + 1;
        --выбираем текущий символ
        --если он равен '%', то мы понимаем, что это какой-то символ или кириллица
        --Для кириллицы символ всегда представим в виде "%D0%AB" или "D1%AB" 
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
        --собираем строку посимвольно
        l_string := l_string || l_symbol;
      end loop;
    return l_string;
  end fnc_url_decode;
  
  --isadikov: 14.09.2012
  --функция кодирования в URL type
  --строки вида "Привет" в "%D0%9F%D1%80%D0%B8%D0%B2%D0%B5%D1%82"
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
  
  --функция замены спецсимволов для формирования комментариев
  --надо допилить до нормального состояния
  function fnc_symb_replace (
    p_str in varchar2
  )
  return varchar2
  is
    l_str f013_comments.f013_comment%type :='';
  begin
    l_str := p_str;
    --1. Заменяем символы break_line на \u000A (или \n\r)
    l_str := replace(l_str, chr(10), '\u000A');
    --2. Заменяем символы " на \u0022
    l_str := replace(l_str, '"', '\u0022');
    --возвращаем преобразованную строку
    return l_str;  
  end fnc_symb_replace;
  
  --процедура заполнения таблицы b009_attr_attr_group
  procedure load_b009 (
    p_attribute_id in d035_attribute.attribute_id%type,
    p_attribute_group_id in d033_attribute_group.attribute_group_id%type
  )
  is
    --флаг, сигнализирующий о наличии комбинации attribute_id и attribute_group_id в таблице b009
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
      --при отсуствии такой комбинации id-шников, происходит вставка записи в таблицу b009
      insert into b009_attr_attr_group values(p_attribute_id, p_attribute_group_id);
      commit;

  end load_b009;

  --процедура заполнения таблицы d035_attribute
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
    --распарсиваем строку с параметрами
    current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

    while current_element is not null
      loop
        begin
          --формируем маску типа "p2="
          mask := 'p'|| to_char(mask_index) || '=';
          --убираем первый элемент строки с параметрами, содержащий данные о количестве параметров
          if (current_element not like 'p0=%') then
            current_element := replace(current_element, mask, '');

            --параметр всегда идет под нечетным индексом
            --значение параметра - под четным
            if (mod(mask_index,2) != 0) then
              current_parameter := current_element;
            else
              current_value := current_element;

              --по окончанию записи значения в current_value можно заполнить таблицу d035_attribute
              --так как получаем "параметр-значение"
              select seq_dim.nextval into parameter_id from dual;
              --мерджим записи
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

              --берем текущие current_parameter и current_value
              --и определяем id, соответсвующий этой паре "параметр-значение"
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

              --вызывается процедура заполнения таблицы b009 с текущими id атрибута и группы атрибутов
              load_b009(current_id, p_attribute_group_id);

              end if;
            end if;
          end;
         mask_index := mask_index + 1;
         current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);
      end loop;
   end load_d035;

  --процедура заполнения таблицы d033_attribute_group
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
    --распарсиваем строку с параметрами и их значениями
    current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

    while current_element is not null
      loop
        begin

          --формируем маску типа "p2=", чтобы
          --впоследствии удалить ее из текущего параметра (оставляем только значение)
          mask := 'p'|| to_char(mask_index) || '=';

          --убираем первый параметр "p0=число", содержащий количество передаваемых параметров
          if (current_element not like 'p0=%') then

            current_element := replace(current_element, mask, '');
              --и объединяем остальные в строку
              current_code := current_code || current_element;

            end if;

        end;
        --увеличиваем индекс маски
        mask_index := mask_index + 1;

        current_index := fnc_get_next_word(p_parameters,current_index + 1,';', current_element);

      end loop;

      --формируем id группы атрибутов из последовательности
      select seq_dim.nextval into attr_group_id from dual;

      --мерджим записи в таблице d033_attribute_group
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

      --находим для текущего комментария id группы атрибутов в таблице d033_attribute_group
      --и присваиваем переменной на выходе значение этого id
      select
        d033_attribute_group.attribute_group_id into p_attribute_group_id
      from
        d033_attribute_group,
        (select
          ora_hash(current_code) as code
          from dual) src_group
      where src_group.code = d033_attribute_group.d033_group_cd;

  end load_d033;

  --процедура заполнения таблицы f013_comments
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
    --формируем id таблицы f013_comments и заносим ее в переменную comments_id
    select seq_dim.nextval into comments_id from dual;

    --вызываем процедуру загрузки таблицы d033
    --и возвращаем id группы атрибутов, записываем ее в переменную attr_group_id
    load_d033(p_parameters, attr_group_id);

    --вызываем процедуру заполнения таблицы d035_attribute
    load_d035(p_parameters, attr_group_id);

    --заполняем таблицу f013_comments
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

  --стартовая процедура загрузки комментариев
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
   
    --запускаем процедуру загрузки f013_comments
    l_report_name := fnc_url_decode(p_report_name);
    l_comment := fnc_url_decode(p_comment);
    l_parameters := fnc_url_decode(p_parameters);
    
    load_f013(p_username, l_report_name, l_comment,l_parameters);

  end write_comment;

  --функция возврата набора "номер строки, пользователь, комментарий, дата вставки комментария"
  function get_comment (
    --имя отчета
    p_report_name in f013_comments.f013_report_name%type,
    --входная строка параметров имеет вид p0=2;p1=City;p2=Moscow;p3=Week;p4=53th Week
    p_parameters in varchar2
  )
  return comment_table_type pipelined
  is
    --алиасы для входных параметров
    l_report_name f013_comments.f013_report_name%type :='';
    l_parameters f013_comments.f013_comment%type :='';
    --текст запроса, возвращающего строки из таблицы f013_comments для строки с параметрами
    query varchar2(4000) :='';
    --динамическая часть запроса (добавляет фильтрацию по текущему атрибуту)
    query_part varchar2(1024) :='';
    --ID комментария
    comment_id number(16);
    --имя пользователя
    user_name varchar2(128) := '';
    --текст комментария
    comment_text varchar2(4000) := '';
    --дата вставки
    insert_date date;

    /*служебные переменные*/
    ind number :=0;
    current_element varchar2(1024) := '';
    mask varchar2(64) :='';
    mask_index number(3) :=1;
    parameters_count number(3) :=0;
    row_number number(5) :=0;
    row_count number :=0;

    --текущие значения пары "название-значение" атрибута
    current_parameter varchar2(1024) := '';
    current_value varchar2(1024) := '';
  begin
    --присваиваем значения алиасам
    l_report_name := fnc_url_decode(p_report_name);
    l_parameters := fnc_url_decode(p_parameters);
    
    --задаем значение переменной текста запроса
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

    --распарсиваем строку с параметрами
    ind := fnc_get_next_word(l_parameters, ind + 1, ';', current_element);
    while current_element is not null
      loop
        begin
          --для каждого current_element формируем маску вида "p[i]="
          mask := 'p' || to_char(mask_index) || '=';
          --выбираем первый параметр строки "p0=", содерж. количество передаваемых параметров
          if (current_element like 'p0=%') then
            parameters_count := to_number(replace(current_element, 'p0=', ''));
          else
            --убираем из current_element часть строки по маске
            current_element := replace(current_element, mask, '');
            --каждое название атрибута идет под нечетной маской (p1=)
            if (mod(mask_index, 2) != 0) then
              current_parameter := current_element;
            else
              --каждое значение атрибута - под четной маской (p2=)
              current_value := current_element;
              --если значение идет под маской "p2=" (первый атрибут), то мы добавляем в предикат условия:
              if (mask_index = 2) then
                query_part := '
                  and d32.d035_name = ''' || current_parameter || '''
                  and d32.d035_value = ''' || current_element || '''';
              else
                --наличие последующих атрибутов добавляем в предикат "and exists()"
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

              --формируем запрос, конкатенируя с текущей частью
              query := query || query_part;

            end if;
          end if;
        end;
        mask_index := mask_index + 1;
        ind := fnc_get_next_word(l_parameters, ind + 1, ';', current_element);
      end loop;

    --завершаем запрос окончанием конструкции "select * from (select smth from tables) d"
    query := query || ' ) d';

    --подсчитываем количество возвращаемых строк
    execute immediate 'select count(*) from ('|| query || ')' into row_count;

    --добавляем в запрос предикат для вывода определенной строки возвращаемой таблицы
    query := query || ' where d.order_num = :1';

    --выводим строки таблицы
    --(!)при этом при выводе (в pipe row) заменям спецсимволы с помощью функции fnc_symb_replace
    if row_count is null or row_count = 0 then
      pipe row (comment_return_type(1, -1,'user', 'Комментарии отсутствуют', sysdate));
    else
      for i in 1 .. row_count
        loop
          execute immediate query into row_number, comment_id, user_name, comment_text, insert_date using i;
          pipe row (comment_return_type(row_number, comment_id, user_name, fnc_symb_replace(comment_text), insert_date));
        end loop;
    end if;

    return;

  end get_comment;

  --процедура удаления комментария
  --параметры: пользователь дата добавления комментария, название отчета, текст комментария
  procedure delete_comment (
    p_username in f013_comments.f013_user%type,
    p_comment_id in f013_comments.comment_id%type
  )
  is
  
  begin
    --удаляем запись с выбранным id комментария
    delete from f013_comments
    where
      f013_comments.comment_id = p_comment_id
      and f013_comments.f013_user = p_username;

    commit;

  end delete_comment;

end COMMENT_PKG;
/
