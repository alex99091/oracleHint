# Oracle Query Optimization with Hints

[![Oracle](https://img.shields.io/badge/Oracle-%23FF5733.svg?style=for-the-badge&logo=oracle&logoColor=white)](https://www.oracle.com/)

> **Note**: 본 프로젝트는 실무에서 쿼리 성능 개선을 위해 오라클 힌트를 활용한 예제입니다.  
> 성능 최적화 및 실행 계획 분석을 중심으로 구성된 문서 기반 포트폴리오입니다.

---

## 🧩 Overview

이 프로젝트는 **Oracle Hint**를 활용하여 쿼리 성능을 개선한 경험을 다룹니다.  
특히 **서브쿼리에서 Full Table Scan을 피하는 방법**, **조인 최적화**, **병렬 처리** 등을 다루며,  
**실제 업무에서 쿼리 성능 개선을 위한 구체적인 예시**를 제공합니다.

- **적용 대상 시스템**: Oracle DB
- **주요 문제점**: 서브쿼리에서의 Full Table Scan, 잘못된 실행 계획, 비효율적인 조인 처리
- **해결책**: Oracle Hint 사용하여 성능 최적화 및 실행 계획 제어

---

## ❗ Problem

실무에서 발생한 쿼리 성능 문제는 대부분 다음과 같음:

1. **서브쿼리에서 Full Table Scan 발생**
   - 쿼리 실행 시간이 길어지며 성능이 저하됨.
   
2. **잘못된 실행 계획 선택**
   - 조인 시 비효율적인 방식으로 쿼리가 실행되어 성능에 큰 영향을 미침.
   
3. **병렬 처리 미활용**
   - 대용량 데이터를 처리할 때 병렬 처리가 적용되지 않아 성능 저하 발생.

---

## 💡 Solution

### 1. 서브쿼리에서 Full Table Scan 발생하는 경우
- 🔹 해결 방법: `INDEX(table index_name)` 힌트를 사용하여 인덱스를 강제 적용.
- 🔹 예시:
     ```sql
     SELECT /*+ INDEX(emp emp_idx) */ * FROM emp WHERE dept_no IN 
     (SELECT dept_no FROM department WHERE dept_name = 'Sales');
     ```

### 2. 조인 시 잘못된 실행 계획이 선택되는 경우
- 🔹 해결 방법: `USE_NL`, `USE_HASH`, `LEADING` 힌트를 사용하여 조인 순서 및 방식을 제어.
- 🔹 예시:
     ```sql
     SELECT /*+ LEADING(e d) USE_NL(d) */ e.emp_id, e.emp_name, d.dept_name 
     FROM emp e JOIN department d ON e.dept_no = d.dept_no;
     ```

### 3. 병렬 처리를 활용해야 하는 경우
- 🔹 해결 방법: `PARALLEL(table N)` 힌트를 사용하여 병렬 실행 유도.
- 🔹 예시:
     ```sql
     SELECT /*+ PARALLEL(emp 4) */ * FROM emp;
     ```

---

## 📊 성능 개선 전후 비교

| 항목               | 개선 전 평균 | 개선 후 평균 |
|------------------|------------|------------|--------------|
| 전체 실행 시간       | 해당쿼리 호출 전 Time Out Error         | 35s (배치정상수행)        |
---

## 📘 Experience

### 실제 업무 경험
현대카드 실무에서 업무용 단말 (자체 GUI)을 사용하는데,  
DML을 통한 특정 업무에 대한 DB 조회 시 성능 문제를 일으킬 때가 있다.  
대부분의 경우 **subquery에서 full scan**을 타는 경우이며,  
이 경우 오라클 hint 추가를 통해 해결해야 한다.

(힌트는 DB의 옵티마이저가 제대로 작동하지 않아, 쿼리의 성능이 느려지는 경우에 사용)

---

## 📋 Example Query

```sql
/* 서브쿼리에서 성능에러 발생으로 인한 쿼리수행속도 지연 후 index를 통한 hint 추가 
   a.b 로 조인된 서브쿼리에서 각각의 index를 추가하여 성능개선활용 */

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
                sum(a.lnam) as lnam 
              , sum(b.nea) as nea
              , sum(b.lnam - b.nea) as loanepoamt
              , sum(1) as loanttCnt
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
```

---
## 📘 Lessons Learned

### 1. 서브쿼리에서 Full Table Scan을 피하려면 `INDEX` 힌트를 활용  
서브쿼리에서 **전체 테이블 스캔**이 발생하면 성능에 큰 영향을 미침.  
`INDEX` 힌트를 통해 인덱스를 강제 적용하면 성능이 크게 개선될 수 있음.  

### 2. 잘못된 조인 순서 및 방식은 성능을 저하  
`USE_NL`, `USE_HASH`, `LEADING` 힌트를 사용하여 조인 방식을 명확히 지정하고,  
실행 계획을 제어하면 성능이 개선된다.  

### 3. 병렬 처리 활용 시 성능을 더 향상  
병렬 처리를 유도하는 `PARALLEL` 힌트를 사용하면 대용량 데이터 처리 성능이 크게 향상  
