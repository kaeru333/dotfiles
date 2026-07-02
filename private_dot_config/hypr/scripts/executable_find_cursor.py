#!/usr/bin/env python3
"""カーソル位置に同心円を一瞬表示するオーバーレイ (Hyprland 用)

`hyprctl cursorpos` で現在のカーソル座標を取得し、
gtk-layer-shell を使ってクリックスルーの全面オーバーレイを描画する。
DURATION_MS 経過後に自動終了する。
"""

from __future__ import annotations

import json
import math
import subprocess
import sys

import cairo
import gi

gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, GLib, Gtk, GtkLayerShell  # noqa: E402

DURATION_MS = 1400  # オーバーレイ表示時間 (ms)

# 深いオリーブ系パレット (RGB, 0..1)
COLOR_MAIN = (0.43, 0.50, 0.27)  # 深いオリーブドラブ (#6E7F45)
COLOR_ACCENT = (0.58, 0.64, 0.38)  # 少し明るいオリーブ (#94A461) ハイライト用

# 中央の細い十字 (4本のティック)
TICK_GAP = 28  # 中心から各ティックまでの余白
TICK_LENGTH = 22  # ティックの長さ
TICK_WIDTH = 3.0

# 広がる ripple リング
RIPPLE_START = 60
RIPPLE_END = 360
RIPPLE_WIDTH = 3.4

FRAME_INTERVAL_MS = 16  # 描画フレーム間隔 (~60fps)


def get_cursor_info() -> tuple[int, int, int, int]:
    """現在のカーソル位置とそれが属するモニタの起点を返す。

    Returns:
        (monitor_x, monitor_y, local_x, local_y) のタプル。
        monitor_x/y は Hyprland グローバル座標でのモニタ原点。
        local_x/y はモニタローカル座標。
    """
    pos = subprocess.check_output(["hyprctl", "cursorpos"], text=True).strip()
    gx, gy = (int(v.strip()) for v in pos.split(","))

    monitors = json.loads(
        subprocess.check_output(["hyprctl", "monitors", "-j"], text=True)
    )
    for m in monitors:
        mx, my = m["x"], m["y"]
        mw, mh = m["width"], m["height"]
        if mx <= gx < mx + mw and my <= gy < my + mh:
            return mx, my, gx - mx, gy - my

    # 該当モニタが見つからない場合は先頭にフォールバック
    m = monitors[0]
    return m["x"], m["y"], gx - m["x"], gy - m["y"]


def find_gdk_monitor(origin_x: int, origin_y: int) -> Gdk.Monitor | None:
    """Hyprland のモニタ原点座標と一致する Gdk.Monitor を返す。"""
    display = Gdk.Display.get_default()
    if display is None:
        return None
    for i in range(display.get_n_monitors()):
        mon = display.get_monitor(i)
        geom = mon.get_geometry()
        if geom.x == origin_x and geom.y == origin_y:
            return mon
    return display.get_primary_monitor() or display.get_monitor(0)


