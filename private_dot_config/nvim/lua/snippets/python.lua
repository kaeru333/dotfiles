
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
    -- numpy + pandas
    s("numpan", {
        t({
            "import numpy as np",
            "import pandas as pd",
            "", 
        }),
    }),

    -- matplotlib + japanize_matplotlib
    s("matja", {
        t({
            "import japanize_matplotlib  # noqa: F401",
            "import matplotlib.pyplot as plt",
            "",
        }),
    }),
    -- rich logger
    s("logger", {
        t({
          "import logging",
          "from rich.logging import RichHandler",
          "",
          "logger = logging.getLogger(__name__)",
          "logging.basicConfig(",
          "    level=logging.INFO,",
          '    format="%(message)s",',
          '    datefmt="[%X]",',
          "    handlers=[RichHandler(markup=True, rich_tracebacks=True)]",
          ")",
          "",
        }),
    }),
    -- main
    s("main", {
        t({ "def main():", "    " }),
        i(1),
        t({ "", "", "if __name__ == '__main__':", "    params = {", "    }", "    main(**params)" }),
    }),
    -- for
    s({ trig = "for", priority = 1001 }, {
        t({ "for "}),
        i(1),
        t({ " in range(" }),
        i(2),
        t({ ")"}),
    }),
    -- yes
    s("yes", {
        t('"Yes" if '),
        i(1),
        t(' else "No"'),
    }),
    -- MOD
    s("mod", {
        t('MOD = 10**9 + 7'),
    }),
    -- nmap
    s("ni", {
      t({
        "int(input())", 
        "", 
      }), 
    }),
    -- nm
    s("nm", {
      t({
        "map(int, input().split())", 
        "", 
      }), 
    }),
    -- nli
    s("nl", {
      t({
        "list(map(int, input().split()))", 
        "", 
      }), 
    }),
    -- inf
    s("inf", {
      t({
        'float("inf")'
      })
    }), 
    -- defaultdict
    s("imdd", {
      t({
        'from collections import defaultdict', 
        ''
      }), 
    }), 
    s("dd", {
      t({
        'defaultdict(', 
      }), 
      i(1), 
      t(')')
    }), 
    -- Counter
    s("imcter", {
      t({
        'from collections import Counter', 
        ''
      }), 
    }),
    s("cter", {
      t({
        'Counter(',
      }),
      i(1),
      t(')'),
    }),
    -- deque
    s("imdeq", {
      t({
        'from collections import deque'
      })
    }),
    -- sys.stdin.readline (高速入力)
    s("sio", {
      t({
        'import sys',
        'input = sys.stdin.readline',
        '',
      }),
    }),
    -- sys.setrecursionlimit
    s("rec", {
      t({
        'import sys',
        'sys.setrecursionlimit(',
      }),
      i(1, '10**6'),
      t(')'),
    }),
    -- heapq
    s("imhq", {
      t({
        'from heapq import heapify, heappush, heappop',
        ''
      }),
    }),
    -- SortedList
    s("imsl", {
      t({
        'from sortedcontainers import SortedList',
        ''
      }),
    }),
    s("sl", {
      t({
        'SortedList(',
      }),
      i(1),
      t(')'),
    }),
    -- 4方向 (上下左右)
    s("dxdy", {
      t('[(0, 1), (1, 0), (0, -1), (-1, 0)]'),
    }),
    -- Union-Find
    s("uf", {
      t({
        'class UnionFind:',
        '    def __init__(self, n: int) -> None:',
        '        self.parent = list(range(n))',
        '        self.size = [1] * n',
        '',
        '    def find(self, x: int) -> int:',
        '        while self.parent[x] != x:',
        '            self.parent[x] = self.parent[self.parent[x]]',
        '            x = self.parent[x]',
        '        return x',
        '',
        '    def union(self, x: int, y: int) -> bool:',
        '        rx, ry = self.find(x), self.find(y)',
        '        if rx == ry:',
        '            return False',
        '        if self.size[rx] < self.size[ry]:',
        '            rx, ry = ry, rx',
        '        self.parent[ry] = rx',
        '        self.size[rx] += self.size[ry]',
        '        return True',
        '',
        '    def same(self, x: int, y: int) -> bool:',
        '        return self.find(x) == self.find(y)',
        '',
      }),
    }),
}
