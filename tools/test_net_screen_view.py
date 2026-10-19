#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import importlib.util
import os
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC = importlib.util.spec_from_file_location("net_screen_view", os.path.join(ROOT, "tools", "net_screen_view.py"))
nsv = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(nsv)


def pkt14(seq, mode, score, level, lines, secs):
    d = bytearray([0xA5, 0x5A, 0x04, seq & 0xFF, mode & 1,
                   (score >> 16) & 0x0F, (score >> 8) & 0xFF, score & 0xFF,
                   level & 7, (lines >> 8) & 0xFF, lines & 0xFF,
                   (secs >> 8) & 0xFF, secs & 0xFF])
    x = 0
    for b in d[3:13]:
        x ^= b
    d.append(x)
    return bytes(d)


def pkt13(seq, score, level, lines, secs):
    d = bytearray([0xA5, 0x5A, 0x04, seq & 0xFF,
                   (score >> 16) & 0x0F, (score >> 8) & 0xFF, score & 0xFF,
                   level & 7, (lines >> 8) & 0xFF, lines & 0xFF,
                   (secs >> 8) & 0xFF, secs & 0xFF])
    x = 0
    for b in d[3:12]:
        x ^= b
    d.append(x)
    return bytes(d)


class ResultTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        nsv.SCORE_CSV = os.path.join(self.tmp.name, "scoreboard.csv")
        nsv.scores[:] = []
        nsv.last_res["key"] = None
        nsv.last_res["t"] = 0.0
        nsv.cur_res.update({"got":False, "mode":"solo", "seq":0, "score":0, "level":0, "lines":0, "secs":0})
        nsv.stat.update({"res":0, "res_dup":0, "res_bad":0})

    def tearDown(self):
        self.tmp.cleanup()

    def test_new_packets_and_dedup(self):
        nsv.res_handle(pkt14(7, 0, 12345, 6, 128, 383))
        nsv.res_handle(pkt14(7, 1, 22222, 3, 77, 200))
        self.assertEqual([r["mode"] for r in nsv.scores], ["solo", "duo"])
        self.assertEqual(nsv.cur_res["mode"], "duo")
        self.assertEqual(nsv.cur_res["score"], 22222)
        nsv.res_handle(pkt14(7, 1, 22222, 3, 77, 200))
        self.assertEqual(nsv.stat["res_dup"], 1)

    def test_legacy_packet_is_solo(self):
        nsv.res_handle(pkt13(8, 3456, 2, 19, 61))
        self.assertEqual(len(nsv.scores), 1)
        self.assertEqual(nsv.scores[0]["mode"], "solo")
        self.assertEqual(nsv.scores[0]["score"], 3456)

    def test_bad_checksum_rejected(self):
        d = bytearray(pkt14(9, 0, 100, 1, 2, 3))
        d[-1] ^= 1
        nsv.res_handle(bytes(d))
        self.assertEqual(len(nsv.scores), 0)
        self.assertEqual(nsv.stat["res_bad"], 1)

    def test_mode_top5_and_sort(self):
        rows = [("solo",1,100,1,10,100), ("solo",2,300,2,20,90), ("solo",3,300,3,30,80),
                ("duo",4,500,4,40,70), ("duo",5,400,5,50,60)]
        for mode, seq, score, lv, lines, secs in rows:
            nsv.scores.append({"time":"2026-01-01 00:00:00", "mode":mode, "seq":seq,
                               "score":score, "level":lv, "lines":lines, "secs":secs})
        txt = nsv.top5_rows("solo")
        self.assertIn("300", txt)
        self.assertNotIn("500", txt)
        self.assertLess(txt.find("30L"), txt.find("20L"))
        self.assertIn("500", nsv.top5_rows("duo"))

    def test_csv_migration_to_solo(self):
        with open(nsv.SCORE_CSV, "w", encoding="utf-8") as f:
            f.write("time,seq,score,level,lines,seconds\n")
            f.write("2026-01-01 00:00:00,1,120,2,12,33\n")
        nsv.res_csv_migrate()
        with open(nsv.SCORE_CSV, "r", encoding="utf-8") as f:
            lines = f.read().splitlines()
        self.assertEqual(lines[0], "time,mode,seq,score,level,lines,seconds")
        self.assertEqual(lines[1], "2026-01-01 00:00:00,solo,1,120,2,12,33")


if __name__ == "__main__":
    unittest.main()