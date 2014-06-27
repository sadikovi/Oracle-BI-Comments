create or replace function fnc_get_next_word(
  p_list  in varchar2,
  p_spos  in number,
  p_sep   in varchar2,
  p_res   out varchar2
) return number
is
  fp  number(3) := 1;
  lp  number(3) := 0;
  s   varchar2(1024);
begin  
  fp := p_spos;
  s := substr(p_list,fp,length(p_list));
  
  if s not like '%' || p_sep || '%' then
    lp := length(s) + 1;
  else
    lp := regexp_instr(s,p_sep,1,1);
  end if;

  p_res := trim(substr(s,1,lp - 1));

  return fp + lp + length(p_sep) - 2;
end fnc_get_next_word;
/
