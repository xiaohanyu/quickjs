#include "./quickjs.h"
#include <math.h>
#import <Foundation/Foundation.h>

#define countof(x) (sizeof(x) / sizeof((x)[0]))

static JSClassID js_nsdate_class_id;

static void js_nsdate_finalizer(JSRuntime *rt, JSValue val)
{
    NSDate *d = JS_GetOpaque(val, js_nsdate_class_id);
    /* Note: 's' can be NULL in case JS_SetOpaque() was not called */
    js_free_rt(rt, d);
}

static JSValue js_nsdate_ctor(JSContext *ctx,
                              JSValueConst new_target,
                              int argc, JSValueConst *argv)
{
    NSDate *d;
    JSValue obj = JS_UNDEFINED;
    JSValue proto;

    d = js_mallocz(ctx, sizeof(NSDate*));
    if (!d)
        return JS_EXCEPTION;

    /* using new_target to get the prototype is necessary when the
       class is extended. */
    proto = JS_GetPropertyStr(ctx, new_target, "prototype");
    if (JS_IsException(proto))
        goto fail;
    obj = JS_NewObjectProtoClass(ctx, proto, js_nsdate_class_id);
    JS_FreeValue(ctx, proto);
    if (JS_IsException(obj))
        goto fail;
    JS_SetOpaque(obj, d);
    return obj;
 fail:
    js_free(ctx, d);
    JS_FreeValue(ctx, obj);
    return JS_EXCEPTION;
}

static JSValue js_nsdate_date(JSContext *ctx, JSValueConst this_val,
                             int argc, JSValueConst *argv)
{
    NSDate *d = JS_GetOpaque2(ctx, this_val, js_nsdate_class_id);
    if (!d)
        return JS_EXCEPTION;
    JSValue object = JS_NewObject(ctx);
    NSLog(@"%p", object.u.ptr);
    return object;
}

static JSClassDef js_nsdate_class = {
    "NSDate",
    .finalizer = js_nsdate_finalizer,
};

static const JSCFunctionListEntry js_nsdate_proto_funcs[] = {
    JS_CFUNC_DEF("date", 0, js_nsdate_date),
};

static int js_nsdate_init(JSContext *ctx, JSModuleDef *m)
{
    JSValue nsdate_proto, nsdate_class;

    /* create the nsdate class */
    JS_NewClassID(&js_nsdate_class_id);
    JS_NewClass(JS_GetRuntime(ctx), js_nsdate_class_id, &js_nsdate_class);

    nsdate_proto = JS_NewObject(ctx);
    JS_SetPropertyFunctionList(ctx, nsdate_proto, js_nsdate_proto_funcs, countof(js_nsdate_proto_funcs));

    nsdate_class = JS_NewCFunction2(ctx, js_nsdate_ctor, "nsdate", 2, JS_CFUNC_constructor, 0);
    /* set proto.constructor and ctor.prototype */
    JS_SetConstructor(ctx, nsdate_class, nsdate_proto);
    JS_SetClassProto(ctx, js_nsdate_class_id, nsdate_proto);

    JS_SetModuleExport(ctx, m, "NSDate", nsdate_class);
    return 0;
}

JSModuleDef *js_init_module(JSContext *ctx, const char *module_name)
{
    JSModuleDef *m;
    m = JS_NewCModule(ctx, module_name, js_nsdate_init);
    if (!m)
        return NULL;
    JS_AddModuleExport(ctx, m, "NSDate");
    return m;
}

