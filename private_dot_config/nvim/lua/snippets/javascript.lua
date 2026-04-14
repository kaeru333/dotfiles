
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
    -- main (競技プログラミング用テンプレート)
    s("main", {
        t({ "function main(input) {", "    " }),
        i(1),
        t({ "", "}", "", 'main(require("fs").readFileSync("/dev/stdin", "utf8"));' }),
    }),
}
