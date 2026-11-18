"""check_manifest.py: the hand-written Cargo.toml against the generator's."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from check_manifest import problems  # noqa: E402

GENERATED = {
    "dependencies": {"serde": "^1.0", "bon": {"version": "^3", "optional": True}},
    "features": {"default": ["full"], "full": ["chat"], "chat": ["chat-types", "_api"], "chat-types": ["dep:bon"], "_api": []},
}


def ours(**changes):
    manifest = {
        "dependencies": {"serde": "^1.0", "bon": {"version": "^3", "optional": True}, "tokio": "1"},
        "features": {"default": ["chat"], "full": ["chat"], "chat": ["_api", "chat-types"], "chat-types": ["dep:bon"], "_api": []},
    }
    for section, values in changes.items():
        manifest[section] = {**manifest[section], **values}
    return manifest


class CheckManifestTests(unittest.TestCase):
    def test_our_own_default_and_dependencies_are_fine(self):
        self.assertEqual(problems(GENERATED, ours()), [])

    def test_a_feature_that_differs_is_reported(self):
        found = problems(GENERATED, ours(features={"chat-types": []}))
        self.assertEqual(len(found), 1)
        self.assertIn("chat-types", found[0])

    def test_a_missing_and_an_extra_feature_are_reported(self):
        manifest = ours(features={"audio": []})
        del manifest["features"]["full"]
        found = problems(GENERATED, manifest)
        self.assertEqual(len(found), 2)
        self.assertTrue(any("full" in p and "missing" in p for p in found))
        self.assertTrue(any("audio" in p for p in found))

    def test_a_dependency_must_be_declared_and_optional_as_generated(self):
        manifest = ours(dependencies={"bon": "^3"})
        del manifest["dependencies"]["serde"]
        found = problems(GENERATED, manifest)
        self.assertEqual(len(found), 2)
        self.assertTrue(any("serde is missing" in p for p in found))
        self.assertTrue(any("bon must be optional" in p for p in found))


if __name__ == "__main__":
    unittest.main()
