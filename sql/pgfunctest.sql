CREATE OR REPLACE FUNCTION i_void(internal)
  RETURNS internal AS
$BODY$
-- mymodule.lua
local M = {} -- public interface

-- private
local x = 1
local function baz() print 'test' end

function M.foo() print("foo", x) end

function M.bar()
  M.foo()
  baz()
  print "bar"
end

function M.getAnswer()
  return 42
end

return M

$BODY$ LANGUAGE pllua;

CREATE OR REPLACE FUNCTION pg_temp.pgfunc_test()
RETURNS SETOF text AS $$
  local quote_ident = pgfunc("quote_ident(text)")
  coroutine.yield(quote_ident("int"))
  local right = pgfunc("right(text,int)")
  coroutine.yield(right('abcde', 2))
  local factorial = pgfunc("factorial(int8)")
  coroutine.yield(tostring(factorial(50)))
  local i_void = pgfunc("i_void(internal)")
  coroutine.yield(i_void.getAnswer())
$$ LANGUAGE pllua;
select pg_temp.pgfunc_test();

do $$
print(pgfunc('quote_nullable(text)')(nil))
$$ language pllua;

create or replace function pg_temp.throw_error(text) returns void as $$
begin
raise exception '%', $1;
end
$$ language plpgsql;

do $$
pgfunc('pg_temp.throw_error(text)',{only_internal=false})("exception test")
$$ language pllua;

do $$
local f = pgfunc('pg_temp.throw_error(text)',{only_internal=false})
print(pcall(f, "exception test"))
$$ language pllua;

create or replace function pg_temp.no_throw() returns jsonb as $$
select '{"a":5, "b":10}'::jsonb
$$ language sql;

do $$
local f = pgfunc('pg_temp.no_throw()',{only_internal=false, throwable=false})
print(f())
$$ language pllua;
