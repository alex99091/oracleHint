/* 서브쿼리에서 성능에러 발생으로 인한 쿼리수행속도 지연 후 index를 통한 hint 추가 
   a.b 로 조인된 서브쿼리에서 각각의 index를 추가하여 성능개선활용
*/

select nvl(e.user_id, ' ') as loanacpteno
     , nvl((select user_nm from table1 where user_id = c.user_id and rownum = 1), ' ') as cstlnm
     , nvl(a.lnam, 0) as lnam
     , nvl(a.loanepoamt, 0) as loanepoamt
     , nvl(a.loanttCnt, 0) as loanttCnt
     , nvl(b.callcount, 0) as calltrycnt
     , nvl(b.callexecsecd, 0) as callexecsecd
     , nvl( (select substr(to_char(numtodsinterval(b.callexecsecd, 'second')), 12, 8) from dual)
                  , '00000000') as clnghmsc
  from ( select /*+ index(t2 ix_xxxx_01) */
                sum(a.lnam) as lnam /* 신청금액 */
              , sum(b.nea) as nea /* 대출승인금액 */
              , sum(b.lnam - b.nea) as loanepoamt /* 대출실행금액 */
              , sum(1) as loanttCnt /* 대출 건수 */
              , a.loan_acpt_eno
           from table2 a
              , table3 b
          where a.loan_apl_dt between :dto_srtdt and :dto_enddt
            and a.loan_apl_no = b.loan_apl_no(+)
          group by a.loan_acpt_eno
       ) a
     , (select /*+ index(t4 ix_xxxx_02) */
               sum(1) as callcount
             , sum(call_exec_secd) as callexecsecd
             , cns1_eno as cns1_eno
          from table4
         where cns1_dtm between to_date(:dto_srtdt || '000000', 'yyyymmddhh24miss') 
                            and to_date(:dto_enddt || '235959', 'yyyymmddhh24miss')
         group by cns1_eno
       ) b
  where 1=1
    and a.gp_eno = b.gp_eno
    and a.cs_tp_clsf_cd = b.cs_tp_clsf_cd
    and a.gp_stat_cd = b.gp_stat_cd
    <if test "alias.trldCsno" != null || "".equals(alias.trldCsno)>
    and a.csno = #{trldCsno, jdbcType = VARCHAR}
    </if>
