#include "erl_nif.h"

// http://erlang.org/doc/tutorial/nif.html
// compile with gcc -I /usr/lib/erlang/erts-6.1/include/ -o sum.so -fpic -shared  c/sum.c
extern int foo(int x);
extern int bar(int y);

static ERL_NIF_TERM foo_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    int x, ret;
    if (!enif_get_int(env, argv[0], &x)) {
	return enif_make_badarg(env);
    }
    ret = foo(x);
    return enif_make_int(env, ret);
}

static ERL_NIF_TERM bar_nif(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
    int y, ret;
    if (!enif_get_int(env, argv[0], &y)) {
	return enif_make_badarg(env);
    }
    ret =bar(y);
    return enif_make_int(env, ret);
}

static ErlNifFunc nif_funcs[] = {
    {"foo", 1, foo_nif},
    {"bar", 1, bar_nif}
};

// ERL_NIF_INIT第一个参数的名字必须和 调用该nif函数的模块一致
ERL_NIF_INIT(nif_example, nif_funcs, NULL, NULL, NULL, NULL)


int bar(int x){
    return 2*x;
}

int foo(int y){
    return 5*y;
}