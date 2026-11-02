"""验证双人键位、别名并按、失焦取消和协议快照。"""
import unittest
from keyboard_controls import KeyState, encode_keys


class KeyboardTests(unittest.TestCase):
    def test_independent_players(self):
        state = KeyState()
        for vk in (65, 87, 40, 96):
            state.update(vk, True)
        self.assertEqual(state.packet(), bytes.fromhex('a55a050914'))
        state.update(65, False)
        self.assertEqual(state.packet(), bytes.fromhex('a55a050814'))

    def test_alias_release_preserves_other_key(self):
        state = KeyState()
        state.update(13, True)
        state.update(101, True)
        state.update(13, False)
        self.assertEqual(state.bits, 1 << 5)
        state.update(101, False)
        self.assertEqual(state.bits, 0)

    def test_focus_loss_cancels_everything_until_new_input(self):
        state = KeyState()
        state.update(83, True)
        state.update(40, True)
        state.clear()
        self.assertEqual(state.packet(), bytes.fromhex('a55a058000'))
        self.assertEqual(state.bits, 0)
        state.update(68, True)
        self.assertEqual(state.packet(), bytes.fromhex('a55a050200'))

    def test_repeat_and_shared_commands(self):
        state = KeyState()
        for _ in range(5):
            state.update(81, True)
        state.update(27, True)
        state.update(123, True)
        self.assertEqual(state.packet(), bytes.fromhex('a55a055020'))
        state.update(81, False)
        self.assertEqual(state.bits & 16, 0)
        self.assertFalse(state.update(66, True))


if __name__ == '__main__':
    unittest.main()
