// MySQL: backslash escapes HQL quote but MySQL consumes it
// Name: abc\' or 1=sleep(2) --
// HQL: 'abc\'' → whole string; MySQL: 'abc\'' → string ends, SQL injection

// PostgreSQL: dollar-quoted strings $$='$$
// HQL: $$='$$=... valid HQL comparison; PG: $$='$$... dollar-quoted spills into SQL

// Oracle: DBMS_XMLGEN.getxml() passes through to SQL
// HQL: WHERE NVL(TO_CHAR(DBMS_XMLGEN.getxml('SELECT 1')),'1')!='1'
