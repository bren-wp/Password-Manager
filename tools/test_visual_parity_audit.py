"""Regression tests for strict reference-to-Flutter pixel comparisons."""
import io
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

from PIL import Image

from visual_parity_audit import compare, scan


class VisualParityTest(unittest.TestCase):
    def test_exact_rgb_equality_requires_every_pixel(self):
        with tempfile.TemporaryDirectory() as directory:
            baseline = Image.new("RGB", (128, 128), (16, 32, 48))
            altered = baseline.copy()
            altered.putpixel((3, 5), (17, 32, 48))
            image_file = Path(directory) / "actual.png"
            altered.save(image_file)
            archive_path = Path(directory) / "reference.zip"
            buffer = io.BytesIO()
            baseline.save(buffer, format="PNG")
            with ZipFile(archive_path, "w") as archive:
                archive.writestr("01.png", buffer.getvalue())
            with ZipFile(archive_path) as archive:
                result = compare(archive, "01.png", image_file)
            self.assertTrue(result["native_size_match"])
            self.assertEqual(result["rgb_mean_absolute_error"], 0)
            self.assertFalse(result["pixel_perfect"])
            self.assertEqual(result["mismatched_pixels"], 1)
            self.assertEqual(result["difference_bbox"], [3, 5, 4, 6])
            self.assertEqual(result["max_channel_difference"], 1)

    def test_resizing_does_not_count_as_exact(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Image.new("RGB", (16, 16), (24, 46, 90))
            image_file = Path(directory) / "actual.png"
            Image.new("RGB", (8, 8), (24, 46, 90)).save(image_file)
            archive_path = Path(directory) / "reference.zip"
            buffer = io.BytesIO()
            source.save(buffer, format="PNG")
            with ZipFile(archive_path, "w") as archive:
                archive.writestr("01.png", buffer.getvalue())
            with ZipFile(archive_path) as archive:
                result = compare(archive, "01.png", image_file)
            self.assertFalse(result["native_size_match"])
            self.assertEqual(result["mismatched_pixels"], 0)
            self.assertFalse(result["pixel_perfect"])

    def test_duplicate_reference_basename_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            archive_path = root / "android.zip"
            buffer = io.BytesIO()
            Image.new("RGB", (4, 4)).save(buffer, format="PNG")
            with ZipFile(archive_path, "w") as archive:
                archive.writestr("one/01.png", buffer.getvalue())
                archive.writestr("two/01.png", buffer.getvalue())
            rows = scan([("android", archive_path)], root)
            self.assertEqual(len(rows), 1)
            self.assertIn("Duplicate reference", rows[0]["error"])


if __name__ == "__main__":
    unittest.main()
