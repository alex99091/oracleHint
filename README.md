# Oracle-Hint

## Definition
```
오라클 힌트(Hint) 는 SQL 실행 계획을 제어하기 위해 제공되는 명령어로, 
옵티마이저가 선택하는 실행 경로를 개발자가 직접 조정할 수 있도록 한다. 
주석(/*+ HINT */) 형태로 SQL 문에 삽입되며, 성능 최적화에 활용된다.
```

### Types of Hint
| 힌트 | 설명 |
|------|------|
| `INDEX(table index_name)` | 특정 인덱스 사용 강제 |
| `FULL(table)` | 테이블 전체 스캔 강제 |
| `PARALLEL(table N)` | 병렬 처리 활성화 |
| `USE_NL(table)` | Nested Loop 조인 강제 |
| `USE_HASH(table)` | Hash Join 강제 |
| `LEADING(table1 table2)` | 조인 시 테이블 우선순위 지정 |

### How to use

1. 서브쿼리에서 Full Table Scan이 발생하는 경우
🔹 해결 방법
INDEX(table index_name) 힌트를 사용하여 인덱스를 강제 적용
🔹 예시
     ```sql
     SELECT /*+ INDEX(emp emp_idx) */ * FROM emp WHERE dept_no IN 
     (SELECT dept_no FROM department WHERE dept_name = 'Sales');
     ```

2. 조인 시 잘못된 실행 계획이 선택되는 경우
🔹 해결 방법
USE_NL, USE_HASH, LEADING 힌트를 사용하여 조인 순서 및 방식을 제어
🔹 예시
     ```sql
     SELECT /*+ LEADING(e d) USE_NL(d) */ e.emp_id, e.emp_name, d.dept_name 
     FROM emp e JOIN department d ON e.dept_no = d.dept_no;
     ```

3. 병렬 처리를 활용해야 하는 경우
🔹 해결 방법
PARALLEL(table N) 힌트를 사용하여 병렬 실행 유도
🔹 예시
     ```sql
     SELECT /*+ PARALLEL(emp 4) */ * FROM emp;
     ```

### Experience
```
현대카드 실무에서 업무용 단말 (자체 GUI)을 사용하는데, 
DML을 통한 특정 업무에 대한 DB 조회 시 성능 문제를 일으킬 때가 있다.
대부분의 경우 subquery에서 full scan을 타는 경우이며, 
이 경우 오라클 hint 추가를 통해 해결해야 한다.

(힌트는 DB의 옵티마이저가 제대로 작동하지 않아, 쿼리의 성능이 느려지는 경우에 사용)
```

- 아래의 케이스는 업무 내용과 관련하여 서브쿼리에 Hint를 추가하여 적용한 예
- 보안을 위해 테이블명이나, 주요 내용은 삭제 후 쿼리예시만 적용함
[Example](./hint_example.sql)