class FindCursorOverlay:
    """カーソル位置オーバーレイのアプリケーションクラス。"""

    def __init__(self, mon_origin_x: int, mon_origin_y: int, x: int, y: int) -> None:
        self.x = x
        self.y = y
        self.start_time_ms: float | None = None

        self.win = Gtk.Window()
        self.win.set_app_paintable(True)
        self.win.set_decorated(False)
        self.win.set_accept_focus(False)

        screen = self.win.get_screen()
        visual = screen.get_rgba_visual()
        if visual is not None:
            self.win.set_visual(visual)

        GtkLayerShell.init_for_window(self.win)
        GtkLayerShell.set_layer(self.win, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_keyboard_mode(
            self.win, GtkLayerShell.KeyboardMode.NONE
        )
        GtkLayerShell.set_namespace(self.win, "find-cursor")
        for edge in (
            GtkLayerShell.Edge.TOP,
            GtkLayerShell.Edge.LEFT,
            GtkLayerShell.Edge.RIGHT,
            GtkLayerShell.Edge.BOTTOM,
        ):
            GtkLayerShell.set_anchor(self.win, edge, True)
        GtkLayerShell.set_exclusive_zone(self.win, -1)

        mon = find_gdk_monitor(mon_origin_x, mon_origin_y)
        if mon is not None:
            GtkLayerShell.set_monitor(self.win, mon)

        self.win.connect("realize", self._on_realize)
        self.win.connect("draw", self._on_draw)
        self.win.show_all()

        # アニメーション用タイマー
        GLib.timeout_add(FRAME_INTERVAL_MS, self._on_frame)

    def _on_realize(self, widget: Gtk.Widget) -> None:
        """クリックスルーにするため入力領域を空にする。"""
        gdk_win = widget.get_window()
        if gdk_win is not None:
            empty = cairo.Region()
            gdk_win.input_shape_combine_region(empty, 0, 0)

    def _progress(self) -> float:
        """0..1 のアニメーション進行度を返す。"""
        if self.start_time_ms is None:
            self.start_time_ms = GLib.get_monotonic_time() / 1000.0
            return 0.0
        elapsed = GLib.get_monotonic_time() / 1000.0 - self.start_time_ms
        return min(elapsed / DURATION_MS, 1.0)

    @staticmethod
    def _ease_out_cubic(t: float) -> float:
        return 1.0 - (1.0 - t) ** 3

    def _draw_ticks(
        self, ctx: cairo.Context, cx: float, cy: float, alpha: float
    ) -> None:
        """中央の細い十字ティック (4本) を描画する。"""
        r, g, b = COLOR_ACCENT
        ctx.set_source_rgba(r, g, b, alpha)
        ctx.set_line_width(TICK_WIDTH)
        ctx.set_line_cap(cairo.LINE_CAP_ROUND)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            x1, y1 = cx + dx * TICK_GAP, cy + dy * TICK_GAP
            x2, y2 = x1 + dx * TICK_LENGTH, y1 + dy * TICK_LENGTH
            ctx.move_to(x1, y1)
            ctx.line_to(x2, y2)
            ctx.stroke()

    def _draw_ripple(
        self,
        ctx: cairo.Context,
        cx: float,
        cy: float,
        progress: float,
    ) -> None:
        """中心から広がりフェードする ripple リング。"""
        eased = self._ease_out_cubic(progress)
        radius = RIPPLE_START + (RIPPLE_END - RIPPLE_START) * eased
        # アルファは進行度の二乗で素早く消える
        alpha = (1.0 - progress) ** 2 * 0.65
        if alpha <= 0:
            return
        r, g, b = COLOR_MAIN
        ctx.set_source_rgba(r, g, b, alpha)
        ctx.set_line_width(RIPPLE_WIDTH)
        ctx.arc(cx, cy, radius, 0, 2 * math.pi)
        ctx.stroke()

    def _on_draw(self, widget: Gtk.Widget, ctx: cairo.Context) -> bool:
        # 背景を完全透明にクリア
        ctx.set_operator(cairo.OPERATOR_SOURCE)
        ctx.set_source_rgba(0.0, 0.0, 0.0, 0.0)
        ctx.paint()
        ctx.set_operator(cairo.OPERATOR_OVER)

        progress = self._progress()
        cx, cy = self.x, self.y

        # 静的要素は全体的にゆっくりフェードアウト
        static_alpha = (1.0 - progress) ** 1.3

        self._draw_ripple(ctx, cx, cy, progress)
        self._draw_ticks(ctx, cx, cy, static_alpha * 0.95)
        return False

    def _on_frame(self) -> bool:
        if self.start_time_ms is None:
            self.start_time_ms = GLib.get_monotonic_time() / 1000.0
        elapsed = GLib.get_monotonic_time() / 1000.0 - self.start_time_ms
        if elapsed >= DURATION_MS:
            Gtk.main_quit()
            return False
        self.win.queue_draw()
        return True


def main() -> int:
    try:
        mx, my, x, y = get_cursor_info()
    except (subprocess.CalledProcessError, ValueError) as e:
        print(f"カーソル位置の取得に失敗: {e}", file=sys.stderr)
        return 1

    FindCursorOverlay(mx, my, x, y)
    Gtk.main()
    return 0


if __name__ == "__main__":
    sys.exit(main())
