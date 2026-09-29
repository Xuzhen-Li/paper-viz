"""Edge-connected background removal keeps interior light pixels."""

import unittest

import numpy as np
from PIL import Image

from build_hybrid import remove_connected_background


class BackgroundRemovalTest(unittest.TestCase):
    def test_only_the_outer_background_disappears(self):
        image = Image.fromarray(np.full((40, 40, 4), (180, 210, 240, 255), dtype=np.uint8))
        arr = np.array(image)
        arr[8:32, 8:32] = (255, 255, 255, 255)
        arr[14:18, 14:26] = (4, 23, 79, 255)
        arr[20:28, 16:24] = (255, 255, 255, 255)
        cleaned = np.array(remove_connected_background(Image.fromarray(arr), tolerance=20))
        self.assertEqual(int(cleaned[0, 0, 3]), 0)
        self.assertEqual(int(cleaned[10, 10, 3]), 255)
        self.assertEqual(tuple(int(v) for v in cleaned[10, 10, :3]), (255, 255, 255))
        self.assertEqual(int(cleaned[22, 18, 3]), 255)
        self.assertEqual(tuple(int(v) for v in cleaned[16, 18, :3]), (4, 23, 79))


if __name__ == "__main__":
    unittest.main()
