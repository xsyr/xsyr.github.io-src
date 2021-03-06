---
layout: post
title: 'lua-resty-validator'
subtitle: ''
date: 2017-09-16 22:46:26 +0800
categories: 编程 lua
tags: 编程 lua
---

之前项目中用到 openresty 作为 Web Api  的开发平台, 用 openresty 很适合开发以 http 接口形式
提供的服务. openresty 可以使用 lua 进行逻辑控制,加上完备的组件driver(redis, mysql, rabbitmq 等),
只需要写业务代码将各种数据读取,加工,输出,就是充当胶水的角色.

最重要的一点是, openresty + lua 已经很好的处理并行(开多个 nginx worker即可)和并发(lua coroutine),
lua vm 已经默默的处理了阻塞的IO操作,开发人员可以用写同步代码的方式实现异步.

既然是 Web Api,自然少不了对参数的校验, [validator](https://github.com/xsyr/lua-resty-validator)库实现对 lua table 的校验.


# 安装
把 validator.lua 文件放入 openresty 安装目录的 `lualib/resty/` 下即可.

# Demo
```

location /validator_demo {
    content_by_lua_block {
        local v = require("resty.validator")
        local cjson = require("cjson")

        local user = {
            id = {
                type     = v.NUMBER,
                required = true,
            },
            name = {
                type     = v.STRING,
                required = true,
            },
            addr = {
                type     = v.OBJECT,
                required = true,
                struct = {
                    city = {
                        type      = v.STRING,
                        required  = true,
                        minlength = 2,
                    },
                    postcode = {
                        type      = v.STRING,
                        required  = true,
                        minlength = 6,
                        maxlength = 6,
                    }
                }
            }
        }

        ngx.req.read_body()
        local body = ngx.req.get_body_data()
        local json = cjson.decode(body)
        local ok, user, err = v.bind(user, json)
        if not ok then
            ngx.say(err)
        else
            ngx.say(cjson.encode(user))
        end
    }
}


```

```bash
$ curl -d '{}' 'http://localhost/validator_demo'
'addr' is required

$ curl -d '{ "addr":{ "city": "guangzhou" } }' 'http://localhost/validator_demo'
'addr.postcode' is required

$ curl -d '{ "addr":{ "city": "guangzhou", "postcode": "510000" } }' 'http://localhost/validator_demo'
'name' is required

$ curl -d '{ "name": "xsyr", "addr":{ "city": "guangzhou", "postcode": "510000" } }' 'http://localhost/validator_demo'
'id' is required

$ curl -d '{ "id" : 100, "name": "xsyr", "addr":{ "city": "guangzhou", "postcode": "510000" } }' 'http://localhost/validator_demo'
{"addr":{"city":"guangzhou","postcode":"510000"},"name":"xsyr","id":100}

```

---

# 参数类型定义


## 1. NUMBER - 数值类型
```
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.NUMBER,

        -- 默认值（可选，默认为 nil）
        default = 0,

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, checker, post
        pre = function(val) return dosth(val) end,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }
```

## 2. STRING - 字符串类型
```
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.STRING,

        -- 默认值（可选，默认为 nil）
        default = "unknown",

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, minlength, maxlength, checker, post
        pre = function(val) return dosth(val) end,

        -- 最小长度（可选，默认 nil 无限制）
        minlength = 1,

        -- 最大长度（可选，默认 nil 无限制）
        maxlength = 5,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }
```

## 3. OBJECT - 对象类型（对象成员的类型可以是任意类型（NUMBER, STRING, ...））
```
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.OBJECT,

        -- 默认值（可选，默认为 nil）
        default = { a = 1, b = 2 },

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- 对象的结构（必填）
        struct = {

            -- 对象的成员，成员的类型可以为 NUMBER, STRING, OBJECT
            <member> = {
                type = STRING, -- 成员的类型，详见 STRING 类型的定义
                required = true,
                ...
            },
            ...
        }

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, checker, post
        pre = function(val) return dosth(val) end,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }
```

## 4. ARRAY - 数组类型（数组元素的类型可以是任意类型（NUMBER, STRING, ...））
```
    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.ARRAY,

        -- 默认值（可选，默认为 nil）
        default = {},

        -- 是否必填项（可选，默认为 false）
        required = true,

        -- 数组元素的结构（可以是任意类型）
        element = {
            type = NUMBER, -- 可以是任意类型，类型的绑定语法详见各类型的说明
            ...
        },

        -- checker 执行前的处理函数，函数的返回值用作后续的处理（可选，默认无）
        -- 执行顺序：pre, minlength, maxlength, checker, post
        pre = function(val) return dosth(val) end,

        -- 最小长度（可选，默认 nil 无限制）
        minlength = 1,

        -- 最大长度（可选，默认 nil 无限制）
        maxlength = 5,

        -- 对填写的值进行校验，返回 res, err （可选，默认无）
        -- res: 校验的结果（true/false）
        -- err: 如果校验不通过（res = false）的错误提示信息，如果不填
        --      则使用 err_msg。
        checker = function(val, field) return docheck(val) end,

        -- checker 执行后的处理函数，函数的返回值作为最终 field 的值（可选，默认无）
        post = function(val) return dosth(val) end,
    }
```

## 5. STRINGIFY_OBJECT - 字符串化的对象类型（对象成员的类型可以是任意类型（NUMBER, STRING, ...））
```
    如： module = "{\"type\":\"audio\",\"id\":1}"

    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.STRINGIFY_OBJECT,

        -- NOTE: 其他定义与 OBJECT 相同
    }
```

## 6. STRINGIFY_ARRAY - 数组类型（数组元素的类型可以是任意类型（NUMBER, STRING, ...））
```
    如： lists = "[{\"type\":\"audio\",\"id\":1},{\"type\":\"album\",\"id\":2}]"

    绑定语法：
    <field> = {
        -- 数值类型（必填）
        type = validator.STRINGIFY_ARRAY,

        -- NOTE: 其他定义与 ARRAY 相同
    }
```
